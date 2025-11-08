from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy
import platform
import os
import subprocess


# Determine platform-specific libraries
libraries = ['glpk']
if platform.system() != 'Windows':
    libraries.append('m')  # Math library not needed on Windows

# Get GLPK paths from environment or brew on macOS
include_dirs = [numpy.get_include(), 'src']
library_dirs = []
extra_link_args = []

# macOS-specific configuration
if platform.system() == 'Darwin':
    # Try to get brew prefix from environment or by calling brew
    brew_prefix = os.environ.get('HOMEBREW_PREFIX')
    if not brew_prefix:
        try:
            brew_prefix = subprocess.check_output(['brew', '--prefix'], text=True).strip()
        except (subprocess.CalledProcessError, FileNotFoundError):
            brew_prefix = '/usr/local'  # fallback
    
    # Check if CFLAGS/LDFLAGS are set (e.g., by cibuildwheel)
    # If set, extract paths from them; otherwise use brew prefix
    cflags = os.environ.get('CFLAGS', '')
    ldflags = os.environ.get('LDFLAGS', '')
    
    # Extract include dirs from CFLAGS
    if '-I' in cflags:
        for flag in cflags.split():
            if flag.startswith('-I'):
                include_dirs.append(flag[2:])
    else:
        include_dirs.append(os.path.join(brew_prefix, 'include'))
    
    # Extract library dirs from LDFLAGS
    if '-L' in ldflags:
        for flag in ldflags.split():
            if flag.startswith('-L'):
                lib_dir = flag[2:]
                library_dirs.append(lib_dir)
                # Add rpath for each library dir found in LDFLAGS
                extra_link_args.append(f'-Wl,-rpath,{lib_dir}')
    else:
        library_dirs.append(os.path.join(brew_prefix, 'lib'))
        extra_link_args.append(f'-Wl,-rpath,{os.path.join(brew_prefix, "lib")}')
    
    # Add rpath for delocate-repaired wheels (where dylibs are bundled)
    extra_link_args.append('-Wl,-rpath,@loader_path/../.dylibs')

ext = Extension(name="benpy",
                sources=["src/benpy.pyx",
                        "src/bensolve-2.1.0/bslv_vlp.c",
                        "src/bensolve-2.1.0/bslv_algs.c",
                        "src/bensolve-2.1.0/bslv_lists.c",
                        "src/bensolve-2.1.0/bslv_poly.c",
                        "src/bensolve-2.1.0/bslv_lp.c"
                        ],
                include_dirs=include_dirs,
                library_dirs=library_dirs,
                libraries=libraries,
                extra_compile_args=['-std=c99', '-O3'],
                extra_link_args=extra_link_args
                )
setup(
    ext_modules=cythonize([ext], include_path=['src'])
)
