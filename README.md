# BENPY

[![CI](https://github.com/markobud/benpy/actions/workflows/ci.yml/badge.svg)](https://github.com/markobud/benpy/actions/workflows/ci.yml)

A Python wrapper for [Bensolve](http://www.bensolve.org/) **v2.1.0**.  

**New in v2.1.0:** In-memory interface for 2-3x faster solving without file I/O! See [In-Memory Interface](doc/InMemoryInterface.md) for details.

---

## ✨ Key Features

- **Fast in-memory interface** - Solve problems directly from numpy arrays (no temporary files)
- **Direct structure access** - Access problem and solution data in memory
- **Full bensolve 2.1.0 support** - Updated to latest bensolve API
- **Python-friendly API** - Works seamlessly with numpy, scipy, and pandas
- **GIL release for responsiveness** - Long-running solves release Python's GIL for better I/O concurrency

---

## 🚀 Quick Start

```python
import numpy as np
import benpy

# Define a bi-objective linear program
B = np.array([[2.0, 1.0],    # Constraint matrix
              [1.0, 2.0]])
P = np.array([[1.0, 0.0],    # Objective matrix
              [0.0, 1.0]])
b = np.array([4.0, 4.0])     # Upper bounds

# Solve directly from arrays (fast, no files!)
sol = benpy.solve_direct(B, P, b=b, opt_dir=1)

print(f"Found {len(sol.Primal.vertex_value)} efficient points")
```

See [In-Memory Interface Documentation](doc/InMemoryInterface.md) for more examples.

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

## 📚 Documentation

- **[In-Memory Interface](doc/InMemoryInterface.md)** - Fast array-based interface
- **[Threading Safety](doc/ThreadingSafety.md)** - GIL release and threading considerations
- **[Memory Management](doc/MemoryManagement.md)** - Memory ownership patterns
- **[Ownership Patterns](doc/OwnershipPatterns.md)** - Developer guide for contributors

---

## 🏠 Built With
- **[setuptools](https://pypi.python.org/pypi/setuptools)** – Used for building the package.
- **[Bensolve](http://www.bensolve.org/)** – Bensolve v2.1.0 library for VLP/MOLP solving, included in this repository.
- **[PTable](https://pypi.python.org/pypi/PTable/0.9.0)** – Used for pretty-printing results.

---

## 🐛 Issues
`benpy` depends on `bensolve` for computations, so any issues in `bensolve` will also affect `benpy`.  
Please refer to the [original Bensolve software](http://www.bensolve.org/) for more details.

---

## 📂 Versioning
We use [Semantic Versioning (SemVer)](http://semver.org/) for versioning.  
For available versions, see the [tags on this repository](https://github.com/markobud/benpy/releases).

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
- Thanks to **Damien Vintache** for the initial package version.
- Special thanks to the **Bensolve** developers for their work.

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