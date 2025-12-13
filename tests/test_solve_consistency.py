"""
Tests for consistency between solve() and solve_legacy() methods.

This module contains regression tests for the issue where the old solve_direct()
(now solve()) incorrectly reported problems as "unbounded" while the file-based
solve() (now solve_legacy()) correctly found optimal solutions.
"""

import pytest
import numpy as np

# Skip all tests if benpy cannot be imported
pytest.importorskip('benpy')
import benpy


@pytest.mark.consistency
class TestSolveConsistency:
    """Test cases for solve() and solve_legacy() consistency."""
    
    def test_example01_consistency(self):
        """
        Test that solve() and solve_legacy() return consistent results for example01.
        
        This is a regression test for the issue where solve() (formerly solve_direct())
        incorrectly reported the problem as "unbounded" while solve_legacy() (formerly 
        the file-based solve()) correctly found an optimal solution with eta=[0.25, 0.75].
        """
        # Example 01 problem data
        B = np.array([[2.0, 1.0], [1.0, 2.0]])
        P = np.array([[1.0, -1.0], [1.0, 1.0]])
        a = np.array([6.0, 6.0])
        l = np.array([0.0, 0.0])
        opt_dir = 1
        
        # Solve with solve() (direct array interface)
        sol_direct = benpy.solve(B, P, a=a, l=l, opt_dir=opt_dir)
        
        # Solve with solve_legacy() (file-based)
        problem = benpy.vlpProblem(B=B, P=P, a=a, l=l, opt_dir=opt_dir)
        sol_file = benpy.solve_legacy(problem)
        
        # Both methods should return the same status
        assert sol_direct.status == sol_file.status, \
            f"Status mismatch: solve()='{sol_direct.status}', solve_legacy()='{sol_file.status}'"
        
        # Both should have found an optimal solution (regression check)
        assert sol_direct.status == "optimal", \
            f"Regression: solve() returned status '{sol_direct.status}', expected 'optimal'"
        
        # Both should have the same eta parameter
        np.testing.assert_allclose(sol_direct.eta, sol_file.eta,
                                   err_msg="eta mismatch between solve() and solve_legacy()")
        
        # Verify eta is the expected value (not [0, 0] which indicated the bug)
        expected_eta = np.array([0.25, 0.75])
        np.testing.assert_allclose(sol_direct.eta, expected_eta,
                                   err_msg="Regression: solve() returned incorrect eta")
    
    def test_consistency_with_bounds(self):
        """Test consistency when problems have various bound types."""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        a = np.array([1.0, 0.5])
        b = np.array([2.0, 1.0])
        l = np.array([0.0, 0.0])
        s = np.array([1.0, 1.0])
        opt_dir = 1
        
        # Solve with both methods
        sol_direct = benpy.solve(B, P, a=a, b=b, l=l, s=s, opt_dir=opt_dir)
        
        problem = benpy.vlpProblem(B=B, P=P, a=a, b=b, l=l, s=s, opt_dir=opt_dir)
        sol_file = benpy.solve_legacy(problem)
        
        # Should have consistent status
        assert sol_direct.status == sol_file.status, \
            f"Status mismatch with bounds: solve()='{sol_direct.status}', solve_legacy()='{sol_file.status}'"
        
        # Should have consistent eta if both found solution
        if sol_direct.status in ["optimal", "no_vertex"]:
            np.testing.assert_allclose(sol_direct.eta, sol_file.eta, rtol=1e-5,
                                       err_msg="eta mismatch with bounds")
    
    def test_consistency_maximization(self):
        """Test consistency for maximization problems."""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, -1.0], [1.0, 1.0]])
        b = np.array([2.0])
        l = np.array([0.0, 0.0])
        opt_dir = -1  # maximization
        
        # Solve with both methods
        sol_direct = benpy.solve(B, P, b=b, l=l, opt_dir=opt_dir)
        
        problem = benpy.vlpProblem(B=B, P=P, b=b, l=l, opt_dir=opt_dir)
        sol_file = benpy.solve_legacy(problem)
        
        # Should have consistent status
        assert sol_direct.status == sol_file.status, \
            f"Status mismatch for maximization: solve()='{sol_direct.status}', solve_legacy()='{sol_file.status}'"
        
        # Should have consistent eta
        if sol_direct.status in ["optimal", "no_vertex"]:
            np.testing.assert_allclose(sol_direct.eta, sol_file.eta, rtol=1e-5,
                                       err_msg="eta mismatch for maximization")
    
    def test_vertex_counts_match(self):
        """Test that vertex counts match between both methods."""
        B = np.array([[2.0, 1.0], [1.0, 2.0]])
        P = np.array([[1.0, -1.0], [1.0, 1.0]])
        a = np.array([6.0, 6.0])
        l = np.array([0.0, 0.0])
        
        # Solve with both methods
        sol_direct = benpy.solve(B, P, a=a, l=l, opt_dir=1)
        
        problem = benpy.vlpProblem(B=B, P=P, a=a, l=l, opt_dir=1)
        sol_file = benpy.solve_legacy(problem)
        
        # Vertex counts should match
        assert sol_direct.num_vertices_upper == sol_file.num_vertices_upper, \
            f"num_vertices_upper mismatch: solve()={sol_direct.num_vertices_upper}, solve_legacy()={sol_file.num_vertices_upper}"
        assert sol_direct.num_vertices_lower == sol_file.num_vertices_lower, \
            f"num_vertices_lower mismatch: solve()={sol_direct.num_vertices_lower}, solve_legacy()={sol_file.num_vertices_lower}"
