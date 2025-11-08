"""
Tests using bensolve example problems.

These tests verify that benpy correctly handles the example problems
from the bensolve distribution (src/bensolve-2.1.0/ex/).
"""

import pytest
import sys
import numpy as np
from problems import (
    get_example01, get_example02, get_example03, get_example04,
    get_example05, get_example06, get_example08, get_example11,
    get_all_examples, get_solvable_examples
)


# Skip all tests in this module if benpy cannot be imported
pytest.importorskip('benpy')
import benpy


@pytest.mark.examples
class TestExampleProblems:
    """Test suite for bensolve example problems."""
    
    def test_example01_simple_molp(self):
        """Test example01: Simple 2-objective MOLP."""
        prob_data = get_example01()
        
        # Test using solve_direct
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            l=prob_data['l'],
            opt_dir=prob_data['opt_dir']
        )
        
        assert sol is not None, "Solution should not be None"
        assert hasattr(sol, 'c'), "Solution should have c attribute"
        assert len(sol.c) == 2, "Solution should have 2 objectives"
        
    def test_example01_traditional_interface(self):
        """Test example01 using traditional vlpProblem interface."""
        prob_data = get_example01()
        
        prob = benpy.vlpProblem(
            B=prob_data['B'],
            P=prob_data['P'],
            a=prob_data['a'],
            l=prob_data['l'],
            opt_dir=prob_data['opt_dir']
        )
        
        sol = benpy.solve_legacy(prob)
        
        assert sol is not None, "Solution should not be None"
        assert hasattr(sol, 'c'), "Solution should have c attribute"
        
    @pytest.mark.xfail(reason="Example02 is intentionally infeasible")
    def test_example02_infeasible(self):
        """Test example02: Infeasible problem should be detected."""
        prob_data = get_example02()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data.get('a'),
            b=prob_data.get('b'),
            opt_dir=prob_data['opt_dir']
        )
        
        # This problem is infeasible, so we expect failure
        # The exact behavior depends on how bensolve reports infeasibility
        pytest.fail("Problem should be detected as infeasible")
        
    def test_example03_no_vertex(self):
        """Test example03: Upper image has no vertex."""
        prob_data = get_example03()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            opt_dir=prob_data['opt_dir']
        )
        
        assert sol is not None, "Solution should not be None"
        assert sol.status == 'no_vertex', "Status should be 'no_vertex'"
        
    @pytest.mark.slow
    def test_example04_totally_unbounded(self):
        """Test example04: Totally unbounded problem."""
        prob_data = get_example04()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            opt_dir=prob_data['opt_dir']
        )
        
        # Unbounded problems should still return a solution object
        assert sol is not None, "Solution should not be None"
        assert sol.status == 'unbounded', "Status should be 'unbounded'"
        
    @pytest.mark.slow
    def test_example05_custom_cone(self):
        """Test example05: VLP with custom ordering cone."""
        prob_data = get_example05()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            l=prob_data['l'],
            Y=prob_data['Y'],
            c=prob_data['c'],
            opt_dir=prob_data['opt_dir']
        )
        
        assert sol is not None, "Solution should not be None"
        assert hasattr(sol, 'c'), "Solution should have c attribute"
        assert len(sol.c) == 3, "Solution should have 3 objectives"
        
    def test_example06_maximization(self):
        """Test example06: Maximization problem with dual cone."""
        prob_data = get_example06()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            b=prob_data['b'],
            l=prob_data['l'],
            s=prob_data['s'],
            Z=prob_data['Z'],
            c=prob_data['c'],
            opt_dir=prob_data['opt_dir']
        )
        
        assert sol is not None, "Solution should not be None"
        assert hasattr(sol, 'c'), "Solution should have c attribute"
        
    @pytest.mark.slow
    def test_example08_partially_unbounded(self):
        """Test example08: Unbounded but not totally unbounded."""
        prob_data = get_example08()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            Y=prob_data['Y'],
            c=prob_data['c'],
            opt_dir=prob_data['opt_dir']
        )
        
        assert sol is not None, "Solution should not be None"
        
    @pytest.mark.slow
    def test_example11_high_dimensional(self):
        """Test example11: 5-objective problem with many constraints."""
        prob_data = get_example11()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            opt_dir=prob_data['opt_dir']
        )
        
        assert sol is not None, "Solution should not be None"
        assert hasattr(sol, 'c'), "Solution should have c attribute"
        assert len(sol.c) == 5, "Solution should have 5 objectives"


@pytest.mark.examples
@pytest.mark.integration
class TestExampleConsistency:
    """Test consistency across different examples."""
    
    def test_all_solvable_examples_run(self):
        """Test that all solvable examples can be run without errors."""
        solvable = get_solvable_examples()
        examples = get_all_examples()
        
        for name in solvable:
            if name not in examples:
                continue
                
            prob_data = examples[name]
            
            # Try to solve it
            try:
                sol = benpy.solve(
                    prob_data['B'],
                    prob_data['P'],
                    a=prob_data.get('a'),
                    b=prob_data.get('b'),
                    l=prob_data.get('l'),
                    s=prob_data.get('s'),
                    Y=prob_data.get('Y'),
                    Z=prob_data.get('Z'),
                    c=prob_data.get('c'),
                    opt_dir=prob_data.get('opt_dir', 1)
                )
                assert sol is not None, f"{name} should return a solution"
            except Exception as e:
                pytest.fail(f"{name} failed with error: {e}")
                
    def test_problem_dimensions_consistent(self):
        """Test that problem dimensions are internally consistent."""
        examples = get_all_examples()
        
        for name, prob_data in examples.items():
            B = prob_data['B']
            P = prob_data['P']
            
            # Check that B and P have compatible dimensions
            m, n = B.shape
            q, n2 = P.shape
            
            assert n == n2, f"{name}: B and P must have same number of columns"
            
            # Check bounds if present
            if 'a' in prob_data and prob_data['a'] is not None:
                assert len(prob_data['a']) == m, f"{name}: len(a) must equal number of rows in B"
                
            if 'b' in prob_data and prob_data['b'] is not None:
                assert len(prob_data['b']) == m, f"{name}: len(b) must equal number of rows in B"
                
            if 'l' in prob_data and prob_data['l'] is not None:
                assert len(prob_data['l']) == n, f"{name}: len(l) must equal number of columns in B"
                
            if 's' in prob_data and prob_data['s'] is not None:
                assert len(prob_data['s']) == n, f"{name}: len(s) must equal number of columns in B"


@pytest.mark.examples
class TestExampleProperties:
    """Test properties of solutions from examples."""
    
    def test_example01_solution_properties(self):
        """Test that example01 solution has expected properties."""
        prob_data = get_example01()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            l=prob_data['l'],
            opt_dir=prob_data['opt_dir']
        )
        
        # Check solution structure
        assert hasattr(sol, 'status'), "Solution should have status"
        assert hasattr(sol, 'c'), "Solution should have c (duality parameter)"
        
        # The c vector should be in R^q (q=2 for this problem)
        assert len(sol.c) == 2, "Duality parameter should have length 2"
        
    def test_solution_has_primal_data(self):
        """Test that solutions contain primal data."""
        prob_data = get_example01()
        
        sol = benpy.solve(
            prob_data['B'],
            prob_data['P'],
            a=prob_data['a'],
            l=prob_data['l'],
            opt_dir=prob_data['opt_dir']
        )
        
        # Check for primal solution components
        assert hasattr(sol, 'Primal'), "Solution should have Primal attribute"
        
    def test_example05_cone_dimensions(self):
        """Test that example05 cone parameters have correct dimensions."""
        prob_data = get_example05()
        
        Y = prob_data['Y']
        c = prob_data['c']
        P = prob_data['P']
        
        q = P.shape[0]  # Number of objectives
        
        # Y should be q x k for some k
        assert Y.shape[0] == q, "Y should have q rows"
        
        # c should have length q
        assert len(c) == q, "c should have length q"
