# Windows Diagnostics Test Suite

## Overview

This test suite (`test_windows_diagnostics.py`) provides systematic diagnostic testing to identify which specific tests crash on Windows versus which work correctly. It complements the documentation in `doc/WindowsTestCrashes.md`.

## Purpose

During cross-platform testing, we discovered that while benpy **builds and installs successfully** on Windows, certain edge case tests crash with "Fatal Python error: Aborted". This test suite helps:

1. **Identify** exactly which tests crash and which don't
2. **Categorize** tests by their Windows compatibility
3. **Enable** safe CI testing on Windows
4. **Guide** debugging efforts for C-level fixes

## Test Organization

The test suite is organized into four main test classes:

### 1. TestWindowsCompatibilityMatrix

Systematically tests each example problem individually to create a complete compatibility matrix.

**Tests included:**
- `test_example01_diagnostic` - Simple MOLP (PASS on all platforms)
- `test_example02_infeasible_diagnostic` - Infeasible problem (Windows only)
- `test_example03_no_vertex_diagnostic` - No vertex problem (CRASH on Windows)
- `test_example04_totally_unbounded_diagnostic` - Totally unbounded (CRASH on Windows)
- `test_example05_custom_cone_diagnostic` - Custom cone (PASS on all platforms)
- `test_example06_maximization_diagnostic` - Maximization (PASS on all platforms)
- `test_example08_partially_unbounded_diagnostic` - Partially unbounded (PASS on all platforms)
- `test_example11_high_dimensional_diagnostic` - High dimensional (PASS on all platforms)

### 2. TestWindowsCrashPatterns

Explores variations and minimal versions of crashing problems to understand root causes.

**Tests included:**
- `test_no_vertex_minimal` - Minimal no-vertex problem
- `test_unbounded_minimal` - Minimal unbounded problem
- `test_bounded_with_vertices` - Baseline bounded problem (always works)

### 3. TestWindowsSafeSubset

Contains only tests confirmed safe to run on Windows without crashes. These can be included in Windows CI.

**Safe tests:**
- Example 01 (Simple MOLP)
- Example 05 (Custom cone)
- Example 06 (Maximization)
- Example 08 (Partially unbounded)
- Example 11 (High dimensional)

### 4. test_generate_diagnostic_report

Generates a comprehensive diagnostic report categorizing all examples.

## Usage

### Run All Diagnostic Tests

```bash
pytest tests/test_windows_diagnostics.py -v
```

### Run Only Safe Tests (for CI)

```bash
pytest tests/test_windows_diagnostics.py::TestWindowsSafeSubset -v
```

### Run Windows-Only Tests

On Windows:
```bash
pytest tests/test_windows_diagnostics.py -v -m "windows_only"
```

### Generate Diagnostic Report

```bash
pytest tests/test_windows_diagnostics.py::test_generate_diagnostic_report -v -s
```

### Run with Detailed Output

```bash
pytest tests/test_windows_diagnostics.py -v -s --tb=short > windows_diagnostic_report.txt
```

## Test Markers

The suite uses the following pytest markers:

- `@pytest.mark.diagnostics` - All diagnostic tests
- `@pytest.mark.windows_crash` - Tests known to crash on Windows
- `@pytest.mark.windows_only` - Tests that only run on Windows (skip on Linux/macOS)

## Expected Results

### On Linux/macOS

All tests should either:
- **PASS** - The problem solves successfully
- **SKIP** - Windows-only tests are skipped

### On Windows

Expected behavior:
- **PASS** - Safe examples (01, 05, 06, 08, 11) work correctly
- **SKIP** or **CRASH** - example03 and example04 are expected to crash
  - These are marked with `@pytest.mark.windows_crash`
  - They may crash the Python process with "Fatal Python error: Aborted"

## Known Issues on Windows

Based on documented crashes (see `doc/WindowsTestCrashes.md`):

### Crashing Tests

1. **example03_no_vertex** - Upper image has no vertex
   - Crash Type: Fatal Python error: Aborted
   - Problem Type: No vertex in feasible region projection

2. **example04_totally_unbounded** - Totally unbounded problem
   - Crash Type: Fatal Python error: Aborted
   - Problem Type: Objective can be improved indefinitely

### Working Tests

All other examples work correctly on Windows, including:
- Simple bounded problems (example01)
- Custom ordering cones (example05)
- Maximization problems (example06)
- Partially unbounded problems (example08) - interesting contrast to totally unbounded
- High-dimensional problems (example11)

## Integration with CI

### Current CI Configuration

Windows CI should:
1. Build and install benpy successfully ✅
2. Run the safe test subset only
3. Skip tests marked with `@pytest.mark.windows_crash`

### Recommended CI Command

```bash
# Run only safe tests on Windows
pytest tests/test_windows_diagnostics.py::TestWindowsSafeSubset -v
```

Or use markers:
```bash
# Skip crash tests
pytest tests/test_windows_diagnostics.py -v -m "not windows_crash"
```

## Debugging Workflow

When investigating Windows crashes:

1. **Run diagnostic report** to confirm status:
   ```bash
   pytest tests/test_windows_diagnostics.py::test_generate_diagnostic_report -v -s
   ```

2. **Test minimal versions** to isolate the issue:
   ```bash
   pytest tests/test_windows_diagnostics.py::TestWindowsCrashPatterns -v
   ```

3. **Compare with safe tests** to understand differences:
   ```bash
   pytest tests/test_windows_diagnostics.py::TestWindowsSafeSubset -v
   ```

4. **Refer to detailed documentation**:
   - See `doc/WindowsTestCrashes.md` for:
     - Technical analysis of crash patterns
     - Debugging recommendations
     - Platform differences
     - C-level investigation steps

## Adding New Diagnostic Tests

When adding new examples or finding new issues:

1. Add the test to `TestWindowsCompatibilityMatrix`
2. Use appropriate markers (`@pytest.mark.windows_crash` if it crashes)
3. Add platform guards (`@pytest.mark.skipif` as needed)
4. Update the categorization in `test_generate_diagnostic_report`
5. Document findings in `doc/WindowsTestCrashes.md`

## Example Test Structure

```python
@pytest.mark.windows_crash  # If expected to crash on Windows
@pytest.mark.skipif(
    sys.platform != 'win32',
    reason="Only test on Windows - this is the crash test"
)
def test_new_edge_case_diagnostic(self):
    """
    Diagnostic: New edge case
    
    Expected: CRASH/PASS on Windows
    Problem type: Description
    """
    # Test implementation
    try:
        sol = benpy.solve_direct(...)
        print("\n✓ New edge case: SUCCESS")
        assert sol is not None
    except Exception as e:
        print(f"\n✗ New edge case: {type(e).__name__}: {e}")
        pytest.fail(f"Test raised exception: {e}")
```

## Related Files

- **Test file**: `tests/test_windows_diagnostics.py` (this file)
- **Documentation**: `doc/WindowsTestCrashes.md`
- **Problem definitions**: `tests/problems.py`
- **Main test suite**: `tests/test_examples.py`
- **Pytest config**: `pytest.ini`

## References

- [WindowsTestCrashes.md](../doc/WindowsTestCrashes.md) - Detailed crash analysis
- [benpy GitHub Issues](https://github.com/markobud/benpy/issues) - Report new findings
- [pytest documentation](https://docs.pytest.org/) - Testing framework docs

## Summary

This diagnostic test suite enables:

✅ **Safe Windows CI** - Run tests that don't crash  
✅ **Clear categorization** - Know what works and what doesn't  
✅ **Debugging guidance** - Systematic approach to fixing crashes  
✅ **Progress tracking** - Measure improvements over time  
✅ **Documentation** - Clear record of Windows compatibility  

For questions or to contribute fixes, please open an issue referencing this test suite and the WindowsTestCrashes.md documentation.
