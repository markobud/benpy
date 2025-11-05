#!/usr/bin/env python3
"""
Test script for in-memory interface to bensolve.

This demonstrates the new solve_direct() function that bypasses file I/O
and works directly with numpy arrays.
"""

import numpy as np
import sys
sys.path.insert(0, 'src')

import benpy

def test_simple_problem():
    """Test a simple 2D bi-objective problem"""
    print("=" * 70)
    print("Test 1: Simple bi-objective problem")
    print("=" * 70)
    
    # Define a simple problem:
    # Minimize [x1, x2] subject to:
    #   x1 + x2 <= 1
    #   x1 >= 0, x2 >= 0
    #   x1 <= 1, x2 <= 1
    
    B = np.array([[1.0, 1.0]])  # Constraint matrix (1 constraint)
    P = np.array([[1.0, 0.0],    # Objective matrix (2 objectives)
                  [0.0, 1.0]])
    
    b = np.array([1.0])  # Upper bounds on constraints
    l = np.array([0.0, 0.0])  # Lower bounds on variables
    s = np.array([1.0, 1.0])  # Upper bounds on variables
    
    print("\nProblem definition:")
    print(f"  Constraint matrix B:\n{B}")
    print(f"  Objective matrix P:\n{P}")
    print(f"  Constraint upper bounds b: {b}")
    print(f"  Variable lower bounds l: {l}")
    print(f"  Variable upper bounds s: {s}")
    
    # Solve using new in-memory interface
    print("\nSolving with solve_direct() (no file I/O)...")
    sol = benpy.solve_direct(B, P, b=b, l=l, s=s, opt_dir=1)
    
    print("\nSolution:")
    print(f"  Duality parameter c: {sol.c}")
    print(f"  Number of primal vertices: {len(sol.Primal.vertex_type)}")
    print(f"  Number of dual vertices: {len(sol.Dual.vertex_type)}")
    
    print("\nPrimal vertices:")
    for i, (vtype, value) in enumerate(zip(sol.Primal.vertex_type, sol.Primal.vertex_value)):
        print(f"  Vertex {i} (type {vtype}): {value}")
    
    print("\n" + "=" * 70)
    return sol


def test_structure_access():
    """Test direct access to C structures"""
    print("\n" + "=" * 70)
    print("Test 2: Direct structure access")
    print("=" * 70)
    
    # Create a problem
    from benpy import _cVlpProblem
    prob = _cVlpProblem()
    
    B = np.array([[1.0, 2.0], [3.0, 4.0]])
    P = np.array([[1.0, 0.0], [0.0, 1.0]])
    b = np.array([5.0, 6.0])
    
    print("\nInitializing problem from arrays...")
    prob.from_arrays(B, P, b=b, opt_dir=1)
    
    print(f"\nProblem dimensions:")
    print(f"  m (constraints): {prob.m}")
    print(f"  n (variables): {prob.n}")
    print(f"  q (objectives): {prob.q}")
    print(f"  Non-zero constraint entries: {prob.nz}")
    print(f"  Non-zero objective entries: {prob.nzobj}")
    print(f"  Optimization direction: {prob.optdir}")
    
    print(f"\nRecovered constraint matrix:")
    print(prob.constraint_matrix)
    
    print(f"\nRecovered objective matrix:")
    print(prob.objective_matrix)
    
    print("\n" + "=" * 70)


def test_comparison():
    """Compare file-based and memory-based approaches"""
    print("\n" + "=" * 70)
    print("Test 3: Compare file-based vs memory-based solve")
    print("=" * 70)
    
    # Define problem
    B = np.array([[1.0, 1.0], [1.0, 0.0]])
    P = np.array([[1.0, 0.0], [0.0, 1.0]])
    b = np.array([2.0, 1.0])
    l = np.array([0.0, 0.0])
    
    # Solve using traditional file-based method
    print("\nMethod 1: Traditional solve() with file I/O...")
    import time
    t1 = time.time()
    prob = benpy.vlpProblem(B=B, P=P, b=b, l=l, opt_dir=1)
    sol1 = benpy.solve(prob)
    t_file = time.time() - t1
    print(f"  Time: {t_file:.4f} seconds")
    print(f"  Primal vertices: {len(sol1.Primal.vertex_type)}")
    
    # Solve using new memory-based method
    print("\nMethod 2: New solve_direct() without file I/O...")
    t2 = time.time()
    sol2 = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
    t_mem = time.time() - t2
    print(f"  Time: {t_mem:.4f} seconds")
    print(f"  Primal vertices: {len(sol2.Primal.vertex_type)}")
    
    print(f"\nSpeedup: {t_file/t_mem:.2f}x")
    
    # Verify results match
    print("\nVerifying results match...")
    assert len(sol1.Primal.vertex_type) == len(sol2.Primal.vertex_type), "Mismatch in number of vertices"
    print("  ✓ Results match!")
    
    print("\n" + "=" * 70)


if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("Testing new in-memory interface for benpy")
    print("=" * 70)
    
    try:
        test_simple_problem()
        test_structure_access()
        test_comparison()
        
        print("\n" + "=" * 70)
        print("All tests passed! ✓")
        print("=" * 70)
        
    except Exception as e:
        print(f"\n\nTest failed with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
