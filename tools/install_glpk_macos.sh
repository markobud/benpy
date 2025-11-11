#!/bin/bash
set -e

echo "Installing GLPK for macOS with cross-compilation support..."

# Detect runner architecture
RUNNER_ARCH=$(uname -m)
echo "Runner architecture: $RUNNER_ARCH"

# Get target architecture from CIBW_ARCHS environment variable
TARGET_ARCH="${CIBW_ARCHS:-$RUNNER_ARCH}"
echo "Target architecture: $TARGET_ARCH"

# Create a config file to store GLPK paths for setup.py
CONFIG_FILE="/tmp/glpk_config.txt"

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
    
    GLPK_INCLUDE_DIR="/usr/local/glpk-x86_64/include"
    GLPK_LIBRARY_DIR="/usr/local/glpk-x86_64/lib"
    
    echo "GLPK installed to /usr/local/glpk-x86_64"
    
else
    echo "Native compilation detected, using Homebrew GLPK"
    brew install glpk
    
    # Set paths for consistency
    BREW_PREFIX=$(brew --prefix)
    GLPK_INCLUDE_DIR="${BREW_PREFIX}/include"
    GLPK_LIBRARY_DIR="${BREW_PREFIX}/lib"
fi

# Write config to file for setup.py to read
echo "GLPK_INCLUDE_DIR=${GLPK_INCLUDE_DIR}" > "$CONFIG_FILE"
echo "GLPK_LIBRARY_DIR=${GLPK_LIBRARY_DIR}" >> "$CONFIG_FILE"

echo "GLPK installation complete"
echo "GLPK_INCLUDE_DIR: $GLPK_INCLUDE_DIR"
echo "GLPK_LIBRARY_DIR: $GLPK_LIBRARY_DIR"
echo "Config written to: $CONFIG_FILE"
cat "$CONFIG_FILE"
