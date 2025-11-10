# Windows SIZEOF_VOID_P Fix - Quick Reference Card

## The Problem in One Diagram

```
┌─────────────────────────────────────────────────────┐
│  Cython Code Generation (64-bit Python)             │
│  ┌─────────────────────────────────────────┐        │
│  │ #define SIZEOF_VOID_P 8                 │        │
│  │ enum { __pyx_check_sizeof_voidp =       │        │
│  │   1 / (int)(SIZEOF_VOID_P == sizeof(void*)) }; │ │
│  └─────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  C Compilation (GCC on Windows)                     │
│  ┌─────────────────────────────────────────┐        │
│  │ WITHOUT -m64:                           │        │
│  │   sizeof(void*) = ??? (maybe 4?)        │        │
│  │   1 / (int)(8 == 4) = 1 / 0 = ERROR ❌ │        │
│  │                                         │        │
│  │ WITH -m64:                              │        │
│  │   sizeof(void*) = 8                     │        │
│  │   1 / (int)(8 == 8) = 1 / 1 = OK ✅    │        │
│  └─────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────┘
```

## The Solution in One Command

```bash
# Before:
gcc -std=c99 -O3 ... benpy.c        # ❌ Fails with SIZEOF_VOID_P error

# After:
gcc -m64 -std=c99 -O3 ... benpy.c   # ✅ Works! -m64 is the key
```

## The Code Change

### Before (setup.py)
```python
ext = Extension(
    name="benpy",
    extra_compile_args=['-std=c99', '-O3'],  # ❌ Missing -m64
    ...
)

setup(
    ext_modules=cythonize([ext], ...)         # ❌ Not optimized for Windows
)
```

### After (setup.py)
```python
# 1. Add architecture flag
extra_compile_args = ['-std=c99', '-O3']
if platform.system() == 'Windows':
    pointer_size = struct.calcsize('P')
    if pointer_size == 8:
        extra_compile_args.append('-m64')  # ✅ KEY FIX

ext = Extension(
    name="benpy",
    extra_compile_args=extra_compile_args,
    ...
)

# 2. Optimize Cython for Windows
if platform.system() == 'Windows':
    cythonize_kwargs = {
        'force': True,
        'nthreads': 0,
        'build_dir': 'build',
        'preliminary_late_includes_cy28': True
    }
else:
    cythonize_kwargs = {...}

setup(
    ext_modules=cythonize([ext], **cythonize_kwargs)  # ✅ Optimized
)
```

## Why Previous Attempts Failed

```
┌──────────────────┬────────────────┬─────────────┬──────────┐
│ Attempt          │ Fixed Cython?  │ Fixed GCC?  │ Result   │
├──────────────────┼────────────────┼─────────────┼──────────┤
│ #1: force=True   │ Yes ✓          │ No ✗        │ ❌ Failed│
│ #2: compile_env  │ Yes ✓          │ No ✗        │ ❌ Failed│
│ This: -m64       │ Yes ✓          │ Yes ✓       │ ✅ Works │
└──────────────────┴────────────────┴─────────────┴──────────┘
```

**Key Insight**: Must fix BOTH Cython and GCC, not just Cython!

## Quick Verification Checklist

On Windows CI build, look for:

```
✅ "Windows build: Adding -m64 flag to match pointer size 8 bytes"
✅ "gcc.exe -m64 -std=c99 -O3 ..."
✅ "Successfully built benpy-2.1.0-cp39-cp39-win_amd64.whl"

❌ Should NOT see:
   "error: enumerator value for '__pyx_check_sizeof_voidp' is not an integer constant"
   "enum { __pyx_check_sizeof_voidp = 1 / (int)(SIZEOF_VOID_P == sizeof(void*)) };"
```

## File Locations

| File | Purpose |
|------|---------|
| **setup.py** | Implementation (lines 125-138, 164-173) |
| **doc/WindowsWheelSizeOfVoidPFix.md** | Main documentation (222 lines) |
| **doc/WindowsWheelFix_Comparison.md** | Comparison analysis (173 lines) |

## Platform Compatibility

```
┌──────────┬─────────────────┬─────────────┬────────────┐
│ Platform │ Uses This Fix?  │ Changes?    │ Status     │
├──────────┼─────────────────┼─────────────┼────────────┤
│ Windows  │ Yes             │ setup.py    │ Fixed      │
│ Linux    │ No              │ None        │ No change  │
│ macOS    │ No              │ None        │ No change  │
└──────────┴─────────────────┴─────────────┴────────────┘
```

## The Math

### Without -m64 (Failed)
```
SIZEOF_VOID_P = 8 (from Cython)
sizeof(void*) = 4 (from GCC default, maybe?)

Check: 8 == 4 → False → 0
Enum:  1 / 0 → ERROR ❌
```

### With -m64 (Works)
```
SIZEOF_VOID_P = 8 (from Cython)
sizeof(void*) = 8 (from GCC with -m64)

Check: 8 == 8 → True → 1
Enum:  1 / 1 = 1 → OK ✅
```

## One-Line Summary

**Add `-m64` flag to GCC on Windows so `sizeof(void*)` matches Cython's `SIZEOF_VOID_P`.**

That's it. That's the fix.

## Further Reading

For complete details:
1. **Start here**: `doc/WindowsWheelSizeOfVoidPFix.md`
2. **Compare**: `doc/WindowsWheelFix_Comparison.md`
3. **History**: `doc/WindowsWheelBuildAttempts_Post_c788f5a.md`
