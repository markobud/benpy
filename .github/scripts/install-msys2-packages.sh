#!/bin/bash
set -e

# Add MSYS2 to PATH if not already there
export PATH="/c/msys64/usr/bin:/c/msys64/mingw64/bin:$PATH"

# Retry up to 3 times to update MSYS2 database and install required packages
for i in 1 2 3; do
    echo "Attempt $i: update database and install packages"
    if /c/msys64/usr/bin/pacman -Syu --noconfirm && /c/msys64/usr/bin/pacman -S --noconfirm mingw-w64-x86_64-glpk mingw-w64-x86_64-gcc; then
        echo "pacman install succeeded"
        break
    fi
    echo "pacman install failed, retrying in $((i*10)) seconds..."
    sleep $((i*10))
done
