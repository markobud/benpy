# BENPY

A python wrapper of [Bensolve](http://www.bensolve.org/)
Internally, we use a modified version, which is available (here)[https://gitlab.univ-nantes.fr/mbudinich/bensolve-mod], and under the folder `bensolve-mod`

## Getting Started

### Prerequisites

bensolve-mod uses (glpk)[https://www.gnu.org/software/glpk/], which has to be installed prior to benpy. Please follow the site instructions to install


### Installing

BENPY uses distutils to install. Run


```
pip install .
```


## Running the tests

Some test cases are provided in `src/test` folder. From benpy folder

```
python src/tests/TestVLP.py
```


## Built With

* [setuptools](https://pypi.python.org/pypi/setuptools) - used to generate a python egg or wheel
* [bensolve-mod](https://gitlab.univ-nantes.fr/mbudinich/bensolve-mod) - a modified version of [bensolve](http://www.bensolve.org/)
* [PTable](https://pypi.python.org/pypi/PTable/0.9.0)  - used to pretty print results
## Contributing

Please read [CONTRIBUTING.md](https://gitlab.univ-nantes.fr/mbudinich/benpy/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://gitlab.univ-nantes.fr/mbudinich/benpy/tags).

## Authors

* **Marko Budinich** - *Initial work* - [Benpy](https://gitlab.univ-nantes.fr/mbudinich/benpy)

See also the list of [contributors](https://gitlab.univ-nantes.fr/mbudinich/benpy/contributors) who participated in this project.

## License

This project is licensed under the GNU GPLv3 License - see the [LICENSE.md](https://gitlab.univ-nantes.fr/mbudinich/benpy/blob/license/LICENSE.md) file for details

## Acknowledgments

* bensolve code
* Damian for first version
