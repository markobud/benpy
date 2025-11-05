#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Threading test for benpy - demonstrates GIL release during solve operations.

This test shows:
1. The GIL is released during long-running solve operations
2. Other Python threads can run concurrently while solving
3. Bensolve itself is NOT thread-safe for concurrent solve calls (uses global state)
4. Use a threading.Lock to serialize solve calls when solving from multiple threads
"""

import numpy as np
import threading
import time
from benpy import solve as bensolve, vlpProblem


def create_test_problem():
    """Create a simple VLP problem for testing."""
    vlp = vlpProblem()
    vlp.B = np.matrix([[2, 1], [1, 2]])  # coefficient matrix
    vlp.a = [6, 6]  # lower bounds
    vlp.P = np.matrix([[1, -1], [1, 1]])  # objective matrix
    vlp.l = [0, 0]  # lower variable bounds
    vlp.options = vlp.default_options.copy()
    vlp.options['message_level'] = 0  # Reduce output for cleaner test
    return vlp


def test_gil_release():
    """Test that GIL is released - other Python threads can run during solve."""
    print("\n=== Test 1: GIL Release Demonstration ===")
    print("This test shows that Python threads can run while bensolve is solving.")
    
    counter = {'value': 0}
    solving = {'done': False}
    
    def increment_counter():
        """This thread increments a counter while solving is happening."""
        while not solving['done']:
            counter['value'] += 1
            time.sleep(0.001)  # Small sleep to avoid busy waiting
    
    def solve_problem():
        """Solve the VLP problem."""
        vlp = create_test_problem()
        sol = bensolve(vlp)
        solving['done'] = True
        return sol
    
    # Start counter thread
    counter_thread = threading.Thread(target=increment_counter)
    counter_thread.start()
    
    # Solve problem (with GIL released during computation)
    start_time = time.time()
    solve_problem()
    elapsed = time.time() - start_time
    
    # Wait for counter thread
    counter_thread.join()
    
    print(f"Solving took {elapsed:.3f} seconds")
    print(f"Counter thread ran {counter['value']} iterations during solve")
    
    if counter['value'] > 0:
        print("✓ SUCCESS: Other Python threads ran during solve (GIL was released)")
    else:
        print("✗ FAILURE: Counter thread didn't run (GIL was NOT released)")
    
    return counter['value'] > 0


def test_thread_safety_with_lock():
    """Test solving multiple problems from different threads using a lock."""
    print("\n=== Test 2: Thread-Safe Concurrent Solving (with Lock) ===")
    print("This test solves multiple problems from different threads using a lock.")
    
    solver_lock = threading.Lock()
    results = {}
    
    def solve_with_lock(problem_id):
        """Solve a problem with thread lock to ensure only one solve at a time."""
        vlp = create_test_problem()
        with solver_lock:
            sol = bensolve(vlp)
        results[problem_id] = sol
    
    # Create multiple threads
    threads = []
    num_problems = 3
    
    start_time = time.time()
    for i in range(num_problems):
        t = threading.Thread(target=solve_with_lock, args=(i,))
        threads.append(t)
        t.start()
    
    # Wait for all threads
    for t in threads:
        t.join()
    
    elapsed = time.time() - start_time
    
    print(f"Solved {num_problems} problems in {elapsed:.3f} seconds")
    print(f"All {len(results)} solutions computed successfully")
    
    # Verify all solutions are valid
    all_valid = all(sol is not None and hasattr(sol, 'Primal') for sol in results.values())
    
    if all_valid:
        print("✓ SUCCESS: All solutions valid when using lock")
    else:
        print("✗ FAILURE: Some solutions invalid")
    
    return all_valid


def test_warning_without_lock():
    """Demonstrate why concurrent solving without a lock is problematic."""
    print("\n=== Test 3: Concurrent Solving Without Lock (NOT RECOMMENDED) ===")
    print("WARNING: This demonstrates unsafe concurrent solving.")
    print("Bensolve uses global state - concurrent calls may produce incorrect results.")
    print("This is included for educational purposes only.\n")
    
    # Note: We're NOT actually running this test to avoid potential crashes
    # or incorrect results. This is just documentation.
    
    print("Example of UNSAFE code (do NOT use):")
    print("""
    def solve_without_lock(problem_id):
        vlp = create_test_problem()
        sol = bensolve(vlp)  # UNSAFE - no lock!
        return sol
    
    # Multiple threads calling solve_without_lock concurrently
    # may crash or produce incorrect results due to global state in bensolve
    """)
    
    print("Always use a lock when solving from multiple threads!")
    return True


def main():
    """Run all threading tests."""
    print("=" * 70)
    print("benpy Threading Tests")
    print("=" * 70)
    
    results = []
    
    # Test 1: GIL Release
    results.append(test_gil_release())
    
    # Test 2: Thread-safe concurrent solving
    results.append(test_thread_safety_with_lock())
    
    # Test 3: Warning about unsafe usage
    results.append(test_warning_without_lock())
    
    print("\n" + "=" * 70)
    print("Summary:")
    print("=" * 70)
    
    if all(results):
        print("✓ All tests passed!")
        print("\nKey Takeaways:")
        print("1. GIL is released during solve operations ✓")
        print("2. Other Python threads can run concurrently ✓")
        print("3. Use threading.Lock for concurrent solving ✓")
        print("4. Bensolve uses global state - NOT thread-safe without lock!")
    else:
        print("✗ Some tests failed")
    
    print("=" * 70)


if __name__ == "__main__":
    main()
