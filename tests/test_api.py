"""
API compatibility tests for benpy.

These tests verify that the benpy API works correctly and maintains
backward compatibility.
"""

import pytest
import numpy as np
from scipy.sparse import lil_matrix


# Skip all tests if benpy cannot be imported
pytest.importorskip('benpy')
import benpy


@pytest.mark.api
class TestInMemoryInterface:
    """Test cases for the in-memory interface."""
    
    def test_from_arrays_basic(self, simple_2d_problem):
        """Test basic from_arrays functionality."""
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert prob.m == 2
        assert prob.n == 2
        assert prob.q == 2
        assert prob.optdir == 1
        
    def test_constraint_matrix_recovery(self, simple_2d_problem):
        """Test that we can recover the constraint matrix."""
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        recovered_B = prob.constraint_matrix
        np.testing.assert_array_almost_equal(recovered_B, simple_2d_problem['B'])
        
    def test_objective_matrix_recovery(self, simple_2d_problem):
        """Test that we can recover the objective matrix."""
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        recovered_P = prob.objective_matrix
        np.testing.assert_array_almost_equal(recovered_P, simple_2d_problem['P'])
        
    def test_solve_direct(self, simple_2d_problem):
        """Test solve_direct function."""
        sol = benpy.solve_direct(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Check that solution is returned
        assert sol is not None
        assert sol.c is not None
        assert len(sol.c) == 2
        
    def test_dimension_mismatch(self):
        """Test that dimension mismatches are caught."""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0, 0.0]])  # Wrong size
        
        prob = benpy._cVlpProblem()
        with pytest.raises(ValueError):
            prob.from_arrays(B, P, opt_dir=1)
            
    def test_sparse_matrices(self, simple_2d_problem):
        """Test with sparse matrices."""
        B_sparse = lil_matrix(simple_2d_problem['B'])
        P_sparse = lil_matrix(simple_2d_problem['P'])
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(
            B_sparse,
            P_sparse,
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Should handle sparse matrices correctly
        assert prob.m == 2
        assert prob.n == 2
        
    def test_bounds_handling(self):
        """Test various bound specifications."""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        
        prob = benpy._cVlpProblem()
        
        # Test with different bound combinations
        a = np.array([1.0, -np.inf])
        b = np.array([np.inf, 2.0])
        l = np.array([0.0, -np.inf])
        s = np.array([np.inf, 5.0])
        
        prob.from_arrays(B, P, a=a, b=b, l=l, s=s, opt_dir=1)
        
        assert prob.m == 2
        assert prob.n == 2
        
    def test_ordering_cone(self):
        """Test custom ordering cone specification."""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0, 1.0])
        l = np.array([0.0, 0.0])
        
        prob = benpy._cVlpProblem()
        
        # Define a custom cone
        Y = np.array([[1.0, 0.0], [0.0, 1.0]])
        
        prob.from_arrays(B, P, b=b, l=l, Y=Y, opt_dir=1)
        
        assert prob.q == 2
        
    def test_duality_parameter(self):
        """Test duality parameter specification."""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0, 1.0])
        l = np.array([0.0, 0.0])
        
        prob = benpy._cVlpProblem()
        
        c = np.array([0.5, 0.5])
        prob.from_arrays(B, P, b=b, l=l, c=c, opt_dir=1)
        
        assert prob.q == 2


@pytest.mark.api
class TestStructureExposure:
    """Test cases for direct structure access."""
    
    def test_problem_properties(self):
        """Test problem property access."""
        B = np.array([[2.0, 1.0], [1.0, 3.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([4.0, 5.0])
        l = np.array([0.0, 0.0])
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
        
        # Test dimension properties
        assert isinstance(prob.m, int)
        assert isinstance(prob.n, int)
        assert isinstance(prob.q, int)
        assert isinstance(prob.nz, int)
        assert isinstance(prob.nzobj, int)
        assert isinstance(prob.optdir, int)
        
    def test_matrix_properties(self):
        """Test matrix property access."""
        B = np.array([[2.0, 1.0], [1.0, 3.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([4.0, 5.0])
        l = np.array([0.0, 0.0])
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(B, P, b=b, l=l, opt_dir=1)
        
        # Test matrix recovery
        A = prob.constraint_matrix
        P_recovered = prob.objective_matrix
        
        assert A.shape == (2, 2)
        assert P_recovered.shape == (2, 2)
        assert isinstance(A, np.ndarray)
        assert isinstance(P_recovered, np.ndarray)


@pytest.mark.api
class TestCompatibility:
    """Test backward compatibility."""
    
    def test_traditional_solve_still_works(self):
        """Ensure traditional solve() method still works."""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([1.0])
        l = np.array([0.0, 0.0])
        
        # Traditional approach
        prob = benpy.vlpProblem(B=B, P=P, b=b, l=l, opt_dir=1)
        sol = benpy.solve(prob)
        
        assert sol is not None
        assert sol.c is not None
        
    def test_vlp_problem_attributes(self):
        """Test that vlpProblem has expected attributes."""
        prob = benpy.vlpProblem()
        
        # Should be able to set these attributes
        prob.B = np.array([[1.0, 1.0]])
        prob.P = np.array([[1.0, 0.0], [0.0, 1.0]])
        prob.b = np.array([1.0])
        prob.l = np.array([0.0, 0.0])
        prob.opt_dir = 1
        
        assert prob.B is not None
        assert prob.P is not None


@pytest.mark.api
class TestSolutionInterface:
    """Test solution object interface."""
    
    def test_solution_attributes(self, simple_2d_problem):
        """Test that solution has expected attributes."""
        sol = benpy.solve_direct(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Check basic attributes
        assert hasattr(sol, 'status')
        assert hasattr(sol, 'c')
        assert hasattr(sol, 'c_vector')
        assert hasattr(sol, 'Primal')
        
    def test_solution_primal_access(self, simple_2d_problem):
        """Test accessing primal solution data."""
        sol = benpy.solve_direct(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Access primal data
        primal = sol.Primal
        assert primal is not None
        
    def test_solution_cone_data(self, simple_2d_problem):
        """Test accessing ordering cone data from solution."""
        sol = benpy.solve_direct(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # Check cone-related attributes
        assert hasattr(sol, 'Y')
        assert hasattr(sol, 'Z')
        
    def test_solution_vertex_counts(self, simple_2d_problem):
        """Test vertex count attributes."""
        sol = benpy.solve_direct(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert hasattr(sol, 'num_vertices_upper')
        assert hasattr(sol, 'num_vertices_lower')
        assert isinstance(sol.num_vertices_upper, int)
        assert isinstance(sol.num_vertices_lower, int)


@pytest.mark.api
class TestOptimizationDirections:
    """Test minimization and maximization."""
    
    def test_minimization(self):
        """Test minimization (opt_dir=1)."""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0])
        l = np.array([0.0, 0.0])
        
        sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
        assert sol is not None
        
    def test_maximization(self):
        """Test maximization (opt_dir=-1)."""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0])
        l = np.array([0.0, 0.0])
        
        sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=-1)
        assert sol is not None


@pytest.mark.api
class TestDataTypes:
    """Test that various data types are handled correctly."""
    
    def test_float32_arrays(self):
        """Test with float32 arrays."""
        B = np.array([[1.0, 1.0]], dtype=np.float32)
        P = np.array([[1.0, 0.0], [0.0, 1.0]], dtype=np.float32)
        b = np.array([1.0], dtype=np.float32)
        l = np.array([0.0, 0.0], dtype=np.float32)
        
        sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
        assert sol is not None
        
    def test_float64_arrays(self):
        """Test with float64 arrays (default)."""
        B = np.array([[1.0, 1.0]], dtype=np.float64)
        P = np.array([[1.0, 0.0], [0.0, 1.0]], dtype=np.float64)
        b = np.array([1.0], dtype=np.float64)
        l = np.array([0.0, 0.0], dtype=np.float64)
        
        sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
        assert sol is not None
        
    def test_integer_conversion(self):
        """Test that integer arrays are converted to float."""
        B = np.array([[1, 1]])
        P = np.array([[1, 0], [0, 1]])
        b = np.array([1])
        l = np.array([0, 0])
        
        # Should work by converting to float
        sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
        assert sol is not None
