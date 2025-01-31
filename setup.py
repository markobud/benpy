from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy


ext = Extension(name="benpy",
                sources=["src/benpy.pyx",
                        "src/bensolve-mod/bslv_main.c",
                        "src/bensolve-mod/bslv_vlp.c",
                        "src/bensolve-mod/bslv_algs.c",
                        "src/bensolve-mod/bslv_lists.c",
                        "src/bensolve-mod/bslv_poly.c",
                        "src/bensolve-mod/bslv_lp.c"
                        ],
                include_dirs=[numpy.get_include()],
                libraries=['glpk', 'm'],
                extra_compile_args=['-std=c99', '-O3']
                )
setup(
    ext_modules=cythonize([ext])
)
