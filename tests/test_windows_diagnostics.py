"""
Windows Diagnostics Test Suite

This test module systematically identifies which specific tests crash on Windows
versus which ones work correctly. It provides detailed categorization and
reporting to help devise a solution plan for Windows compatibility.

Related documentation: doc/WindowsTestCrashes.md

Test Categories:
1. Known working tests (verified on Windows)
2. Known crashing tests (documented crashes)
3. Edge case tests (need verification)
4. Systematic test matrix for all examples

Usage:
    # Run all diagnostic tests
    pytest tests/test_windows_diagnostics.py -v
    
    # Run only on Windows
    pytest tests/test_windows_diagnostics.py -v -m "windows_only"
    
    # Generate diagnostic report
    pytest tests/test_windows_diagnostics.py -v --tb=short > windows_test_report.txt
"""

import pytest
import sys
import numpy as np
from problems import (
    get_example01, get_example02, get_example03, get_example04,
    get_example05, get_example06, get_example08, get_example11,
    get_all_examples
)

# Skip all tests if benpy cannot be imported
pytest.importorskip('benpy')
import benpy


# Test markers for categorization
pytestmark = pytest.mark.diagnostics


class TestWindowsCompatibilityMatrix:
    """
    Systematic testing matrix to identify which problems work on Windows.
    
    This class tests each example problem individually to pinpoint exactly
    which ones crash versus which ones work.
    """
    
    def test_example01_diagnostic(self):
        """
        Diagnostic: Example01 - Simple MOLP
        
        Expected: PASS on all platforms
        Problem type: Bounded, has vertices
        """
        prob_data = get_example01()
        
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data['a'],
                l=prob_data['l'],
                opt_dir=prob_data['opt_dir']
            )
            assert sol is not None
            # Record success
            print("\n✓ Example01: SUCCESS - Simple MOLP works")
        except Exception as e:
            pytest.fail(f"Example01 FAILED: {type(e).__name__}: {e}")
    
    @pytest.mark.skipif(
        sys.platform != 'win32',
        reason="Only test on Windows - known to pass on Linux/macOS"
    )
    def test_example02_infeasible_diagnostic(self):
        """
        Diagnostic: Example02 - Infeasible problem
        
        Expected: Should handle gracefully (may fail with infeasibility)
        Problem type: Infeasible
        """
        prob_data = get_example02()
        
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data.get('a'),
                b=prob_data.get('b'),
                opt_dir=prob_data['opt_dir']
            )
            print("\n⚠ Example02: Returned solution (expected infeasibility)")
        except Exception as e:
            print(f"\n✓ Example02: Handled correctly - {type(e).__name__}")
    
    @pytest.mark.windows_crash
    @pytest.mark.skipif(
        sys.platform != 'win32',
        reason="Only test on Windows - this is the crash test"
    )
    def test_example03_no_vertex_diagnostic(self):
        """
        Diagnostic: Example03 - No vertex problem
        
        Expected: CRASH on Windows (documented)
        Problem type: Upper image has no vertex
        
        This test is EXPECTED to crash on Windows. It's marked as such
        to document the crash behavior.
        """
        prob_data = get_example03()
        
        # On Windows, this may crash the Python process
        # We use try-except but crashes may not be catchable
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data['a'],
                opt_dir=prob_data['opt_dir']
            )
            print("\n✓ Example03: SUCCESS - No vertex problem works!")
            assert sol is not None
        except Exception as e:
            print(f"\n✗ Example03: EXCEPTION - {type(e).__name__}: {e}")
            pytest.fail(f"Example03 raised exception: {e}")
    
    @pytest.mark.windows_crash
    @pytest.mark.skipif(
        sys.platform != 'win32',
        reason="Only test on Windows - this is the crash test"
    )
    def test_example04_totally_unbounded_diagnostic(self):
        """
        Diagnostic: Example04 - Totally unbounded problem
        
        Expected: CRASH on Windows (documented)
        Problem type: Totally unbounded
        
        This test is EXPECTED to crash on Windows.
        """
        prob_data = get_example04()
        
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data['a'],
                opt_dir=prob_data['opt_dir']
            )
            print("\n✓ Example04: SUCCESS - Totally unbounded works!")
            assert sol is not None
        except Exception as e:
            print(f"\n✗ Example04: EXCEPTION - {type(e).__name__}: {e}")
            pytest.fail(f"Example04 raised exception: {e}")
    
    def test_example05_custom_cone_diagnostic(self):
        """
        Diagnostic: Example05 - Custom ordering cone
        
        Expected: PASS on all platforms (documented as working on Windows)
        Problem type: Custom cone, bounded
        """
        prob_data = get_example05()
        
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data['a'],
                l=prob_data['l'],
                Y=prob_data['Y'],
                c=prob_data['c'],
                opt_dir=prob_data['opt_dir']
            )
            assert sol is not None
            print("\n✓ Example05: SUCCESS - Custom cone works")
        except Exception as e:
            pytest.fail(f"Example05 FAILED: {type(e).__name__}: {e}")
    
    def test_example06_maximization_diagnostic(self):
        """
        Diagnostic: Example06 - Maximization problem
        
        Expected: PASS on all platforms (documented as working on Windows)
        Problem type: Maximization with dual cone
        """
        prob_data = get_example06()
        
        try:
            sol = benpy.solve_direct(
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
            assert sol is not None
            print("\n✓ Example06: SUCCESS - Maximization works")
        except Exception as e:
            pytest.fail(f"Example06 FAILED: {type(e).__name__}: {e}")
    
    def test_example08_partially_unbounded_diagnostic(self):
        """
        Diagnostic: Example08 - Partially unbounded
        
        Expected: PASS on all platforms (documented as working on Windows)
        Problem type: Unbounded but not totally unbounded
        
        Interesting: This works while totally unbounded (example04) crashes.
        """
        prob_data = get_example08()
        
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data['a'],
                Y=prob_data['Y'],
                c=prob_data['c'],
                opt_dir=prob_data['opt_dir']
            )
            assert sol is not None
            print("\n✓ Example08: SUCCESS - Partially unbounded works")
        except Exception as e:
            pytest.fail(f"Example08 FAILED: {type(e).__name__}: {e}")
    
    def test_example11_high_dimensional_diagnostic(self):
        """
        Diagnostic: Example11 - High dimensional problem
        
        Expected: PASS on all platforms (documented as working on Windows)
        Problem type: 5 objectives, many constraints, unbounded
        """
        prob_data = get_example11()
        
        try:
            sol = benpy.solve_direct(
                prob_data['B'],
                prob_data['P'],
                a=prob_data['a'],
                opt_dir=prob_data['opt_dir']
            )
            assert sol is not None
            print("\n✓ Example11: SUCCESS - High dimensional works")
        except Exception as e:
            pytest.fail(f"Example11 FAILED: {type(e).__name__}: {e}")


class TestWindowsCrashPatterns:
    """
    Test patterns that may reveal the root cause of Windows crashes.
    
    These tests explore variations of the crashing problems to understand
    what specifically triggers the crash.
    """
    
    @pytest.mark.skipif(
        sys.platform != 'win32',
        reason="Pattern analysis only needed on Windows"
    )
    def test_no_vertex_minimal(self):
        """
        Test a minimal no-vertex problem.
        
        This is a simplified version of example03 to isolate the issue.
        """
        # Minimal problem that should have no vertex
        B = np.array([[1.0, 1.0, 1.0], [1.0, 1.0, -1.0]])
        P = np.array([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]])
        a = np.array([1.0, 1.0])
        
        try:
            sol = benpy.solve_direct(B, P, a=a, opt_dir=1)
            print("\n✓ Minimal no-vertex: SUCCESS")
            assert sol is not None
        except Exception as e:
            print(f"\n✗ Minimal no-vertex: {type(e).__name__}: {e}")
            pytest.skip(f"Crashes as expected: {e}")
    
    @pytest.mark.skipif(
        sys.platform != 'win32',
        reason="Pattern analysis only needed on Windows"
    )
    def test_unbounded_minimal(self):
        """
        Test a minimal unbounded problem.
        
        This is a simplified version of example04 to isolate the issue.
        """
        # Minimal totally unbounded problem
        B = np.array([[1.0, 1.0, 1.0], [1.0, 1.0, 2.0]])
        P = np.array([[1.0, 0.0, 0.0], [0.0, 1.0, 0.0]])
        a = np.array([1.0, 1.0])
        
        try:
            sol = benpy.solve_direct(B, P, a=a, opt_dir=1)
            print("\n✓ Minimal unbounded: SUCCESS")
            assert sol is not None
        except Exception as e:
            print(f"\n✗ Minimal unbounded: {type(e).__name__}: {e}")
            pytest.skip(f"Crashes as expected: {e}")
    
    def test_bounded_with_vertices(self):
        """
        Test that bounded problems with vertices work on all platforms.
        
        This should always work - it's a baseline for comparison.
        """
        # Simple bounded problem with clear vertices
        B = np.array([[1.0, 0.0], [0.0, 1.0]])
        P = np.array([[1.0, 0.0], [0.0, 1.0]])
        a = np.array([1.0, 1.0])
        
        try:
            sol = benpy.solve_direct(B, P, a=a, opt_dir=1)
            assert sol is not None
            print("\n✓ Bounded with vertices: SUCCESS")
        except Exception as e:
            pytest.fail(f"Basic bounded problem failed: {e}")


class TestWindowsSafeSubset:
    """
    Tests that are confirmed safe to run on Windows.
    
    This class contains only tests that are documented as working on Windows.
    These can be run in CI without risk of crashes.
    """
    
    def test_safe_example01(self):
        """Safe: Example01 works on Windows"""
        prob_data = get_example01()
        sol = benpy.solve_direct(
            prob_data['B'], prob_data['P'],
            a=prob_data['a'], l=prob_data['l'],
            opt_dir=prob_data['opt_dir']
        )
        assert sol is not None
    
    def test_safe_example05(self):
        """Safe: Example05 works on Windows"""
        prob_data = get_example05()
        sol = benpy.solve_direct(
            prob_data['B'], prob_data['P'],
            a=prob_data['a'], l=prob_data['l'],
            Y=prob_data['Y'], c=prob_data['c'],
            opt_dir=prob_data['opt_dir']
        )
        assert sol is not None
    
    def test_safe_example06(self):
        """Safe: Example06 works on Windows"""
        prob_data = get_example06()
        sol = benpy.solve_direct(
            prob_data['B'], prob_data['P'],
            a=prob_data['a'], b=prob_data['b'],
            l=prob_data['l'], s=prob_data['s'],
            Z=prob_data['Z'], c=prob_data['c'],
            opt_dir=prob_data['opt_dir']
        )
        assert sol is not None
    
    def test_safe_example08(self):
        """Safe: Example08 works on Windows"""
        prob_data = get_example08()
        sol = benpy.solve_direct(
            prob_data['B'], prob_data['P'],
            a=prob_data['a'], Y=prob_data['Y'],
            c=prob_data['c'], opt_dir=prob_data['opt_dir']
        )
        assert sol is not None
    
    def test_safe_example11(self):
        """Safe: Example11 works on Windows"""
        prob_data = get_example11()
        sol = benpy.solve_direct(
            prob_data['B'], prob_data['P'],
            a=prob_data['a'], opt_dir=prob_data['opt_dir']
        )
        assert sol is not None


@pytest.fixture
def diagnostic_summary(request):
    """
    Fixture to collect and print diagnostic summary after tests.
    """
    yield
    
    # Print summary at the end of the session
    if hasattr(request.session, 'testscollected'):
        print("\n" + "="*70)
        print("WINDOWS DIAGNOSTICS SUMMARY")
        print("="*70)
        print("\nRefer to doc/WindowsTestCrashes.md for detailed analysis.")
        print("\nTest Categories:")
        print("  • Known Safe: example01, 05, 06, 08, 11")
        print("  • Known Crash: example03 (no vertex), example04 (totally unbounded)")
        print("  • Needs Verification: example02 (infeasible)")
        print("\nExpected Behavior:")
        print("  Linux/macOS: All tests should pass")
        print("  Windows: example03 and example04 may crash with 'Fatal Python error'")


def test_generate_diagnostic_report():
    """
    Generate a comprehensive diagnostic report.
    
    This test creates a summary of all examples and their expected behavior
    on Windows versus other platforms.
    """
    examples = get_all_examples()
    
    report = []
    report.append("\n" + "="*70)
    report.append("BENPY WINDOWS COMPATIBILITY DIAGNOSTIC REPORT")
    report.append("="*70)
    report.append(f"\nPlatform: {sys.platform}")
    report.append(f"Total examples available: {len(examples)}")
    
    # Categorize examples
    safe = ['example01', 'example05', 'example06', 'example08', 'example11']
    crash = ['example03', 'example04']
    unknown = ['example02']
    
    report.append("\n" + "-"*70)
    report.append("SAFE ON WINDOWS (Verified):")
    report.append("-"*70)
    for name in safe:
        if name in examples:
            desc = examples[name].get('description', 'No description')
            report.append(f"  ✓ {name}: {desc}")
    
    report.append("\n" + "-"*70)
    report.append("CRASHES ON WINDOWS (Documented):")
    report.append("-"*70)
    for name in crash:
        if name in examples:
            desc = examples[name].get('description', 'No description')
            report.append(f"  ✗ {name}: {desc}")
    
    report.append("\n" + "-"*70)
    report.append("UNKNOWN STATUS:")
    report.append("-"*70)
    for name in unknown:
        if name in examples:
            desc = examples[name].get('description', 'No description')
            report.append(f"  ? {name}: {desc}")
    
    report.append("\n" + "-"*70)
    report.append("RECOMMENDATIONS:")
    report.append("-"*70)
    report.append("  1. Run safe tests in Windows CI")
    report.append("  2. Skip crash tests with @pytest.mark.skipif on Windows")
    report.append("  3. Investigate C-level code for example03 and example04")
    report.append("  4. Focus on: memory access, floating point, assertions")
    report.append("\n" + "="*70)
    
    for line in report:
        print(line)
    
    # Always pass - this is just for reporting
    assert True
