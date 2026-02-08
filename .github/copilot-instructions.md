# Copilot Instructions for benpy

## Project Overview
benpy is a Python wrapper for Bensolve v2.1.0, a software for solving Vector Linear Programs (VLP) and Multi-Objective Linear Programs (MOLP). The project uses Cython to interface with the Bensolve C library.

## Project Structure
- `src/benpy.pyx` - Main Cython module that wraps the C library
- `src/bensolve-2.1.0/` - Bensolve 2.1.0 C library sources (vendored)
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
- The wrapped library is bensolve 2.1.0 from http://www.bensolve.org/
- The library sources are vendored in `src/bensolve-2.1.0/`
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
- Current version: 2.1.0
- Uses Semantic Versioning (SemVer)
- Version is defined in `pyproject.toml`

## License
GNU GPLv3 - Be aware when adding dependencies or code that all contributions must be compatible with this license.

## Getting Help
- Bensolve documentation: http://www.bensolve.org/
- GLPK documentation: https://www.gnu.org/software/glpk/
- Cython documentation: https://cython.readthedocs.io/

## CI/CD and Service Access

### GitHub Actions Workflows
The repository has configured CI/CD workflows that Copilot agents can access:

**Available Workflows:**
1. **CI - Build and Test** (`.github/workflows/ci.yml`)
   - Multi-platform testing (Linux, macOS, Windows)
   - Python 3.9, 3.10, 3.11, 3.12 support
   - Automated GLPK installation
   - Code quality checks (flake8, cython-lint)

2. **CodeQL Security Analysis** (`.github/workflows/codeql.yml`)
   - Python and C/C++ security scanning
   - Weekly automated scans
   - Vulnerability detection and reporting

3. **Dependency Security Scan** (`.github/workflows/dependency-scan.yml`)
   - pip-audit for Python package vulnerabilities
   - Daily automated scans
   - Dependency update tracking

### Accessing Workflow Logs and Results

Copilot agents have access to GitHub Actions through built-in tools:

**For Debugging Build Failures:**
```
# Get AI-powered failure analysis (USE THIS FIRST)
summarize_run_log_failures(owner="markobud", repo="benpy", run_id=12345)

# Get specific job logs if needed
get_job_logs(owner="markobud", repo="benpy", run_id=12345, failed_only=true)
```

**For Security Analysis:**
```
# List security alerts
list_code_scanning_alerts(owner="markobud", repo="benpy", state="open")

# Get specific alert details
get_code_scanning_alert(owner="markobud", repo="benpy", alertNumber=1)
```

**For CI/CD History:**
```
# List recent workflow runs
list_workflow_runs(owner="markobud", repo="benpy", workflow_id="ci.yml")

# Get workflow run details
get_workflow_run(owner="markobud", repo="benpy", run_id=12345)
```

**Detailed Documentation:**
- **GitHub Actions Access Guide**: `.github/GITHUB_ACTIONS_ACCESS.md`
- **External MCP Resources**: `.github/MCP_RESOURCES.md`

### Best Practices for Agents

1. **Always use `summarize_run_log_failures` first** when debugging CI/CD issues
2. **Filter for failed jobs** using `failed_only=true` to reduce noise
3. **Check multiple runs** to identify patterns and trends
4. **Correlate with commits** to understand what changes caused failures
5. **Use platform-specific analysis** for cross-platform build issues

### Workflow Permissions

All workflows are configured with appropriate permissions for agent access:
```yaml
permissions:
  actions: read          # Access workflow runs and logs
  contents: read         # Read repository contents
  security-events: write # Write security scanning results
  pull-requests: read    # Access PR information
```

### Agent-to-Workflow Mapping

- **cicd-agent**: Primary user of GitHub Actions tools for build/test debugging
- **crossplatform-compiler**: Analyzes platform-specific compilation failures
- **testing-agent**: Reviews test results and failure patterns
- **security-agent**: Monitors CodeQL and dependency scan results
- **performance-agent**: Can access timing data from workflow runs
- **dev_base**: Uses CI/CD feedback for development decisions
