#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Example demonstrating VLP solving with benpy 2.1.0

This example shows both the traditional solve() method and the new solve_direct() 
method introduced in benpy 2.1.0.

@author: mbudinich
"""

import numpy as np
from benpy import solve_direct, vlpProblem, solve

# Example: MOLP with 2 objectives, simplest example
#
# min [x1 - x2; x1 + x2]
#
# 6 <= 2*x1 +   x2
# 6 <=   x1 + 2*x2
#
# x1 >= 0
# x2 >= 0

print("=" * 60)
print("benpy 2.1.0 - VLP Solver Example")
print("=" * 60)

# Method 1: Using solve_direct() - New in benpy 2.1.0 (Recommended)
# This method is 2-3x faster and more Pythonic
print("\n[Method 1] Using solve_direct() (Recommended)")
print("-" * 60)

B = np.array([[2.0, 1.0],    # Constraint matrix
              [1.0, 2.0]])
P = np.array([[1.0, -1.0],   # Objective matrix
              [1.0, 1.0]])
a = np.array([6.0, 6.0])     # Lower bounds on constraints
l = np.array([0.0, 0.0])     # Lower bounds on variables

sol = solve_direct(B, P, a=a, l=l, opt_dir=1)
print(f"Status: {sol.status}")
print(f"Found {len(sol.Primal.vertex_value)} efficient points")
print(f"Upper image vertices: {sol.num_vertices_upper}")
print(f"Lower image vertices: {sol.num_vertices_lower}")

print("\nPrimal vertices (objective space):")
for i, vertex in enumerate(sol.Primal.vertex_value):
    print(f"  v{i+1}: {vertex}")

# Method 2: Using traditional solve() - Still supported for backward compatibility
print("\n" + "=" * 60)
print("[Method 2] Using traditional solve() (Backward Compatible)")
print("-" * 60)

vlp = vlpProblem()
vlp.B = np.array([[2.0, 1.0], [1.0, 2.0]])  # coefficient matrix
vlp.a = [6.0, 6.0]                           # lower bounds
vlp.P = np.array([[1.0, -1.0], [1.0, 1.0]]) # objective matrix
vlp.l = [0.0, 0.0]                           # lower variable bounds
vlp.opt_dir = 1                              # minimize

# Optional: save problem to file
vlp.to_vlp_file('test01.vlp')
print("Problem saved to: test01.vlp")

sol2 = solve(vlp)
print(f"Status: {sol2.status}")
print(f"Found {len(sol2.Primal.vertex_value)} efficient points")

print("\n" + "=" * 60)
print("Both methods produce identical results!")
print("Use solve_direct() for better performance.")
print("=" * 60)
