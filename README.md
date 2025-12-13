# BENPY

[![CI](https://github.com/markobud/benpy/actions/workflows/ci.yml/badge.svg)](https://github.com/markobud/benpy/actions/workflows/ci.yml)
[![PyPI version](https://badge.fury.io/py/benpy.svg)](https://badge.fury.io/py/benpy)
[![Python Version](https://img.shields.io/badge/python-3.10%20%7C%203.11%20%7C%203.12-blue)](https://www.python.org/)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CodeQL](https://github.com/markobud/benpy/actions/workflows/codeql.yml/badge.svg)](https://github.com/markobud/benpy/actions/workflows/codeql.yml)

A high-performance Python wrapper for [Bensolve](http://www.bensolve.org/) **v2.1.0** - solve Vector Linear Programs (VLP) and Multi-Objective Linear Programs (MOLP) with ease.

**🎯 New in v2.1.0:** Fast array-based interface for 2-3x faster solving! See [In-Memory Interface](doc/InMemoryInterface.md) for details.

---

## 📖 Table of Contents

- [What is VLP/MOLP?](#-what-is-vlpmolp)
- [Key Features](#-key-features)
- [Quick Start](#-quick-start)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Installing benpy](#-installing-benpy)
- [Running Examples](#-running-examples)
- [Migration Guide](#-migration-guide)
- [Documentation](#-documentation)
- [Performance](#-performance)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [Citation](#-citation)
- [Built With](#-built-with)
- [Issues](#-issues)
- [Versioning](#-versioning)
- [Authors](#-authors)
- [License](#-license)
- [Acknowledgments](#-acknowledgments)
- [Appendix: Installing GLPK](#-annex-installing-glpk)

---

## 🎓 What is VLP/MOLP?

**Vector Linear Programming (VLP)** and **Multi-Objective Linear Programming (MOLP)** are optimization techniques for solving problems with multiple, often conflicting objectives.

Unlike traditional linear programming that optimizes a single objective, VLP/MOLP finds the **Pareto frontier** - the set of all solutions where improving one objective would worsen another. This is crucial for real-world applications like:

- **Portfolio optimization**: Maximizing returns while minimizing risk
- **Engineering design**: Balancing cost, performance, and reliability
- **Resource allocation**: Optimizing multiple competing goals simultaneously
- **Supply chain**: Minimizing cost while maximizing service quality

**benpy** makes these advanced optimization techniques accessible through a simple, Pythonic interface powered by the robust [Bensolve](http://www.bensolve.org/) solver.

**Example:** A bi-objective problem might be:
```
Minimize both cost AND weight
Subject to: strength constraints, material availability, etc.
```

benpy finds all **efficient solutions** (Pareto optimal points) where you can't improve one objective without worsening the other.

---

## ✨ Key Features

- **Fast array-based interface** - Solve problems directly from numpy arrays (no temporary files)
- **Direct structure access** - Access problem and solution data in memory
- **Full bensolve 2.1.0 support** - Updated to latest bensolve API
- **Python-friendly API** - Works seamlessly with numpy, scipy, and pandas
- **GIL release for responsiveness** - Long-running solves release Python's GIL for better I/O concurrency

---

## 🚀 Quick Start

Get started with benpy in just a few lines:

```python
import numpy as np
import benpy

# Define a bi-objective linear program (MOLP)
# Minimize both objectives: [x1, x2] 
# Subject to: 2*x1 + x2 <= 4
#             x1 + 2*x2 <= 4
#             x1, x2 >= 0

B = np.array([[2.0, 1.0],    # Constraint matrix (m × n)
              [1.0, 2.0]])
P = np.array([[1.0, 0.0],    # Objective matrix (q × n)
              [0.0, 1.0]])
b = np.array([4.0, 4.0])     # Upper bounds on constraints
l = np.array([0.0, 0.0])     # Lower bounds on variables

# Solve directly from arrays (fast!)
sol = benpy.solve(B, P, b=b, l=l, opt_dir=1)

# Access results
print(f"Status: {sol.status}")
print(f"Found {len(sol.Primal.vertex_value)} efficient points")

# Print Pareto-optimal solutions
print("\nEfficient solutions (objective space):")
for i, vertex in enumerate(sol.Primal.vertex_value):
    print(f"  Point {i+1}: {vertex}")
```

**Expected Output:**
```
Status: VLP_OPTIMAL
Found 3 efficient points

Efficient solutions (objective space):
  Point 1: [0. 0.]
  Point 2: [2. 0.]
  Point 3: [0. 2.]
```

See [In-Memory Interface Documentation](doc/InMemoryInterface.md) for more examples and [notebooks/](notebooks/) for interactive tutorials.

---

## 🚀 Getting Started

### **Prerequisites**
`benpy` depends on **GLPK** ([GNU Linear Programming Kit](https://www.gnu.org/software/glpk/)), which must be installed before installing `benpy`.  
See the **Installing GLPK** section below for platform-specific installation instructions.

---

## 🛠 Installing `benpy`

### **Using `pip` (Recommended)**
```sh
pip install benpy
```

### **From a Cloned Repository**
```sh
git clone https://github.com/markobud/benpy.git
cd benpy
pip install .
```

### **Installing the Development Version**
```sh
pip install git+https://github.com/markobud/benpy@development
```

---

## 📌 Running Examples

Example scripts are provided in the `src/examples/` folder.  
To run an example from the cloned `benpy` repository:
```sh
python src/examples/TestVLP.py
```
More examples are available in `src/examples/bensolve_examples.py`.

If you installed `benpy` using `pip`, you can locate the `examples` folder with the following:
```python
import os
import benpy

example_dir = os.path.join(os.path.dirname(benpy.__file__), "examples")
print(f"Examples are located at: {example_dir}")
```

---

## 🔄 Migration Guide

### Upgrading from benpy 1.0.x to 2.1.0

**✅ Good news:** benpy 2.1.0 is fully backward compatible! Your existing code will continue to work without changes.

> 💡 **Recommendation:** Migrate to the new `solve()` API for 2-3x better performance.

#### What's New
- **Faster solving**: New `solve()` function works directly with arrays (2-3x faster)
- **No temporary files**: Solves problems in memory without creating temp files
- **Enhanced solutions**: Solution objects now include additional status and metadata

#### Recommended Migration

**Old way (still works, but slower):**
```python
from benpy import vlpProblem, solve_legacy

vlp = vlpProblem()
vlp.B = np.array([[2.0, 1.0], [1.0, 2.0]])
vlp.P = np.array([[1.0, 0.0], [0.0, 1.0]])
vlp.b = [4.0, 4.0]
vlp.l = [0.0, 0.0]

sol = solve_legacy(vlp)  # Deprecated: writes to temp file
```

**New way (recommended for better performance):**
```python
from benpy import solve

B = np.array([[2.0, 1.0], [1.0, 2.0]])
P = np.array([[1.0, 0.0], [0.0, 1.0]])
b = np.array([4.0, 4.0])
l = np.array([0.0, 0.0])

sol = solve(B, P, b=b, l=l, opt_dir=1)  # Fast: no temp files
```

**Key differences:**
- `solve()` takes numpy arrays directly as function arguments
- No need to create a `vlpProblem` object
- `opt_dir` parameter (1 for minimize, -1 for maximize) is passed explicitly
- Returns the same `vlpSolution` object with additional status information

#### New Solution Attributes

Solutions now include helpful metadata:
```python
sol = solve(B, P, b=b, opt_dir=1)

print(sol.status)                # "optimal", "infeasible", etc.
print(sol.num_vertices_upper)    # Number of upper image vertices
print(sol.num_vertices_lower)    # Number of lower image vertices
```

See the [CHANGELOG](CHANGELOG.md) for complete migration details.

---

## 📚 Documentation

### User Documentation
- **[In-Memory Interface](doc/InMemoryInterface.md)** - Fast array-based interface (recommended)
- **[Threading Safety](doc/ThreadingSafety.md)** - GIL release and threading considerations
- **[Jupyter Notebooks](notebooks/)** - Interactive examples demonstrating various problem types

### Developer Documentation
- **[Memory Management](doc/MemoryManagement.md)** - Memory ownership patterns
- **[Ownership Patterns](doc/OwnershipPatterns.md)** - Developer guide for contributors
- **[Cross-Platform Compilation](doc/CrossPlatformCompilation.md)** - Building on different platforms
- **[CI/CD Documentation](doc/CI_CD_Documentation.md)** - Continuous integration pipeline

### Additional Resources
- **[CHANGELOG.md](CHANGELOG.md)** - Detailed version history
- **[Test Suite](tests/README.md)** - Comprehensive test documentation

---

## ⚡ Performance

benpy 2.1.0 introduces significant performance improvements through its in-memory interface:

| Method | Implementation | Typical Speed | Use Case |
|--------|---------------|---------------|----------|
| `solve()` | Direct array-based (in-memory) | **Baseline** | ✅ Recommended for all new code |
| `solve_legacy()` | File-based (temp files) | 2-3x slower | Legacy code compatibility |

**Benchmark Example** (2 objectives, 100 constraints, 50 variables):
- `solve()`: ~50ms
- `solve_legacy()`: ~150ms

**Performance Tips:**
1. Use `solve()` instead of `solve_legacy()` for best performance
2. Pre-allocate numpy arrays with correct dtype (`np.float64`)
3. For batch solving, consider parallel execution (benpy releases the GIL)
4. Use sparse matrices (scipy.sparse) for large problems

See [In-Memory Interface](doc/InMemoryInterface.md) for detailed performance analysis.

---

## 🔧 Troubleshooting

### Common Issues

#### ImportError: cannot import name 'benpy'
**Solution:** Ensure GLPK is installed before installing benpy. See [Installing GLPK](#-annex-installing-glpk).

```bash
# Verify GLPK installation
glpsol --version

# Reinstall benpy
pip uninstall benpy
pip install benpy --no-cache-dir
```

#### Compilation errors on Windows
**Solution:** Use MSYS2 with MinGW-w64. Ensure environment variables are set:

```bash
export PATH="/mingw64/bin:$PATH"
export CFLAGS="-I/mingw64/include"
export LDFLAGS="-L/mingw64/lib"
```

See [Windows installation guide](#-windows-msys2--mingw) for details.

#### "VLP_INFEASIBLE" status
**Problem:** No feasible solution exists for the given constraints.

**Solution:** Check your constraint matrices:
- Ensure `B`, `a`, `b`, `l`, `s` are consistent
- Verify bounds don't contradict constraints (e.g., `a > b` for the same constraint)
- Try relaxing tight constraints

#### Slow performance
**Solution:** Make sure you're using the new `solve()` method, not `solve_legacy()`:

```python
# Fast (recommended)
sol = benpy.solve(B, P, b=b, opt_dir=1)

# Slow (deprecated)
from benpy import vlpProblem, solve_legacy
vlp = vlpProblem()
vlp.B = B
vlp.P = P
vlp.b = b
sol = solve_legacy(vlp)  # 2-3x slower
```

### Getting Help

- **GitHub Issues**: [Report bugs or request features](https://github.com/markobud/benpy/issues)
- **Bensolve Documentation**: [http://www.bensolve.org/](http://www.bensolve.org/)
- **Examples**: Check [src/examples/](src/examples/) and [notebooks/](notebooks/)

---

## 🤝 Contributing

Contributions are welcome! benpy is an open-source project that benefits from community involvement.

### Ways to Contribute
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📝 Improve documentation
- 🧪 Add test cases
- 🔧 Submit pull requests

### Development Setup

```bash
# Clone the repository
git clone https://github.com/markobud/benpy.git
cd benpy

# Install GLPK (see platform-specific instructions below)

# Install in development mode
pip install -e .

# Run tests
pytest

# Run linters
flake8 src/benpy.pyx --max-line-length=120
cython-lint src/benpy.pyx
```

### Code Standards
- Follow PEP 8 for Python code
- Add tests for new features
- Update documentation for API changes
- Ensure all tests pass before submitting PRs

See [Ownership Patterns](doc/OwnershipPatterns.md) for developer guidelines.

---

## 📚 Citation

If you use benpy in academic research, please cite:

**Software Citation:**
```bibtex
@software{benpy,
  author = {Budinich, Marko and Vintache, Damien},
  title = {benpy: A Python wrapper for Bensolve},
  year = {2025},
  url = {https://github.com/markobud/benpy},
  version = {2.1.0}
}
```

**Bensolve Algorithm:**
```bibtex
@software{bensolve,
  author = {Löhne, Andreas and Weißing, Benjamin},
  title = {Bensolve - A Free VLP Solver},
  year = {2016},
  url = {http://www.bensolve.org/}
}
```

For the underlying algorithms and theory, please refer to the publications listed on the [Bensolve website](http://www.bensolve.org/).

---

## 🏠 Built With

### Core Dependencies
- **[Bensolve v2.1.0](http://www.bensolve.org/)** – The underlying VLP/MOLP solver (included in repository)
- **[GLPK](https://www.gnu.org/software/glpk/)** – GNU Linear Programming Kit (system dependency)
- **[Cython](https://cython.org/)** – For high-performance C extension module generation
- **[NumPy](https://numpy.org/)** – For numerical array operations
- **[SciPy](https://scipy.org/)** – For sparse matrix support

### Build & Development Tools
- **[setuptools](https://pypi.python.org/pypi/setuptools)** – Package building and distribution
- **[pytest](https://pytest.org/)** – Testing framework
- **[cibuildwheel](https://cibuildwheel.readthedocs.io/)** – Multi-platform wheel building
- **[PrettyTable](https://pypi.python.org/pypi/PTable/)** – Pretty-printing solver results

### CI/CD
- **[GitHub Actions](https://github.com/features/actions)** – Automated testing and deployment
- **[CodeQL](https://codeql.github.com/)** – Security analysis

---

## 🐛 Issues & Support

### Reporting Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/markobud/benpy/issues) on GitHub.

**Before reporting:**
1. Check [existing issues](https://github.com/markobud/benpy/issues) to avoid duplicates
2. Review the [Troubleshooting](#-troubleshooting) section
3. Ensure you're using a supported Python version (3.10, 3.11, or 3.12)

**When reporting, please include:**
- benpy version (`python -c "import benpy; print(benpy.__version__)"`)
- Python version (`python --version`)
- Operating system and version
- Minimal code example that reproduces the issue
- Full error traceback

### Known Limitations

**Bensolve Dependency:** `benpy` wraps the Bensolve C library for computations. Any limitations or bugs in Bensolve will affect benpy. For Bensolve-specific issues, please refer to the [Bensolve documentation](http://www.bensolve.org/).

**Platform Support:**
- ✅ Linux (Ubuntu, Debian, CentOS, etc.)
- ✅ macOS (Intel and Apple Silicon)
- ✅ Windows (via MSYS2/MinGW)
- ❌ WebAssembly/Pyodide (not supported due to native dependencies)

---

## 📂 Versioning

We use [Semantic Versioning (SemVer)](http://semver.org/) for versioning.

**Current Version:** 2.1.0 (Development)  
**Latest Stable Release on PyPI:** [1.0.3](https://pypi.org/project/benpy/)

> ⚠️ **Note:** Version 2.1.0 with the new in-memory interface is currently in development.  
> To use v2.1.0 features, install from the development branch:
> ```bash
> pip install git+https://github.com/markobud/benpy@development
> ```

**Version History:**
- **2.1.0** (In Development) - Bensolve 2.1.0 integration, in-memory interface, GIL release
- **1.0.3** (Latest on PyPI) - Renamed examples folder, improved distribution
- **1.0.2** - Added MANIFEST.in for package building
- **1.0.1** - Modern packaging with pyproject.toml

For detailed changes, see [CHANGELOG.md](CHANGELOG.md).  
For all releases, see [GitHub Releases](https://github.com/markobud/benpy/releases).

---

## 👨‍💻 Authors
- **Marko Budinich** – *Initial work* – [Benpy Legacy Code](https://gitlab.univ-nantes.fr/mbudinich/benpy)
- **Damien Vintache** – *Initial work* – [Benpy Legacy Code](https://gitlab.univ-nantes.fr/mbudinich/benpy)

---

## 📝 License
This project is licensed under the **GNU GPLv3 License**.  
See the [LICENSE.md](https://github.com/markobud/benpy/blob/master/LICENSE.md) file for details.

---

## 🎉 Acknowledgments

- **Damien Vintache** – For creating the initial benpy package version
- **Andreas Löhne & Benjamin Weißing** – For developing Bensolve
- **The Bensolve team** – For their continued work on VLP/MOLP algorithms
- **GLPK developers** – For the GNU Linear Programming Kit
- **Contributors** – Everyone who has contributed code, documentation, and bug reports

### Related Projects

- **[Bensolve](http://www.bensolve.org/)** – The underlying VLP/MOLP solver
- **[bensolve-mod](https://gitlab.univ-nantes.fr/mbudinich/bensolve-mod)** – Modified Bensolve fork (legacy)
- **[GLPK](https://www.gnu.org/software/glpk/)** – Linear programming solver used by Bensolve

---

# 📚 Annex: Installing GLPK

These installation methods have been tested by some users but may vary by system.  
For official instructions, please refer to the [GLPK documentation](https://www.gnu.org/software/glpk/).

## 🐧 Linux (Debian/Ubuntu)
```sh
sudo apt update && sudo apt install -y glpk-utils libglpk-dev

# Set environment variables
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib"
export PATH="/usr/bin:$PATH"

# To make these changes permanent, add them to ~/.bashrc
echo 'export CFLAGS="-I/usr/include"' >> ~/.bashrc
echo 'export LDFLAGS="-L/usr/lib"' >> ~/.bashrc
echo 'export PATH="/usr/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 🍏 macOS (Homebrew)
```sh
brew install glpk

# Set environment variables (needed for compilation)
export CFLAGS="-I$(brew --prefix glpk)/include"
export LDFLAGS="-L$(brew --prefix glpk)/lib"
export PATH="$(brew --prefix glpk)/bin:$PATH"

# To make these changes permanent, add them to ~/.zshrc
echo 'export CFLAGS="-I$(brew --prefix glpk)/include"' >> ~/.zshrc
echo 'export LDFLAGS="-L$(brew --prefix glpk)/lib"' >> ~/.zshrc
echo 'export PATH="$(brew --prefix glpk)/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

---

## 🖥 Windows (MSYS2 / MinGW)

### **1⃣ Install MSYS2**
- Download MSYS2: [https://www.msys2.org](https://www.msys2.org/)
- Open the **MSYS2 UCRT64 Terminal**.

### **2⃣ Install GLPK**
```sh
pacman -S mingw-w64-ucrt-x86_64-glpk
```

### **3⃣ Set Environment Variables**
```sh
export CFLAGS="-I/mingw64/include"
export LDFLAGS="-L/mingw64/lib"
export PATH="/mingw64/bin:$PATH"

# To make these changes permanent, add them to ~/.bashrc
echo 'export CFLAGS="-I/mingw64/include"' >> ~/.bashrc
echo 'export LDFLAGS="-L/mingw64/lib"' >> ~/.bashrc
echo 'export PATH="/mingw64/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

---

## 🎯 Final Notes
- If you encounter any issues, refer to the **GLPK official documentation**: [https://www.gnu.org/software/glpk/](https://www.gnu.org/software/glpk/)
- Ensure that `glpsol --version` outputs a valid version after installation.