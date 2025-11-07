# Cross-Platform Compilation

This document describes the cross-platform compilation support in benpy and the changes made to support Windows, macOS, and Linux.

## Overview

benpy now supports compilation on three major platforms:
- **Linux** (Ubuntu and other distributions)
- **macOS** (via Homebrew)
- **Windows** (via MSYS2/MinGW)

## Platform-Specific Changes

### Timing Implementation

The original bensolve C code used Unix-specific timing functions (`gettimeofday()` from `<sys/time.h>`). We've implemented platform-specific timing:

#### Unix/Linux/macOS
- Uses `gettimeofday()` from `<sys/time.h>`
- Provides microsecond precision
- Traditional POSIX timing mechanism

#### Windows
- Uses `QueryPerformanceCounter()` and `QueryPerformanceFrequency()` from `<windows.h>`
- Provides high-precision timing
- Native Windows API for performance measurements

Both implementations provide millisecond precision for bensolve's performance measurements.

### Header Files

The following changes were made to make headers platform-independent:

1. **Removed `<unistd.h>`**: This Unix-specific header was included but not actually used.
2. **Conditional `<sys/time.h>`**: Only included on Unix-like systems.
3. **Conditional `<windows.h>`**: Only included on Windows for timing functions.

Modified files:
- `src/bensolve-2.1.0/bslv_main.c`
- `src/bensolve-2.1.0/bslv_algs.c`
- `src/bensolve-2.1.0/bslv_lp.c`

### Library Linking

The math library linking in `setup.py` is now platform-specific:

- **Unix/Linux/macOS**: Links with `libglpk` and `libm` (math library)
- **Windows**: Links only with `libglpk` (math functions are built into the C runtime)

## Building on Different Platforms

### Linux (Ubuntu/Debian)

```bash
# Install dependencies
sudo apt update
sudo apt install -y glpk-utils libglpk-dev

# Set environment variables
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib"

# Build and install
pip install .
```

### macOS (Homebrew)

```bash
# Install dependencies
brew install glpk

# Set environment variables
export CFLAGS="-I$(brew --prefix)/include"
export LDFLAGS="-L$(brew --prefix)/lib"

# Build and install
pip install .
```

### Windows (MSYS2)

```bash
# Install MSYS2 from https://www.msys2.org/
# Open MSYS2 MINGW64 terminal

# Install dependencies
pacman -S mingw-w64-x86_64-glpk mingw-w64-x86_64-gcc

# Set environment variables
export CFLAGS="-I/mingw64/include"
export LDFLAGS="-L/mingw64/lib"
export PATH="/mingw64/bin:$PATH"

# Build and install
pip install .
```

## Continuous Integration

The GitHub Actions workflow (`.github/workflows/ci.yml`) tests all three platforms:

- **ubuntu-py312**: Tests on Ubuntu with Python 3.12
- **macos-py312**: Tests on macOS with Python 3.12  
- **windows-py312**: Tests on Windows with Python 3.12 using MSYS2/MinGW

All tests must pass on all platforms before code is merged.

## Technical Details

### Conditional Compilation

The code uses the `_WIN32` preprocessor macro to detect Windows:

```c
#ifdef _WIN32
    // Windows-specific code
    #include <windows.h>
    LARGE_INTEGER t_start, t_end, t_freq;
#else
    // Unix/macOS code
    #include <sys/time.h>
    struct timeval t_start, t_end;
#endif
```

### C99 Standard

All C code is compiled with the `-std=c99` flag, ensuring:
- Portable integer types (`int`, `size_t`, etc.)
- Standard library functions
- Compatible format specifiers (`%zd`, `%zu`)

### Format Specifiers

The code uses C99 format specifiers like `%zd` (for `size_t` with signed output) and `%zu` (for `size_t` unsigned), which are supported on all platforms with a C99-compliant compiler.

## Troubleshooting

### Windows: Missing GLPK headers
- Ensure MSYS2 MinGW64 terminal is used (not MSYS or UCRT)
- Verify GLPK is installed: `pacman -Q mingw-w64-x86_64-glpk`
- Check environment variables are set correctly

### macOS: Library not found
- Ensure Homebrew GLPK is installed: `brew list glpk`
- Use correct Homebrew prefix: `brew --prefix`
- On Apple Silicon, may need to specify architecture

### Linux: Compiler not found
- Install build essentials: `sudo apt install build-essential`
- Ensure GCC is available: `gcc --version`

## Future Considerations

If adding new platform-specific code:

1. Use `#ifdef _WIN32` for Windows-specific code
2. Use `#else` block for Unix/macOS code
3. Prefer portable C99 standard library functions
4. Test on all three platforms via CI
5. Document any platform differences

## References

- [MSYS2 Official Website](https://www.msys2.org/)
- [Homebrew Package Manager](https://brew.sh/)
- [GLPK - GNU Linear Programming Kit](https://www.gnu.org/software/glpk/)
- [C99 Standard](https://en.cppreference.com/w/c/language)
