#!/bin/bash
set -e

echo "Installing GLPK for macOS..."

# Detect runner architecture
RUNNER_ARCH=$(uname -m)
echo "Runner architecture: $RUNNER_ARCH"

# Get target architecture from CIBW_ARCHS environment variable
TARGET_ARCH="${CIBW_ARCHS:-$RUNNER_ARCH}"
echo "Target architecture: $TARGET_ARCH"

# Create a config file to store GLPK paths for setup.py
CONFIG_FILE="/tmp/glpk_config.txt"

# Install GLPK using Homebrew (native architecture)
echo "Installing GLPK using Homebrew..."
brew install glpk

# Set paths for consistency
BREW_PREFIX=$(brew --prefix)
GLPK_INCLUDE_DIR="${BREW_PREFIX}/include"
GLPK_LIBRARY_DIR="${BREW_PREFIX}/lib"

# Write config to file for setup.py to read
echo "GLPK_INCLUDE_DIR=${GLPK_INCLUDE_DIR}" > "$CONFIG_FILE"
echo "GLPK_LIBRARY_DIR=${GLPK_LIBRARY_DIR}" >> "$CONFIG_FILE"

echo "GLPK installation complete"
echo "GLPK_INCLUDE_DIR: $GLPK_INCLUDE_DIR"
echo "GLPK_LIBRARY_DIR: $GLPK_LIBRARY_DIR"
echo "Config written to: $CONFIG_FILE"
cat "$CONFIG_FILE"
