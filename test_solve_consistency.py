#!/usr/bin/env python3
"""
Test to reproduce the inconsistency between solve() and solve_direct().

This test compares the results of solve() and solve_direct() on example01
to demonstrate that solve_direct() incorrectly reports "unbounded" while
solve() correctly finds "optimal" solution.
"""

import numpy as np
import sys
import os

# Add src to path to find benpy
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

try:
    import benpy
except ImportError:
    print("ERROR: benpy not built. Please build first with:")
    print("  python setup.py build_ext --inplace")
    sys.exit(1)

def test_example01_consistency():
    """Test example01 using both solve() and solve_direct()."""
    
    # Example 01 problem data
    B = np.array([[2.0, 1.0], [1.0, 2.0]])
    P = np.array([[1.0, -1.0], [1.0, 1.0]])
    a = np.array([6.0, 6.0])
    l = np.array([0.0, 0.0])
    opt_dir = 1
    
    print("="*80)
    print("Testing Example 01: Consistency between solve() and solve_direct()")
    print("="*80)
    print()
    
    # Test with solve_direct()
    print("Testing solve_direct()...")
    print("-" * 40)
    try:
        sol_direct = benpy.solve_direct(B, P, a=a, l=l, opt_dir=opt_dir)
        print(f"Status: {sol_direct.status}")
        print(f"eta: {sol_direct.eta}")
        print(f"c: {sol_direct.c}")
        print(f"num_vertices_upper: {sol_direct.num_vertices_upper}")
        print(f"num_vertices_lower: {sol_direct.num_vertices_lower}")
    except Exception as e:
        print(f"ERROR in solve_direct(): {e}")
        import traceback
        traceback.print_exc()
    
    print()
    print("Testing solve() (file-based)...")
    print("-" * 40)
    
    # Test with solve() - need to create vlpProblem first
    try:
        problem = benpy.vlpProblem(B=B, P=P, a=a, l=l, opt_dir=opt_dir)
        
        # Print the VLP file content for debugging
        print("VLP file content:")
        print("-" * 40)
        vlpfile = problem.vlpfile
        content = vlpfile.read()
        print(content)
        print("-" * 40)
        print()
        
        sol_file = benpy.solve(problem)
        print(f"Status: {sol_file.status}")
        print(f"eta: {sol_file.eta}")
        print(f"c: {sol_file.c}")
        print(f"num_vertices_upper: {sol_file.num_vertices_upper}")
        print(f"num_vertices_lower: {sol_file.num_vertices_lower}")
    except Exception as e:
        print(f"ERROR in solve(): {e}")
        import traceback
        traceback.print_exc()
    
    print()
    print("="*80)
    print("Comparison:")
    print("="*80)
    try:
        print(f"solve_direct() status: {sol_direct.status}")
        print(f"solve()        status: {sol_file.status}")
        print()
        print(f"solve_direct() eta: {sol_direct.eta}")
        print(f"solve()        eta: {sol_file.eta}")
        print()
        
        if sol_direct.status != sol_file.status:
            print("❌ STATUS MISMATCH - This is the bug!")
            print(f"   Expected (from solve): {sol_file.status}")
            print(f"   Got (from solve_direct): {sol_direct.status}")
            return False
        else:
            print("✅ Status matches")
            
        if not np.allclose(sol_direct.eta, sol_file.eta):
            print("❌ ETA MISMATCH")
            print(f"   Expected (from solve): {sol_file.eta}")
            print(f"   Got (from solve_direct): {sol_direct.eta}")
            return False
        else:
            print("✅ eta matches")
            
        return True
    except Exception as e:
        print(f"ERROR comparing results: {e}")
        return False

if __name__ == "__main__":
    success = test_example01_consistency()
    sys.exit(0 if success else 1)
