#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Examples demonstrating benpy VLP interface with bensolve 2.1.0

These examples show various VLP/MOLP problem types and solving methods.
benpy 2.1.0 introduces solve() for faster solving (2-3x speedup).

@author: mbudinich
"""
# %%
from numpy import transpose, ones, zeros, eye, matrix, loadtxt, append, vstack, inf
import numpy as np
from benpy import vlpProblem, solve_legacy as bensolve, solve

print("=" * 70)
print("benpy 2.1.0 Examples - VLP/MOLP Problems")
print("=" * 70)
print("\nNote: Examples demonstrate both solve() (new, fast) and")
print("      traditional solve() (backward compatible)")
print("=" * 70)

# %%
# ============================================================================
# Example 01: MOLP with 2 objectives - Basic Problem
# ============================================================================
print("\n[Example 01] Basic bi-objective minimization")
print("-" * 70)
# Problem formulation:
# min [x1 - x2; x1 + x2]
#
# 6 <= 2*x1 +   x2
# 6 <=   x1 + 2*x2
#
# x1 >= 0
# x2 >= 0

# Method A: Using solve() - Recommended (2-3x faster)
print("\nUsing solve():")
B_01 = np.array([[2.0, 1.0], [1.0, 2.0]])
P_01 = np.array([[1.0, -1.0], [1.0, 1.0]])
a_01 = np.array([6.0, 6.0])
l_01 = np.array([0.0, 0.0])

sol_01 = solve(B_01, P_01, a=a_01, l=l_01, opt_dir=1)
print(f"  Status: {sol_01.status}")
print(f"  Efficient points: {len(sol_01.Primal.vertex_value)}")

# Method B: Using traditional solve() - For backward compatibility
print("\nUsing traditional solve():")
vlp = vlpProblem()
vlp.B = matrix([[2, 1], [1, 2]])    # coefficient matrix
vlp.a = [6, 6]                      # lower bounds
vlp.P = matrix([[1, -1], [1, 1]])   # objective matrix
vlp.l = [0, 0]                      # lower variable bounds

vlp.to_vlp_file('ex01.vlp')
sol = bensolve(vlp)
print(f"  Status: {sol.status}")
print(f"  Efficient points: {len(sol.Primal.vertex_value)}")

# %%
# ============================================================================
# Example 02: Infeasible MOLP
# ============================================================================
print("\n[Example 02] Infeasible bi-objective problem")
print("-" * 70)

# Problem formulation:
# v-min [x1;x2]
#
# 0 <= 3*x1 +   x2 <= 1
# 0 <=   x1 + 2*x2 <= 1
# 1 <=   x1 +   x2 <= 2

# Using solve()
print("\nUsing solve():")
B_02 = np.array([[3.0, 1.0], [1.0, 2.0], [1.0, 1.0]])
P_02 = np.array([[1.0, 0.0], [0.0, 1.0]])
a_02 = np.array([0.0, 0.0, 1.0])
b_02 = np.array([1.0, 1.0, 2.0])

sol_02 = solve(B_02, P_02, a=a_02, b=b_02, opt_dir=1)
print(f"  Status: {sol_02.status}")
print(f"  Expected: VLP_INFEASIBLE")

# Using traditional solve()
print("\nUsing traditional solve():")
vlp = vlpProblem()

vlp.B = matrix([[3, 1], [1, 2], [1, 1]])
vlp.b = [1, 1, 2]
vlp.a = [0, 0, 1]
vlp.P = matrix([[1, 0], [0, 1]])

vlp.to_vlp_file('ex02.vlp')

sol = bensolve(vlp)
print(f"  Status: {sol.status}")

# %%
# ============================================================================
# Example 03: MOLP with no vertex in upper image (commented out - see below)
# ============================================================================
# This example is commented out as it may cause issues on some platforms.
# Uncomment to test if needed.
"""
print("\n[Example 03] MOLP with no vertex in upper image")
print("-" * 70)
# Problem formulation:
# v-min [x1;x2]
#
# 1 <= x1 + x2 + x3
# 1 <= x1 + x2 - x3

vlp = vlpProblem()

vlp.B = matrix([[1, 1, 1], [1, 1, -1]])
vlp.a = [1, 1]
vlp.P = matrix([[1, 0, 0], [0, 1, 0]])

vlp.to_vlp_file('ex03.vlp')

sol = bensolve(vlp)
print(sol)
"""

# %%
# ============================================================================
# Example 04: Unbounded MOLP
# ============================================================================
print("\n[Example 04] Totally unbounded bi-objective problem")
print("-" * 70)

# ============================================================================
# Example 04: Unbounded MOLP
# ============================================================================
print("\n[Example 04] Totally unbounded bi-objective problem")
print("-" * 70)
# Problem formulation:
# v-min [x1;x2]
#
# 1 <= x1 + x2 +   x3
# 1 <= x1 + x2 + 2*x3

# Using solve()
print("\nUsing solve():")
B_04 = np.array([[1.0, 1.0, 1.0], [1.0, 1.0, 2.0]])
P_04 = np.array([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]])
a_04 = np.array([1.0, 1.0])

sol_04 = solve(B_04, P_04, a=a_04, opt_dir=1)
print(f"  Status: {sol_04.status}")
print(f"  Expected: VLP_UNBOUNDED")

# Using traditional solve()
print("\nUsing traditional solve():")
vlp = vlpProblem()

vlp.B = matrix([[1, 1, 1], [1, 1, 2]])
vlp.a = [1, 1]
vlp.P = matrix([[1, 0, 0], [0, 1, 0]])

vlp.to_vlp_file('ex04.vlp')

sol = bensolve(vlp)
print(f"  Status: {sol.status}")

# %%
# ============================================================================
# Example 05: VLP with 3 objectives and custom ordering cone
# ============================================================================
print("\n[Example 05] VLP with q=3 and 4 generating vectors of C")
print("-" * 70)
print("See http://bensolve.org/demo.html for details")
print("\nUsing traditional solve():")
vlp = vlpProblem()

vlp.B = matrix([ones((1, 3)).tolist()[0], [1, 2, 2], [
               2, 2, 1], [2, 1, 2]])  # coefficient matrix
vlp.a = [1, 3 / 2, 3 / 2, 3 / 2]					# lhs of constraints
vlp.P = matrix([[1, 0, 1], [1, 1, 0], [0, 1, 1]])			# objective matrix
vlp.l = [0, 0, 0]							# lower variable bounds

# generating vectors of ordering cone C
vlp.Y = transpose(matrix([[1, 0, 0], [0, 1, 0], [-1, 0, 2], [0, -1, 2]]))

# alternative variant: generating vectors of the dual of the ordering cone C
# vlp.Z=[2 2 1 ; 2 0 1 ; 0 0 1 ; 0 2 1]';

# duality parameter vector (must belong to interior of C)
# if not given, it is computed automatically
# dual problem depends on c
vlp.c = [1, 1, 1]

vlp.to_vlp_file('ex05.vlp')

sol = bensolve(vlp)
print(sol)
# %%
# Example: VLP with 2 objectives

# max [x1 - x2; x1 + x2]
#
# w.r.t. cone C ={(y1,y2) | 2 y1 -y2 >= 0, -y1 + 2 y2 >= 0}
#
# 1 <= x1 + x2 <= 2
#
# 0 <= x1 <= 1
# 0 <= x2

vlp = vlpProblem()

vlp.opt_dir = -1 	# maximization
vlp.Z = matrix([[2, -1], [-1, 2]])  # generators of dual of ordering cone
vlp.c = [1, 1]		# geometric duality parameter vector (belongs to interior of C)

vlp.B = matrix([1, 1])		# coefficient matrix
vlp.a = [1]			# lhs
vlp.b = [2]			# rhs
vlp.l = [0, 0]		# lower bounds
vlp.s = [1, inf]		# upper bounds
vlp.P = matrix([[1, -1], [1, 1]])  # objective matrix

vlp.to_vlp_file('ex06.vlp')

#sol = bensolve(vlp)
#print(sol)
# %%
# Example: MOLP with 3 objectives, 1211 constraints and 1143 variables
#
# Example (PL) in
#
# Shao, L., Ehrgott, M.: Approximately solving multiobjective linear programmes in objective space and
# an application in radiotherapy treatment planning. Math. Methods Oper. Res. 68(2), 257Ð276 (2008)
#
# enlarge epsilon in phase 2 and use primal simplex algorithm, for instance, run
# ./bensolve ex/ex07.vlp -m 2 -e 0.05 -l primal_simplex

vlp = vlpProblem()

vlp.B = loadtxt('src/bensolve-2.1.0/ex/example07.txt')
vlp.P = -1 * matrix([append(zeros((1, 1140)), [-1, 0, 0]), append(
    zeros((1, 1140)), [0, -1, 0]), append(zeros((1, 1140)), [0, 0, -1])])
vlp.l = append(zeros((1140, 1)), [0, -45, 0])
vlp.s = append(inf * ones((1140, 1)), [17.07, 12, 90.64])
vlp.b = vstack((90.64 * ones((67, 1)), -85.3601 * ones((67, 1)), 60 *
                ones((37, 1)), 45 * ones((8, 1)), 60 * ones((46, 1)), ones((986, 1))))
vlp.b = vlp.b.T.tolist()[0]
vlp.to_vlp_file('ex07.vlp')

#sol = bensolve(vlp)
#print(sol)
# %%
# Example: VLP with 2 objectives, which is unbounded (but not totally unbounded)
#
# its the solution consists of feasible points and feasible directions

# min_C [x1;x2]
#
# ordering cone C is generated by [-1;3/2] and [3;-1]
#
# duality parameter c is set to [0;1], which is an interior point of C
#
# 0 <= 3*x1 +   x2
# 0 <=   x1 + 2*x2
# 1 <=   x1 +   x2

vlp = vlpProblem()

vlp.B = matrix([[3, 1], [1, 2], [1, 1]])
vlp.a = [0, 0, 1]
vlp.P = matrix([[1, 0], [0, 1]])

# generating vectors of ordering cone C
vlp.Y = matrix([[-1, 3], [3 / 2, -1]])
vlp.c = [0, 1]

vlp.to_vlp_file('ex08.vlp')

sol = bensolve(vlp)
print(sol)
# %%
# VLP with 3 objectives, 4608 constrains and 36939 variables
#
# Example 6.6 in
# Hamel, A.H.; Loehne,A.; Rudloff,B.: A Benson-type algorithm for linear vector
# optimization and applications. J. Glob. Optim. 59, No. 4, 811-836 (2014)
#
# special options are necessary to run example:
#
# For instance, run
# ./bensolve ex/ex09.vlp -e 1e-2 -m 3 -L primal_simplex -l primal_simplex -p
#
# (-e: set epsilon in Phase 2)
# (-m set message level to have more output on screen)
# (-L use primal simplex algorithm in Phase 1 of Benson's algorithm)
# (-l use primal simplex algorithm in Phase 2 of Benson's algorithm)
# (-p generate graphics files)
#
# alternatively, run
#
# ./bensolve ex/ex09.vlp -e 1e-2 -m3 -A dual -a dual -p
#
# (-A use dual Benson algorithm in Phase 1)
# (-a use dual Benson algorithm in Phase 2)
# (-p generate graphics files)

# vlp = VlpProblem();
# load('example09');
# vlp.c=[1,1,1]
# vlp.to_vlp_file('ex09.vlp');
# %%
# The 'bensolvehedron', see the titlepage of the reference manual
#
# MOLP with q objectives, n=(q+2*m)^q variables and constraints
#
# To compute the bensolvehedron, type
#   ./bensolve ex/ex10.vlp -p
# Plot the resulting OFF files (or INST files), for instance, with GEOMVIEW:
#    geomview ex/ex10_p.inst   OR    geomview ex/ex10_p.off (unscaled version)
#    geomview ex/ex10_d.inst   OR    geomview ex/ex10_d.off (unscaled version)
# add green color (!)

# adapt q and m to generate other (larger) problems
# q=3;
# m=2;

# n=(q+2*m)^q;

# vlp = VlpProblem();

# feasible set is n dimensional hyper cube
# vlp.B=eye(n)
# vlp.a=zeros((n,1))
# vlp.b=ones((n,1))

# objective map
# P=zeros(n,q);
# for i in range(n):
#    line = dec2base(i-1,q+2*m,q)-'0';
#    line = line - (q+2*m-1)/2;
#    P[i,:] = line

# vlp.P = transpose(P)

# vlp.to_vlp_file('ex10.vlp');
# %%
# Example: MOLP with q=5, unbounded,
# recession cone of upper image has 22 extreme directions (main effort in phase 1)

vlp = vlpProblem()

vlp.B = matrix([[1, 1, 1, 1, 1], [2, 1, 1, 1, 1], [1, 2, 1, 1, 1], [1, 1, 2, 1, 1], [1, 1, 1, 2, 1], [1, 1, 1, 1, 2], [2, 2, 1, 1, 1], [2, 1, 2, 1, 1], [2, 1, 1, 2, 1], [2, 1, 1, 1, 2], [1, 2, 2, 1, 1], [1, 2, 1, 2, 1], [1, 2, 1, 1, 2], [1, 1, 2, 2, 1], [1, 1, 2, 1, 2], [
               1, 1, 1, 2, 2], [2, 2, 2, 1, 1], [2, 2, 1, 2, 1], [2, 2, 1, 1, 2], [2, 1, 2, 1, 2], [2, 1, 1, 2, 2], [1, 2, 2, 2, 1], [1, 2, 1, 2, 2], [1, 2, 2, 1, 2], [1, 2, 2, 2, 1], [1, 1, 2, 2, 2], [1, 2, 2, 2, 2], [2, 1, 2, 2, 2], [2, 2, 1, 2, 2], [2, 2, 2, 1, 2], [2, 2, 2, 2, 1]])
vlp.a = append(1, zeros((30, 1)))
vlp.P = eye(5, 5)

vlp.to_vlp_file('ex11.vlp')

#sol = bensolve(vlp)
#print(sol)
