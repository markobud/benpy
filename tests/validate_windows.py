#!/usr/bin/env python3
"""
Windows Test Validator

This script provides a simple way to test benpy on Windows and identify
which specific examples crash versus which work correctly.

It can be run directly (not through pytest) to test individual examples
with better error handling and reporting.

Usage:
    python tests/validate_windows.py              # Test all safe examples
    python tests/validate_windows.py --all        # Test all examples (may crash!)
    python tests/validate_windows.py --example 01 # Test specific example
    python tests/validate_windows.py --report     # Generate report only
"""

import sys
import argparse
import traceback
from pathlib import Path

# Add src to path to import benpy
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

try:
    import benpy
    import numpy as np
    from problems import (
        get_example01, get_example02, get_example03, get_example04,
        get_example05, get_example06, get_example08, get_example11,
        get_all_examples
    )
except ImportError as e:
    print(f"Error importing required modules: {e}")
    print("\nMake sure benpy is built and installed:")
    print("  python setup.py build_ext --inplace")
    sys.exit(1)


# Categorize examples based on known behavior
SAFE_EXAMPLES = ['example01', 'example05', 'example06', 'example08', 'example11']
CRASH_EXAMPLES = ['example03', 'example04']
UNKNOWN_EXAMPLES = ['example02']


def test_example(name, prob_data, verbose=True):
    """
    Test a single example and return the result.
    
    Args:
        name: Example name (e.g., 'example01')
        prob_data: Problem data dictionary
        verbose: Print detailed output
        
    Returns:
        dict: Result with 'status', 'message', and optionally 'error'
    """
    if verbose:
        print(f"\n{'='*70}")
        print(f"Testing: {name}")
        print(f"Description: {prob_data.get('description', 'N/A')}")
        print(f"{'='*70}")
    
    try:
        # Attempt to solve the problem
        sol = benpy.solve_direct(
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
        
        if verbose:
            print(f"✓ SUCCESS: {name} solved without errors")
            if hasattr(sol, 'status'):
                print(f"  Status: {sol.status}")
            if hasattr(sol, 'c'):
                print(f"  Duality parameter c: {sol.c}")
        
        return {
            'status': 'PASS',
            'message': 'Solved successfully',
            'solution': sol
        }
        
    except Exception as e:
        error_type = type(e).__name__
        error_msg = str(e)
        
        if verbose:
            print(f"✗ EXCEPTION: {name} raised {error_type}")
            print(f"  Message: {error_msg}")
            print(f"  Traceback:")
            traceback.print_exc()
        
        return {
            'status': 'EXCEPTION',
            'message': f'{error_type}: {error_msg}',
            'error_type': error_type,
            'error': e
        }


def run_safe_tests(verbose=True):
    """Run only tests known to be safe on Windows."""
    print("\n" + "="*70)
    print("RUNNING SAFE TESTS (Known to work on Windows)")
    print("="*70)
    
    examples = get_all_examples()
    results = {}
    
    for name in SAFE_EXAMPLES:
        if name in examples:
            result = test_example(name, examples[name], verbose=verbose)
            results[name] = result
        else:
            print(f"\n⚠ Warning: {name} not found in examples")
    
    return results


def run_crash_tests(verbose=True):
    """
    Run tests known to crash on Windows.
    
    WARNING: This may crash the Python process!
    """
    print("\n" + "="*70)
    print("WARNING: RUNNING CRASH TESTS")
    print("These tests are known to crash on Windows!")
    print("The Python process may abort with 'Fatal Python error'")
    print("="*70)
    
    examples = get_all_examples()
    results = {}
    
    for name in CRASH_EXAMPLES:
        if name in examples:
            input(f"\nPress Enter to test {name} (or Ctrl+C to skip)...")
            result = test_example(name, examples[name], verbose=verbose)
            results[name] = result
        else:
            print(f"\n⚠ Warning: {name} not found in examples")
    
    return results


def run_all_tests(verbose=True):
    """Run all available tests."""
    print("\n" + "="*70)
    print("RUNNING ALL TESTS")
    print("WARNING: Some tests may crash on Windows!")
    print("="*70)
    
    examples = get_all_examples()
    results = {}
    
    for name, prob_data in examples.items():
        result = test_example(name, prob_data, verbose=verbose)
        results[name] = result
    
    return results


def print_summary(results):
    """Print a summary of test results."""
    print("\n" + "="*70)
    print("TEST SUMMARY")
    print("="*70)
    
    passed = [name for name, r in results.items() if r['status'] == 'PASS']
    failed = [name for name, r in results.items() if r['status'] == 'EXCEPTION']
    
    print(f"\nTotal tests: {len(results)}")
    print(f"Passed: {len(passed)}")
    print(f"Failed: {len(failed)}")
    
    if passed:
        print("\n✓ PASSED:")
        for name in passed:
            print(f"  • {name}")
    
    if failed:
        print("\n✗ FAILED:")
        for name in failed:
            error_type = results[name].get('error_type', 'Unknown')
            print(f"  • {name}: {error_type}")
    
    print("\n" + "="*70)


def generate_report():
    """Generate a diagnostic report without running tests."""
    print("\n" + "="*70)
    print("BENPY WINDOWS COMPATIBILITY REPORT")
    print("="*70)
    
    print(f"\nPlatform: {sys.platform}")
    print(f"Python version: {sys.version}")
    
    try:
        print(f"benpy available: Yes")
        print(f"NumPy version: {np.__version__}")
    except Exception as e:
        print(f"benpy available: Error - {e}")
    
    examples = get_all_examples()
    print(f"\nTotal examples: {len(examples)}")
    
    print("\n" + "-"*70)
    print("SAFE ON WINDOWS (Verified):")
    print("-"*70)
    for name in SAFE_EXAMPLES:
        if name in examples:
            desc = examples[name].get('description', 'No description')
            print(f"  ✓ {name}: {desc}")
    
    print("\n" + "-"*70)
    print("CRASHES ON WINDOWS (Documented):")
    print("-"*70)
    for name in CRASH_EXAMPLES:
        if name in examples:
            desc = examples[name].get('description', 'No description')
            print(f"  ✗ {name}: {desc}")
    
    print("\n" + "-"*70)
    print("UNKNOWN STATUS:")
    print("-"*70)
    for name in UNKNOWN_EXAMPLES:
        if name in examples:
            desc = examples[name].get('description', 'No description')
            print(f"  ? {name}: {desc}")
    
    print("\n" + "-"*70)
    print("USAGE RECOMMENDATIONS:")
    print("-"*70)
    print("  • Safe for production: Use examples 01, 05, 06, 08, 11")
    print("  • Avoid on Windows: Examples 03, 04 (known to crash)")
    print("  • For edge cases: Test on Linux/macOS first")
    print("  • CI/CD: Run only safe tests on Windows")
    
    print("\n" + "="*70)


def main():
    parser = argparse.ArgumentParser(
        description='Validate benpy on Windows and identify working vs crashing tests'
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='Test all examples (WARNING: may crash on Windows!)'
    )
    parser.add_argument(
        '--crash',
        action='store_true',
        help='Test only examples known to crash (WARNING: will likely crash!)'
    )
    parser.add_argument(
        '--example',
        type=str,
        help='Test a specific example (e.g., "01", "example01", or "1")'
    )
    parser.add_argument(
        '--report',
        action='store_true',
        help='Generate report only (no testing)'
    )
    parser.add_argument(
        '--quiet',
        action='store_true',
        help='Reduce output verbosity'
    )
    
    args = parser.parse_args()
    verbose = not args.quiet
    
    # Generate report only
    if args.report:
        generate_report()
        return 0
    
    # Test specific example
    if args.example:
        examples = get_all_examples()
        # Normalize example name
        ex_num = args.example.lstrip('example').zfill(2)
        ex_name = f'example{ex_num}'
        
        if ex_name not in examples:
            print(f"Error: Example '{args.example}' not found")
            print(f"Available examples: {', '.join(examples.keys())}")
            return 1
        
        result = test_example(ex_name, examples[ex_name], verbose=verbose)
        print_summary({ex_name: result})
        return 0 if result['status'] == 'PASS' else 1
    
    # Run tests based on flags
    if args.all:
        results = run_all_tests(verbose=verbose)
    elif args.crash:
        results = run_crash_tests(verbose=verbose)
    else:
        results = run_safe_tests(verbose=verbose)
    
    # Print summary
    print_summary(results)
    
    # Return 0 if all tests passed
    all_passed = all(r['status'] == 'PASS' for r in results.values())
    return 0 if all_passed else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(130)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        traceback.print_exc()
        sys.exit(1)
