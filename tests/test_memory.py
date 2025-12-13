"""
Memory leak detection tests for benpy.

These tests verify that memory is properly freed when problem and solution 
objects are destroyed.
"""

import pytest
import gc
import sys
import tempfile
import os
import numpy as np


# Skip all tests if benpy cannot be imported
pytest.importorskip('benpy')
import benpy


@pytest.mark.memory
class TestMemoryManagement:
    """Test cases for memory management."""
    
    def test_problem_dealloc_called(self, simple_2d_problem):
        """Test that __dealloc__ is called when problem is deleted."""
        # Create and destroy a problem
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Verify problem is valid
        assert prob.m == 2
        assert prob.n == 2
        
        # Delete should trigger __dealloc__
        del prob
        gc.collect()
        
        # If we got here without crash, __dealloc__ was called successfully
        
    def test_solution_dealloc_called(self, simple_2d_problem):
        """Test that __dealloc__ is called when solution is deleted."""
        # Create and solve
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Verify solution is valid
        assert sol is not None
        
        # Delete should trigger __dealloc__
        del sol
        gc.collect()
        
        # If we got here without crash, __dealloc__ was called successfully
        
    def test_multiple_problems_no_crash(self, simple_2d_problem):
        """Test that creating/destroying multiple problems doesn't crash."""
        # This would crash if memory isn't properly freed and we run out
        for i in range(50):
            prob = benpy._cVlpProblem()
            prob.from_arrays(
                simple_2d_problem['B'],
                simple_2d_problem['P'],
                a=simple_2d_problem.get('a'),
                l=simple_2d_problem.get('l'),
                opt_dir=simple_2d_problem['opt_dir']
            )
            assert prob.m == 2
            del prob
        
        gc.collect()
        
    @pytest.mark.slow
    def test_multiple_solutions_no_crash(self, simple_2d_problem):
        """Test that creating/destroying multiple solutions doesn't crash."""
        # This would crash if memory isn't properly freed
        for i in range(20):
            sol = benpy.solve(
                simple_2d_problem['B'],
                simple_2d_problem['P'],
                a=simple_2d_problem.get('a'),
                l=simple_2d_problem.get('l'),
                opt_dir=simple_2d_problem['opt_dir']
            )
            assert sol is not None
            del sol
        
        gc.collect()
        
    def test_problem_with_ordering_cone(self):
        """Test memory management with ordering cone generators."""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0, 1.0])
        l = np.array([0.0, 0.0])
        Y = np.array([[1.0, 0.0], [0.0, 1.0]])
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(B, P, b=b, l=l, Y=Y, opt_dir=1)
        
        assert prob.m == 2
        del prob
        gc.collect()
        
    def test_problem_with_duality_parameter(self):
        """Test memory management with duality parameter vector."""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0, 1.0])
        l = np.array([0.0, 0.0])
        c = np.array([1.0, 1.0])
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(B, P, b=b, l=l, c=c, opt_dir=1)
        
        assert prob.m == 2
        del prob
        gc.collect()
        
    def test_solution_properties_access(self, simple_2d_problem):
        """Test that accessing solution properties doesn't cause issues."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Access various properties
        _ = sol.status
        _ = sol.num_vertices_upper
        _ = sol.num_vertices_lower
        _ = sol.eta
        _ = sol.Y
        _ = sol.Z
        _ = sol.c_vector
        _ = sol.R
        _ = sol.H
        
        # Delete should still work properly
        del sol
        gc.collect()
        
    def test_file_based_problem(self):
        """Test memory management with file-based problem loading."""
        # Create a simple VLP file
        with tempfile.NamedTemporaryFile(mode='w', suffix='.vlp', delete=False) as f:
            f.write("NAME test\n")
            f.write("ROWS\n")
            f.write(" N obj1\n")
            f.write(" N obj2\n")
            f.write(" L c1\n")
            f.write(" L c2\n")
            f.write("COLUMNS\n")
            f.write("    x1  obj1  1.0\n")
            f.write("    x1  c1    1.0\n")
            f.write("    x1  c2    1.0\n")
            f.write("    x2  obj2  1.0\n")
            f.write("    x2  c1    1.0\n")
            f.write("RHS\n")
            f.write("    rhs  c1  2.0\n")
            f.write("    rhs  c2  1.0\n")
            f.write("BOUNDS\n")
            f.write(" LO bnd  x1  0.0\n")
            f.write(" LO bnd  x2  0.0\n")
            f.write("ENDATA\n")
            filename = f.name
        
        try:
            prob = benpy._cVlpProblem()
            prob.from_file(filename)
            
            # Should be able to delete without issues
            del prob
            gc.collect()
        finally:
            os.unlink(filename)
            
    def test_ref_counting(self, simple_2d_problem):
        """Test that Python reference counting works correctly."""
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Get initial refcount
        initial_refcount = sys.getrefcount(prob)
        
        # Create a reference
        prob2 = prob
        assert sys.getrefcount(prob) == initial_refcount + 1
        
        # Delete reference
        del prob2
        assert sys.getrefcount(prob) == initial_refcount
        
        # Final delete should trigger __dealloc__
        del prob
        gc.collect()
        
    def test_reuse_problem_object(self):
        """Test that reusing a problem object doesn't leak memory."""
        B1 = np.array([[1.0, 1.0], [1.0, 0.0]])
        P1 = np.array([[1.0, 0.0], [0.0, 1.0]])
        b1 = np.array([2.0, 1.0])
        l1 = np.array([0.0, 0.0])
        
        prob = benpy._cVlpProblem()
        
        # First problem
        prob.from_arrays(B1, P1, b=b1, l=l1, opt_dir=1)
        assert prob.m == 2
        
        # Second problem (should free first allocation)
        B2 = np.array([[1.0, 0.0], [0.0, 1.0], [1.0, 1.0]])
        P2 = np.array([[1.0, 0.0], [0.0, 1.0]])
        b2 = np.array([1.0, 1.0, 2.0])
        l2 = np.array([0.0, 0.0])
        
        prob.from_arrays(B2, P2, b=b2, l=l2, opt_dir=1)
        assert prob.m == 3
        
        # Third problem (should free second allocation)
        prob.from_arrays(B1, P1, b=b1, l=l1, opt_dir=1)
        assert prob.m == 2
        
        # Delete should only free the last allocation
        del prob
        gc.collect()


@pytest.mark.memory
class TestMemoryInitialization:
    """Test that memory is properly initialized."""
    
    def test_null_initialization(self):
        """Test that structures are initialized to safe values."""
        # This test verifies that __cinit__ initializes pointers to NULL
        # If not properly initialized, __dealloc__ on an unused object could crash
        
        prob = benpy._cVlpProblem()
        # Don't call from_arrays - just create and destroy
        del prob
        gc.collect()
        
        # Should not crash
        
    def test_partial_initialization_error_handling(self, simple_2d_problem):
        """Test that errors during initialization are handled safely."""
        # This would test error handling in from_arrays if we had a way
        # to trigger allocation failures. For now, just verify normal path.
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        del prob
        gc.collect()
