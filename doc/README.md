# benpy Documentation

This directory contains technical documentation for benpy developers and advanced users.

## User Documentation

For general usage, installation instructions, and quick start examples, see the main [README.md](../README.md) in the repository root.

## Technical Documentation

### API Documentation

- **[InMemoryInterface.md](InMemoryInterface.md)** - Complete guide to the in-memory interface
  - `solve_direct()` API reference
  - Direct structure access
  - Performance benchmarks
  - Migration guide from file-based interface

### Developer Guides

- **[MemoryManagement.md](MemoryManagement.md)** - Memory management patterns in benpy
  - bensolve 2.1.0 memory ownership
  - Wrapper memory management
  - Memory leak prevention
  - Technical audit details

- **[OwnershipPatterns.md](OwnershipPatterns.md)** - Developer guide for contributors
  - Memory ownership by component
  - Lifecycle examples
  - Common pitfalls and best practices
  - Testing guidelines

### Safety and Concurrency

- **[ThreadingSafety.md](ThreadingSafety.md)** - Threading behavior and GIL release
  - Thread safety status of bensolve 2.1.0
  - Safe and unsafe usage patterns
  - GIL release implementation details
  - Multiprocessing for parallelism

### Infrastructure

- **[CI_CD_Documentation.md](CI_CD_Documentation.md)** - CI/CD workflow documentation
  - GitHub Actions pipeline overview
  - Platform-specific build configurations
  - Wheel building with cibuildwheel
  - Troubleshooting guide

## Additional Resources

- **Main README**: [../README.md](../README.md)
- **Changelog**: [../CHANGELOG.md](../CHANGELOG.md)
- **License**: [../LICENSE.md](../LICENSE.md)
- **Examples**: [../src/examples/](../src/examples/)
- **Test Suite**: [../tests/README.md](../tests/README.md)
- **Notebooks**: [../notebooks/README.md](../notebooks/README.md)

## Contributing

When adding new documentation:

1. **User-facing features** → Update main README.md
2. **API changes** → Update InMemoryInterface.md or create new API doc
3. **Internal implementation** → Update MemoryManagement.md or OwnershipPatterns.md
4. **Build/CI changes** → Update CI_CD_Documentation.md
5. **Version changes** → Update CHANGELOG.md

Keep documentation:
- **Accurate** - Update when code changes
- **Concise** - Focus on what users/developers need to know
- **Current** - Remove outdated information
- **Organized** - One clear purpose per document
