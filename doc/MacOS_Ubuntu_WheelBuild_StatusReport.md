# macOS and Ubuntu Wheel Build Status Report

**Date**: November 9, 2024  
**Purpose**: Check the current status of macOS and Ubuntu wheel builds after Windows triage

## Executive Summary

This report documents the status of wheel builds for macOS and Ubuntu platforms. These builds were temporarily disabled during Windows wheel build triage and are now being re-enabled to assess their current state.

## Background

- **Previous State**: macOS and Ubuntu builds were commented out in `build-wheels.yml` to focus on Windows triage
- **Windows Status**: Windows wheel builds have been triaged and fixed (see `doc/WindowsWheelBuildTriage.md`)
- **Current Task**: Re-enable macOS and Ubuntu builds to verify they work correctly

## Build Matrix Re-enabled

The following build configurations have been re-enabled:

### Ubuntu (Linux)
- **Runner**: `ubuntu-latest`
- **Architectures**: x86_64, aarch64 (ARM64)
- **Python Versions**: 3.9, 3.10, 3.11, 3.12
- **Total Wheels**: 8 wheels (2 architectures × 4 Python versions)

### macOS x86_64 (Intel)
- **Runner**: `macos-13` (Intel runner)
- **Architecture**: x86_64
- **Python Versions**: 3.9, 3.10, 3.11, 3.12
- **Deployment Target**: macOS 13.0
- **Total Wheels**: 4 wheels

### macOS ARM64 (Apple Silicon)
- **Runner**: `macos-14` (Apple Silicon runner)
- **Architecture**: arm64
- **Python Versions**: 3.9, 3.10, 3.11, 3.12
- **Deployment Target**: macOS 14.0
- **Total Wheels**: 4 wheels

### Windows (Reference)
- **Runner**: `windows-latest`
- **Architecture**: AMD64
- **Python Versions**: 3.9, 3.10, 3.11, 3.12
- **Total Wheels**: 4 wheels

**Total Expected Wheels**: 20 wheels across all platforms

## Build Configuration Details

### Ubuntu Configuration

**GLPK Installation** (`pyproject.toml`):
```bash
# Supports both yum (CentOS/RHEL) and apt-get (Ubuntu/Debian)
bash -c 'if command -v yum >/dev/null 2>&1; then 
    yum install -y epel-release || true
    yum install -y glpk glpk-devel
elif command -v apt-get >/dev/null 2>&1; then 
    apt-get update
    apt-get install -y libglpk-dev glpk-utils
else 
    echo "No supported package manager found"
    exit 1
fi'
```

**Wheel Repair**: `auditwheel` (manylinux2014)
- Bundles GLPK shared libraries into wheel
- Creates portable manylinux wheels

**Container Image**: manylinux2014 (x86_64 and aarch64)

### macOS Configuration

**GLPK Installation** (`pyproject.toml`):
```bash
brew install glpk
pip install delocate
```

**Architecture Strategy**:
- **macos-13 runner**: Installs x86_64 GLPK via Homebrew, builds x86_64 wheels
- **macos-14 runner**: Installs ARM64 GLPK via Homebrew, builds arm64 wheels
- **No cross-compilation**: Each runner builds for its native architecture

**Wheel Repair**: `delocate-wheel`
- Bundles GLPK dylibs into wheel
- Uses `--require-archs {delocate_archs}` to verify correct architecture

**Deployment Targets**:
- macOS 13.0 for x86_64 wheels (macos-13 runner)
- macOS 14.0 for ARM64 wheels (macos-14 runner)

### Windows Configuration (Reference)

See `doc/WindowsWheelBuildTriage.md` for complete Windows configuration details.

## Verification Tests

The `verify_wheels` job tests each platform with Python 3.12:

1. **Install GLPK** (runtime dependency for testing)
2. **Download and install wheel** matching the platform
3. **Import benpy** and verify it loads successfully
4. **Run basic tests** from `tests/test_import.py`

### Ubuntu Verification
- Installs GLPK via `apt-get`
- Tests wheel import
- Verifies bundled libraries work

### macOS Verification
- Installs GLPK via Homebrew
- Sets `DYLD_FALLBACK_LIBRARY_PATH` for runtime library loading
- Uses `otool -L` to inspect library dependencies
- Verifies bundled `.dylibs` directory exists
- Tests wheel import on both x86_64 (macos-13) and arm64 (macos-14)

### Windows Verification
- Installs GLPK via MSYS2
- Tests wheel import
- Verifies bundled DLLs work

## Build Results

**Status**: ⏳ Pending - Workflow triggered

### Ubuntu Builds

#### x86_64
- **Python 3.9**: ⏳ Pending
- **Python 3.10**: ⏳ Pending
- **Python 3.11**: ⏳ Pending
- **Python 3.12**: ⏳ Pending

#### aarch64 (ARM64)
- **Python 3.9**: ⏳ Pending
- **Python 3.10**: ⏳ Pending
- **Python 3.11**: ⏳ Pending
- **Python 3.12**: ⏳ Pending

**Ubuntu Build Status**: ⏳ Waiting for results

### macOS x86_64 (Intel) Builds

- **Python 3.9**: ⏳ Pending
- **Python 3.10**: ⏳ Pending
- **Python 3.11**: ⏳ Pending
- **Python 3.12**: ⏳ Pending

**macOS x86_64 Build Status**: ⏳ Waiting for results

### macOS ARM64 (Apple Silicon) Builds

- **Python 3.9**: ⏳ Pending
- **Python 3.10**: ⏳ Pending
- **Python 3.11**: ⏳ Pending
- **Python 3.12**: ⏳ Pending

**macOS ARM64 Build Status**: ⏳ Waiting for results

### Windows Builds (Reference)

- **Python 3.9**: ⏳ Pending
- **Python 3.10**: ⏳ Pending
- **Python 3.11**: ⏳ Pending
- **Python 3.12**: ⏳ Pending

**Windows Build Status**: ⏳ Waiting for results

## Verification Results

### Ubuntu Verification (Python 3.12)
- **Status**: ⏳ Pending
- **Import Test**: ⏳ Pending
- **pytest Test**: ⏳ Pending

### macOS x86_64 Verification (Python 3.12)
- **Status**: ⏳ Pending
- **Import Test**: ⏳ Pending
- **Library Bundling**: ⏳ Pending (checking for `.dylibs` directory)
- **pytest Test**: ⏳ Pending

### macOS ARM64 Verification (Python 3.12)
- **Status**: ⏳ Pending
- **Import Test**: ⏳ Pending
- **Library Bundling**: ⏳ Pending (checking for `.dylibs` directory)
- **pytest Test**: ⏳ Pending

### Windows Verification (Python 3.12)
- **Status**: ⏳ Pending
- **Import Test**: ⏳ Pending
- **pytest Test**: ⏳ Pending

## Issues Discovered

*This section will be updated with any issues found during the build process*

### Ubuntu Issues
- None yet (pending build results)

### macOS Issues
- None yet (pending build results)

### Windows Issues
- None yet (pending build results)

## Known Platform-Specific Considerations

### Ubuntu
- **ARM64 builds**: Use QEMU for emulation on x86_64 runners
- **Container base**: manylinux2014 provides compatibility back to CentOS 7 / Ubuntu 14.04
- **GLPK availability**: Available in standard apt repositories

### macOS
- **Architecture separation**: Using separate runners (macos-13, macos-14) to avoid cross-compilation issues
- **Deployment targets**: Different minimum macOS versions for x86_64 (13.0) and ARM64 (14.0)
- **Homebrew architecture**: Automatically matches runner architecture
- **Library bundling**: delocate must bundle GLPK dylibs for portability

### Windows
- **Compiler**: Uses MinGW GCC instead of MSVC
- **GLPK source**: MSYS2 package manager
- **Library bundling**: delvewheel bundles GLPK and GCC runtime DLLs

## Recommendations

*This section will be updated based on build results*

### If All Builds Succeed
1. ✅ Keep all platforms enabled in `build-wheels.yml`
2. ✅ Consider tagging a new release to publish wheels
3. ✅ Update documentation with successful build status

### If Builds Fail
1. 🔍 Analyze failure logs for each platform
2. 🔍 Check for platform-specific configuration issues
3. 🔍 Verify GLPK installation steps
4. 🔍 Check wheel repair commands
5. 📝 Document issues in this report
6. 🔧 Apply fixes and re-test

## Next Steps

1. ⏳ **Wait for workflow completion** - Monitor GitHub Actions for build results
2. 📊 **Analyze build logs** - Review logs for any errors or warnings
3. 📝 **Update this report** - Document findings for each platform
4. 🔧 **Fix any issues** - Address platform-specific problems if found
5. ✅ **Verify wheels** - Ensure wheels install and run correctly on each platform
6. 📋 **Create summary** - Provide clear status on which platforms are working

## Workflow Information

- **Workflow File**: `.github/workflows/build-wheels.yml`
- **Trigger**: Push to branch `copilot/check-macos-ubuntu-wheels-status`
- **Expected Duration**: ~30-45 minutes (includes all platforms and verification)
- **Artifacts**: Wheels stored as GitHub Actions artifacts for 30 days

## References

- **Windows Triage**: `doc/WindowsWheelBuildTriage.md`
- **Configuration Guide**: `doc/CibuildwheelConfiguration.md`
- **Building Wheels**: `doc/BuildingWheels.md`
- **cibuildwheel**: https://cibuildwheel.readthedocs.io/

---

**Report Status**: 🔄 Initial template - Awaiting build results  
**Last Updated**: November 9, 2024
