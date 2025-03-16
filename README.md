# BENPY

A python wrapper of [Bensolve](http://www.bensolve.org/)
Internally, we use a modified version, which is available [here](https://gitlab.univ-nantes.fr/mbudinich/bensolve-mod), and under the folder `bensolve-mod`

## Getting Started

### Prerequisites

bensolve-mod uses [glpk](https://www.gnu.org/software/glpk/), which has to be installed before benpy. Please follow the site instructions to install in your plataform. We will provide some methods for install at the end of this file.


### Installing

`bensolve` uses 

#### Usign pip

```
pip install benpy
```

#### From cloned repo

```
pip install .
```

#### Installing development from repo

```
pip install git+https://github.com/markobud/benpy@development  

```

## Running examples

Some test cases are provided in `src/examples` folder. From the cloned benpy repository:

```
python src/examples/TestVLP.py
```

More examples are available in the `src/examples/bensolve_examples.py`.

If you installed using pip, the following code tells you where to find the `examples` folder:

```python
import os
import benpy

example_dir = os.path.join(os.path.dirname(benpy.__file__), "examples")
print(f"Examples are located at: {example_dir}")
```


## Built With

* [setuptools](https://pypi.python.org/pypi/setuptools) - used to generate the build
* [bensolve-mod](https://gitlab.univ-nantes.fr/mbudinich/bensolve-mod) - a modified version of [bensolve](http://www.bensolve.org/). A copy is included in this repository.
* [PTable](https://pypi.python.org/pypi/PTable/0.9.0)  - used to pretty print results

## Issues

`benpy` relies into `bensolve` code for running calculations, so any issues with `bensolve` will happen forcely in `benpy`. Please, [take a look to the original software](http://www.bensolve.org/) for details.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/markobud/benpy/releases).

## Authors

* **Marko Budinich** - *Initial work* - [Benpy Legacy code](https://gitlab.univ-nantes.fr/mbudinich/benpy)
* **Damien Vintache** - *Initial work* - [Benpy Legacy code](https://gitlab.univ-nantes.fr/mbudinich/benpy)

## License

This project is licensed under the GNU GPLv3 License - see the [LICENSE.md](https://github.com/markobud/benpy/blob/master/LICENSE.md) file for details

## Acknowledgments

* bensolve code
* Damian V. for first package version

## Annex

### Installing glpk

These methods have not fully tested, but worked for some peolple. Please refer to [glpk](https://www.gnu.org/software/glpk/) official documentation for details on how to install.

#### 🐧 Linux (Debian/Ubuntu)
```sh
sudo apt update && sudo apt install -y glpk-utils libglpk-dev

# Set environment variables
export CFLAGS="-I/usr/include"
export LDFLAGS="-L/usr/lib"
export PATH="/usr/bin:$PATH"

# To make these changes permanent, add them to ~/.bashrc
```

#### 🖥 macOS (Homebrew)

```sh
brew install glpk

# Set environment variables (needed for compilation)
export CFLAGS="-I$(brew --prefix glpk)/include"
export LDFLAGS="-L$(brew --prefix glpk)/lib"
export PATH="$(brew --prefix glpk)/bin:$PATH"

# To make these changes permanent, add them to ~/.zshrc
```

#### 🖥 Windows (MSYS2 / MinGW)

On Windows, you need MSYS2 to install GLPK properly.

1️⃣ Install MSYS2
	•	Download MSYS2: https://www.msys2.org
	•	Open the MSYS2 UCRT64 Terminal.

2️⃣ Install GLPK

Run:

```sh
pacman -S mingw-w64-ucrt-x86_64-glpk
```

```sh
export CFLAGS="-I/mingw64/include"
export LDFLAGS="-L/mingw64/lib"
export PATH="/mingw64/bin:$PATH"

# To make these changes permanent, add them to ~/.bashrc
```
