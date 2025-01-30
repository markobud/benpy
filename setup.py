from setuptools import setup, find_packages, Extension
import os, numpy
from warnings import warn
from Cython.Build import cythonize, build_ext

# TODO: Build without numpy or cython!
""" try:
    from Cython.Build import cythonize
except ImportError:
    warn("Prior cython install is required")

try:
    import numpy
except ImportError:
    warn("Prior numpy install is required") """

ext = Extension("benpy", sources=["src/benpy.pyx",
                                  "src/bensolve-mod/bslv_main.c",
                                  "src/bensolve-mod/bslv_vlp.c",
                                  "src/bensolve-mod/bslv_algs.c",
                                  "src/bensolve-mod/bslv_lists.c",
                                  "src/bensolve-mod/bslv_poly.c",
                                  "src/bensolve-mod/bslv_lp.c"
                                  ],
                #include_dirs=[numpy.get_include(), os.environ['CONDA_PREFIX'] + "/include"],
                include_dirs=[numpy.get_include()],
                libraries=['glpk', 'm'],
                extra_compile_args=['-std=c99', '-O3']
                )

setup(
    name="benpy",
    version='1.0',
    description='Python Benpy Utility',
    author='Marko Budinich',
    author_email='marko.budinich@gmail.com',
    url='https://github.com/markobud/benpy',
    license='GPLv3',
    long_description='Benpy',
    ext_modules=cythonize([ext]),
    platforms='linux, OSX', 
    install_requires=['numpy', 'prettytable', 'scipy'],
    packages=find_packages(),
    cmdclass = {
        "build_ext": build_ext
      }
)
