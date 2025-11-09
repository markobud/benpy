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

# Windows-specific configuration
elif platform.system() == 'Windows':
    # On Windows, rely on CFLAGS/LDFLAGS environment variables set by cibuildwheel
    # These point to MSYS2/MinGW GLPK installation
    cflags = os.environ.get('CFLAGS', '')
    ldflags = os.environ.get('LDFLAGS', '')
    
    print(f"Windows build with CFLAGS={cflags}, LDFLAGS={ldflags}")
    
    # Extract include dirs from CFLAGS
    if '-I' in cflags:
        for flag in cflags.split():
            if flag.startswith('-I'):
                include_dirs.append(flag[2:])
    else:
        # Fallback to default MSYS2 MinGW64 paths if no CFLAGS set
        include_dirs.append('C:/msys64/mingw64/include')
    
    # Extract library dirs from LDFLAGS
    if '-L' in ldflags:
        for flag in ldflags.split():
            if flag.startswith('-L'):
                library_dirs.append(flag[2:])
    else:
        # Fallback to default MSYS2 MinGW64 paths if no LDFLAGS set
        library_dirs.append('C:/msys64/mingw64/lib')
    
    print(f"Windows GLPK paths: includes={include_dirs}, libs={library_dirs}")

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

# Cython compiler directives to handle Windows/MinGW compatibility
compiler_directives = {
    'language_level': 3,
    'embedsignature': True,
    'c_string_type': 'unicode',  # Use unicode strings
    'c_string_encoding': 'utf8',  # UTF-8 encoding
}

# On Windows AMD64, explicitly set compile_time_env to provide correct SIZEOF_VOID_P
# This prevents Cython from using the wrong value when generating code
compile_time_env = None
if platform.system() == 'Windows':
    import struct
    compile_time_env = {'SIZEOF_VOID_P': struct.calcsize('P')}
    print(f"Set compile_time_env SIZEOF_VOID_P={struct.calcsize('P')} for Windows build")

# Force Cython to generate code that works with the target platform
# by regenerating the C code on each platform rather than using cached/pregenerated code
setup(
    ext_modules=cythonize([ext], include_path=['src'], compiler_directives=compiler_directives, 
                          compile_time_env=compile_time_env, force=True)
)
