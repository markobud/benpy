from setuptools import setup, Extension
from Cython.Build import cythonize
import numpy
import platform
import os
import subprocess
import re


def fix_sizeof_voidp_check(c_file_path):
    """
    Post-process generated C file to replace non-portable SIZEOF_VOID_P check.
    
    Replaces the enum-based division-by-zero trick that fails on some Windows toolchains:
        enum { __pyx_check_sizeof_voidp = 1 / (int)(SIZEOF_VOID_P == sizeof(void*)) };
    
    With a portable compile-time assertion:
        #if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
        _Static_assert(SIZEOF_VOID_P == sizeof(void*), "SIZEOF_VOID_P mismatch");
        #else
        typedef char __pyx_check_sizeof_voidp[(SIZEOF_VOID_P == sizeof(void*)) ? 1 : -1];
        #endif
    """
    if not os.path.exists(c_file_path):
        return False
    
    try:
        with open(c_file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Pattern to match the problematic enum check
        pattern = r'enum\s*\{\s*__pyx_check_sizeof_voidp\s*=\s*1\s*/\s*\(int\)\(SIZEOF_VOID_P\s*==\s*sizeof\(void\*\)\)\s*\}\s*;'
        
        # Replacement with portable compile-time assertion
        replacement = (
            '#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L\n'
            '_Static_assert(SIZEOF_VOID_P == sizeof(void*), "SIZEOF_VOID_P does not match sizeof(void*)");\n'
            '#else\n'
            'typedef char __pyx_check_sizeof_voidp[(SIZEOF_VOID_P == sizeof(void*)) ? 1 : -1];\n'
            '#endif'
        )
        
        # Check if the pattern exists
        if re.search(pattern, content):
            content = re.sub(pattern, replacement, content)
            
            with open(c_file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print(f"Fixed SIZEOF_VOID_P check in {c_file_path}")
            return True
        
    except Exception as e:
        print(f"Warning: Could not fix SIZEOF_VOID_P check in {c_file_path}: {e}")
    
    return False


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

# Platform-specific compile args
extra_compile_args = ['-std=c99', '-O3']
if platform.system() == 'Windows':
    # On Windows AMD64, explicitly set architecture to ensure SIZEOF_VOID_P matches
    # This fixes Cython's compile-time assertion: enum { __pyx_check_sizeof_voidp = 1 / (int)(SIZEOF_VOID_P == sizeof(void*)) }
    import struct
    pointer_size = struct.calcsize('P')
    if pointer_size == 8:
        # 64-bit
        extra_compile_args.append('-m64')
    elif pointer_size == 4:
        # 32-bit
        extra_compile_args.append('-m32')
    print(f"Windows build: Adding -m{pointer_size*8} flag to match pointer size {pointer_size} bytes")

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

# Cython compiler directives to handle Windows/MinGW compatibility
compiler_directives = {
    'language_level': 3,
    'embedsignature': True,
}

# Windows-specific Cython configuration to fix SIZEOF_VOID_P compile-time assertion
# The issue occurs when Cython generates C code with SIZEOF_VOID_P that doesn't match
# the target platform's sizeof(void*) during C compilation on Windows
if platform.system() == 'Windows':
    compiler_directives['preliminary_late_includes_cy28'] = True
    # Use build_dir to ensure clean builds on Windows
    cythonize_kwargs = {
        'include_path': ['src'],
        'compiler_directives': compiler_directives,
        'nthreads': 0,  # Force single-threaded to avoid race conditions
        'build_dir': 'build',
        'force': True,  # Force regeneration on Windows
    }
else:
    cythonize_kwargs = {
        'include_path': ['src'],
        'compiler_directives': compiler_directives,
    }

# Cythonize the extensions
ext_modules = cythonize([ext], **cythonize_kwargs)

# Post-process generated C file to fix SIZEOF_VOID_P check
# This fixes the non-portable enum trick that causes build failures with MinGW/GCC on Windows
# We apply this fix on all platforms since the C file may be built on different systems
# Check both possible locations where Cython might generate the C file
c_file_paths = ['src/benpy.c', 'build/src/benpy.c']
fixed = False
for c_file_path in c_file_paths:
    if os.path.exists(c_file_path):
        if fix_sizeof_voidp_check(c_file_path):
            fixed = True

if not fixed:
    print(f"Warning: Generated C file not found at any of: {c_file_paths}")

setup(
    ext_modules=ext_modules
)
