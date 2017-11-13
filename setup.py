from distutils.core import setup, Extension
from Cython.Build import cythonize
import numpy

ext = Extension("benpy", sources=["benpy.pyx",
                                  "bensolve-mod/bslv_main.c",
                                  "bensolve-mod/bslv_vlp.c",
                                  "bensolve-mod/bslv_algs.c",
                                  "bensolve-mod/bslv_lists.c",
                                  "bensolve-mod/bslv_poly.c",
                                  "bensolve-mod/bslv_lp.c"
                                  ],
                libraries=['glpk', 'm'],
                extra_compile_args=['-std=c99', '-O3']
                )
setup(
    name="benpy",
    ext_modules=cythonize([ext]),
    include_dirs=[numpy.get_include()]
)
