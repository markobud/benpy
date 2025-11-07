# Change Log

All notable changes to benpy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- Cleaned up repository documentation, removed outdated phase summaries and diagnostic reports

## [2.1.0] - In Development

Major upgrade to bensolve 2.1.0 with new in-memory interface.

### Added
- **In-memory interface**: `solve_direct()` function for 2-3x faster solving without file I/O
- **Direct structure access**: Access problem and solution data directly from memory
- **Property access**: Access problem dimensions, matrices, and solution data via Python properties
- **GIL release**: Long-running solve operations release Python's GIL for better concurrency
- **Threading safety documentation**: Comprehensive guide to thread safety considerations
- **Memory management documentation**: Detailed memory ownership patterns
- **CI/CD pipeline**: GitHub Actions workflow for multi-platform testing
- **Comprehensive test suite**: pytest-based tests with 60+ test cases
- **Example notebooks**: Jupyter notebooks demonstrating various problem types

### Changed
- Updated to bensolve 2.1.0 API (from bensolve-mod)
- Improved memory management with proper cleanup in `__dealloc__` methods
- Enhanced error handling with better exception messages
- Updated README with new quick start examples

### Fixed
- Memory leaks in `_cVlpProblem` and `_cVlpSolution` cleanup
- LP structure cleanup in solve operations
- `solve_direct()` consistency bug for bounded problems
- Objective matrix sign correction for minimization problems

## [1.0.3] - Release date unknown

This release renames the `tests` folder to `examples` and includes them in distribution files.

### Changed
- Renamed `tests` folder to `examples` and include them in distribution files
- Updated MANIFEST.in to include examples
- Improved README installation instructions

## [1.0.2] - Release date unknown

This release adds MANIFEST.in for package building.

### Added
- MANIFEST.in for package building

## [1.0.1] - Release date unknown

This release updates the installation method and replaces a deprecated function used in the example script.

### Added
- pyproject.toml for modern Python packaging
- .devcontainer for easier development
- CHANGELOG.md for tracking changes

### Changed
- Updated setup.py
- Replaced deprecated functions in example scripts
