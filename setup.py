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
extra_compile_args = []  # Will be set per platform

# macOS-specific configuration
if platform.system() == 'Darwin':
    # Try pkg-config first (most reliable for getting correct flags)
    try:
        pkg_config_cflags = subprocess.check_output(
            ['pkg-config', '--cflags', 'glpk'],
            text=True,
            stderr=subprocess.DEVNULL
        ).strip()
        pkg_config_libs = subprocess.check_output(
            ['pkg-config', '--libs-only-L', 'glpk'],
            text=True,
            stderr=subprocess.DEVNULL
        ).strip()
        
        # Extract include dirs from pkg-config
        for flag in pkg_config_cflags.split():
            if flag.startswith('-I'):
                include_dirs.append(flag[2:])
        
        # Extract library dirs from pkg-config
        for flag in pkg_config_libs.split():
            if flag.startswith('-L'):
                lib_dir = flag[2:]
                library_dirs.append(lib_dir)
                extra_link_args.append(f'-Wl,-rpath,{lib_dir}')
        
        print(f"Using pkg-config for GLPK: includes={include_dirs}, libs={library_dirs}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        # Fallback to brew or environment variables if pkg-config not available
        print("pkg-config not available, using brew/environment variables")
        
        # Try to get brew prefix from environment or by calling brew
        brew_prefix = os.environ.get('HOMEBREW_PREFIX')
        if not brew_prefix:
            try:
                # Get the brew prefix for the current architecture
                brew_prefix = subprocess.check_output(['brew', '--prefix'], text=True).strip()
            except (subprocess.CalledProcessError, FileNotFoundError):
                # Try architecture-specific defaults
                import platform as plat
                machine = plat.machine()
                if machine == 'arm64':
                    brew_prefix = '/opt/homebrew'
                else:
                    brew_prefix = '/usr/local'
        
        print(f"Using brew prefix: {brew_prefix}")
        
        # Check if CFLAGS/LDFLAGS are set (e.g., by cibuildwheel)
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
            lib_dir = os.path.join(brew_prefix, 'lib')
            library_dirs.append(lib_dir)
            extra_link_args.append(f'-Wl,-rpath,{lib_dir}')
    
    # Add rpath for delocate-repaired wheels (where dylibs are bundled)
    extra_link_args.append('-Wl,-rpath,@loader_path/../.dylibs')
    
    # Use GCC-style flags for macOS
    extra_compile_args = ['-std=c99', '-O3']

# Windows-specific configuration (MSVC)
elif platform.system() == 'Windows':
    # Use vcpkg-installed GLPK paths from environment variables
    glpk_include = os.environ.get('GLPK_INCLUDE_DIR', 'C:\\vcpkg\\installed\\x64-windows\\include')
    glpk_lib = os.environ.get('GLPK_LIBRARY_DIR', 'C:\\vcpkg\\installed\\x64-windows\\lib')
    
    include_dirs.append(glpk_include)
    library_dirs.append(glpk_lib)
    
    # Use MSVC-friendly compile flags
    extra_compile_args = ['/EHsc', '/O2']  # Exception handling and optimization
    
    print(f"Windows MSVC build: GLPK include={glpk_include}, lib={glpk_lib}")
else:
    # Default for other platforms
    extra_compile_args = ['-std=c99', '-O3']

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
                extra_compile_args=extra_compile_args,
                extra_link_args=extra_link_args
                )
setup(
    ext_modules=cythonize([ext], include_path=['src'])
)
