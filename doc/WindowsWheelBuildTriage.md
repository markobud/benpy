# Windows Wheel Build Triage - Configuration Fixes

## Issue Summary

Windows wheel builds were failing due to missing GLPK library path configuration and missing delvewheel installation. This document details the triage findings and fixes applied.

## Problems Identified

### 1. Missing Windows-Specific Path Handling in setup.py

**Problem**: The `setup.py` file had extensive macOS-specific configuration to extract GLPK paths from environment variables (lines 68-91), but this logic was inside an `if platform.system() == 'Darwin':` block. On Windows, the script would not extract CFLAGS/LDFLAGS from environment variables, leading to missing GLPK headers and library paths.

**Impact**: Windows builds would fail with "GLPK headers not found" or "cannot find -lglpk" linker errors.

**Root Cause**: When the macOS GLPK path handling was added, Windows was not given equivalent logic.

### 2. Missing delvewheel Installation

**Problem**: The `pyproject.toml` configured `repair-wheel-command = "delvewheel repair -w {dest_dir} {wheel}"` for Windows, but delvewheel was never installed during the build process.

**Impact**: After successfully building the wheel, the repair step would fail with "delvewheel: command not found".

**Comparison**: macOS properly installs `delocate` via `pip install delocate` in the `before-all` step, but Windows was missing the equivalent `pip install delvewheel`.

## Solutions Implemented

### Fix #1: Add Windows-Specific GLPK Path Handling to setup.py

Added a new Windows-specific configuration block to `setup.py` (after line 94):

```python
# Windows-specific configuration
elif platform.system() == 'Windows':
    # On Windows, rely on CFLAGS/LDFLAGS environment variables set by cibuildwheel
    # These point to MSYS2/MinGW GLPK installation
    cflags = os.environ.get('CFLAGS', '')
    ldflags = os.environ.get('LDFLAGS', '')
    
    print(f"Windows build with CFLAGS={cflags}, LDFLAGS={ldflags}")
    
    # Extract include dirs from CFLAGS
    if '-I' in cflags:
        for flag in cflags.split():
            if flag.startswith('-I'):
                include_dirs.append(flag[2:])
    else:
        # Fallback to default MSYS2 MinGW64 paths if no CFLAGS set
        include_dirs.append('C:/msys64/mingw64/include')
    
    # Extract library dirs from LDFLAGS
    if '-L' in ldflags:
        for flag in ldflags.split():
            if flag.startswith('-L'):
                library_dirs.append(flag[2:])
    else:
        # Fallback to default MSYS2 MinGW64 paths if no LDFLAGS set
        library_dirs.append('C:/msys64/mingw64/lib')
    
    print(f"Windows GLPK paths: includes={include_dirs}, libs={library_dirs}")
```

**Key Features**:
- Mirrors the macOS approach of extracting paths from CFLAGS/LDFLAGS
- Includes fallback to default MSYS2 MinGW64 paths
- Adds diagnostic logging to help debug path issues
- Ensures GLPK headers and libraries are found during compilation

### Fix #2: Install delvewheel in Windows Build Pipeline

Modified `pyproject.toml` to install delvewheel before building wheels:

```toml
[tool.cibuildwheel.windows]
before-all = [
    "C:\\msys64\\usr\\bin\\bash -lc 'pacman -S --noconfirm mingw-w64-x86_64-glpk mingw-w64-x86_64-gcc'",
    "pip install delvewheel",  # Added this line
]
```

**Purpose**: Ensures delvewheel is available for the `repair-wheel-command` to bundle required DLLs (glpk.dll, libgcc_s_seh-1.dll, etc.) into the wheel.

### Fix #3: Updated Build Workflow for Triage

Modified `.github/workflows/build-wheels.yml` to focus exclusively on Windows builds for triage:

- Commented out macOS x86_64 and ARM64 builds
- Commented out Linux x86_64 and aarch64 builds
- Enabled Windows AMD64 builds
- Commented out the entire `verify_wheels` job (per triage instructions)

**Purpose**: Isolate Windows builds to capture and analyze any compilation or linking errors without interference from other platforms.

### Fix #4: Force MinGW/GCC Compiler Usage on Windows

**Problem**: cibuildwheel was defaulting to MSVC compiler on Windows, but MinGW headers (from GLPK) contain GCC-specific syntax (`__asm__`, `__volatile__`, `__builtin_*`) that MSVC cannot parse.

**Solution**: Added `CC="gcc"` and `CXX="g++"` to the environment section in `pyproject.toml`:

```toml
[tool.cibuildwheel.windows]
environment = { CC="gcc", CXX="g++", CFLAGS="-IC:/msys64/mingw64/include", LDFLAGS="-LC:/msys64/mingw64/lib", PATH="C:\\msys64\\mingw64\\bin;$PATH" }
```

**Impact**: This forces setuptools/distutils to use MinGW GCC from the PATH instead of auto-detecting and using MSVC. This ensures:
- GCC can compile the code with `-std=c99` flag
- MinGW headers are compatible with the compiler
- Cross-platform consistency (GCC on all platforms)

## Windows Build Configuration Summary

### Toolchain: MSYS2/MinGW (Not MSVC)

The project uses **MinGW** (Minimalist GNU for Windows) instead of MSVC for Windows builds. This is the correct approach because:

1. **GLPK Availability**: GLPK is readily available via MSYS2 package manager
2. **GCC Compatibility**: The Bensolve C code is written for GCC (uses `-std=c99`)
3. **Cross-Platform Consistency**: Uses GCC on all platforms (Linux, macOS, Windows)
4. **Header Compatibility**: MinGW headers use GCC-specific syntax incompatible with MSVC

### GLPK Installation Strategy

**Method**: MSYS2 package manager (pacman)
```bash
pacman -S --noconfirm mingw-w64-x86_64-glpk mingw-w64-x86_64-gcc
```

**Paths**:
- Headers: `C:/msys64/mingw64/include`
- Libraries: `C:/msys64/mingw64/lib`
- Binaries: `C:/msys64/mingw64/bin`

**Environment Variables Set by cibuildwheel**:
```
CC="gcc"
CXX="g++"
CFLAGS="-IC:/msys64/mingw64/include"
LDFLAGS="-LC:/msys64/mingw64/lib"
PATH="C:\msys64\mingw64\bin;$PATH"
```

### DLL Bundling: delvewheel

**Purpose**: Bundle required runtime DLLs into the wheel so it's self-contained.

**Required DLLs**:
- `libglpk-40.dll` - GLPK library
- `libgcc_s_seh-1.dll` - GCC runtime
- `libwinpthread-1.dll` - Threading library
- `libgmp-10.dll` - GMP library (GLPK dependency)

**Command**: `delvewheel repair -w {dest_dir} {wheel}`

This automatically detects and bundles all required DLLs, similar to how `delocate` works on macOS and `auditwheel` works on Linux.

## Build Process Flow

1. **Install MSYS2 packages** (before-all)
   - GLPK library and headers
   - GCC compiler toolchain
   - Install delvewheel via pip

2. **Build wheel** (cibuildwheel)
   - Environment variables (CFLAGS, LDFLAGS, PATH) set
   - setup.py extracts paths from environment variables
   - Cython compiles .pyx to C
   - GCC compiles C sources and bensolve library
   - Links against GLPK from MinGW64
   - Creates initial wheel

3. **Repair wheel** (delvewheel)
   - Analyzes wheel for DLL dependencies
   - Copies required DLLs into wheel
   - Patches imports to load bundled DLLs
   - Creates final distributable wheel

## Testing the Fixes

### Expected Build Output

When the build succeeds, you should see:

1. **Compiler selection** (GCC instead of MSVC):
   ```
   building 'benpy' extension
   gcc.exe -std=c99 -O3 ...
   ```
   NOT: `cl.exe` (MSVC compiler)

2. **setup.py output**:
   ```
   Windows build with CFLAGS=-IC:/msys64/mingw64/include, LDFLAGS=-LC:/msys64/mingw64/lib
   Windows GLPK paths: includes=['...', 'C:/msys64/mingw64/include'], libs=['C:/msys64/mingw64/lib']
   ```

3. **Compilation output**:
   ```
   building 'benpy' extension
   gcc ... -IC:/msys64/mingw64/include ...
   ```

4. **Linking output**:
   ```
   gcc ... -LC:/msys64/mingw64/lib -lglpk ...
   ```

5. **delvewheel output**:
   ```
   analyzing wheel: benpy-2.1.0-cp39-cp39-win_amd64.whl
   adding libglpk-40.dll
   adding libgcc_s_seh-1.dll
   ...
   ```

### Common Failure Patterns to Watch For

❌ **MSVC compiler being used instead of GCC** (THE CRITICAL ISSUE):
```
cl.exe /c /nologo /O2 /W3 /GL /DNDEBUG /MD ...
C:/msys64/mingw64/include\stdio.h(214): error C2061: syntax error: identifier '__asm__'
C:/msys64/mingw64/include\stdio.h(214): error C2059: syntax error: ';'
```
**Diagnosis**: CC and CXX environment variables not set, causing setuptools to auto-detect and use MSVC
**Solution**: Set `CC="gcc"` and `CXX="g++"` in pyproject.toml environment section

❌ **GLPK headers not found**:
```
glpk.h: No such file or directory
```
**Diagnosis**: CFLAGS not properly extracted or GLPK not installed

❌ **Cannot find -lglpk**:
```
ld.exe: cannot find -lglpk
```
**Diagnosis**: LDFLAGS not properly extracted or library path incorrect

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

| Aspect | Linux | macOS | Windows |
|--------|-------|-------|---------|
| **Package Manager** | apt/yum | Homebrew | MSYS2/pacman |
| **Compiler** | GCC | Clang/GCC | MinGW GCC |
| **GLPK Package** | libglpk-dev | glpk | mingw-w64-x86_64-glpk |
| **Wheel Repair** | auditwheel | delocate | delvewheel |
| **Math Library** | libm (explicit) | libm (explicit) | Built into CRT |
| **Path Setup** | Simple | pkg-config/brew | CFLAGS/LDFLAGS env |

## Next Steps

Once the workflow runs successfully:

1. ✅ Verify wheel builds without compilation errors
2. ✅ Verify delvewheel successfully repairs the wheel
3. ✅ Check that required DLLs are bundled into the wheel
4. ⏳ Download and test the wheel on a clean Windows system
5. ⏳ Re-enable verification tests to ensure wheel imports correctly
6. ⏳ Re-enable Linux and macOS builds once Windows is stable

## References

- **MSYS2**: https://www.msys2.org/
- **delvewheel**: https://github.com/adang1345/delvewheel
- **cibuildwheel Windows**: https://cibuildwheel.readthedocs.io/en/stable/options/#windows-options
- **MinGW-w64**: https://www.mingw-w64.org/
- **GLPK**: https://www.gnu.org/software/glpk/

## Related Documentation

- `doc/CrossPlatformCompilation.md` - Platform-specific build instructions
- `doc/CibuildwheelConfiguration.md` - Detailed cibuildwheel configuration
- `doc/BuildingWheels.md` - General wheel building guide
- `doc/WindowsTestCrashes_RESOLVED.md` - Windows runtime crash issues (separate from build issues)

## Commit History

1. `Focus build-wheels.yml on Windows builds only` - Isolated Windows builds for triage
2. `Add Windows-specific GLPK path handling to setup.py and install delvewheel` - Core fixes
3. `Add comprehensive Windows wheel build triage documentation` - Initial triage documentation
4. `Force MinGW GCC compiler usage on Windows to avoid MSVC incompatibility` - MinGW/GCC approach
5. `Use MSVC with vcpkg GLPK instead of MinGW` - MSVC approach (REVERTED - broke other checks)
6. `Revert to MinGW approach` - Back to MinGW/GCC (current)

## Status

✅ **MinGW/GCC Approach Active**: Using MinGW GCC compiler with MSYS2 GLPK installation.

⚠️ **Previous MSVC Attempt Failed**: vcpkg/MSVC approach broke other CI checks and was reverted.

⏳ **Current State**: Back to MinGW approach, investigating if additional fixes needed.

**Current Configuration:**
- Compiler: MinGW GCC (via CC=gcc, CXX=g++)
- GLPK: MSYS2 package (mingw-w64-x86_64-glpk)
- Compile flags: -std=c99 -O3
- DLL bundling: delvewheel

**Known Challenges:**
- MSVC approach broke CI checks (reason under investigation)
- MinGW approach may still have build issues
- Need to verify Windows wheel builds successfully

The Windows wheel build configuration uses MinGW/GCC to avoid MSVC/MinGW header conflicts. Further investigation may be needed to ensure successful builds.
