#!/bin/sh
# Build Neovim from source for el8.x86_64.glibc2p28.
#
# Targets a Release build with statically linked bundled deps (libuv,
# tree-sitter, luajit, etc.) so the resulting binary links only against
# system glibc — no bundled libs needed.
#
# Policy: always build from a stable tagged release. Never build from
# an untagged HEAD or nightly branch. See stable tags at:
#   https://github.com/neovim/neovim/releases
#
# Usage:
#   cd ~/neovim          # any neovim source checkout
#   /path/to/build-nvim.sh --tag v0.11.3
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

tag=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --tag)
            shift
            [ "$#" -gt 0 ] || { echo "missing value for --tag" >&2; exit 2; }
            tag="$1"
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0"
            exit 0
            ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

if [ -z "$tag" ]; then
    echo "ERROR: --tag is required. Specify a stable release tag, e.g.:" >&2
    echo "  $0 --tag v0.11.3" >&2
    echo "" >&2
    echo "Stable releases: https://github.com/neovim/neovim/releases" >&2
    echo "" >&2
    echo "Policy: this project ships stable releases only." >&2
    echo "Nightly/dev builds are not accepted." >&2
    exit 1
fi

git checkout "$tag"

if [ -r /opt/rh/gcc-toolset-14/enable ]; then
    # shellcheck disable=SC1091
    . /opt/rh/gcc-toolset-14/enable
fi

CMAKE=${CMAKE:-cmake}

# Build bundled deps first (luajit, luv, libuv, treesitter, etc.).
# Must use the bundled luajit as the Lua compiler — the system luajit
# (if installed) may have an incompatible bytecode format and cause
# "E970: Failed to initialize builtin Lua modules" at runtime.
echo "Building bundled deps..."
"$CMAKE" -S cmake.deps -B .deps -DCMAKE_BUILD_TYPE=Release
"$CMAKE" --build .deps -j"$(nproc)"

BUNDLED_LUAJIT="$(pwd)/.deps/usr/bin/luajit"

echo "Configuring nvim..."
DEPS_BUILD_DIR="$(pwd)/.deps" "$CMAKE" -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
    -DENABLE_TRANSLATIONS=OFF \
    -DLUA_PRG="$BUNDLED_LUAJIT" \
    -G Ninja

ninja -C build -j"$(nproc)"

echo ""
echo "Build complete: $(./build/bin/nvim --version | head -1)"
echo ""

echo "Installing runtime (requires sudo)..."
sudo ninja -C build install

echo ""
echo "Packaging for repo..."

cp "$INSTALL_PREFIX/bin/nvim" /tmp/nvim_tmp
strip /tmp/nvim_tmp
"$PATCHELF" --set-rpath '$ORIGIN/../lib64:$ORIGIN/../lib' /tmp/nvim_tmp
bzip2 -kf /tmp/nvim_tmp
cp /tmp/nvim_tmp.bz2 "$BIN_DIR/nvim.bz2"

tar -cjf /tmp/nvim.tar.bz2 -C "$INSTALL_PREFIX/share/nvim" ./runtime
cp /tmp/nvim.tar.bz2 "$RUNTIME_DIR/nvim.tar.bz2"

echo ""
echo "Installed: $BIN_DIR/nvim.bz2"
echo "Runtime:   $RUNTIME_DIR/nvim.tar.bz2"
echo ""
echo "Next steps:"
echo "  cd $REPO"
echo "  ./strip_all_elf_binaries"
echo "  git add pre_built/el8.x86_64.glibc2p28/bin/nvim.bz2 \\"
echo "          pre_built/el8.x86_64.glibc2p28/runtime/nvim.tar.bz2 \\"
echo "          .strip-manifest"
echo "  git commit"
echo ""
echo "Also update tools.json: set \"version\": \"${tag#v}\" for the nvim entry."
