# Windows Wheel Build Attempts - Post Commit c788f5a

## Summary

This document tracks all attempts to fix the Windows wheel build issues after commit `c788f5a37e6a1a8ead00f610ff0b27e9cf0b230f` (Pin Cython>=3.0.0 to fix SIZEOF_VOID_P compile-time assertion issue on Windows).

## Timeline of Attempts

### Commit c788f5a (Starting Point)
**Date**: 2025-11-09  
**Changes**:
- Pinned `Cython>=3.0.0` in pyproject.toml build requirements
- Added compiler_directives in setup.py with `language_level=3` and `embedsignature=True`
- Goal: Fix Cython-generated code with division-by-zero pattern for compile-time assertions

**Result**: Build still failed with SIZEOF_VOID_P mismatch error

---

### Attempt #1: Force Cython Regeneration (Commit 05c33aa)
**Date**: 2025-11-09  
**Approach**: Added `force=True` parameter to `cythonize()` call

**Changes Made**:
```python
# setup.py
compiler_directives = {
    'language_level': 3,
    'embedsignature': True,
    'c_string_type': 'unicode',
    'c_string_encoding': 'utf8',
}

setup(
    ext_modules=cythonize([ext], include_path=['src'], 
                          compiler_directives=compiler_directives, 
                          force=True)
)
```

**Rationale**:
- Force Cython to regenerate C code on each platform
- Ensure SIZEOF_VOID_P is set correctly for the target architecture
- Added unicode string handling directives

**Result**: ❌ Failed
- Build logs: https://github.com/markobud/benpy/actions/runs/19207438083/job/54904695940
- Wheel build: https://github.com/markobud/benpy/actions/runs/19207438348/job/54904695936
- Error: SIZEOF_VOID_P still mismatched even with force=True

---

### Attempt #2: Explicit compile_time_env (Commit 6eeaf4c)
**Date**: 2025-11-09  
**Approach**: Explicitly set SIZEOF_VOID_P via `compile_time_env` parameter

**Changes Made**:
```python
# setup.py
compile_time_env = None
if platform.system() == 'Windows':
    import struct
    compile_time_env = {'SIZEOF_VOID_P': struct.calcsize('P')}
    print(f"Set compile_time_env SIZEOF_VOID_P={struct.calcsize('P')} for Windows build")

setup(
    ext_modules=cythonize([ext], include_path=['src'], 
                          compiler_directives=compiler_directives, 
                          compile_time_env=compile_time_env, 
                          force=True)
)
```

**Rationale**:
- `struct.calcsize('P')` returns actual pointer size for current Python interpreter (8 bytes on AMD64)
- `compile_time_env` dictionary overrides Cython's default compile-time values
- Ensures SIZEOF_VOID_P matches sizeof(void*) during C compilation

**Result**: ❌ Failed (Status unknown at time of documentation)
- User reported: "Still filling [failing]"

---

## Technical Analysis

### Root Problem
The SIZEOF_VOID_P compile-time assertion in Cython-generated code:
```c
enum { __pyx_check_sizeof_voidp = 1 / (int)(SIZEOF_VOID_P == sizeof(void*)) };
```

This fails when:
1. Cython sets SIZEOF_VOID_P based on the Python interpreter generating the code
2. The value doesn't match the target platform's actual pointer size during C compilation
3. Causes division by zero or non-constant enumerator errors

### Challenges Encountered

1. **Cross-platform code generation**: Cython generates C code that may have different architecture assumptions than the target platform

2. **CI environment complexity**: Build environments may have mismatched configurations between code generation and compilation phases

3. **MinGW/GCC specificity**: The project requires MinGW/GCC on Windows (not MSVC), adding toolchain complexity

### Solutions Attempted

| Attempt | Approach | Outcome |
|---------|----------|---------|
| 1 | Pin Cython>=3.0.0 | Partial - better code but still mismatch |
| 2 | Force regeneration (force=True) | Failed - still incorrect SIZEOF_VOID_P |
| 3 | Explicit compile_time_env | Failed - issue persisted |

## Previous Successful Changes (Before c788f5a)

For context, these were the successful changes leading to commit c788f5a:

1. **Commit 09fe8d6, 00e3d9a**: Added Windows-specific GLPK path handling in setup.py
2. **Commit 4103982**: Baseline MinGW configuration with CC=gcc, CXX=g++
3. **Commit a690617**: Created pydistutils.cfg to force MinGW compiler (solved MSVC/MinGW mixing)
4. **Commit c788f5a**: Pinned Cython>=3.0.0 (addressed division-by-zero pattern)

## Recommended Next Steps

1. **Investigate Cython internals**: Understand exactly how SIZEOF_VOID_P is determined and why compile_time_env might not be working

2. **Check cibuildwheel environment**: Verify that the Python interpreter used for code generation matches the target architecture

3. **Consider alternative approaches**:
   - Patch the generated C code post-generation (less maintainable)
   - Use Cython's conditional compilation features
   - Investigate if there's a cibuildwheel configuration issue

4. **Test locally on Windows**: Reproduce the issue outside CI to better understand the environment mismatch

5. **Consult Cython documentation/community**: This may be a known issue with specific workarounds

## References

- Initial successful commit: c788f5a37e6a1a8ead00f610ff0b27e9cf0b230f
- Cython documentation: https://cython.readthedocs.io/en/latest/
- Build logs showing failures: 
  - https://github.com/markobud/benpy/actions/runs/19207438083/job/54904695940
  - https://github.com/markobud/benpy/actions/runs/19207438348/job/54904695936

## Conclusion

After commit c788f5a, two additional attempts were made to fix the SIZEOF_VOID_P mismatch:
1. Forcing Cython regeneration with `force=True`
2. Explicitly setting SIZEOF_VOID_P via `compile_time_env`

Both approaches failed to resolve the issue. The problem appears to be more fundamental, possibly related to how cibuildwheel sets up the build environment or how Cython determines platform-specific values in cross-compilation scenarios.

Further investigation is needed, potentially involving:
- Deep dive into cibuildwheel's Windows build environment
- Cython's compile-time value determination mechanism
- Alternative build strategies or toolchain configurations

## Status

**Branch**: `copilot/triage-windows-wheel-builds`  
**Current HEAD**: `6eeaf4c` (Set compile_time_env SIZEOF_VOID_P explicitly for Windows to fix pointer size mismatch)  
**Reverting to**: `c788f5a` (Pin Cython>=3.0.0 to fix SIZEOF_VOID_P compile-time assertion issue on Windows)  
**Action**: This PR will be closed and the issue will be addressed in a follow-up task
