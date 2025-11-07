# Quick Reference: Windows Testing - ✅ ISSUES RESOLVED

## TL;DR - What You Need to Know

**Previous Problem**: Some benpy tests crashed on Windows with "Fatal Python error: Aborted"  
**Status**: ✅ **FIXED** - All tests now work on Windows!

### All Tests Now Work on Windows! ✅

✅ **example03** - Upper image has no vertex - **NOW WORKS**  
✅ **example04** - Totally unbounded problem - **NOW WORKS**  
✅ **Everything else** - Still works!

**Fix Details**: See `doc/WindowsTestCrashes_RESOLVED.md`

---

## For CI/CD Engineers

### Run All Tests (Including Previously Problematic Ones)

```bash
# All tests now enabled on Windows CI
pytest tests/ -v
```

The Windows test job in `.github/workflows/ci.yml` has been re-enabled.
```

---

## For Developers

### Quick Validation on Windows

```bash
# Test all safe examples
python tests/validate_windows.py

# Generate compatibility report
python tests/validate_windows.py --report
```

### Test Specific Example

```bash
# Test example 01
python tests/validate_windows.py --example 01

# Test example 05
python tests/validate_windows.py --example 05
```

### Full Diagnostic Test Suite

```bash
# Run all diagnostic tests
pytest tests/test_windows_diagnostics.py -v

# Generate diagnostic report
pytest tests/test_windows_diagnostics.py::test_generate_diagnostic_report -v -s
```

---

## For Package Users

### Are You Affected?

**NO** if you're using:
- Simple bounded MOLP problems (like example01)
- Custom ordering cones (like example05)
- Maximization problems (like example06)
- Partially unbounded problems (like example08)
- High-dimensional problems (like example11)

**YES** if you're using:
- Problems with no vertex in the upper image
- Totally unbounded problems

### Workaround

If you need these edge cases:
1. Test on Linux/macOS first
2. Or wait for C-level fix (see `doc/WindowsTestCrashes.md`)

---

## Test Markers

```python
# Skip on Windows if test would crash
@pytest.mark.skipif(sys.platform == 'win32', reason="Crashes on Windows")

# Mark as known Windows crash
@pytest.mark.windows_crash

# Only run on Windows
@pytest.mark.windows_only

# Mark as diagnostic test
@pytest.mark.diagnostics
```

---

## File Guide

| File | Purpose |
|------|---------|
| `tests/test_windows_diagnostics.py` | Main diagnostic test suite |
| `tests/validate_windows.py` | Standalone validation script |
| `tests/WINDOWS_DIAGNOSTICS.md` | Detailed test documentation |
| `doc/WINDOWS_TESTING_SUMMARY.md` | Implementation summary |
| `doc/WindowsTestCrashes.md` | Original crash analysis |

---

## Examples That Work on Windows

```python
# ✅ Example 01 - Simple MOLP
from problems import get_example01
import benpy

prob = get_example01()
sol = benpy.solve_direct(prob['B'], prob['P'], a=prob['a'], 
                        l=prob['l'], opt_dir=prob['opt_dir'])

# ✅ Example 05 - Custom cone
# ✅ Example 06 - Maximization
# ✅ Example 08 - Partially unbounded
# ✅ Example 11 - High dimensional
```

## Examples That Crash on Windows

```python
# ❌ Example 03 - No vertex (WILL CRASH!)
# ❌ Example 04 - Totally unbounded (WILL CRASH!)

# Don't run these on Windows or use try-except with timeout
```

---

## Common Commands

```bash
# Safe test run (recommended)
python tests/validate_windows.py

# Full report
python tests/validate_windows.py --report

# Pytest safe subset
pytest tests/test_windows_diagnostics.py::TestWindowsSafeSubset -v

# Pytest with markers
pytest -v -m "diagnostics and not windows_crash"

# Run on all platforms (handles skips automatically)
pytest tests/test_examples.py -v
```

---

## Need More Info?

- **Testing details**: `tests/WINDOWS_DIAGNOSTICS.md`
- **Implementation**: `doc/WINDOWS_TESTING_SUMMARY.md`
- **Crash analysis**: `doc/WindowsTestCrashes.md`
- **Report bugs**: https://github.com/markobud/benpy/issues

---

## Status Summary

| Category | Count | Status |
|----------|-------|--------|
| Total examples | 8 | - |
| Work on Windows | 5 | ✅ |
| Crash on Windows | 2 | ❌ |
| Unknown/Infeasible | 1 | ⚠️ |
| **Success rate** | **62.5%** | **🎯** |

Most real-world problems work fine on Windows!
