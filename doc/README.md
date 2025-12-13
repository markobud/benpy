# benpy Documentation

This directory contains technical documentation for benpy developers and advanced users.

## User Documentation

For general usage, installation instructions, and quick start examples, see the main [README.md](../README.md) in the repository root.

## Core API Documentation

- **[InMemoryInterface.md](InMemoryInterface.md)** - Complete guide to the in-memory interface
  - `solve_direct()` API reference with examples
  - Direct structure access patterns
  - Performance benchmarks and comparisons
  - Migration guide from file-based interface

## Developer Guides

- **[MemoryManagement.md](MemoryManagement.md)** - Memory management patterns in benpy
  - bensolve 2.1.0 memory ownership model
  - Wrapper memory management best practices
  - Memory leak prevention strategies
  - Technical audit details

- **[OwnershipPatterns.md](OwnershipPatterns.md)** - Developer guide for contributors
  - Memory ownership by component
  - Object lifecycle examples
  - Common pitfalls and best practices
  - Testing guidelines for memory safety

## Safety and Concurrency

- **[ThreadingSafety.md](ThreadingSafety.md)** - Threading behavior and GIL release
  - Thread safety status of bensolve 2.1.0
  - Safe and unsafe usage patterns
  - GIL release implementation details
  - Multiprocessing for parallelism

## Build and Distribution

- **[CI_CD_Documentation.md](CI_CD_Documentation.md)** - CI/CD workflow documentation
  - GitHub Actions pipeline overview
  - Test suite execution
  - Troubleshooting guide

- **[BuildingWheels.md](BuildingWheels.md)** - Building distributable wheels
  - Local wheel building with cibuildwheel
  - GitHub Actions workflows for releases
  - Publishing to PyPI

- **[CibuildwheelConfiguration.md](CibuildwheelConfiguration.md)** - Detailed cibuildwheel config
  - Platform-specific build configurations
  - GLPK dependency installation
  - Wheel repair and testing

- **[CrossPlatformCompilation.md](CrossPlatformCompilation.md)** - Cross-platform implementation
  - Platform-specific code (timing, headers)
  - Windows/Unix compatibility layer
  - Compilation troubleshooting

### Windows-Specific Build Issues

- **[WindowsWheelSizeOfVoidPFix.md](WindowsWheelSizeOfVoidPFix.md)** - **⭐ Windows wheel SIZEOF_VOID_P fix**
  - Complete solution to Cython compile-time assertion error
  - Root cause analysis and technical details
  - Testing and verification guide
  - **Start here** if encountering Windows build issues

- **[WindowsWheelFix_Comparison.md](WindowsWheelFix_Comparison.md)** - Comparison with previous attempts
  - Why previous fixes failed
  - Side-by-side technical comparison
  - Timeline and lessons learned

- **[WindowsWheelBuildAttempts_Post_c788f5a.md](WindowsWheelBuildAttempts_Post_c788f5a.md)** - Historical attempt log
  - Chronological record of failed attempts
  - Build logs and error messages
  - Background context

- **[WindowsWheelBuildTriage.md](WindowsWheelBuildTriage.md)** - Initial triage documentation
  - GLPK path configuration
  - MinGW vs MSVC strategy
  - delvewheel setup

## Historical Reference

- **[WindowsTestCrashes_RESOLVED.md](WindowsTestCrashes_RESOLVED.md)** - Windows crash fix documentation
  - Root cause analysis of Windows test failures
  - Solution implementation details
  - Control flow fix in _csolve()

## Additional Resources

- **Main README**: [../README.md](../README.md)
- **Changelog**: [../CHANGELOG.md](../CHANGELOG.md)
- **License**: [../LICENSE.md](../LICENSE.md)
- **Examples**: [../src/examples/](../src/examples/)
- **Test Suite**: [../tests/](../tests/)
- **Notebooks**: [../notebooks/](../notebooks/)

## Contributing

When adding new documentation:

1. **User-facing features** → Update main README.md
2. **API changes** → Update InMemoryInterface.md or create new API doc
3. **Internal implementation** → Update MemoryManagement.md or OwnershipPatterns.md
4. **Build/CI changes** → Update CI_CD_Documentation.md or BuildingWheels.md
5. **Version changes** → Update CHANGELOG.md

Keep documentation:
- **Accurate** - Update when code changes
- **Concise** - Focus on what users/developers need to know
- **Current** - Remove outdated information
- **Organized** - One clear purpose per document
