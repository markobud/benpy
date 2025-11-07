from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy
import sys


# Platform-specific configuration
if sys.platform == 'win32':
    # Windows/MSVC configuration
    libraries = ['glpk']  # No 'm' library on Windows (math is built into MSVC)
    extra_compile_args = ['/O2']  # MSVC optimization flag
else:
    # Unix-like systems (Linux, macOS)
    libraries = ['glpk', 'm']
    extra_compile_args = ['-std=c99', '-O3']

ext = Extension(name="benpy",
                sources=["src/benpy.pyx",
                        "src/bensolve-2.1.0/bslv_vlp.c",
                        "src/bensolve-2.1.0/bslv_algs.c",
                        "src/bensolve-2.1.0/bslv_lists.c",
                        "src/bensolve-2.1.0/bslv_poly.c",
                        "src/bensolve-2.1.0/bslv_lp.c"
                        ],
                include_dirs=[numpy.get_include(), 'src'],
                libraries=libraries,
                extra_compile_args=extra_compile_args
                )
setup(
    ext_modules=cythonize([ext], include_path=['src'])
)
