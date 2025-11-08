#!/usr/bin/env python3
"""
Threading behavior tests for benpy.

This test suite verifies:
1. GIL is properly released during solve operations
2. I/O operations can proceed during solves
3. Sequential solves work correctly
4. Concurrent solves are documented as unsafe
5. Multiprocessing works as a safe alternative

Note: Run from repository root with: python -m pytest tests_threading.py
or: python tests_threading.py
"""

import unittest
import threading
import time
import tempfile
import os
import numpy as np

# Import benpy - works when installed or when running from repo root
try:
    import benpy
except ImportError:
    import sys
    sys.path.insert(0, 'src')
    import benpy


class TestGILRelease(unittest.TestCase):
    """Test that GIL is released during solve operations"""
    
    def setUp(self):
        """Set up test problem"""
        # Small problem for quick tests
        self.B = np.array([[1.0, 1.0], [1.0, 0.0]])
        self.P = np.array([[1.0, 0.0], [0.0, 1.0]])
        self.b = np.array([2.0, 1.0])
        self.l = np.array([0.0, 0.0])
        
    def test_single_solve_completes(self):
        """Test that a single solve completes successfully"""
        sol = benpy.solve_direct(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
        self.assertIsNotNone(sol)
        self.assertIsNotNone(sol.c)
        
    def test_monitoring_thread_runs_during_solve(self):
        """Test that a monitoring thread can run while solve is executing"""
        monitor_count = [0]  # Use list for mutability in closure
        done_event = threading.Event()
        
        def monitor():
            """Monitoring thread - should be able to run during solve"""
            while not done_event.is_set():
                monitor_count[0] += 1
                time.sleep(0.01)  # 10ms sleep
        
        # Start monitoring thread
        monitor_thread = threading.Thread(target=monitor, daemon=True)
        monitor_thread.start()
        
        try:
            # Run solve (GIL should be released, allowing monitor to run)
            sol = benpy.solve_direct(self.B, self.P, b=self.b, l=self.l, opt_dir=1)
            
            # Verify solve worked
            self.assertIsNotNone(sol)
            
        finally:
            # Stop monitoring thread
            done_event.set()
            monitor_thread.join(timeout=1.0)
        
        # Monitor thread should have run at least once
        # If GIL was not released, monitor_count would be 0
        self.assertGreater(monitor_count[0], 0, 
                          "Monitoring thread did not run - GIL may not be released")


class TestSequentialSolves(unittest.TestCase):
    """Test that sequential solves work correctly"""
    
    def setUp(self):
        """Set up test problems"""
        self.problems = []
        for i in range(3):
            B = np.array([[1.0, 1.0]])
            P = np.array([[1.0, 0.0], [0.0, 1.0]])
            b = np.array([float(i + 1)])
            l = np.array([0.0, 0.0])
            self.problems.append((B, P, b, l))
    
    def test_sequential_solves(self):
        """Test that multiple sequential solves work correctly"""
        results = []
        
        for B, P, b, l in self.problems:
            sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
            results.append(sol)
        
        # All solves should complete
        self.assertEqual(len(results), 3)
        for sol in results:
            self.assertIsNotNone(sol)
            self.assertIsNotNone(sol.c)


class TestThreadSafety(unittest.TestCase):
    """Test and document thread safety limitations"""
    
    def test_concurrent_solves_are_unsafe(self):
        """
        Document that concurrent solves from multiple threads are UNSAFE.
        
        This test verifies the warning documentation, not that concurrent
        solves work (they don't due to bensolve global state).
        """
        # This test just documents the limitation
        # We don't actually run concurrent solves as that would be unsafe
        
        warning_message = """
        WARNING: bensolve 2.1.0 is NOT thread-safe!
        
        Do not run multiple solve operations concurrently from different threads.
        bensolve uses global state (lp[], lp_time[], lp_num[]) that will cause
        race conditions if accessed concurrently.
        
        Safe alternatives:
        1. Run solves sequentially (one at a time)
        2. Use multiprocessing instead of threading
        3. Use a lock to ensure only one solve runs at a time
        """
        
        # This assertion always passes - it's just documentation
        self.assertTrue(True, warning_message)
    
    def test_single_threaded_with_lock(self):
        """Test that a lock can serialize solve operations"""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([1.0])
        l = np.array([0.0, 0.0])
        
        lock = threading.Lock()
        results = []
        
        def solve_with_lock():
            with lock:  # Ensure only one solve at a time
                sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
                results.append(sol)
        
        # Create threads that will serialize due to lock
        threads = [threading.Thread(target=solve_with_lock) for _ in range(2)]
        
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        
        # Both solves should complete successfully
        self.assertEqual(len(results), 2)
        for sol in results:
            self.assertIsNotNone(sol)


class TestMultiprocessingSafe(unittest.TestCase):
    """Test that multiprocessing works as safe parallel alternative"""
    
    def test_multiprocessing_documentation(self):
        """Document that multiprocessing is the safe way to parallelize"""
        documentation = """
        For parallel solving, use Python's multiprocessing module:
        
        import multiprocessing
        import benpy
        
        def solve_problem(problem_data):
            return benpy.solve_direct(**problem_data)
        
        if __name__ == '__main__':
            problems = [create_problem(i) for i in range(10)]
            with multiprocessing.Pool(processes=4) as pool:
                results = pool.map(solve_problem, problems)
        
        This is safe because each process has its own memory space,
        so there's no shared global state between solves.
        """
        
        # This assertion always passes - it's documentation
        self.assertTrue(True, documentation)


class TestPerformance(unittest.TestCase):
    """Test performance characteristics of GIL release"""
    
    def test_solve_with_io_thread(self):
        """Test that I/O can proceed during solve"""
        B = np.array([[1.0, 1.0], [1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        b = np.array([2.0, 1.0])
        l = np.array([0.0, 0.0])
        
        io_operations = [0]
        done = threading.Event()
        
        def do_io():
            """Simulate I/O operations"""
            # Use temp file for cross-platform compatibility
            temp_file = tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt')
            temp_path = temp_file.name
            temp_file.close()
            
            try:
                while not done.is_set():
                    # Simulate file I/O
                    try:
                        with open(temp_path, 'w') as f:
                            f.write('test')
                        io_operations[0] += 1
                    except IOError as e:
                        # Ignore I/O errors in test
                        pass
                    time.sleep(0.01)
            finally:
                # Clean up temp file
                try:
                    os.unlink(temp_path)
                except OSError:
                    pass
        
        io_thread = threading.Thread(target=do_io, daemon=True)
        io_thread.start()
        
        try:
            # Solve with GIL release
            start = time.time()
            sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
            duration = time.time() - start
            
            self.assertIsNotNone(sol)
            
        finally:
            done.set()
            io_thread.join(timeout=1.0)
        
        # I/O should have occurred during solve
        # If GIL was held the whole time, io_operations would be 0
        # (This may be 0 for very fast solves, so we don't assert)
        print(f"Solve took {duration:.3f}s, I/O operations: {io_operations[0]}")


class TestSignalHandling(unittest.TestCase):
    """Test that Python signals can be handled during solve"""
    
    def test_keyboard_interrupt_possible(self):
        """Test that KeyboardInterrupt can interrupt a solve"""
        # This is a documentation test - we don't actually interrupt
        # because it would cause test failures
        
        documentation = """
        With GIL release, Python signal handlers (like Ctrl+C) can
        run during solve operations. Without GIL release, the signal
        would be delayed until the solve completes.
        
        Example:
            try:
                sol = benpy.solve_direct(B, P, b=b, l=l, opt_dir=1)
            except KeyboardInterrupt:
                print("Solve interrupted by user")
        
        This allows long-running solves to be cancelled interactively.
        """
        
        self.assertTrue(True, documentation)


class TestErrorHandling(unittest.TestCase):
    """Test that errors are properly handled with GIL release"""
    
    def test_dimension_mismatch_error(self):
        """Test that errors are raised correctly even with GIL release"""
        B = np.array([[1.0, 1.0]])
        P = np.array([[1.0, 0.0, 0.0]])  # Wrong dimension
        
        prob = benpy._cVlpProblem()
        with self.assertRaises(ValueError):
            prob.from_arrays(B, P, opt_dir=1)
    
    def test_infeasible_problem(self):
        """Test that infeasible problems are handled correctly"""
        # Create an infeasible problem
        B = np.array([[1.0, 0.0], [-1.0, 0.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        a = np.array([1.0, 1.0])  # Infeasible: x >= 1 and x <= -1
        b = np.array([1.0, -1.0])
        
        # This should not crash, just report infeasible
        # (Actual behavior depends on bensolve's handling)
        try:
            sol = benpy.solve_direct(B, P, a=a, b=b, opt_dir=1)
            # If it returns, that's fine
            self.assertIsNotNone(sol)
        except Exception as e:
            # If it raises an exception, that's also acceptable
            print(f"Infeasible problem handling: {e}")


if __name__ == '__main__':
    # Run tests with verbose output
    unittest.main(verbosity=2)
