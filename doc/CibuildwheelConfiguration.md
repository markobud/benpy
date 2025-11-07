# cibuildwheel Configuration Documentation

This document describes the cibuildwheel configuration for building distributable binary wheels for benpy across multiple platforms.

## Overview

benpy uses [cibuildwheel](https://cibuildwheel.readthedocs.io/) to build portable binary wheels for Linux, macOS, and Windows. The configuration is defined in `pyproject.toml` under the `[tool.cibuildwheel]` section.

## Configuration Summary

### Supported Platforms

- **Linux**: x86_64 and aarch64 (ARM64) using manylinux2014
- **macOS**: x86_64 (Intel), arm64 (Apple Silicon), and universal2 (both)
- **Windows**: AMD64 (x86_64) using MSYS2/MinGW toolchain

### Python Versions

Building wheels for **CPython 3.9, 3.10, 3.11, and 3.12**.

- Python 3.8 reached EOL in October 2024 and is not supported
- PyPy is not supported due to Cython extension requirements
- 32-bit builds are skipped

## Platform-Specific Details

### Linux Configuration

```toml
[tool.cibuildwheel.linux]
archs = ["x86_64", "aarch64"]
before-all = [
    "yum install -y glpk glpk-devel || apt-get update && apt-get install -y libglpk-dev glpk-utils",
]
repair-wheel-command = "auditwheel repair -w {dest_dir} {wheel}"
manylinux-x86_64-image = "manylinux2014"
manylinux-aarch64-image = "manylinux2014"
```

**Key Points:**
- Builds for both x86_64 and ARM64 architectures
- Uses manylinux2014 for maximum compatibility (supports glibc 2.17+)
- GLPK installation works on both RHEL-based (yum) and Debian-based (apt-get) systems
- `auditwheel` repairs wheels to vendor external dependencies

**Compatibility:**
- manylinux2014 is compatible with most Linux distributions from 2014 onwards
- Includes CentOS 7+, Ubuntu 14.04+, Debian 8+, Fedora 24+

### macOS Configuration

```toml
[tool.cibuildwheel.macos]
archs = ["x86_64", "arm64", "universal2"]
before-all = [
    "brew install glpk",
]
environment = { CFLAGS="-I$(brew --prefix)/include", LDFLAGS="-L$(brew --prefix)/lib" }
repair-wheel-command = "delocate-wheel --require-archs {delocate_archs} -w {dest_dir} -v {wheel}"
```

**Key Points:**
- Builds three types of wheels:
  - x86_64: For Intel Macs
  - arm64: For Apple Silicon Macs
  - universal2: Fat binaries that work on both architectures
- GLPK installed via Homebrew
- Environment variables set dynamically to support both Intel and ARM64 Homebrew paths
- `delocate-wheel` bundles external dylibs into the wheel

**Compatibility:**
- x86_64 wheels: macOS 10.9+
- arm64 wheels: macOS 11.0+ (Apple Silicon only)
- universal2 wheels: macOS 10.9+ with architecture-specific code

### Windows Configuration

```toml
[tool.cibuildwheel.windows]
archs = ["AMD64"]
before-all = [
    "C:\\msys64\\usr\\bin\\bash -lc 'pacman -S --noconfirm mingw-w64-x86_64-glpk mingw-w64-x86_64-gcc'",
]
environment = { CFLAGS="-IC:/msys64/mingw64/include", LDFLAGS="-LC:/msys64/mingw64/lib", PATH="C:\\msys64\\mingw64\\bin;$PATH" }
repair-wheel-command = "delvewheel repair -w {dest_dir} {wheel}"
```

**Key Points:**
- Uses MSYS2/MinGW toolchain for GCC compiler and GLPK
- Installs GLPK and GCC via pacman (MSYS2 package manager)
- Sets up PATH to include MinGW bin directory
- `delvewheel` bundles DLLs into the wheel for redistribution

**Compatibility:**
- Windows 7+ (64-bit only)
- Requires Visual C++ Redistributable (usually already present)

## Build Process

### 1. Before All

Platform-specific system dependencies (GLPK) are installed before any wheels are built:

- **Linux**: Installs `glpk` and `glpk-devel` packages
- **macOS**: Installs GLPK via Homebrew
- **Windows**: Installs GLPK and GCC via MSYS2

### 2. Before Build

Python build dependencies are installed for each wheel:

```bash
pip install Cython numpy setuptools wheel
```

These are required to compile the Cython extension module.

### 3. Build

cibuildwheel builds the wheel using the standard Python packaging tools:
1. Cython compiles `src/benpy.pyx` to C
2. setuptools compiles C sources (benpy + bensolve)
3. Links against GLPK and math libraries
4. Creates wheel file

### 4. Repair

Platform-specific tools ensure wheels are portable:

- **Linux**: `auditwheel` vendors shared libraries and sets RPATH
- **macOS**: `delocate-wheel` vendors dylibs and fixes install names
- **Windows**: `delvewheel` vendors DLLs into the wheel

### 5. Test

Each wheel is tested after building:

```bash
pytest {project}/tests/test_import.py -v
```

This runs basic import tests to ensure the wheel works correctly.

## Wheel Naming Convention

Wheels follow the PEP 427 naming convention:

```
{distribution}-{version}(-{build tag})?-{python tag}-{abi tag}-{platform tag}.whl
```

Examples:
- `benpy-1.0.3-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl`
- `benpy-1.0.3-cp311-cp311-macosx_10_9_universal2.whl`
- `benpy-1.0.3-cp310-cp310-win_amd64.whl`

## GitHub Actions Workflow

The `.github/workflows/build-wheels.yml` workflow orchestrates the build process:

### Jobs

1. **build_wheels**: Builds wheels on multiple OS runners
   - Matrix: Ubuntu, macOS (Intel), macOS (ARM), Windows
   - Uses QEMU for Linux ARM builds
   - Uploads wheels as artifacts

2. **build_sdist**: Builds source distribution
   - Runs on Ubuntu
   - Uploads sdist as artifact

3. **verify_wheels**: Tests wheels on clean environments
   - Matrix: All OS × Python 3.9-3.12
   - Downloads wheels from previous job
   - Installs GLPK system dependency
   - Installs and tests wheel

### Triggers

- Push to `main` or `development` branches
- Pull requests to `main` or `development`
- Manual workflow dispatch
- Git tags starting with `v*`

## PyPI Publishing

The `.github/workflows/publish.yml` workflow handles publishing to PyPI:

### Features

- **Manual confirmation**: Requires typing "publish" for manual triggers
- **TestPyPI support**: Optionally publishes to TestPyPI first
- **Trusted publishing**: Uses GitHub OIDC (no API token needed)
- **Verification**: Tests installation from PyPI after publishing

### Setup Required

Before using the publish workflow:

1. Configure PyPI trusted publishing:
   - Go to https://pypi.org/manage/account/publishing/
   - Add GitHub repository as trusted publisher
   - Specify workflow: `publish.yml`
   - Specify environment: `pypi`

2. Create GitHub environments:
   - Create `testpypi` environment (optional)
   - Create `pypi` environment with protection rules

3. Test the workflow:
   - Use manual dispatch with "publish" confirmation
   - Verify on TestPyPI first
   - Then proceed to PyPI

## Local Testing

You can test the wheel building process locally:

### Install cibuildwheel

```bash
pip install cibuildwheel
```

### Build for current platform

```bash
cibuildwheel --platform linux  # or macos, windows
```

### Build specific Python version

```bash
cibuildwheel --platform linux --only cp312-*
```

### Test with limited architectures

```bash
# Linux: Build only x86_64
CIBW_ARCHS_LINUX=x86_64 cibuildwheel --platform linux

# macOS: Build only x86_64
CIBW_ARCHS_MACOS=x86_64 cibuildwheel --platform macos
```

## Troubleshooting

### GLPK Not Found During Build

**Symptoms**: Build fails with linker errors about `-lglpk`

**Solutions**:
- Verify GLPK installation succeeded in `before-all` step
- Check that CFLAGS and LDFLAGS point to correct locations
- For local builds, ensure GLPK is installed system-wide

### Wheel Repair Failures

**Linux**: `auditwheel repair` fails
- Check that manylinux image has necessary tools
- Verify wheel is compatible with manylinux2014
- Check for blacklisted libraries

**macOS**: `delocate-wheel` fails
- Verify Homebrew GLPK is installed correctly
- Check that dylibs are not system libraries
- For universal2, ensure both architectures link correctly

**Windows**: `delvewheel repair` fails
- Verify MSYS2 DLLs are in PATH
- Check that DLLs are from MinGW, not MSYS2
- Ensure all dependent DLLs are available

### Test Failures After Wheel Install

**Symptoms**: `pytest` fails when testing built wheel

**Solutions**:
- Check that GLPK is installed on test system (runtime dependency)
- Verify wheel includes all necessary compiled libraries
- Check Python version compatibility
- Review test output for specific errors

### ARM64 Build Issues

**Linux ARM64**: 
- Requires QEMU for cross-compilation
- May be slower due to emulation
- Some packages may not be available in manylinux ARM image

**macOS ARM64**:
- Requires macOS 11+ runner
- Use `macos-14` runner for native ARM builds
- Use `macos-13` runner for Intel builds

## Performance Considerations

### Build Times

Typical build times per platform:
- **Linux x86_64**: 5-10 minutes per Python version
- **Linux ARM64**: 15-30 minutes per Python version (QEMU emulation)
- **macOS x86_64**: 5-10 minutes per Python version
- **macOS ARM64**: 5-10 minutes per Python version
- **macOS universal2**: 10-15 minutes per Python version
- **Windows**: 10-15 minutes per Python version

### Optimization Strategies

1. **Skip unused architectures**: Remove ARM64 if not needed
2. **Reduce Python versions**: Focus on 3.11+ for faster iteration
3. **Use workflow caching**: Cache pip dependencies
4. **Parallel builds**: GitHub Actions runs matrix jobs in parallel
5. **Skip tests**: Use `CIBW_TEST_SKIP` for faster builds (not recommended for releases)

## Security Considerations

### Dependency Vendoring

Wheels vendor external dependencies (GLPK) for portability:
- **Benefit**: Users don't need to install GLPK separately
- **Risk**: Vendored libraries may have security vulnerabilities
- **Mitigation**: Regularly update GLPK and rebuild wheels

### Supply Chain Security

- Wheels are built in GitHub-hosted runners (trusted environment)
- Build logs are public and auditable
- Trusted publishing eliminates need for API tokens
- Source code is tagged and immutable

## Maintenance

### Updating GLPK Version

To update the GLPK version used in wheels:

1. Update `before-all` commands in `pyproject.toml`
2. For Linux: Update package names if needed
3. For macOS: Homebrew installs latest by default
4. For Windows: Update pacman package specification
5. Rebuild and test all platforms

### Adding New Python Versions

When a new Python version is released:

1. Update `build` pattern in `pyproject.toml`:
   ```toml
   build = "cp39-* cp310-* cp311-* cp312-* cp313-*"
   ```

2. Test with pre-release versions using:
   ```toml
   build = "cp313-*"
   ```

3. Update CI matrix in workflows

### Deprecating Old Python Versions

When a Python version reaches EOL:

1. Remove from `build` pattern
2. Update documentation
3. Add to `skip` pattern if needed for clarity
4. Announce in release notes

## References

- [cibuildwheel documentation](https://cibuildwheel.readthedocs.io/)
- [PEP 427: The Wheel Binary Package Format](https://www.python.org/dev/peps/pep-0427/)
- [manylinux specification](https://github.com/pypa/manylinux)
- [auditwheel documentation](https://github.com/pypa/auditwheel)
- [delocate documentation](https://github.com/matthew-brett/delocate)
- [delvewheel documentation](https://github.com/adang1345/delvewheel)
- [PyPA: Trusted Publishers](https://docs.pypi.org/trusted-publishers/)
