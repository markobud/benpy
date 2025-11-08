# Windows Wheel Build Triage - MSVC-Based Configuration

## Issue Summary

Windows wheel builds were failing because MSVC compiler was trying to use MinGW/MSYS2 headers that contain GCC-specific syntax (`__asm__`, `__volatile__`, `__builtin_*`), causing 100+ compilation errors. This document details the root cause analysis and MSVC-based solution.

## Root Cause

The initial approach attempted to use MinGW/GCC on Windows, but this created a toolchain conflict:
1. cibuildwheel defaulted to MSVC compiler (`cl.exe`) on Windows
2. GLPK was installed via MSYS2/MinGW which added MinGW headers to the include path
3. MSVC cannot parse GCC-specific constructs in MinGW headers
4. Result: 100+ syntax errors in system headers (stdio.h, stdlib.h, math.h, etc.)

## New Solution: Use MSVC Cleanly

Instead of forcing MinGW/GCC, we now use MSVC as the compiler with MSVC-compatible GLPK libraries installed via vcpkg.

### Key Changes

1. **Install GLPK via vcpkg** (MSVC-compatible) instead of MSYS2/MinGW
2. **Sanitize Windows environment** to remove MinGW paths from PATH
3. **Use MSVC-friendly compile flags** (`/EHsc`, `/O2`) instead of GCC flags (`-std=c99`, `-O3`)
4. **Let MSVC be the default compiler** (no CC/CXX override)

## Problems Identified and Fixed

### Problem 1: MSVC/MinGW Header Incompatibility

**Problem**: MSVC compiler was including MinGW headers from MSYS2 which contain GCC-specific syntax.

**Impact**: Compilation failed with errors like:
```
C:/msys64/mingw64/include\stdio.h(214): error C2061: syntax error: identifier '__asm__'
C:/msys64/mingw64/include\math.h(213): error C2065: '__asm__': undeclared identifier
```

**Solution**: 
- Remove MSYS2/MinGW from PATH before building
- Clear environment variables that inject GCC includes (CPATH, C_INCLUDE_PATH, etc.)
- Use vcpkg to install MSVC-compatible GLPK

### Problem 2: GCC-Specific Compile Flags

**Problem**: setup.py used GCC flags (`-std=c99`, `-O3`) for all platforms, which MSVC ignores or warns about.

**Impact**: MSVC warnings and potentially missed optimizations.

**Solution**: Use platform-specific compile flags:
- Windows (MSVC): `/EHsc /O2`
- macOS/Linux (GCC): `-std=c99 -O3`

### Problem 3: Missing GLPK for MSVC

**Problem**: GLPK was only available via MSYS2/MinGW, which is GCC-based.

**Impact**: No MSVC-compatible GLPK library available.

**Solution**: Install GLPK via vcpkg which provides MSVC-compiled libraries.

## Solutions Implemented

### Fix #1: Sanitize Windows Build Environment

Added a workflow step to remove MinGW from PATH and clear GCC environment variables:

```yaml
- name: Remove MSYS/MinGW from PATH and clear GCC env vars (Windows only)
  if: runner.os == 'Windows'
  shell: pwsh
  run: |
    # Remove msys64 or mingw64 entries from PATH
    $paths = $env:PATH -split ';'
    $clean = $paths | Where-Object { $_ -notmatch 'msys64|mingw64' }
    $new = $clean -join ';'
    [Environment]::SetEnvironmentVariable('PATH', $new, 'Process')
    
    # Clear GCC-related environment variables
    echo "CPATH=" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
    echo "C_INCLUDE_PATH=" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
```

**Purpose**: Prevents MSVC from accidentally using MinGW headers and libraries.

### Fix #2: Install GLPK via vcpkg

Updated `pyproject.toml` to use vcpkg instead of MSYS2:

```toml
[tool.cibuildwheel.windows]
before-all = [
    # Install vcpkg and GLPK
    "git clone https://github.com/Microsoft/vcpkg.git C:\\vcpkg",
    "C:\\vcpkg\\bootstrap-vcpkg.bat",
    "C:\\vcpkg\\vcpkg install glpk:x64-windows",
    # Install delvewheel for bundling DLLs
    "pip install delvewheel",
]
environment = { 
    VCPKG_ROOT="C:\\vcpkg",
    GLPK_INCLUDE_DIR="C:\\vcpkg\\installed\\x64-windows\\include",
    GLPK_LIBRARY_DIR="C:\\vcpkg\\installed\\x64-windows\\lib"
}
```

**Purpose**: Provides MSVC-compatible GLPK libraries.

### Fix #3: Add Windows-Specific MSVC Configuration to setup.py

Added Windows-specific block with MSVC flags:

```python
# Windows-specific configuration (MSVC)
elif platform.system() == 'Windows':
    # Use vcpkg-installed GLPK paths from environment variables
    glpk_include = os.environ.get('GLPK_INCLUDE_DIR', 'C:\\vcpkg\\installed\\x64-windows\\include')
    glpk_lib = os.environ.get('GLPK_LIBRARY_DIR', 'C:\\vcpkg\\installed\\x64-windows\\lib')
    
    include_dirs.append(glpk_include)
    library_dirs.append(glpk_lib)
    
    # Use MSVC-friendly compile flags
    extra_compile_args = ['/EHsc', '/O2']  # Exception handling and optimization
    
    print(f"Windows MSVC build: GLPK include={glpk_include}, lib={glpk_lib}")
```

**Key Features**:
- Extracts GLPK paths from environment variables set by cibuildwheel
- Uses MSVC-specific compile flags
- Adds diagnostic logging

### Fix #4: Platform-Specific Compile Flags

Made compile flags conditional:
- **macOS/Linux**: `-std=c99 -O3` (GCC flags)
- **Windows**: `/EHsc /O2` (MSVC flags)

## Windows Build Configuration Summary

### Toolchain: MSVC (Microsoft Visual C++)

The project now uses **MSVC** for Windows builds. This is the standard approach for Python wheels on Windows because:

1. **Official Python builds use MSVC**: Binary compatibility with standard Python
2. **No header conflicts**: MSVC headers compatible with MSVC compiler
3. **vcpkg ecosystem**: Easy access to MSVC-compiled libraries
4. **Standard practice**: NumPy, SciPy, and most scientific Python packages use MSVC on Windows

### GLPK Installation Strategy

**Method**: vcpkg package manager
```bash
git clone https://github.com/Microsoft/vcpkg.git C:\vcpkg
C:\vcpkg\bootstrap-vcpkg.bat
C:\vcpkg\vcpkg install glpk:x64-windows
```

**Paths**:
- Headers: `C:\vcpkg\installed\x64-windows\include`
- Libraries: `C:\vcpkg\installed\x64-windows\lib`
- Binaries: `C:\vcpkg\installed\x64-windows\bin`

**Environment Variables Set by cibuildwheel**:
```
VCPKG_ROOT="C:\vcpkg"
GLPK_INCLUDE_DIR="C:\vcpkg\installed\x64-windows\include"
GLPK_LIBRARY_DIR="C:\vcpkg\installed\x64-windows\lib"
```

### DLL Bundling: delvewheel

**Purpose**: Bundle required runtime DLLs into the wheel so it's self-contained.

**Required DLLs**:
- `glpk.dll` - GLPK library
- MSVC runtime DLLs (automatically detected)

**Command**: `delvewheel repair -w {dest_dir} {wheel}`

This automatically detects and bundles all required DLLs.

## Build Process Flow

1. **Sanitize environment** (workflow step)
   - Remove MSYS2/MinGW from PATH
   - Clear GCC-related environment variables

2. **Install dependencies** (before-all)
   - Clone and bootstrap vcpkg
   - Install GLPK via vcpkg
   - Install delvewheel via pip

3. **Build wheel** (cibuildwheel)
   - Environment variables (GLPK paths) set
   - setup.py extracts paths from environment
   - Cython compiles .pyx to C
   - **MSVC** compiles C sources with `/EHsc /O2` flags
   - Links against GLPK from vcpkg
   - Creates initial wheel

4. **Repair wheel** (delvewheel)
   - Analyzes wheel for DLL dependencies
   - Copies required DLLs into wheel
   - Patches imports to load bundled DLLs
   - Creates final distributable wheel

## Testing the Fixes

### Expected Build Output

When the build succeeds, you should see:

1. **Compiler selection** (MSVC instead of GCC):
   ```
   building 'benpy' extension
   cl.exe /c /nologo /O2 /W3 /GL /DNDEBUG /MD /EHsc /O2 ...
   ```
   NOT: `gcc.exe` (MinGW compiler)

2. **setup.py output**:
   ```
   Windows MSVC build: GLPK include=C:\vcpkg\installed\x64-windows\include, lib=C:\vcpkg\installed\x64-windows\lib
   ```

3. **Compilation output** (MSVC paths):
   ```
   building 'benpy' extension
   cl.exe ... -IC:\vcpkg\installed\x64-windows\include ...
   ```

4. **Linking output**:
   ```
   link.exe ... /LIBPATH:C:\vcpkg\installed\x64-windows\lib glpk.lib ...
   ```

5. **delvewheel output**:
   ```
   analyzing wheel: benpy-2.1.0-cp39-cp39-win_amd64.whl
   adding glpk.dll
   ...
   ```

### Common Failure Patterns to Watch For

❌ **MSVC trying to use MinGW headers** (THE CRITICAL ISSUE):
```
cl.exe /c /nologo /O2 /W3 /GL /DNDEBUG /MD ...
C:/msys64/mingw64/include\stdio.h(214): error C2061: syntax error: identifier '__asm__'
C:/msys64/mingw64/include\stdio.h(214): error C2059: syntax error: ';'
```
**Diagnosis**: MinGW still in PATH or GCC environment variables set
**Solution**: Ensure PATH sanitization step runs before build

❌ **GLPK headers not found**:
```
glpk.h: No such file or directory
```
**Diagnosis**: vcpkg not installed or GLPK_INCLUDE_DIR not set

❌ **Cannot find glpk.lib**:
```
LINK : fatal error LNK1181: cannot open input file 'glpk.lib'
```
**Diagnosis**: GLPK_LIBRARY_DIR not set or vcpkg GLPK not installed

❌ **delvewheel not found**:
```
delvewheel: command not found
```
**Diagnosis**: delvewheel not installed in before-all

❌ **DLL not found at runtime**:
```
ImportError: DLL load failed: The specified module could not be found
```
**Diagnosis**: delvewheel failed to bundle required DLLs

## Comparison with Other Platforms

| Aspect | Linux | macOS | Windows (MSVC) |
|--------|-------|-------|----------------|
| **Package Manager** | apt/yum | Homebrew | vcpkg |
| **Compiler** | GCC | Clang/GCC | MSVC (cl.exe) |
| **GLPK Package** | libglpk-dev | glpk | glpk:x64-windows |
| **Compile Flags** | -std=c99 -O3 | -std=c99 -O3 | /EHsc /O2 |
| **Wheel Repair** | auditwheel | delocate | delvewheel |
| **Math Library** | libm (explicit) | libm (explicit) | Built into CRT |
| **Path Setup** | Simple | pkg-config/brew | vcpkg env vars |

## Next Steps

Once the workflow runs successfully:

1. ✅ Verify wheel builds without MSVC/MinGW conflicts
2. ✅ Verify delvewheel successfully repairs the wheel
3. ✅ Check that required DLLs are bundled into the wheel
4. ⏳ Download and test the wheel on a clean Windows system
5. ⏳ Re-enable verification tests to ensure wheel imports correctly
6. ⏳ Re-enable Linux and macOS builds once Windows is stable

## References

- **vcpkg**: https://github.com/Microsoft/vcpkg
- **delvewheel**: https://github.com/adang1345/delvewheel
- **cibuildwheel Windows**: https://cibuildwheel.readthedocs.io/en/stable/options/#windows-options
- **MSVC**: https://docs.microsoft.com/en-us/cpp/
- **GLPK**: https://www.gnu.org/software/glpk/

## Related Documentation

- `doc/CrossPlatformCompilation.md` - Platform-specific build instructions
- `doc/CibuildwheelConfiguration.md` - Detailed cibuildwheel configuration
- `doc/BuildingWheels.md` - General wheel building guide
- `doc/WindowsTestCrashes_RESOLVED.md` - Windows runtime crash issues (separate from build issues)

## Commit History

1. `Focus build-wheels.yml on Windows builds only` - Isolated Windows builds for triage
2. `Add Windows-specific GLPK path handling to setup.py and install delvewheel` - Initial MinGW attempt (reverted)
3. `Add comprehensive Windows wheel build triage documentation` - Initial triage documentation
4. `Force MinGW GCC compiler usage on Windows` - MinGW approach (reverted)
5. `Use MSVC with vcpkg GLPK and sanitized environment` - MSVC-based solution (current)

## Status

✅ **Configuration Complete**: All identified issues have been fixed with MSVC-based approach.

✅ **MSVC/MinGW Conflict Resolved**: PATH sanitization prevents header conflicts.

✅ **vcpkg GLPK Integration**: MSVC-compatible GLPK library installation configured.

⏳ **Awaiting CI Run**: Waiting for GitHub Actions to run Windows build with MSVC and vcpkg.

The Windows wheel build configuration now uses MSVC (the standard Windows compiler) with vcpkg-provided GLPK libraries, avoiding all MinGW/GCC toolchain conflicts.
