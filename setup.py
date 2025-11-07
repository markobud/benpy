from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy
import platform


# Determine platform-specific libraries
libraries = ['glpk']
if platform.system() != 'Windows':
    libraries.append('m')  # Math library not needed on Windows

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
                extra_compile_args=['-std=c99', '-O3']
                )
setup(
    ext_modules=cythonize([ext], include_path=['src'])
)
