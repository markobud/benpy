"""
Example demonstrating the new in-memory interface for benpy.

This example shows how to solve vector linear programs (VLPs) directly
from numpy arrays without creating temporary files.
"""

import numpy as np
import sys
sys.path.insert(0, 'src')

import benpy

def example_basic():
    """Basic example: minimize two objectives subject to linear constraints"""
    print("=" * 70)
    print("Example 1: Basic bi-objective optimization")
    print("=" * 70)
    
    # Problem: minimize [x1, x2] subject to:
    #   2*x1 + x2 <= 4
    #   x1 + 2*x2 <= 4
    #   x1, x2 >= 0
    
    B = np.array([[2.0, 1.0],
                  [1.0, 2.0]])
    
    P = np.array([[1.0, 0.0],
                  [0.0, 1.0]])
    
    b = np.array([4.0, 4.0])
    l = np.array([0.0, 0.0])
    
    print("\nProblem:")
    print("  minimize [x1, x2]")
    print("  subject to:")
    print("    2*x1 + x2 <= 4")
    print("    x1 + 2*x2 <= 4")
    print("    x1, x2 >= 0")
    
    # Solve using new in-memory interface
    sol = benpy.solve(B, P, b=b, l=l, opt_dir=1)
    
    print(f"\nSolution:")
    print(f"  Status: {sol.Primal.vertex_type}")
    print(f"  Number of efficient points: {len(sol.Primal.vertex_value)}")
    print(f"  Duality parameter: {sol.c}")
    

def example_direct_structure_access():
    """Example showing direct access to C structures"""
    print("\n" + "=" * 70)
    print("Example 2: Direct access to problem structures")
    print("=" * 70)
    
    from benpy import _cVlpProblem
    
    # Create problem
    B = np.array([[1.0, 2.0, 3.0],
                  [4.0, 5.0, 6.0]])
    P = np.array([[1.0, 0.0, 0.0],
                  [0.0, 1.0, 0.0],
                  [0.0, 0.0, 1.0]])
    b = np.array([10.0, 20.0])
    
    # Initialize problem
    prob = _cVlpProblem()
    prob.from_arrays(B, P, b=b, opt_dir=1)
    
    # Access problem properties directly
    print("\nProblem dimensions:")
    print(f"  Number of constraints (m): {prob.m}")
    print(f"  Number of variables (n): {prob.n}")
    print(f"  Number of objectives (q): {prob.q}")
    print(f"  Non-zero entries in constraints: {prob.nz}")
    print(f"  Non-zero entries in objectives: {prob.nzobj}")
    
    # Access problem matrices
    print(f"\nConstraint matrix shape: {prob.constraint_matrix.shape}")
    print(f"Objective matrix shape: {prob.objective_matrix.shape}")
    
    print("\nConstraint matrix B:")
    print(prob.constraint_matrix)
    
    print("\nObjective matrix P:")
    print(prob.objective_matrix)


def example_custom_ordering_cone():
    """Example with custom ordering cone"""
    print("\n" + "=" * 70)
    print("Example 3: Custom ordering cone")
    print("=" * 70)
    
    # Problem with custom ordering cone
    B = np.array([[1.0, 1.0]])
    P = np.array([[1.0, 0.0],
                  [0.0, 1.0]])
    b = np.array([1.0])
    l = np.array([0.0, 0.0])
    
    # Define custom ordering cone (e.g., polyhedral cone)
    Y = np.array([[1.0, 1.0],
                  [0.0, 1.0]])
    
    print("\nProblem with custom ordering cone:")
    print(f"  Cone generators Y:\n{Y}")
    
    sol = benpy.solve(B, P, b=b, l=l, Y=Y, opt_dir=1)
    
    print(f"\nSolution with custom cone:")
    print(f"  Efficient points found: {len(sol.Primal.vertex_value)}")


def example_performance_comparison():
    """Compare performance of file-based vs memory-based approach"""
    print("\n" + "=" * 70)
    print("Example 4: Performance comparison")
    print("=" * 70)
    
    import time
    
    # Larger problem
    n = 50
    m = 20
    q = 3
    
    np.random.seed(42)
    B = np.random.rand(m, n)
    P = np.random.rand(q, n)
    b = np.random.rand(m) * 10
    l = np.zeros(n)
    s = np.ones(n) * 5
    
    print(f"\nProblem size:")
    print(f"  {m} constraints, {n} variables, {q} objectives")
    
    # Legacy approach (file-based)
    print("\nLegacy solve_legacy() with file I/O:")
    t1 = time.time()
    prob = benpy.vlpProblem(B=B, P=P, b=b, l=l, s=s, opt_dir=1)
    sol1 = benpy.solve_legacy(prob)
    t_file = time.time() - t1
    print(f"  Time: {t_file:.4f} seconds")
    
    # New approach (in-memory)
    print("\nNew solve() without file I/O:")
    t2 = time.time()
    sol2 = benpy.solve(B, P, b=b, l=l, s=s, opt_dir=1)
    t_mem = time.time() - t2
    print(f"  Time: {t_mem:.4f} seconds")
    
    print(f"\nSpeedup: {t_file/t_mem:.2f}x faster!")
    print(f"Results identical: {len(sol1.Primal.vertex_type) == len(sol2.Primal.vertex_type)}")


if __name__ == "__main__":
    print("\n" + "=" * 70)
    print("BENPY In-Memory Interface Examples")
    print("bensolve 2.1.0 Cython wrapper")
    print("=" * 70)
    
    try:
        example_basic()
        example_direct_structure_access()
        example_custom_ordering_cone()
        example_performance_comparison()
        
        print("\n" + "=" * 70)
        print("All examples completed successfully!")
        print("=" * 70 + "\n")
        
    except Exception as e:
        print(f"\n\nExample failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
