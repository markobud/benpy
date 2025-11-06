# CI/CD Workflow Documentation

This document describes the GitHub Actions CI/CD pipeline for benpy.

## Overview

The CI/CD pipeline is defined in `.github/workflows/ci.yml` and consists of three main jobs:

1. **test** - Run tests on all supported platforms and Python versions
2. **build-wheels** - Build binary wheels using cibuildwheel
3. **build-sdist** - Build source distribution

## Test Job

The test job runs on a matrix of:
- **Operating Systems**: Ubuntu, macOS, Windows
- **Python Versions**: 3.8, 3.9, 3.10, 3.11, 3.12

### Steps:
1. Checkout code
2. Set up Python
3. Install GLPK (platform-specific)
4. Install Python dependencies
5. Build Cython extension
6. Run pytest test suite
7. Upload coverage reports (Ubuntu + Python 3.11 only)

### GLPK Installation

Each platform requires GLPK to be installed differently:

**Linux (Ubuntu):**
```bash
sudo apt-get install -y glpk-utils libglpk-dev
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib"
```

**macOS:**
```bash
brew install glpk
export CFLAGS="-I$(brew --prefix glpk)/include"
export LDFLAGS="-L$(brew --prefix glpk)/lib"
```

**Windows:**
- Uses MSYS2 with UCRT64 environment
- Installs mingw-w64-ucrt-x86_64-gcc and mingw-w64-ucrt-x86_64-glpk
- Sets appropriate CFLAGS and LDFLAGS

## Build Wheels Job

Uses `cibuildwheel` to build wheels for multiple platforms.

### Configuration:
- **Skip**: PyPy and musllinux builds
- **Build**: CPython 3.8-3.12 for all platforms
- **Before All**: Install GLPK on the target platform
- **Before Build**: Install Cython and numpy
- **Test**: Run basic import test on built wheel

### Platform-specific GLPK setup:
- **Linux**: Uses yum or apt-get
- **macOS**: Uses homebrew
- **Windows**: Uses chocolatey

### Notes:
Building wheels with external C dependencies like GLPK can be complex. The current configuration:
- Assumes GLPK can be installed in the cibuildwheel environment
- Tests only basic imports (not full test suite) to keep build times reasonable
- May require adjustments based on actual build results

## Build Source Distribution Job

Builds a source distribution (sdist) on Ubuntu with Python 3.11.

### Steps:
1. Checkout code
2. Set up Python
3. Install build dependencies
4. Build sdist using `python -m build --sdist`
5. Upload sdist as artifact

## Artifacts

All jobs upload artifacts to GitHub:
- **wheels-{os}**: Binary wheels for each OS (30-day retention)
- **sdist**: Source distribution (30-day retention)

## Triggers

The workflow runs on:
- **Push** to: main, development, copilot/** branches
- **Pull requests** to: main, development branches
- **Manual trigger**: via workflow_dispatch

## Status Badge

The README.md includes a status badge showing the current CI status:
```markdown
[![CI](https://github.com/markobud/benpy/actions/workflows/ci.yml/badge.svg)](https://github.com/markobud/benpy/actions/workflows/ci.yml)
```

## Coverage Reports

Coverage reports are uploaded to Codecov for the Ubuntu + Python 3.11 build. This requires the `CODECOV_TOKEN` secret to be set in the repository settings (optional, workflow continues if missing).

## Dependencies

The workflow installs the following Python packages:
- **Build dependencies**: wheel, setuptools, Cython, numpy
- **Runtime dependencies**: scipy, prettytable
- **Test dependencies**: pytest, pytest-cov

## Troubleshooting

### Windows Build Issues
Windows builds use MSYS2 and may encounter path issues. The workflow:
- Uses `bash` shell (not `msys2 {0}`) for Python steps
- Explicitly adds MSYS2 bin directory to PATH
- Sets `SETUPTOOLS_USE_DISTUTILS=stdlib` for compatibility

### GLPK Not Found
If builds fail with GLPK-related errors:
1. Check that CFLAGS and LDFLAGS are set correctly
2. Verify GLPK installation step succeeded
3. For cibuildwheel, check CIBW_BEFORE_ALL_* commands

### Test Failures
Tests run after building the extension. If tests fail:
1. Check that all dependencies are installed
2. Verify the extension built successfully
3. Review test logs for specific failure details

## Future Improvements

Potential enhancements:
1. Add automatic PyPI publishing on tagged releases
2. Build ARM64 wheels for macOS
3. Add performance benchmarks
4. Cache dependencies to speed up builds
5. Add documentation building and deployment
6. Run security scanning (e.g., bandit, safety)

## Related Documentation

- [pytest.ini](../pytest.ini) - Test configuration
- [tests/README.md](../tests/README.md) - Test suite documentation
- [Phase3_TestSuite_Summary.md](Phase3_TestSuite_Summary.md) - Test implementation details
