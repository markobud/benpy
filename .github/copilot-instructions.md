# Copilot Instructions for benpy

## Project Overview
benpy is a Python wrapper for Bensolve v2.1.0, a software for solving Vector Linear Programs (VLP) and Multi-Objective Linear Programs (MOLP). The project uses Cython to interface with the Bensolve C library.

## Project Structure
- `src/benpy.pyx` - Main Cython module that wraps the C library
- `src/bensolve-2.1.0/` - Bensolve C library sources (v2.1.0)
- `src/examples/` - Example scripts demonstrating usage
- `.devcontainer/` - Development container configuration
- `setup.py` - Build configuration using setuptools and Cython
- `pyproject.toml` - Project metadata and dependencies

## Technology Stack
- **Language**: Python 3.12+ with Cython for C interoperability
- **Build System**: setuptools with Cython.Build
- **Key Dependencies**:
  - GLPK (GNU Linear Programming Kit) - Required system dependency
  - Cython - For compiling .pyx files to C extension modules
  - NumPy - For numerical arrays and matrices
  - SciPy - For sparse matrix operations
  - PrettyTable - For formatted output

## Development Environment

### Prerequisites
GLPK must be installed on the system before building benpy. The library requires:
- `libglpk-dev` (development headers)
- `glpk-utils` (command-line tools)

Environment variables needed for compilation:
```bash
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib"
```

### Building the Project
```bash
pip install -r requirements.txt
pip install .
```

The build process:
1. Cython compiles `benpy.pyx` to C
2. setuptools compiles C sources including Bensolve library files
3. Links against GLPK and math libraries

### Development Container
A devcontainer is configured with:
- Python 3.12 base image (Debian bullseye)
- Pre-installed GLPK dependencies
- VSCode extensions for Cython, C/C++, and TOML editing

## Coding Standards

### Python/Cython Code
- Use Python 3 language level (`#cython: language_level=3`)
- Follow PEP 8 for Python code style
- Use NumPy arrays for numerical data
- Document public APIs with docstrings
- Prefer explicit type declarations in Cython code for performance

### C Code Integration
- The Bensolve C library uses C99 standard (`-std=c99`)
- Optimization level O3 is used for performance
- C headers are in `src/bensolve-2.1.0/bslv_main.h`

### Working with Cython
- Use `cimport` for C-level imports (e.g., `cimport numpy as np`)
- Use `cdef` for C-level function/variable declarations
- Use `ctypedef` for type aliases
- External C declarations go in `cdef extern from` blocks
- Memory management: use `malloc/free` from `libc.stdlib`

## Common Development Tasks

### Adding New VLP Functionality
1. Check the Bensolve C API in `src/bensolve-2.1.0/bslv_main.h`
2. Add C function declarations in Cython `cdef extern` block
3. Create Python-facing wrapper functions
4. Use NumPy arrays for input/output
5. Handle memory management properly (malloc/free)

### Testing Changes
- No formal test suite exists; use example scripts in `src/examples/`
- Run `python src/examples/TestVLP.py` to verify basic functionality
- Check both numerical correctness and memory safety

### Adding Dependencies
- System dependencies: Update `.devcontainer/Dockerfile`
- Python dependencies: Update `pyproject.toml` and `requirements.txt`
- Build dependencies: Update `[build-system]` in `pyproject.toml`

## Important Notes

### Working with the Bensolve Library
- The wrapped library is Bensolve v2.1.0 from http://www.bensolve.org/
- Any bugs in Bensolve will affect benpy

### File I/O
- VLP problems can be written to .vlp files using `vlpProblem.to_vlp_file()`
- Temporary files are used internally (see `tempfile.NamedTemporaryFile`)

### Memory Safety
- Pay attention to C memory management in Cython code
- NumPy arrays must be properly typed for C interop
- Use `free()` for any `malloc()`'d memory

### Performance Considerations
- Cython code is compiled with `-O3` optimization
- Use typed memoryviews for NumPy array access when possible
- Avoid Python-level loops in performance-critical sections

## Versioning
- Current version: 1.0.3
- Uses Semantic Versioning (SemVer)
- Version is defined in `pyproject.toml`

## License
GNU GPLv3 - Be aware when adding dependencies or code that all contributions must be compatible with this license.

## Getting Help
- Bensolve documentation: http://www.bensolve.org/
- GLPK documentation: https://www.gnu.org/software/glpk/
- Cython documentation: https://cython.readthedocs.io/
