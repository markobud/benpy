# Building and Publishing Wheels

This guide explains how to build and publish distributable wheels for benpy.

## Quick Start

### Building Wheels Locally

To build wheels on your local machine:

```bash
# Install cibuildwheel
pip install cibuildwheel

# Build for current platform
cibuildwheel --platform auto

# Build for specific platform
cibuildwheel --platform linux   # or macos, windows

# Build specific Python version only
cibuildwheel --only cp312-*

# Output to custom directory
cibuildwheel --output-dir dist
```

The wheels will be in the `wheelhouse/` directory by default.

## GitHub Actions Workflows

### CI Workflow (ci.yml)

Runs on every push and PR to main/development branches:
- Tests on Ubuntu, macOS, Windows with Python 3.12
- Builds source distribution
- Does NOT build wheels (use build-wheels.yml for that)

**When to use**: Automatic on every push/PR. No action needed.

### Build Wheels Workflow (build-wheels.yml)

Builds distributable wheels for all platforms:
- **Linux**: x86_64 and ARM64 (manylinux2014) on `ubuntu-latest`
- **macOS**: 
  - x86_64 (Intel) on `macos-13` runner
  - ARM64 (Apple Silicon) on `macos-14` runner
- **Windows**: AMD64 (x64) on `windows-latest`
- **Python**: 3.9, 3.10, 3.11, 3.12

**macOS Architecture Strategy**:
To avoid cross-compilation issues with GLPK dependencies, we use native builds:
- `macos-13` runner (Intel) builds x86_64 wheels with x86_64 GLPK
- `macos-14` runner (Apple Silicon) builds ARM64 wheels with ARM64 GLPK
- No Universal2 wheels (users get the appropriate arch-specific wheel)

**Triggers**:
- Push to `main` or `development`
- Pull requests
- Git tags starting with `v*`
- Manual dispatch

**Manual trigger**:
```bash
# Via GitHub CLI
gh workflow run build-wheels.yml

# Or via GitHub web interface:
# Actions → Build Wheels → Run workflow
```

**Artifacts**: Uploads wheels and sdist to GitHub Actions artifacts (30-day retention).

### Publish Workflow (publish.yml) - DRAFT

Publishes wheels to PyPI. **This is a draft workflow** requiring setup before use.

**Setup required**:
1. Configure PyPI trusted publishing (see documentation)
2. Create GitHub environments: `testpypi` and `pypi`
3. Test with TestPyPI first

**Triggers**:
- GitHub releases
- Manual dispatch (requires typing "publish" to confirm)

**Manual trigger**:
```bash
# Via GitHub CLI
gh workflow run publish.yml -f confirm=publish

# Or via GitHub web interface:
# Actions → Publish to PyPI → Run workflow → Enter "publish"
```

## Configuration

### pyproject.toml

All cibuildwheel settings are in `pyproject.toml`:

```toml
[tool.cibuildwheel]
build = "cp39-* cp310-* cp311-* cp312-*"
skip = "pp* *-musllinux* *-win32 *-manylinux_i686"
# ... platform-specific settings
```

**To modify**:
- Add/remove Python versions in `build`
- Change architectures in platform sections
- Adjust GLPK installation commands in `before-all`

### Testing Changes

Test configuration changes locally before pushing:

```bash
# Check what would be built
cibuildwheel --print-build-identifiers --platform linux

# Build one wheel for testing
cibuildwheel --only cp312-manylinux_x86_64
```

## Build Matrix

Current build matrix produces **20 wheel variants**:

| Platform | Arch | Py 3.9 | Py 3.10 | Py 3.11 | Py 3.12 |
|----------|------|--------|---------|---------|---------|
| Linux    | x86_64 | ✓ | ✓ | ✓ | ✓ |
| Linux    | ARM64 | ✓ | ✓ | ✓ | ✓ |
| macOS    | x86_64 (Intel) | ✓ | ✓ | ✓ | ✓ |
| macOS    | ARM64 (Apple Silicon) | ✓ | ✓ | ✓ | ✓ |
| Windows  | AMD64 (x64) | ✓ | ✓ | ✓ | ✓ |

**Total**: 20 wheels + 1 source distribution

**Note**: macOS wheels are built using architecture-specific runners:
- `macos-13` (Intel) for x86_64 wheels
- `macos-14` (Apple Silicon) for ARM64 wheels

This approach avoids cross-compilation issues with GLPK dependencies.

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

### Build Failures

**GLPK not found**:
- Check `before-all` commands in pyproject.toml
- Verify GLPK package names are correct for platform
- Check CFLAGS and LDFLAGS environment variables

**macOS architecture mismatch** (symbol not found errors):
- **Symptom**: `ld: warning: ignoring file ... found architecture 'arm64', required architecture 'x86_64'`
- **Symptom**: `ImportError: symbol not found in flat namespace '_glp_add_cols'`
- **Cause**: Trying to cross-compile (e.g., building x86_64 on ARM64 runner)
- **Solution**: Use architecture-specific runners:
  - `macos-13` for x86_64 wheels
  - `macos-14` for ARM64 wheels
- See the `build_wheels` job matrix in `.github/workflows/build-wheels.yml`

**Wheel repair failures**:
- Linux: Check auditwheel compatibility
- macOS: Verify Homebrew paths are correct; check `delocate-wheel` output
- Windows: Ensure MSYS2 DLLs are in PATH

**Test failures**:
- Check that test dependencies are installed
- Verify test command path is correct
- Review pytest output in logs
- On macOS, ensure DYLD_FALLBACK_LIBRARY_PATH is set correctly

### Local Build Issues

**cibuildwheel not found**:
```bash
pip install cibuildwheel
```

**Docker issues (Linux)**:
- Ensure Docker is running
- Check Docker permissions
- Try: `docker pull quay.io/pypa/manylinux2014_x86_64`

**Slow builds**:
- Build specific Python version: `--only cp312-*`
- Skip ARM builds: Set `CIBW_ARCHS_LINUX=x86_64`
- Use local builds only: Skip QEMU emulation

### Publishing Issues

**PyPI upload failed**:
- Check PyPI credentials/trusted publishing
- Verify version number doesn't already exist
- Check wheel platform tags are acceptable
- Review PyPI upload logs

**Wheels not compatible**:
- Verify manylinux/macosx platform tags
- Check Python version compatibility
- Ensure dependencies are properly vendored

## Advanced Usage

### Build Specific Configurations

```bash
# Build only Linux x86_64
CIBW_ARCHS_LINUX=x86_64 cibuildwheel --platform linux

# Build only macOS Universal2
CIBW_ARCHS_MACOS=universal2 cibuildwheel --platform macos

# Skip tests
CIBW_TEST_SKIP="*" cibuildwheel

# Increase verbosity
CIBW_BUILD_VERBOSITY=3 cibuildwheel
```

### Override Configuration

Environment variables override `pyproject.toml`:

```bash
# Use different Python versions
export CIBW_BUILD="cp311-* cp312-*"
cibuildwheel

# Use different manylinux image
export CIBW_MANYLINUX_X86_64_IMAGE=manylinux_2_28
cibuildwheel --platform linux
```

### Custom Build Script

For more control, create a build script:

```bash
#!/bin/bash
# build-wheels.sh

# Set options
export CIBW_BUILD="cp312-*"
export CIBW_ARCHS_LINUX="x86_64"
export CIBW_BUILD_VERBOSITY=1

# Build
cibuildwheel --platform linux --output-dir dist

# Check wheels
ls -lh dist/
twine check dist/*.whl
```

## Resources

- [cibuildwheel documentation](https://cibuildwheel.readthedocs.io/)
- [CibuildwheelConfiguration.md](doc/CibuildwheelConfiguration.md) - Detailed configuration docs
- [PyPI Publishing Guide](https://packaging.python.org/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/)
- [Trusted Publishers](https://docs.pypi.org/trusted-publishers/)

## Getting Help

If you encounter issues:

1. Check workflow logs in GitHub Actions
2. Review [CibuildwheelConfiguration.md](doc/CibuildwheelConfiguration.md)
3. Test locally with `cibuildwheel`
4. Check [cibuildwheel FAQ](https://cibuildwheel.readthedocs.io/en/stable/faq/)
5. Open an issue on GitHub
