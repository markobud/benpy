# CI/CD Workflow Documentation

This document describes the GitHub Actions CI/CD pipeline for benpy.

## Overview

The CI/CD pipeline consists of three separate workflows:

1. **ci.yml** - Continuous integration (tests on all platforms)
2. **build-wheels.yml** - Build distributable binary wheels using cibuildwheel
3. **publish.yml** - Publish releases to PyPI (draft)

## CI Workflow (ci.yml)

The CI workflow runs tests on all supported platforms and Python versions to ensure code quality.

### Test Jobs

The CI workflow runs tests on a matrix of platforms and Python versions:
- **ubuntu-py312**: Ubuntu Latest with Python 3.12
- **macos-py312**: macOS Latest with Python 3.12  
- **windows-py312**: Windows Latest with Python 3.12
- **build-source**: Build source distribution

For complete test matrix details, see the workflow file.

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

## Build Wheels Workflow (build-wheels.yml)

The build-wheels workflow uses **cibuildwheel** to build portable binary wheels for distribution.

See [CibuildwheelConfiguration.md](CibuildwheelConfiguration.md) for comprehensive documentation.

### Key Features

- **Multi-platform builds**: Linux (x86_64, ARM64), macOS (Intel, Apple Silicon, Universal), Windows (x64)
- **Multiple Python versions**: CPython 3.9-3.12
- **Wheel repair**: Vendors dependencies for portability (manylinux, delocate, delvewheel)
- **Automated testing**: Tests each wheel after building
- **Artifact storage**: Uploads wheels and sdist to GitHub

### Jobs

1. **build_wheels**: Builds wheels on multiple OS runners
2. **build_sdist**: Builds source distribution
3. **verify_wheels**: Tests wheels in clean environments

### Configuration

All cibuildwheel configuration is in `pyproject.toml` under `[tool.cibuildwheel]`.

For details on:
- Platform-specific settings
- GLPK installation strategies
- Wheel repair processes
- Troubleshooting

See [CibuildwheelConfiguration.md](CibuildwheelConfiguration.md).

## Publish Workflow (publish.yml)

**Status**: DRAFT - Not yet production-ready

The publish workflow automates publishing releases to PyPI.

### Features

- Manual confirmation required
- TestPyPI support for testing
- Trusted publishing (no API tokens)
- Post-publish verification

### Setup Required

Before using this workflow:

1. Configure PyPI trusted publishing at https://pypi.org/manage/account/publishing/
2. Create GitHub environments: `testpypi` (optional) and `pypi`
3. Test with TestPyPI first

See the workflow file for detailed comments and setup instructions.

## Legacy Build Information

The following sections describe the legacy build configuration that was previously in ci.yml.

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
