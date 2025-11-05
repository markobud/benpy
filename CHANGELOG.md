# Change Log

## [Unreleased]

### Added
- GIL (Global Interpreter Lock) release during long-running solve operations (phase0, phase1, phase2)
- Threading support with comprehensive documentation in THREADING.md
- Threading test suite (src/examples/test_threading.py)
- Thread safety guidelines and examples in README.md

### Changed
- Updated benpy.pyx to release GIL during phase computations using `with nogil:` blocks
- Added `nogil` declarations to C function signatures for phase functions
- Enhanced docstrings for `solve()`, `vlpProblem`, and `_csolve()` with threading notes

### Notes
- GIL is released during computation, allowing other Python threads to run
- Bensolve library uses global state - users must use threading.Lock for concurrent solve calls
- See THREADING.md for detailed threading guidelines and best practices

## [1.0.1] - 2026-02-01

This release updates the installation method and replace a deprecated function used in the example script. 

### Added
- pyproject.toml
- .devcontainer for easier development 
- CHANGELOG.md for tracking changes

### Changed
- setup.py

## [1.0.2] - 2026-03-14

This release adds MANIFEST.in an add changes to prepare the repo for PyPi distribution. 

### Added
- MANIFEST.in for build the package

## [1.0.3] - 2026-03-16

This release renames the `tests` folder to `examples` and includes them in the dist files. Also uptades the Readme for the release.

### Changed
- MANIFEST.in to include the examples
- README.md for improved install instructions
