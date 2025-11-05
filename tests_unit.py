#!/usr/bin/env python3
"""
Unit tests for benpy in-memory interface and structure exposure.
"""

import unittest
import numpy as np
import sys
sys.path.insert(0, 'src')

import benpy


class TestInMemoryInterface(unittest.TestCase):
    """Test cases for the in-memory interface"""
    
    def setUp(self):
        """Set up test fixtures"""
        # Simple test problem
        self.B = np.array([[1.0, 1.0], [1.0, 0.0]])
        self.P = np.array([[1.0, 0.0], [0.0, 1.0]])
        self.b = np.array([2.0, 1.0])
        self.l = np.array([0.0, 0.0])
        
    def test_from_arrays_basic(self):
        """Test basic from_arrays functionality"""
        prob = benpy._cVlpProblem()
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        
        self.assertEqual(prob.m, 2)
        self.assertEqual(prob.n, 2)
        self.assertEqual(prob.q, 2)
        self.assertEqual(prob.optdir, 1)
        
    def test_constraint_matrix_recovery(self):
        """Test that we can recover the constraint matrix"""
        prob = benpy._cVlpProblem()
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        
        recovered_B = prob.constraint_matrix
        np.testing.assert_array_almost_equal(recovered_B, self.B)
        
    def test_objective_matrix_recovery(self):
        """Test that we can recover the objective matrix"""
        prob = benpy._cVlpProblem()
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        
        recovered_P = prob.objective_matrix
        np.testing.assert_array_almost_equal(recovered_P, self.P)
        
    def test_solve_direct(self):
        """Test solve_direct function"""
        sol = benpy.solve_direct(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        
        # Check that solution is returned
        self.assertIsNotNone(sol)
        self.assertIsNotNone(sol.c)
        self.assertEqual(len(sol.c), 2)
        
    def test_dimension_mismatch(self):
        """Test that dimension mismatches are caught"""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0, 0.0]])  # Wrong size
        
        prob = benpy._cVlpProblem()
        with self.assertRaises(ValueError):
            prob.from_arrays(B, P, opt_dir=1)
            
    def test_sparse_matrices(self):
        """Test with sparse matrices"""
        from scipy.sparse import lil_matrix
        
        B_sparse = lil_matrix(self.B)
        P_sparse = lil_matrix(self.P)
        
        prob = benpy._cVlpProblem()
        prob.from_arrays(B_sparse, P_sparse, b=self.b, l=self.l, opt_dir=1)
        
        # Should handle sparse matrices correctly
        self.assertEqual(prob.m, 2)
        self.assertEqual(prob.n, 2)
        
    def test_bounds_handling(self):
        """Test various bound specifications"""
        prob = benpy._cVlpProblem()
        
        # Test with different bound combinations
        a = np.array([1.0, -np.inf])
        b = np.array([np.inf, 2.0])
        l = np.array([0.0, -np.inf])
        s = np.array([np.inf, 5.0])
        
        prob.from_arrays(self.B, self.P, a=a, b=b, l=l, s=s, opt_dir=1)
        
        self.assertEqual(prob.m, 2)
        self.assertEqual(prob.n, 2)
        
    def test_ordering_cone(self):
        """Test custom ordering cone specification"""
        prob = benpy._cVlpProblem()
        
        # Define a custom cone
        Y = np.array([[1.0, 0.0], [0.0, 1.0]])
        
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, Y=Y, opt_dir=1)
        
        self.assertEqual(prob.q, 2)
        
    def test_duality_parameter(self):
        """Test duality parameter specification"""
        prob = benpy._cVlpProblem()
        
        c = np.array([0.5, 0.5])
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, c=c, opt_dir=1)
        
        self.assertEqual(prob.q, 2)


class TestStructureExposure(unittest.TestCase):
    """Test cases for direct structure access"""
    
    def setUp(self):
        """Set up test problem"""
        self.B = np.array([[2.0, 1.0], [1.0, 3.0]])
        self.P = np.array([[1.0, 0.0], [0.0, 1.0]])
        self.b = np.array([4.0, 5.0])
        self.l = np.array([0.0, 0.0])
        
    def test_problem_properties(self):
        """Test problem property access"""
        prob = benpy._cVlpProblem()
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        
        # Test dimension properties
        self.assertIsInstance(prob.m, int)
        self.assertIsInstance(prob.n, int)
        self.assertIsInstance(prob.q, int)
        self.assertIsInstance(prob.nz, int)
        self.assertIsInstance(prob.nzobj, int)
        self.assertIsInstance(prob.optdir, int)
        
    def test_matrix_properties(self):
        """Test matrix property access"""
        prob = benpy._cVlpProblem()
        prob.from_arrays(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        
        # Test matrix recovery
        A = prob.constraint_matrix
        P = prob.objective_matrix
        
        self.assertEqual(A.shape, (2, 2))
        self.assertEqual(P.shape, (2, 2))
        self.assertIsInstance(A, np.ndarray)
        self.assertIsInstance(P, np.ndarray)


class TestCompatibility(unittest.TestCase):
    """Test backward compatibility"""
    
    def test_traditional_solve_still_works(self):
        """Ensure traditional solve() method still works"""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([1.0])
        l = np.array([0.0, 0.0])
        
        # Traditional approach
        prob = benpy.vlpProblem(B=B, P=P, b=b, l=l, opt_dir=1)
        sol = benpy.solve(prob)
        
        self.assertIsNotNone(sol)
        self.assertIsNotNone(sol.c)


if __name__ == '__main__':
    # Run tests
    unittest.main(verbosity=2)
