#!/bin/bash
set -e

echo "Installing GLPK for macOS with cross-compilation support..."

# Detect runner architecture
RUNNER_ARCH=$(uname -m)
echo "Runner architecture: $RUNNER_ARCH"

# Get target architecture from CIBW_ARCHS environment variable
TARGET_ARCH="${CIBW_ARCHS:-$RUNNER_ARCH}"
echo "Target architecture: $TARGET_ARCH"

# If we're on ARM64 and building for x86_64, we need x86_64 GLPK
if [[ "$RUNNER_ARCH" == "arm64" ]] && [[ "$TARGET_ARCH" == "x86_64" ]]; then
    echo "Cross-compilation detected: ARM64 runner building x86_64 wheels"
    echo "Building GLPK from source with x86_64 architecture..."
    
    # Download GLPK source
    GLPK_VERSION="5.0"
    GLPK_TAR="glpk-${GLPK_VERSION}.tar.gz"
    GLPK_URL="https://ftp.gnu.org/gnu/glpk/${GLPK_TAR}"
    
    cd /tmp
    curl -L -O "$GLPK_URL"
    tar -xzf "$GLPK_TAR"
    cd "glpk-${GLPK_VERSION}"
    
    # Configure and build for x86_64
    export CFLAGS="-arch x86_64"
    export CXXFLAGS="-arch x86_64"
    export LDFLAGS="-arch x86_64"
    
    ./configure --prefix=/usr/local/glpk-x86_64 --disable-dependency-tracking
    make -j$(sysctl -n hw.ncpu)
    sudo make install
    
    echo "GLPK installed to /usr/local/glpk-x86_64"
    echo "Setting environment variables for build..."
    
    # Export paths for setup.py to use
    export GLPK_INCLUDE_DIR="/usr/local/glpk-x86_64/include"
    export GLPK_LIBRARY_DIR="/usr/local/glpk-x86_64/lib"
    
    # Save to GITHUB_ENV if available (for GitHub Actions)
    if [ -n "$GITHUB_ENV" ]; then
        echo "GLPK_INCLUDE_DIR=/usr/local/glpk-x86_64/include" >> "$GITHUB_ENV"
        echo "GLPK_LIBRARY_DIR=/usr/local/glpk-x86_64/lib" >> "$GITHUB_ENV"
    fi
    
else
    echo "Native compilation detected, using Homebrew GLPK"
    brew install glpk
    
    # Set environment variables for consistency
    BREW_PREFIX=$(brew --prefix)
    export GLPK_INCLUDE_DIR="${BREW_PREFIX}/include"
    export GLPK_LIBRARY_DIR="${BREW_PREFIX}/lib"
    
    if [ -n "$GITHUB_ENV" ]; then
        echo "GLPK_INCLUDE_DIR=${BREW_PREFIX}/include" >> "$GITHUB_ENV"
        echo "GLPK_LIBRARY_DIR=${BREW_PREFIX}/lib" >> "$GITHUB_ENV"
    fi
fi

echo "GLPK installation complete"
echo "GLPK_INCLUDE_DIR: $GLPK_INCLUDE_DIR"
echo "GLPK_LIBRARY_DIR: $GLPK_LIBRARY_DIR"
