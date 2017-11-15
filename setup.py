from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy
import os


ext = Extension("benpy",sources=["benpy.pyx",
                                    "bensolve-mod/bslv_main.c",
                                    "bensolve-mod/bslv_vlp.c",
                                    "bensolve-mod/bslv_algs.c",
                                    "bensolve-mod/bslv_lists.c",
                                    "bensolve-mod/bslv_poly.c",
                                    "bensolve-mod/bslv_lp.c"
                                    ],
                include_dirs=[numpy.get_include(), os.environ['CONDA_PREFIX'] + "/include"],
                libraries=['glpk','m'],
			    extra_compile_args=['-std=c99','-O3']
               )

setup(
    name="benpy",
    version='1.0',
    description='Python Benpy Utility',
    author='Marko Budinich',
    author_email='marko.budinich@ls2n.fr',
    url='https://gitlab.univ-nantes.fr/mbudinich/benpy',
    license='GPLv3',
    long_description='Benpy',
    platforms='linux, OSX',
    ext_modules = cythonize([ext])
)
