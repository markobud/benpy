# Change Log

All notable changes to benpy will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2025-11-07

Major upgrade to bensolve 2.1.0 with new in-memory interface and comprehensive improvements.

This release represents a significant upgrade from benpy 1.0.3, introducing bensolve 2.1.0 integration,
a new high-performance in-memory interface, and extensive cross-platform improvements.

### Added
- **In-memory interface**: New `solve_direct()` function for 2-3x faster solving without file I/O
  - Solves problems directly from numpy arrays without creating temporary files
  - Cleaner, more Pythonic API that works seamlessly with numpy, scipy, and pandas
  - See [In-Memory Interface Documentation](doc/InMemoryInterface.md) for details
- **Direct structure access**: Access problem and solution data directly from memory via Python properties
  - `_cVlpProblem` properties: `m` (constraints), `n` (variables), `q` (objectives), `k` (cone generators)
  - Direct access to constraint matrices, objective matrices, and bounds
- **GIL release**: Long-running solve operations now release Python's GIL for better I/O concurrency
  - Improves responsiveness in multi-threaded applications
  - See [Threading Safety Documentation](doc/ThreadingSafety.md) for usage guidelines
- **Enhanced solution objects**: Solution objects now include additional attributes
  - `status`: Human-readable status string (VLP_OPTIMAL, VLP_INFEASIBLE, etc.)
  - `num_vertices_upper`, `num_vertices_lower`: Vertex counts
  - `Y`, `Z`: Ordering cone generators
  - `eta`, `R`, `H`: Advanced solution components
- **Comprehensive documentation**:
  - [In-Memory Interface](doc/InMemoryInterface.md) - Fast array-based interface guide
  - [Threading Safety](doc/ThreadingSafety.md) - GIL release and thread safety guide
  - [Memory Management](doc/MemoryManagement.md) - Memory ownership patterns
  - [Ownership Patterns](doc/OwnershipPatterns.md) - Developer guide for contributors
- **CI/CD pipeline**: GitHub Actions workflow for multi-platform testing (Linux, macOS, Windows)
- **Comprehensive test suite**: pytest-based tests with 60+ test cases covering various problem types
- **Example notebooks**: Jupyter notebooks demonstrating VLP problem types and usage patterns

### Changed
- **Updated to bensolve 2.1.0 API**: Migrated from bensolve-mod fork to official bensolve 2.1.0
  - All C API calls updated to use new bensolve 2.1.0 function signatures
  - Memory management aligned with bensolve 2.1.0 ownership patterns
- **Improved memory management**: Proper cleanup in `__dealloc__` methods prevents memory leaks
  - Added `vlp_free()` and `sol_free()` calls in destructors
  - Fixed LP structure cleanup in solve operations
- **Enhanced error handling**: Better exception messages with more context
- **Updated examples**: All examples in `src/examples/` updated to demonstrate current best practices
- **Updated README**: Added quick start examples using `solve_direct()` and updated installation instructions
- **Build configuration**: Updated `setup.py` and `pyproject.toml` for bensolve 2.1.0 compilation

### Fixed
- **Windows crash fix**: Resolved fatal crashes on Windows for unbounded and no-vertex problems (ex03, ex04)
  - Fixed control flow issue in `_csolve()` that continued execution after phase0 detected edge cases
  - Added early returns for VLP_UNBOUNDED and VLP_NOVERTEX status, matching original bensolve behavior
  - Re-enabled Windows tests in CI/CD pipeline
  - See `doc/WindowsTestCrashes_RESOLVED.md` for technical details
- **Memory leaks**: Fixed memory leaks in `_cVlpProblem` and `_cVlpSolution` cleanup
- **Solve consistency**: Fixed `solve_direct()` consistency bug for bounded problems
- **Objective matrix signs**: Corrected objective matrix sign handling for minimization problems
- **File handle issues**: Fixed Windows permission errors with temporary file handling in `solve()`

### Migration Guide

**For users upgrading from benpy 1.0.x:**

1. **Version number**: Update your dependency to `benpy>=2.1.0`

2. **New API - No breaking changes**: The existing `solve()` function continues to work as before. The new `solve_direct()` is an optional, faster alternative:
   ```python
   # Old way (still works)
   from benpy import vlpProblem, solve
   vlp = vlpProblem()
   vlp.B = B
   vlp.P = P
   vlp.b = b
   sol = solve(vlp)
   
   # New way (2-3x faster)
   from benpy import solve_direct
   sol = solve_direct(B, P, b=b, opt_dir=1)
   ```

3. **Enhanced solution objects**: Solutions now include additional status information:
   ```python
   sol = solve_direct(B, P, b=b)
   print(sol.status)  # "VLP_OPTIMAL", "VLP_INFEASIBLE", etc.
   print(sol.num_vertices_upper)  # Number of vertices
   ```

4. **Threading considerations**: If using benpy in a multi-threaded application, review the [Threading Safety Documentation](doc/ThreadingSafety.md) for best practices

5. **No changes to problem specification**: All existing problem specifications (B, P, a, b, l, s, Y, Z, c) remain the same

6. **Recommended**: Migrate to `solve_direct()` for better performance, but migration is optional

## [1.0.3]

This release renames the `tests` folder to `examples` and includes them in distribution files.

### Changed
- Renamed `tests` folder to `examples` and include them in distribution files
- Updated MANIFEST.in to include examples
- Improved README installation instructions

## [1.0.2]

This release adds MANIFEST.in for package building.

### Added
- MANIFEST.in for package building

## [1.0.1]

This release updates the installation method and replaces a deprecated function used in the example script.

### Added
- pyproject.toml for modern Python packaging
- .devcontainer for easier development
- CHANGELOG.md for tracking changes

### Changed
- Updated setup.py
- Replaced deprecated functions in example scripts
