#!/bin/sh
# Build Neovim from source for el8.x86_64.glibc2p28.
#
# Targets a Release build with statically linked bundled deps (libuv,
# tree-sitter, luajit, etc.) so the resulting binary links only against
# system glibc — no bundled libs needed.
#
# Usage:
#   cd ~/neovim          # or any neovim source checkout
#   /path/to/build-nvim.sh [--tag v0.10.4]
#
# After a successful build the binary is at ./build/bin/nvim and the
# runtime is at /usr/local/share/nvim/runtime/ (after make install).
# Run the packaging steps from ADDING_BINARIES.md to add them to the repo.

set -eu

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
BIN_DIR="$REPO/pre_built/el8.x86_64.glibc2p28/bin"
RUNTIME_DIR="$REPO/pre_built/el8.x86_64.glibc2p28/runtime"
PATCHELF="$HOME/.local/bin/patchelf"
INSTALL_PREFIX=/usr/local

if [ "${1:-}" = "--tag" ] && [ -n "${2:-}" ]; then
    git checkout "$2"
fi

if [ -r /opt/rh/gcc-toolset-14/enable ]; then
    # shellcheck disable=SC1091
    . /opt/rh/gcc-toolset-14/enable
fi

CMAKE=${CMAKE:-cmake}
MAKE=${MAKE:-make}

# Build with bundled deps (default); this links everything statically.
"$CMAKE" -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DENABLE_TRANSLATIONS=OFF \
    -G Ninja

ninja -C build -j"$(nproc)"

echo ""
echo "Build complete: $(./build/bin/nvim --version | head -1)"
echo ""
echo "Install runtime (requires sudo):"
echo "  sudo ninja -C build install"
echo ""
echo "Then package for the repo:"
echo ""
echo "  # Binary: strip -> patchelf -> bzip2"
echo "  cp $INSTALL_PREFIX/bin/nvim /tmp/nvim_tmp"
echo "  strip /tmp/nvim_tmp"
echo "  $PATCHELF --set-rpath '\$ORIGIN/../lib64:\$ORIGIN/../lib' /tmp/nvim_tmp"
echo "  bzip2 -k /tmp/nvim_tmp"
echo "  cp /tmp/nvim_tmp.bz2 $BIN_DIR/nvim.bz2"
echo ""
echo "  # Runtime archive"
echo "  tar -cjf /tmp/nvim.tar.bz2 -C $INSTALL_PREFIX/share/nvim ./runtime"
echo "  cp /tmp/nvim.tar.bz2 $RUNTIME_DIR/nvim.tar.bz2"
echo ""
echo "  # Strip manifest + commit"
echo "  cd $REPO && ./strip_all_elf_binaries"
echo "  git add pre_built/el8.x86_64.glibc2p28/bin/nvim.bz2 \\"
echo "          pre_built/el8.x86_64.glibc2p28/runtime/nvim.tar.bz2 \\"
echo "          .strip-manifest"
echo "  git commit"
