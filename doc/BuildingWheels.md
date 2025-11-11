# Building and Publishing Wheels

This guide explains how to build and publish distributable wheels for benpy across Linux, macOS, and Windows platforms.

## Table of Contents

- [Prerequisites by Platform](#prerequisites-by-platform)
- [Quick Start](#quick-start)
- [Using the Development Container](#using-the-development-container)
- [GitHub Actions Workflows](#github-actions-workflows)
- [Configuration](#configuration)
- [Build Matrix](#build-matrix)
- [Release Process](#release-process)
- [Troubleshooting](#troubleshooting)
- [Advanced Usage](#advanced-usage)

## Prerequisites by Platform

### Linux (manylinux)

**System Requirements:**
- Docker installed and running
- `cibuildwheel` will use manylinux2014 images (CentOS 7 based)

**For Native Linux Builds:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    gcc \
    g++ \
    python3-dev \
    libglpk-dev \
    libglpk40 \
    glpk-utils

# RHEL/CentOS/Fedora
sudo yum install -y \
    gcc \
    gcc-c++ \
    python3-devel \
    glpk \
    glpk-devel

# Set environment variables
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib/x86_64-linux-gnu"  # or /usr/lib64 on RHEL
```

**Recommended Versions:**
- GCC: 7.3+ (manylinux2014 provides GCC 10)
- GLPK: 4.48+ (usually 4.65+ in modern repos)
- Python: 3.10, 3.11, 3.12 (3.9 has NumPy compatibility issues)

**Docker Images:**
- x86_64: `quay.io/pypa/manylinux2014_x86_64`
- ARM64: `quay.io/pypa/manylinux2014_aarch64`

### macOS (Homebrew)

**System Requirements:**
- Xcode Command Line Tools: `xcode-select --install`
- Homebrew package manager

**Installing Prerequisites:**
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install GLPK
brew install glpk

# For Intel Macs (x86_64)
brew install glpk  # Installs x86_64 version

# For Apple Silicon (ARM64)
brew install glpk  # Installs ARM64 version

# Verify GLPK installation
pkg-config --modversion glpk
glpsol --version

# Set environment variables (typically not needed with Homebrew)
export CFLAGS="-I$(brew --prefix)/include"
export LDFLAGS="-L$(brew --prefix)/lib"
```

**Recommended Versions:**
- Xcode CLT: 14.0+ (for macOS 13), 15.0+ (for macOS 14)
- GLPK: 5.0+ (Homebrew provides latest)
- Python: 3.10, 3.11, 3.12

**Architecture Handling:**
- **Intel Macs (x86_64)**: Use `macos-13` GitHub Actions runner
- **Apple Silicon (ARM64)**: Use `macos-14` GitHub Actions runner
- benpy builds architecture-specific wheels (not Universal2) to avoid cross-compilation issues

**Important Notes:**
- On Apple Silicon, Homebrew installs to `/opt/homebrew`
- On Intel, Homebrew installs to `/usr/local`
- `brew --prefix` automatically returns the correct path

### Windows (MSYS2/MinGW)

**System Requirements:**
- Windows 10 or later (64-bit)
- MSYS2 with MinGW-w64 toolchain

**Installing MSYS2 and Prerequisites:**

1. **Download and Install MSYS2:**
   - Download from [https://www.msys2.org/](https://www.msys2.org/)
   - Run the installer (e.g., `msys2-x86_64-20231026.exe`)
   - Install to default location: `C:\msys64`

2. **Update MSYS2:**
   ```bash
   # Open MSYS2 MINGW64 terminal
   pacman -Syu
   # Close terminal when prompted, reopen and run again
   pacman -Syu
   ```

3. **Install Build Tools:**
   ```bash
   # Install GCC, GLPK, and build tools
   pacman -S --noconfirm \
       mingw-w64-x86_64-gcc \
       mingw-w64-x86_64-glpk \
       mingw-w64-x86_64-python \
       mingw-w64-x86_64-python-pip \
       mingw-w64-x86_64-cython
   ```

4. **Set Environment Variables:**
   ```bash
   # In MSYS2 MINGW64 terminal
   export PATH="/mingw64/bin:$PATH"
   export CFLAGS="-I/mingw64/include"
   export LDFLAGS="-L/mingw64/lib"
   
   # For Windows Command Prompt/PowerShell
   set PATH=C:\msys64\mingw64\bin;%PATH%
   set CFLAGS=-IC:/msys64/mingw64/include
   set LDFLAGS=-LC:/msys64/mingw64/lib
   ```

**Alternative: Using MSYS2 from cibuildwheel (Recommended for CI):**
- GitHub Actions Windows runners have MSYS2 pre-installed at `C:\msys64`
- cibuildwheel automatically configures the environment

**Recommended Versions:**
- MinGW-w64 GCC: 12.0+
- GLPK: 5.0+ (via MSYS2 repos)
- Python: 3.10, 3.11, 3.12

**Important Notes:**
- Use MinGW-w64 (not MSVC) for compatibility with GLPK
- Ensure `gcc` (not `cl.exe`) is first in PATH
- DLLs must be bundled with wheels using `delvewheel`

### Python and Compiler Versions

**Supported Python Versions:**
- **Python 3.10** (recommended minimum)
- **Python 3.11**
- **Python 3.12** (recommended for new projects)
- Python 3.9 has NumPy compatibility issues and is not supported

**Build Dependencies:**
- `setuptools` (latest)
- `wheel` (latest)
- `Cython` 3.0.0+
- `numpy` (version compatible with Python version)

**Compiler Requirements:**
- **Linux**: GCC 7.3+ or Clang 8+
- **macOS**: Apple Clang 14+ (from Xcode CLT)
- **Windows**: MinGW-w64 GCC 10+

## Quick Start

### Building Wheels Locally

**Install cibuildwheel:**
```bash
pip install cibuildwheel
```

**Basic Commands:**
```bash
# Build for current platform
cibuildwheel --platform auto

# Build for specific platform
cibuildwheel --platform linux   # or macos, windows

# Build specific Python version only
cibuildwheel --only cp312-*

# Build specific architecture
CIBW_ARCHS_LINUX=x86_64 cibuildwheel --platform linux

# Output to custom directory
cibuildwheel --output-dir dist

# Preview what would be built
cibuildwheel --print-build-identifiers --platform linux
```

**Output Location:**
- Wheels are saved to `wheelhouse/` directory by default
- Use `--output-dir` to specify a different location

**Example: Build for Current Platform and Python:**
```bash
# Install cibuildwheel
pip install cibuildwheel

# Build for Python 3.12 on current platform
cibuildwheel --only cp312-* --platform auto

# Test the built wheel
pip install wheelhouse/*.whl
python -c "import benpy; print(benpy.__version__)"
```

## Using the Development Container

The repository includes a development container for reproducible builds.

**Prerequisites:**
- Docker Desktop or Docker Engine
- Visual Studio Code with Dev Containers extension

**Using the Devcontainer:**

1. **Open in VS Code:**
   ```bash
   # Clone the repository
   git clone https://github.com/markobud/benpy.git
   cd benpy
   
   # Open in VS Code
   code .
   ```

2. **Reopen in Container:**
   - Press `F1` or `Ctrl+Shift+P`
   - Select "Dev Containers: Reopen in Container"
   - Wait for container to build (first time only)

3. **Build Inside Container:**
   ```bash
   # The devcontainer has GLPK pre-installed
   
   # Build and install benpy
   pip install -e .
   
   # Run tests
   pytest tests/
   
   # Build wheels (for Linux)
   pip install cibuildwheel
   cibuildwheel --platform linux
   ```

**Devcontainer Features:**
- Based on Python 3.12 Debian Bullseye image
- Pre-installed: GLPK, build tools, Python dependencies
- VS Code extensions: Cython, C++, Docker support
- Automatic dependency installation via `postCreateCommand`

**Configuration Files:**
- `.devcontainer/devcontainer.json` - Container configuration
- `.devcontainer/Dockerfile` - Base image with GLPK

**Benefits:**
- Consistent build environment across developers
- No need to install GLPK on host system
- Matches manylinux environment for Linux builds


## GitHub Actions Workflows

benpy uses three GitHub Actions workflows for building, testing, and publishing wheels.

### CI Workflow (ci.yml)

**Purpose:** Fast continuous integration testing on every push and PR.

**Features:**
- Runs on Ubuntu, macOS, Windows with Python 3.12
- Builds source distribution (sdist)
- Runs test suite
- **Does NOT build wheels** (use build-wheels.yml for that)

**Triggers:**
- Every push to `main` or `development` branches
- Every pull request

**View Results:**
```bash
# Using GitHub CLI
gh run list --workflow=ci.yml
gh run view <run-id>
```

**Configuration:**
```yaml
# .github/workflows/ci.yml (excerpt)
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    python-version: ['3.12']
```

### Build Wheels Workflow (build-wheels.yml)

**Purpose:** Build distributable wheels for all supported platforms and Python versions.

**What Gets Built:**
- **Linux**: x86_64 and ARM64 (manylinux2014)
  - Python 3.10, 3.11, 3.12
  - Built in Docker on `ubuntu-latest`
  
- **macOS**: x86_64 and ARM64 (architecture-specific)
  - Python 3.10, 3.11, 3.12
  - x86_64: Built on `macos-13` (Intel runner)
  - ARM64: Built on `macos-14` (Apple Silicon runner)
  
- **Windows**: AMD64/x64
  - Python 3.10, 3.11, 3.12
  - Built on `windows-latest` using MinGW-w64

**Total Output:** 20 wheels + 1 source distribution

**Triggers:**
- Push to `main` or `development` branches
- Pull requests (for testing)
- Git tags starting with `v*` (for releases)
- Manual dispatch via GitHub UI or CLI

**Manual Trigger:**
```bash
# Via GitHub CLI
gh workflow run build-wheels.yml

# Via GitHub web interface:
# 1. Go to Actions tab
# 2. Select "Build Wheels" workflow
# 3. Click "Run workflow"
# 4. Select branch and click "Run workflow"
```

**Configuration Example:**
```yaml
# .github/workflows/build-wheels.yml (simplified)
jobs:
  build_wheels:
    name: Build wheels on ${{ matrix.os }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          # Linux builds (both architectures)
          - os: ubuntu-latest
            cibw_archs: "x86_64 aarch64"
          
          # macOS Intel builds
          - os: macos-13
            cibw_archs: "x86_64"
            macos_target: "13.0"
          
          # macOS Apple Silicon builds
          - os: macos-14
            cibw_archs: "arm64"
            macos_target: "14.0"
          
          # Windows builds
          - os: windows-latest
            cibw_archs: "AMD64"
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up QEMU (Linux ARM only)
        if: runner.os == 'Linux'
        uses: docker/setup-qemu-action@v3
        with:
          platforms: arm64
      
      - name: Build wheels
        uses: pypa/cibuildwheel@v2.21.3
        env:
          CIBW_BUILD_VERBOSITY: 1
          CIBW_ARCHS: ${{ matrix.cibw_archs }}
          MACOSX_DEPLOYMENT_TARGET: ${{ matrix.macos_target || '13.0' }}
      
      - name: Upload wheels
        uses: actions/upload-artifact@v4
        with:
          name: wheels-${{ matrix.os }}
          path: ./wheelhouse/*.whl
          retention-days: 30
```

**Downloading Built Wheels:**
```bash
# List recent workflow runs
gh run list --workflow=build-wheels.yml --limit 5

# Download artifacts from a specific run
gh run download <run-id>

# Or download specific artifact
gh run download <run-id> -n wheels-ubuntu-latest
```

**Artifacts:**
- Wheels uploaded as GitHub Actions artifacts
- Retention: 30 days
- Accessible via GitHub UI or CLI

### Publish Workflow (publish.yml) - DRAFT

**Purpose:** Publish wheels to PyPI or TestPyPI.

**Status:** This is a **draft workflow** requiring setup before use.

**Setup Requirements:**

1. **Configure PyPI Trusted Publishing:**
   - Go to PyPI → Account Settings → Publishing
   - Add GitHub publisher:
     - Owner: `markobud`
     - Repository: `benpy`
     - Workflow: `publish.yml`
     - Environment: `pypi` (or `testpypi` for testing)

2. **Create GitHub Environments:**
   ```
   Repository Settings → Environments
   - Create "testpypi" environment
   - Create "pypi" environment
   - Optional: Add protection rules (required reviewers)
   ```

3. **Test with TestPyPI First:**
   ```bash
   # Trigger publish to TestPyPI
   gh workflow run publish.yml -f confirm=publish -f environment=testpypi
   ```

**Triggers:**
- GitHub releases (automatic)
- Manual dispatch with confirmation

**Manual Trigger:**
```bash
# Via GitHub CLI (with confirmation)
gh workflow run publish.yml -f confirm=publish

# Via GitHub web interface:
# 1. Go to Actions tab
# 2. Select "Publish to PyPI" workflow
# 3. Click "Run workflow"
# 4. Type "publish" in the confirmation field
# 5. Click "Run workflow"
```

**Safety Features:**
- Requires typing "publish" to confirm
- Uses trusted publishing (no API tokens needed)
- Separate environments for TestPyPI and production

### Example: Complete CI/CD Pipeline

Here's how to set up a complete pipeline from development to release:

**1. Development and Testing:**
```bash
# Create feature branch
git checkout -b feature/my-feature

# Make changes, commit
git commit -am "Add feature"

# Push - triggers ci.yml automatically
git push origin feature/my-feature

# Create PR - triggers both ci.yml and build-wheels.yml
gh pr create --title "Add feature" --body "Description"
```

**2. Pre-Release Testing:**
```bash
# After PR is merged, manually trigger wheel build
gh workflow run build-wheels.yml

# Download and test wheels locally
gh run download <run-id>
pip install wheels-*/benpy-*.whl
python -c "import benpy; print(benpy.__version__)"
```

**3. Release:**
```bash
# Update version in pyproject.toml
# Update CHANGELOG.md
git commit -am "Bump version to 2.2.0"
git push

# Create and push tag (triggers build-wheels.yml)
git tag v2.2.0
git push origin v2.2.0

# Create GitHub release (triggers publish.yml if configured)
gh release create v2.2.0 \
  --title "Version 2.2.0" \
  --notes "Release notes here"
```

**4. Verify Publication:**
```bash
# Wait a few minutes for PyPI to update
pip install --upgrade benpy
python -c "import benpy; print(benpy.__version__)"
```

### Custom Workflow Examples

**Build Only for Python 3.12:**
```yaml
# .github/workflows/build-py312-only.yml
name: Build Python 3.12 Wheels

on:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pypa/cibuildwheel@v2.21.3
        env:
          CIBW_BUILD: "cp312-*"
          CIBW_ARCHS_LINUX: "x86_64"
      - uses: actions/upload-artifact@v4
        with:
          name: wheels
          path: ./wheelhouse/*.whl
```

**Build with Increased Verbosity:**
```yaml
# For debugging build issues
- name: Build wheels (verbose)
  uses: pypa/cibuildwheel@v2.21.3
  env:
    CIBW_BUILD_VERBOSITY: 3
    CIBW_ARCHS: ${{ matrix.cibw_archs }}
```

**Build Only Linux x86_64:**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pypa/cibuildwheel@v2.21.3
        env:
          CIBW_ARCHS_LINUX: "x86_64"  # Skip ARM
          CIBW_BUILD: "cp310-* cp311-* cp312-*"
```


## Configuration

All cibuildwheel settings are defined in `pyproject.toml` under the `[tool.cibuildwheel]` section.

### Main Configuration

```toml
[tool.cibuildwheel]
# Python versions to build for
build = "cp310-* cp311-* cp312-*"

# Skip PyPy, musllinux, and 32-bit builds
skip = "pp* *-musllinux* *-win32 *-manylinux_i686"

# Install build dependencies
before-build = "pip install Cython numpy setuptools wheel"

# Test requirements and command
test-requires = ["pytest", "numpy", "scipy", "prettytable"]
test-command = "python -c \"import benpy; print(benpy.__version__)\""
```

### Platform-Specific Configuration

#### Linux Configuration

```toml
[tool.cibuildwheel.linux]
# Install GLPK before building
before-all = [
    "bash -c 'if command -v yum >/dev/null 2>&1; then yum install -y epel-release || true; yum install -y glpk glpk-devel; elif command -v apt-get >/dev/null 2>&1; then apt-get update; apt-get install -y libglpk-dev glpk-utils; fi'",
]

# Repair wheels to include dependencies
repair-wheel-command = "auditwheel repair -w {dest_dir} {wheel}"

# Use manylinux2014 for glibc 2.17+ compatibility
manylinux-x86_64-image = "manylinux2014"
manylinux-aarch64-image = "manylinux2014"
```

**What This Does:**
- Installs GLPK using the available package manager (yum or apt-get)
- Uses manylinux2014 base image (CentOS 7)
- Bundles GLPK shared library into wheel with auditwheel
- Supports x86_64 and ARM64 architectures

**Available manylinux Images:**
- `manylinux2014`: glibc 2.17+ (CentOS 7) - **Currently used**
- `manylinux_2_28`: glibc 2.28+ (AlmaLinux 8)
- `manylinux_2_24`: glibc 2.24+ (Debian 9)

#### macOS Configuration

```toml
[tool.cibuildwheel.macos]
# Install GLPK via Homebrew
before-all = [
    "brew install glpk",
    "pip install delocate",
]

# Bundle GLPK dylibs into wheel
repair-wheel-command = "delocate-wheel --require-archs {delocate_archs} -w {dest_dir} -v {wheel}"
```

**What This Does:**
- Installs GLPK for the runner's architecture (x86_64 on macos-13, arm64 on macos-14)
- Uses delocate to copy GLPK dylibs into wheel's `.dylibs` directory
- Sets up proper `@loader_path` references

**Deployment Targets:**
- Set via `MACOSX_DEPLOYMENT_TARGET` environment variable in workflow
- x86_64: 13.0 (macOS Ventura)
- ARM64: 14.0 (macOS Sonoma)

**Note:** benpy uses architecture-specific runners instead of Universal2 wheels to avoid cross-compilation issues with GLPK.

#### Windows Configuration

```toml
[tool.cibuildwheel.windows]
# Install GLPK and GCC from MSYS2
before-all = [
    "C:\\msys64\\usr\\bin\\bash -lc 'pacman -S --noconfirm mingw-w64-x86_64-glpk mingw-w64-x86_64-gcc'",
    "pip install delvewheel",
]

# Configure compiler and paths
before-build = [
    "pip install Cython numpy setuptools wheel",
    "python -c \"import os; content='[build]\\ncompiler=mingw32\\n\\n[build_ext]\\ncompiler=mingw32\\n'; os.makedirs(os.path.expanduser('~'), exist_ok=True); open(os.path.join(os.path.expanduser('~'), 'pydistutils.cfg'), 'w').write(content)\"",
]

# Set MinGW environment
environment = { 
    CC="gcc", 
    CXX="g++", 
    CFLAGS="-IC:/msys64/mingw64/include", 
    LDFLAGS="-LC:/msys64/mingw64/lib", 
    PATH="C:\\msys64\\mingw64\\bin;$PATH" 
}

# Bundle DLLs with delvewheel
repair-wheel-command = "delvewheel repair --add-path C:\\msys64\\mingw64\\bin -w {dest_dir} {wheel}"
```

**What This Does:**
- Installs GLPK from MSYS2 repositories (MinGW-w64 build)
- Forces use of MinGW GCC instead of MSVC
- Creates pydistutils.cfg to specify MinGW compiler
- Bundles libglpk-40.dll and dependencies into wheel

**Why MinGW Instead of MSVC:**
- GLPK is available pre-built for MinGW
- Cython code uses C99 features better supported by GCC
- Simpler dependency management

### Modifying Configuration

#### Adding Python Versions

To add Python 3.13 support:
```toml
[tool.cibuildwheel]
build = "cp310-* cp311-* cp312-* cp313-*"
```

Or to build only for Python 3.12:
```toml
[tool.cibuildwheel]
build = "cp312-*"
```

#### Changing Architectures

**Linux - Add/remove architectures:**
```bash
# In workflow or command line
CIBW_ARCHS_LINUX="x86_64"              # x86_64 only
CIBW_ARCHS_LINUX="x86_64 aarch64"      # Both (current)
CIBW_ARCHS_LINUX="aarch64"             # ARM64 only
```

**macOS - Change deployment target:**
```yaml
# In workflow
env:
  MACOSX_DEPLOYMENT_TARGET: "12.0"  # Support older macOS versions
```

**Windows - 32-bit builds (not recommended):**
```toml
[tool.cibuildwheel]
skip = "pp* *-musllinux*"  # Remove *-win32 to enable 32-bit
```

#### Skipping Specific Builds

```toml
[tool.cibuildwheel]
# Skip specific Python/platform combinations
skip = [
    "pp*",                    # Skip PyPy
    "*-musllinux*",           # Skip musllinux
    "cp310-manylinux_aarch64" # Skip Python 3.10 on ARM
]
```

#### Custom Test Commands

```toml
[tool.cibuildwheel]
test-requires = ["pytest", "numpy"]
test-command = [
    "python -c 'import benpy'",
    "pytest {project}/tests/test_import.py"
]
```

Or skip tests entirely:
```toml
[tool.cibuildwheel]
test-skip = "*"  # Skip all tests
# Or skip specific platforms
test-skip = "*-macosx_arm64"  # Skip tests on Apple Silicon
```

#### Increasing Build Verbosity

For debugging build issues:
```bash
# Command line
CIBW_BUILD_VERBOSITY=3 cibuildwheel --platform linux

# Or in pyproject.toml
[tool.cibuildwheel]
build-verbosity = 3  # 0=quiet, 1=normal, 2=verbose, 3=very verbose
```

### Testing Configuration Changes

Before pushing configuration changes:

```bash
# Check what would be built
cibuildwheel --print-build-identifiers --platform linux

# Example output:
# cp310-manylinux_x86_64
# cp310-manylinux_aarch64
# cp311-manylinux_x86_64
# cp311-manylinux_aarch64
# cp312-manylinux_x86_64
# cp312-manylinux_aarch64

# Build one wheel for testing
cibuildwheel --only cp312-manylinux_x86_64

# Verify the wheel
pip install wheelhouse/*.whl
python -c "import benpy; print(benpy.__version__)"
```

### Environment Variable Overrides

Environment variables override `pyproject.toml` settings:

```bash
# Override Python versions
export CIBW_BUILD="cp311-* cp312-*"

# Override architectures  
export CIBW_ARCHS_LINUX="x86_64"
export CIBW_ARCHS_MACOS="arm64"

# Override manylinux image
export CIBW_MANYLINUX_X86_64_IMAGE="manylinux_2_28"

# Skip tests
export CIBW_TEST_SKIP="*"

# Run cibuildwheel
cibuildwheel --platform linux
```

### Configuration Precedence

Settings are applied in this order (later overrides earlier):

1. **pyproject.toml** - Base configuration
2. **Environment variables** - `CIBW_*` variables
3. **Command-line options** - `--platform`, `--only`, etc.

### Example: Custom Build Script

Create a script for consistent local builds:

```bash
#!/bin/bash
# build-custom.sh - Custom build configuration

# Set your preferences
export CIBW_BUILD="cp312-*"
export CIBW_ARCHS_LINUX="x86_64"
export CIBW_BUILD_VERBOSITY=1
export CIBW_OUTPUT_DIR="dist"

# Build
echo "Building wheels..."
cibuildwheel --platform auto

# Verify
echo "Built wheels:"
ls -lh dist/

# Check wheel contents
echo "Checking wheels..."
for wheel in dist/*.whl; do
    echo "Checking $wheel"
    unzip -l "$wheel" | grep -E '(benpy|glpk|\.so|\.pyd|\.dylib|\.dll)'
done
```

Make it executable and run:
```bash
chmod +x build-custom.sh
./build-custom.sh
```

## Build Matrix

Current build configuration produces **15 wheel variants** (Python 3.10, 3.11, 3.12 only):

| Platform | Architecture | Py 3.10 | Py 3.11 | Py 3.12 | Runner | Base Image |
|----------|--------------|---------|---------|---------|--------|------------|
| Linux    | x86_64       | ✓       | ✓       | ✓       | ubuntu-latest | manylinux2014 |
| Linux    | ARM64/aarch64| ✓       | ✓       | ✓       | ubuntu-latest | manylinux2014 |
| macOS    | x86_64 (Intel)| ✓      | ✓       | ✓       | macos-13 | macOS 13.0+ |
| macOS    | ARM64 (Apple Silicon)| ✓ | ✓    | ✓       | macos-14 | macOS 14.0+ |
| Windows  | AMD64 (x64)  | ✓       | ✓       | ✓       | windows-latest | MinGW-w64 |

**Total Build Outputs:**
- 15 binary wheels (.whl files)
- 1 source distribution (.tar.gz file)

### Wheel Naming Convention

Wheels follow Python's standard naming convention:
```
{distribution}-{version}(-{build tag})?-{python tag}-{abi tag}-{platform tag}.whl
```

**Examples:**
```
benpy-2.1.0-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl
benpy-2.1.0-cp311-cp311-macosx_13_0_x86_64.whl
benpy-2.1.0-cp310-cp310-win_amd64.whl
```

**Tag Breakdown:**
- `cp312`: CPython 3.12
- `cp312`: ABI tag (CPython 3.12 stable ABI)
- `manylinux_2_17_x86_64`: Compatible with glibc 2.17+ on x86_64
- `macosx_13_0_x86_64`: macOS 13.0+ on Intel
- `win_amd64`: Windows 64-bit

### Platform Compatibility

**Linux (manylinux2014):**
- glibc 2.17+ (released 2012)
- Compatible with:
  - Ubuntu 14.04+, 16.04, 18.04, 20.04, 22.04, 24.04
  - Debian 8+, 9, 10, 11, 12
  - RHEL/CentOS 7+, 8, 9
  - Fedora 24+
  - Amazon Linux 2+
  - Alpine Linux (with glibc, not musl)

**macOS:**
- x86_64: macOS 13.0+ (Ventura and later)
- ARM64: macOS 14.0+ (Sonoma and later, Apple Silicon only)
- Note: Older macOS versions may work but are not guaranteed

**Windows:**
- Windows 10, 11 (64-bit)
- Windows Server 2016+
- Requires Visual C++ Redistributable (usually pre-installed)

### Architecture-Specific Build Strategy

**macOS Note:** benpy uses **architecture-specific runners** instead of Universal2 wheels:

**Why Not Universal2?**
- Universal2 wheels contain both x86_64 and ARM64 code in a single file
- Requires cross-compilation or fat binaries for all dependencies
- GLPK would need to be built as Universal2, which is complex
- Cross-compilation of GLPK can lead to runtime issues

**Our Approach:**
- Use `macos-13` (Intel runner) to build x86_64 wheels with x86_64 GLPK
- Use `macos-14` (Apple Silicon runner) to build ARM64 wheels with ARM64 GLPK
- pip automatically selects the correct wheel for the user's architecture
- More reliable and simpler build process

**Trade-off:**
- Advantage: Native builds, no cross-compilation issues, simpler CI
- Disadvantage: Two separate wheels instead of one Universal2 wheel

### Build Time Estimates

Approximate build times per platform (GitHub Actions runners):

| Platform | Architecture | Build Time | Notes |
|----------|--------------|------------|-------|
| Linux    | x86_64       | 3-5 min    | Native build |
| Linux    | ARM64        | 15-25 min  | QEMU emulation (slow) |
| macOS    | x86_64       | 5-8 min    | Native on macos-13 |
| macOS    | ARM64        | 5-8 min    | Native on macos-14 |
| Windows  | AMD64        | 8-12 min   | MinGW setup overhead |

**Total CI Time:** 30-45 minutes for all platforms in parallel

**Tips to Speed Up:**
- Skip ARM64 Linux locally: `CIBW_ARCHS_LINUX=x86_64`
- Build only one Python version: `--only cp312-*`
- Use devcontainer for reproducible local builds

### Verifying Built Wheels

After building, verify wheel contents:

```bash
# List wheel files
ls -lh wheelhouse/

# Check wheel metadata
unzip -l wheelhouse/benpy-*.whl | head -20

# Verify platform tags
unzip -l wheelhouse/benpy-*.whl | grep WHEEL

# Check bundled libraries
# Linux: should contain libglpk in .libs/
unzip -l wheelhouse/benpy-*-linux*.whl | grep libglpk

# macOS: should contain libglpk in .dylibs/
unzip -l wheelhouse/benpy-*-macosx*.whl | grep libglpk

# Windows: should contain libglpk DLL
unzip -l wheelhouse/benpy-*-win*.whl | grep glpk
```

### Testing Wheel Compatibility

Test wheels on different platforms:

```bash
# Create test environments
python3.10 -m venv test310
python3.11 -m venv test311
python3.12 -m venv test312

# Test Python 3.12
source test312/bin/activate  # or test312\Scripts\activate on Windows
pip install wheelhouse/benpy-*cp312*.whl
python -c "import benpy; print(f'benpy {benpy.__version__} works on Python 3.12!')"
deactivate

# Repeat for other versions
```

## Release Process

Recommended steps for releasing a new version:

### 1. Prepare Release
```bash
# Update version in pyproject.toml
# Update CHANGELOG.md
# Commit changes
git commit -am "Bump version to X.Y.Z"
git push
```

### 2. Build and Test Wheels
```bash
# Trigger wheel build via GitHub Actions
gh workflow run build-wheels.yml

# Or create a release (will auto-trigger)
gh release create vX.Y.Z --title "Version X.Y.Z" --notes "Release notes"
```

### 3. Verify Wheels
- Check GitHub Actions for successful builds
- Download artifacts and test locally:
  ```bash
  pip install benpy-X.Y.Z-*.whl
  python -c "import benpy; print(benpy.__version__)"
  ```

### 4. Publish to TestPyPI (Optional)
```bash
# Test publishing flow
gh workflow run publish.yml -f confirm=publish

# Or use twine directly:
twine upload --repository testpypi dist/*

# Test installation
pip install --index-url https://test.pypi.org/simple/ benpy
```

### 5. Publish to PyPI
```bash
# Via workflow (after wheels are built)
gh workflow run publish.yml -f confirm=publish

# Or use twine directly:
twine upload dist/*
```

### 6. Verify Publication
```bash
# Wait a minute for PyPI to update, then:
pip install --upgrade benpy
python -c "import benpy; print(benpy.__version__)"
```

## Troubleshooting

This section provides solutions to common build issues organized by category.

### Prerequisites and Installation Issues

#### GLPK Not Found

**Symptoms:**
```
fatal error: glpk.h: No such file or directory
undefined reference to 'glp_create_prob'
```

**Solutions by Platform:**

**Linux:**
```bash
# Verify GLPK is installed
dpkg -l | grep glpk  # Debian/Ubuntu
rpm -qa | grep glpk  # RHEL/CentOS

# Install if missing
sudo apt-get install libglpk-dev libglpk40  # Debian/Ubuntu
sudo yum install glpk glpk-devel            # RHEL/CentOS

# Set environment variables
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib/x86_64-linux-gnu"  # or /usr/lib64
```

**macOS:**
```bash
# Verify GLPK is installed
brew list glpk
pkg-config --modversion glpk

# Install if missing
brew install glpk

# Set environment variables
export CFLAGS="-I$(brew --prefix)/include"
export LDFLAGS="-L$(brew --prefix)/lib"

# Add to pkg-config path if needed
export PKG_CONFIG_PATH="$(brew --prefix)/lib/pkgconfig:$PKG_CONFIG_PATH"
```

**Windows:**
```bash
# In MSYS2 MINGW64 terminal
pacman -Qs glpk  # Check if installed

# Install if missing
pacman -S mingw-w64-x86_64-glpk

# Verify installation
ls /mingw64/include/glpk.h
ls /mingw64/lib/libglpk*

# Set environment variables
export PATH="/mingw64/bin:$PATH"
export CFLAGS="-I/mingw64/include"
export LDFLAGS="-L/mingw64/lib"
```

#### Compiler Not Found

**Symptoms:**
```
error: command 'gcc' failed: No such file or directory
cl.exe is not recognized (Windows)
```

**Solutions:**

**Linux:**
```bash
sudo apt-get install build-essential gcc g++  # Debian/Ubuntu
sudo yum groupinstall "Development Tools"      # RHEL/CentOS
```

**macOS:**
```bash
xcode-select --install
# Accept license and wait for installation
```

**Windows:**
```bash
# In MSYS2 MINGW64 terminal
pacman -S mingw-w64-x86_64-gcc

# Verify gcc is in PATH (not cl.exe)
which gcc
gcc --version
```

### Platform-Specific Build Failures

#### macOS Architecture Mismatch

**Symptoms:**
```
ld: warning: ignoring file ... found architecture 'arm64', required architecture 'x86_64'
ImportError: symbol not found in flat namespace '_glp_add_cols'
dyld: Symbol not found: _glp_create_prob
```

**Root Cause:**
- Trying to cross-compile (e.g., building x86_64 wheel on ARM64 runner with ARM64 GLPK)
- GLPK architecture doesn't match target wheel architecture

**Solutions:**

1. **Use Architecture-Specific Runners (Recommended):**
   ```yaml
   # In GitHub Actions workflow
   matrix:
     include:
       - os: macos-13      # Intel runner
         cibw_archs: "x86_64"
         
       - os: macos-14      # Apple Silicon runner
         cibw_archs: "arm64"
   ```

2. **Verify GLPK Architecture:**
   ```bash
   # Check installed GLPK architecture
   file $(brew --prefix)/lib/libglpk.dylib
   
   # Should output:
   # x86_64: Mach-O 64-bit dynamically linked shared library x86_64
   # ARM64:  Mach-O 64-bit dynamically linked shared library arm64
   ```

3. **Reinstall GLPK for Correct Architecture:**
   ```bash
   # On Apple Silicon, ensure Rosetta 2 is NOT active
   arch  # Should show "arm64" not "i386"
   
   brew uninstall glpk
   brew install glpk
   ```

4. **Check Wheel Architecture:**
   ```bash
   # After building
   unzip -l wheelhouse/*.whl | grep benpy
   # Look for architecture suffix: x86_64 or arm64
   ```

**Reference:** See `.github/workflows/build-wheels.yml` for working configuration

#### Windows MinGW vs MSVC Issues

**Symptoms:**
```
error: unknown type name '__int64'
undefined reference to '__imp_glp_create_prob'
LINK : fatal error LNK1104: cannot open file 'libglpk.lib'
```

**Root Cause:**
- Mixing MSVC and MinGW compilers
- Wrong compiler being used

**Solutions:**

1. **Force MinGW Compiler:**
   ```bash
   # Create pydistutils.cfg
   cat > ~/pydistutils.cfg << EOF
   [build]
   compiler=mingw32
   
   [build_ext]
   compiler=mingw32
   EOF
   ```

2. **Verify Compiler:**
   ```bash
   # Check which compiler is active
   where gcc  # Should show C:\msys64\mingw64\bin\gcc.exe
   where cl   # Should NOT be found (or not first in PATH)
   
   gcc --version  # Should show MinGW-w64 GCC
   ```

3. **Update PATH:**
   ```bash
   # Ensure MinGW is first in PATH
   export PATH="/mingw64/bin:$PATH"
   
   # In Windows CMD
   set PATH=C:\msys64\mingw64\bin;%PATH%
   ```

#### Linux: manylinux Compatibility

**Symptoms:**
```
Error: this file is not compatible with manylinux2014 policy
undefined symbol: __gxx_personality_v0
```

**Solutions:**

1. **Check auditwheel Output:**
   ```bash
   auditwheel show wheelhouse/*.whl
   ```

2. **Repair Wheel:**
   ```bash
   auditwheel repair wheelhouse/*.whl -w dist/
   ```

3. **Verify External Dependencies:**
   ```bash
   # Check what libraries are linked
   unzip -l wheelhouse/*.whl
   readelf -d <extracted_so_file> | grep NEEDED
   ```

### Wheel Repair and Tag Issues

#### Wheel Has Wrong Platform Tag

**Symptoms:**
```
ERROR: benpy-2.1.0-cp312-cp312-linux_x86_64.whl is not a supported wheel
```

**Solutions:**

1. **Check Wheel Tags:**
   ```bash
   unzip -l wheelhouse/*.whl | head -20
   # Look for correct platform tag in filename
   ```

2. **Verify Platform:**
   ```bash
   python -c "import sysconfig; print(sysconfig.get_platform())"
   ```

3. **Rebuild with Correct Tags:**
   ```bash
   # For Linux, ensure auditwheel is run
   pip install auditwheel
   auditwheel repair wheelhouse/*.whl -w dist/
   
   # For macOS
   pip install delocate
   delocate-wheel -w dist wheelhouse/*.whl
   
   # For Windows
   pip install delvewheel
   delvewheel repair wheelhouse/*.whl -w dist/
   ```

#### Missing DLLs/Shared Libraries

**Symptoms:**
```
ImportError: DLL load failed: The specified module could not be found (Windows)
ImportError: cannot open shared object file: No such file or directory (Linux)
Library not loaded: @rpath/libglpk.40.dylib (macOS)
```

**Solutions:**

**Linux:**
```bash
# Verify wheel includes GLPK
unzip -l wheelhouse/*.whl | grep libglpk

# Run auditwheel to bundle dependencies
auditwheel repair wheelhouse/*.whl -w dist/

# Verify repair
auditwheel show dist/*.whl
```

**macOS:**
```bash
# Check what libraries are needed
otool -L wheelhouse/*.whl/*.so

# Bundle with delocate
delocate-wheel -w dist wheelhouse/*.whl -v

# Verify bundled libraries
unzip -l dist/*.whl | grep .dylibs
```

**Windows:**
```bash
# Check dependencies
dumpbin /dependents *.pyd  # If you have MSVC tools

# Bundle with delvewheel
delvewheel repair wheelhouse/*.whl -w dist/ --add-path C:\msys64\mingw64\bin

# Verify
unzip -l dist/*.whl | grep dll
```

### Build Performance and Speed

#### Slow Docker Builds (Linux ARM)

**Issue:** Building ARM wheels on x86_64 host is slow due to QEMU emulation

**Solutions:**

1. **Skip ARM Builds Locally:**
   ```bash
   CIBW_ARCHS_LINUX=x86_64 cibuildwheel --platform linux
   ```

2. **Use Native ARM Builder:**
   - Use ARM-based CI runner
   - Or build on actual ARM hardware

3. **Increase Verbosity to Monitor:**
   ```bash
   CIBW_BUILD_VERBOSITY=3 cibuildwheel --platform linux
   ```

#### Docker Permission Issues

**Symptoms:**
```
docker: Got permission denied while trying to connect to the Docker daemon
```

**Solutions:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify
docker ps
```

### Testing and Import Issues

#### Test Failures After Install

**Symptoms:**
```
ModuleNotFoundError: No module named 'benpy'
ImportError: cannot import name 'solve'
```

**Solutions:**

1. **Verify Installation:**
   ```bash
   pip show benpy
   python -c "import benpy; print(benpy.__file__)"
   ```

2. **Check Import Path:**
   ```bash
   python -c "import sys; print('\n'.join(sys.path))"
   ```

3. **Reinstall Cleanly:**
   ```bash
   pip uninstall benpy -y
   pip cache purge
   pip install wheelhouse/*.whl
   ```

4. **Test in Clean Environment:**
   ```bash
   python -m venv test_env
   source test_env/bin/activate  # or test_env\Scripts\activate on Windows
   pip install wheelhouse/*.whl
   python -c "import benpy"
   ```

#### macOS Library Loading Issues

**Symptoms:**
```
Library not loaded: @rpath/libglpk.40.dylib
dyld: Library not loaded
```

**Solutions:**

1. **Set DYLD_FALLBACK_LIBRARY_PATH:**
   ```bash
   export DYLD_FALLBACK_LIBRARY_PATH="$(brew --prefix)/lib:${DYLD_FALLBACK_LIBRARY_PATH}"
   ```

2. **Verify Wheel Has Bundled Libraries:**
   ```bash
   unzip -l wheelhouse/*.whl | grep .dylibs
   # Should show libglpk.40.dylib in .dylibs directory
   ```

3. **Check Binary's Library Paths:**
   ```bash
   # Find the .so file
   python -c "import benpy; print(benpy.__file__)"
   
   # Check what it's looking for
   otool -L <path_to_benpy_so>
   # Should show @loader_path/../.dylibs/libglpk.40.dylib
   ```

### CI/CD and GitHub Actions Issues

#### Workflow Fails at Wheel Build Step

**Common Issues:**

1. **Check Workflow Logs:**
   - Go to Actions tab in GitHub
   - Click on failed workflow
   - Expand failed step
   - Look for error messages

2. **Test Locally:**
   ```bash
   # Reproduce CI environment
   docker run -it --rm \
     -v $(pwd):/project \
     -w /project \
     quay.io/pypa/manylinux2014_x86_64 \
     bash
   
   # Inside container
   yum install -y glpk glpk-devel
   /opt/python/cp312-cp312/bin/pip install cibuildwheel
   /opt/python/cp312-cp312/bin/cibuildwheel --platform linux
   ```

3. **Enable Verbose Output:**
   ```yaml
   # In workflow file
   env:
     CIBW_BUILD_VERBOSITY: 3
   ```

#### Artifact Upload Failures

**Issue:** Wheels not uploaded or accessible

**Solutions:**

1. **Check Upload Path:**
   ```yaml
   - uses: actions/upload-artifact@v4
     with:
       name: wheels-${{ matrix.os }}
       path: ./wheelhouse/*.whl  # Verify this path is correct
   ```

2. **Verify Wheels Were Built:**
   ```yaml
   # Add debug step before upload
   - name: List built wheels
     run: ls -la wheelhouse/
   ```

### cibuildwheel Configuration Issues

#### Wrong Python Versions Being Built

**Issue:** Building for unsupported Python versions

**Solutions:**

1. **Check pyproject.toml:**
   ```toml
   [tool.cibuildwheel]
   build = "cp310-* cp311-* cp312-*"  # Only 3.10, 3.11, 3.12
   ```

2. **Override Temporarily:**
   ```bash
   CIBW_BUILD="cp312-*" cibuildwheel --platform auto
   ```

3. **Verify Build Identifiers:**
   ```bash
   cibuildwheel --print-build-identifiers --platform linux
   ```

### Getting More Help

If you encounter issues not covered here:

1. **Check Workflow Logs:**
   - GitHub Actions → Failed workflow → Expand steps
   - Use summarize_run_log_failures tool for AI analysis

2. **Enable Verbose Mode:**
   ```bash
   CIBW_BUILD_VERBOSITY=3 cibuildwheel --platform auto 2>&1 | tee build.log
   ```

3. **Test in Clean Environment:**
   - Use the devcontainer
   - Or create a fresh VM/container

4. **Consult Documentation:**
   - [cibuildwheel FAQ](https://cibuildwheel.readthedocs.io/en/stable/faq/)
   - [CibuildwheelConfiguration.md](CibuildwheelConfiguration.md)
   - [CrossPlatformCompilation.md](CrossPlatformCompilation.md)

5. **Open an Issue:**
   - Provide full error message
   - Include platform and Python version
   - Share relevant configuration
   - Include build logs if possible

## Advanced Usage

### Build Specific Configurations

**Build Only Specific Architectures:**
```bash
# Linux x86_64 only (skip ARM)
CIBW_ARCHS_LINUX=x86_64 cibuildwheel --platform linux

# macOS ARM64 only (Apple Silicon)
CIBW_ARCHS_MACOS=arm64 cibuildwheel --platform macos

# Windows AMD64 (default, explicitly set)
CIBW_ARCHS_WINDOWS=AMD64 cibuildwheel --platform windows
```

**Build for Specific Python Versions:**
```bash
# Only Python 3.12
cibuildwheel --only cp312-*

# Python 3.11 and 3.12
CIBW_BUILD="cp311-* cp312-*" cibuildwheel --platform auto

# All versions except 3.10
CIBW_SKIP="cp310-*" cibuildwheel --platform auto
```

**Control Test Execution:**
```bash
# Skip all tests (faster builds)
CIBW_TEST_SKIP="*" cibuildwheel

# Skip tests on specific platforms
CIBW_TEST_SKIP="*-macosx_arm64" cibuildwheel

# Skip tests for specific Python version
CIBW_TEST_SKIP="cp310-*" cibuildwheel
```

**Increase Build Verbosity:**
```bash
# Level 0: Quiet (only errors)
CIBW_BUILD_VERBOSITY=0 cibuildwheel

# Level 1: Normal (default)
CIBW_BUILD_VERBOSITY=1 cibuildwheel

# Level 2: Verbose
CIBW_BUILD_VERBOSITY=2 cibuildwheel

# Level 3: Very verbose (for debugging)
CIBW_BUILD_VERBOSITY=3 cibuildwheel
```

### Override Configuration

Environment variables override `pyproject.toml` settings:

```bash
# Use different Python versions
export CIBW_BUILD="cp311-* cp312-*"
cibuildwheel

# Use different manylinux image
export CIBW_MANYLINUX_X86_64_IMAGE=manylinux_2_28
cibuildwheel --platform linux

# Custom before-build command
export CIBW_BEFORE_BUILD="pip install Cython>=3.0.5 numpy>=1.24"
cibuildwheel

# Custom output directory
export CIBW_OUTPUT_DIR="dist/wheels"
cibuildwheel
```

### Building in Docker (Linux)

For reproducible Linux builds:

```bash
# Pull manylinux image
docker pull quay.io/pypa/manylinux2014_x86_64

# Run interactive shell
docker run -it --rm \
  -v $(pwd):/project \
  -w /project \
  quay.io/pypa/manylinux2014_x86_64 \
  bash

# Inside container:
yum install -y glpk glpk-devel
/opt/python/cp312-cp312/bin/pip install cibuildwheel
/opt/python/cp312-cp312/bin/cibuildwheel --platform linux

# Built wheels will be in ./wheelhouse/
```

### Custom Build Script

Create a comprehensive build script:

```bash
#!/bin/bash
# build-wheels.sh - Build benpy wheels for all platforms

set -e  # Exit on error

# Configuration
PYTHON_VERSIONS="cp310-* cp311-* cp312-*"
OUTPUT_DIR="dist/wheels"
BUILD_VERBOSITY=1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Building benpy wheels${NC}"
echo "Python versions: $PYTHON_VERSIONS"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Export configuration
export CIBW_BUILD="$PYTHON_VERSIONS"
export CIBW_BUILD_VERBOSITY=$BUILD_VERBOSITY
export CIBW_OUTPUT_DIR="$OUTPUT_DIR"

# Detect platform
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    # Skip ARM on local builds (slow in QEMU)
    export CIBW_ARCHS_LINUX="x86_64"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    # Detect macOS architecture
    ARCH=$(uname -m)
    export CIBW_ARCHS_MACOS="$ARCH"
elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
    PLATFORM="windows"
else
    echo -e "${RED}Unknown platform: $OSTYPE${NC}"
    exit 1
fi

echo -e "${YELLOW}Building for platform: $PLATFORM${NC}"

# Clean previous builds
if [ -d "$OUTPUT_DIR" ]; then
    echo "Cleaning previous builds..."
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

# Build wheels
echo ""
echo -e "${GREEN}Running cibuildwheel...${NC}"
cibuildwheel --platform "$PLATFORM"

# Verify builds
echo ""
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "Built wheels:"
ls -lh "$OUTPUT_DIR"

# Check wheel integrity
echo ""
echo -e "${YELLOW}Checking wheel integrity...${NC}"
for wheel in "$OUTPUT_DIR"/*.whl; do
    if [ -f "$wheel" ]; then
        echo "Checking: $(basename $wheel)"
        python -m zipfile -l "$wheel" | grep -E 'benpy|glpk' | head -5
    fi
done

echo ""
echo -e "${GREEN}All done!${NC}"
echo "Wheels saved to: $OUTPUT_DIR"
```

Make it executable:
```bash
chmod +x build-wheels.sh
./build-wheels.sh
```

### Testing Wheels Before Publishing

Always test built wheels before publishing:

```bash
#!/bin/bash
# test-wheels.sh - Test built wheels

WHEEL_DIR="wheelhouse"

for wheel in "$WHEEL_DIR"/*.whl; do
    if [ -f "$wheel" ]; then
        echo "Testing: $(basename $wheel)"
        
        # Create temp venv
        VENV_DIR=$(mktemp -d)
        python -m venv "$VENV_DIR"
        source "$VENV_DIR/bin/activate"
        
        # Install wheel
        pip install "$wheel"
        
        # Test import
        python -c "import benpy; print(f'✓ benpy {benpy.__version__} imported successfully')" || {
            echo "✗ Failed to import benpy from $wheel"
            deactivate
            rm -rf "$VENV_DIR"
            exit 1
        }
        
        # Run basic test
        python -c "
import benpy
import numpy as np

# Test basic solve
B = np.array([[2.0, 1.0], [1.0, 2.0]])
P = np.array([[1.0, 0.0], [0.0, 1.0]])
b = np.array([4.0, 4.0])

try:
    sol = benpy.solve(B, P, b=b, opt_dir=1)
    print(f'✓ Basic solve test passed')
except Exception as e:
    print(f'✗ Basic solve test failed: {e}')
    exit(1)
" || {
            echo "✗ Basic test failed for $wheel"
            deactivate
            rm -rf "$VENV_DIR"
            exit 1
        }
        
        deactivate
        rm -rf "$VENV_DIR"
        echo ""
    fi
done

echo "All wheels tested successfully!"
```

### Debugging Build Failures

**Enable Maximum Verbosity:**
```bash
CIBW_BUILD_VERBOSITY=3 cibuildwheel --platform auto 2>&1 | tee build.log
```

**Interactive Debugging in Docker:**
```bash
# Start container
docker run -it --rm \
  -v $(pwd):/project \
  -w /project \
  quay.io/pypa/manylinux2014_x86_64 \
  bash

# Inside container, run commands step by step:
yum install -y glpk glpk-devel
/opt/python/cp312-cp312/bin/pip install setuptools wheel Cython numpy
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib64"
/opt/python/cp312-cp312/bin/pip install -e . -v
```

**Check Wheel Dependencies:**
```bash
# Linux
auditwheel show wheelhouse/*.whl

# macOS
delocate-listdeps wheelhouse/*.whl
otool -L wheelhouse/*.whl/*.so

# Windows (if you have MinGW objdump)
objdump -p wheelhouse/*.whl/*.pyd | grep 'DLL Name'
```

### Parallel Builds

Build multiple platforms simultaneously using GNU parallel:

```bash
#!/bin/bash
# parallel-build.sh - Build on multiple platforms in parallel

# Install GNU parallel: sudo apt install parallel

# Define build functions
build_linux() {
    CIBW_ARCHS_LINUX=x86_64 cibuildwheel --platform linux --output-dir dist/linux
}

build_macos() {
    cibuildwheel --platform macos --output-dir dist/macos
}

build_windows() {
    cibuildwheel --platform windows --output-dir dist/windows
}

export -f build_linux build_macos build_windows

# Run in parallel (if on macOS or Linux)
parallel ::: build_linux build_macos build_windows

# Collect all wheels
mkdir -p dist/all
cp dist/*/*.whl dist/all/

echo "All wheels built and collected in dist/all/"
ls -lh dist/all/
```

### Cross-Compiling (Advanced)

**Note:** benpy avoids cross-compilation for macOS due to GLPK dependency issues, but here's how you would do it if needed:

```bash
# Build macOS ARM64 wheel on x86_64 (not recommended for benpy)
export CIBW_ARCHS_MACOS="arm64"
export _PYTHON_HOST_PLATFORM="macosx-11.0-arm64"
cibuildwheel --platform macos

# Cross-compile for Linux ARM64 using QEMU
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
export CIBW_ARCHS_LINUX="aarch64"
cibuildwheel --platform linux
```

**Warning:** Cross-compilation for benpy is not recommended because:
- GLPK must match the target architecture
- Runtime linker issues are common
- Native builds are more reliable

### Wheel Inspection Tools

Useful tools for inspecting built wheels:

```bash
# Install tools
pip install wheel-inspect auditwheel delocate delvewheel

# Inspect wheel metadata
wheel-inspect wheelhouse/benpy-*.whl

# Check wheel tags
python -m wheel tags wheelhouse/benpy-*.whl

# Verify wheel integrity
twine check wheelhouse/*.whl

# Extract wheel contents
python -m zipfile -e wheelhouse/benpy-*.whl /tmp/wheel-contents/
ls -R /tmp/wheel-contents/
```

## Resources

### Documentation

- **[cibuildwheel documentation](https://cibuildwheel.readthedocs.io/)** - Official docs
- **[CibuildwheelConfiguration.md](CibuildwheelConfiguration.md)** - Detailed configuration guide
- **[CrossPlatformCompilation.md](CrossPlatformCompilation.md)** - Platform-specific compilation notes
- **[PyPI Publishing Guide](https://packaging.python.org/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/)** - GitHub Actions publishing
- **[Trusted Publishers](https://docs.pypi.org/trusted-publishers/)** - PyPI trusted publishing setup
- **[Python Packaging User Guide](https://packaging.python.org/)** - Official packaging docs

### Tools

- **[cibuildwheel](https://github.com/pypa/cibuildwheel)** - Build wheels on CI
- **[auditwheel](https://github.com/pypa/auditwheel)** - Linux wheel repair
- **[delocate](https://github.com/matthew-brett/delocate)** - macOS wheel repair
- **[delvewheel](https://github.com/adang1345/delvewheel)** - Windows wheel repair
- **[twine](https://github.com/pypa/twine)** - PyPI upload tool
- **[wheel-inspect](https://github.com/jwodder/wheel-inspect)** - Wheel inspection

### Platform-Specific Resources

**Linux:**
- [manylinux GitHub](https://github.com/pypa/manylinux)
- [auditwheel documentation](https://github.com/pypa/auditwheel)

**macOS:**
- [delocate documentation](https://github.com/matthew-brett/delocate)
- [Homebrew](https://brew.sh/)

**Windows:**
- [MSYS2](https://www.msys2.org/)
- [MinGW-w64](https://www.mingw-w64.org/)
- [delvewheel documentation](https://github.com/adang1345/delvewheel)

## Getting Help

If you encounter issues not covered in this guide:

### 1. Check Workflow Logs

For CI/CD failures:
```bash
# List recent workflow runs
gh run list --workflow=build-wheels.yml --limit 10

# View specific run
gh run view <run-id> --log

# Download logs
gh run view <run-id> --log > build.log
```

Or use GitHub's AI-powered analysis:
- Go to Actions → Failed workflow → Click "summarize with AI"

### 2. Enable Verbose Logging

```bash
# Maximum verbosity
CIBW_BUILD_VERBOSITY=3 cibuildwheel --platform auto 2>&1 | tee build.log

# Review the log
less build.log
```

### 3. Test in Clean Environment

Use the devcontainer or a fresh VM:
```bash
# Clone in fresh directory
git clone https://github.com/markobud/benpy.git test-benpy
cd test-benpy

# Use devcontainer or build manually
pip install cibuildwheel
cibuildwheel --platform auto
```

### 4. Search Existing Issues

```bash
# Search benpy issues
gh issue list --repo markobud/benpy --search "build wheel"

# Search cibuildwheel issues
gh issue list --repo pypa/cibuildwheel --search "glpk"
```

### 5. Consult Documentation

- Review [Troubleshooting](#troubleshooting) section above
- Check [cibuildwheel FAQ](https://cibuildwheel.readthedocs.io/en/stable/faq/)
- Read [CibuildwheelConfiguration.md](CibuildwheelConfiguration.md)
- See [CrossPlatformCompilation.md](CrossPlatformCompilation.md)

### 6. Open an Issue

If you still need help, [open an issue](https://github.com/markobud/benpy/issues/new) with:

- **Platform**: Linux/macOS/Windows and version
- **Python version**: Output of `python --version`
- **Error message**: Full error text or log snippet
- **Build command**: Exact command you ran
- **Configuration**: Relevant `pyproject.toml` settings
- **Environment**: Output of `env | grep CIBW`
- **Logs**: Attach build logs if possible

**Template:**
```markdown
### Problem Description
Brief description of the issue

### Environment
- OS: macOS 14.0 (Apple Silicon)
- Python: 3.12.0
- cibuildwheel: 2.21.3

### Steps to Reproduce
1. Run `cibuildwheel --platform macos`
2. ...

### Error Message
```
[error text here]
```

### Configuration
```toml
[tool.cibuildwheel]
build = "cp312-*"
...
```
```
