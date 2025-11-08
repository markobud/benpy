"""
Test for vlpSolution attributes added to fix GitHub issue.

Tests that vlpSolution objects have the following attributes as used in notebooks:
- status: Solution status (e.g., "optimal", "unbounded", etc.)
- num_vertices_upper: Number of vertices in the upper polytope
- num_vertices_lower: Number of vertices in the lower polytope
- Y: Ordering cone generators
- Z: Dual cone generators
"""

import pytest
import numpy as np

pytest.importorskip('benpy')
import benpy


@pytest.mark.api
class TestVlpSolutionAttributes:
    """Test cases for vlpSolution attributes."""
    
    def test_status_attribute_exists(self, simple_2d_problem):
        """Test that status attribute exists and is a string."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert hasattr(sol, 'status'), "vlpSolution should have status attribute"
        assert isinstance(sol.status, str), "status should be a string"
        # Status should be one of the known values
        valid_statuses = ['no_status', 'infeasible', 'unbounded', 'no_vertex', 
                         'optimal', 'input_error', 'unexpected_status']
        assert any(sol.status.startswith(s) for s in valid_statuses), \
            f"status '{sol.status}' should be one of {valid_statuses}"
    
    def test_num_vertices_upper_attribute(self, simple_2d_problem):
        """Test that num_vertices_upper attribute exists and is an integer."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert hasattr(sol, 'num_vertices_upper'), \
            "vlpSolution should have num_vertices_upper attribute"
        assert isinstance(sol.num_vertices_upper, int), \
            "num_vertices_upper should be an integer"
        assert sol.num_vertices_upper >= 0, \
            "num_vertices_upper should be non-negative"
    
    def test_num_vertices_lower_attribute(self, simple_2d_problem):
        """Test that num_vertices_lower attribute exists and is an integer."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert hasattr(sol, 'num_vertices_lower'), \
            "vlpSolution should have num_vertices_lower attribute"
        assert isinstance(sol.num_vertices_lower, int), \
            "num_vertices_lower should be an integer"
        assert sol.num_vertices_lower >= 0, \
            "num_vertices_lower should be non-negative"
    
    def test_Y_attribute(self, simple_2d_problem):
        """Test that Y (ordering cone generators) attribute exists."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert hasattr(sol, 'Y'), "vlpSolution should have Y attribute"
        # Y can be None or a numpy array
        if sol.Y is not None:
            assert isinstance(sol.Y, np.ndarray), "Y should be a numpy array"
            assert sol.Y.ndim == 2, "Y should be a 2D array"
    
    def test_Z_attribute(self, simple_2d_problem):
        """Test that Z (dual cone generators) attribute exists."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        assert hasattr(sol, 'Z'), "vlpSolution should have Z attribute"
        # Z can be None or a numpy array
        if sol.Z is not None:
            assert isinstance(sol.Z, np.ndarray), "Z should be a numpy array"
            assert sol.Z.ndim == 2, "Z should be a 2D array"
    
    def test_all_notebook_attributes(self, simple_2d_problem):
        """Test that all attributes used in example notebooks are present."""
        sol = benpy.solve(
            simple_2d_problem['B'],
            simple_2d_problem['P'],
            a=simple_2d_problem.get('a'),
            l=simple_2d_problem.get('l'),
            opt_dir=simple_2d_problem['opt_dir']
        )
        
        # All attributes from notebooks should exist
        required_attrs = ['status', 'num_vertices_upper', 'num_vertices_lower', 
                         'Y', 'Z', 'c', 'Primal', 'Dual']
        
        for attr in required_attrs:
            assert hasattr(sol, attr), \
                f"vlpSolution should have {attr} attribute (used in notebooks)"
    
    def test_solve_also_has_attributes(self, simple_2d_problem):
        """Test that solve() function also populates new attributes."""
        # Create a vlpProblem
        prob = benpy.vlpProblem()
        prob.B = simple_2d_problem['B']
        prob.P = simple_2d_problem['P']
        if simple_2d_problem.get('a') is not None:
            prob.a = simple_2d_problem['a']
        if simple_2d_problem.get('l') is not None:
            prob.l = simple_2d_problem['l']
        prob.opt_dir = simple_2d_problem['opt_dir']
        
        sol = benpy.solve_legacy(prob)
        
        # Check new attributes exist
        assert hasattr(sol, 'status')
        assert hasattr(sol, 'num_vertices_upper')
        assert hasattr(sol, 'num_vertices_lower')
        assert hasattr(sol, 'Y')
        assert hasattr(sol, 'Z')
        
        # Check types
        assert isinstance(sol.status, str)
        assert isinstance(sol.num_vertices_upper, int)
        assert isinstance(sol.num_vertices_lower, int)
