#!/bin/sh
# Build nedit-ng (Qt5 NEdit rewrite) from source for el8.x86_64.glibc2p28.
#
# nedit-ng is a single binary linking only against system Qt5/X11 libs;
# no bundled libs needed. Added to pre_built as optional tool.
#
# Policy: always build from a stable tagged release. Never build from
# an untagged HEAD or dev branch. See stable tags at:
#   https://github.com/eteran/nedit-ng/releases
#
# Prerequisites on the build machine:
#   sudo dnf install cmake gcc-c++ \
#                    qt5-qtbase-devel qt5-qtsvg-devel \
#                    libXt-devel
#   # gcc-toolset-14 optional but recommended for consistent ABI
#
# Usage:
#   cd ~/nedit-ng       # any nedit-ng source checkout (github.com/eteran/nedit-ng)
#   /path/to/build-nedit-ng.sh [--clean] --tag vX.Y.Z
#
# After a successful build the binary is at ./build/nedit-ng.
# Packaging instructions are printed at the end.

set -eu

REPO="$(cd "$(dirname "$0")/../.." && pwd)"
BIN_DIR="$REPO/pre_built/el8.x86_64.glibc2p28/bin"
JOBS="${JOBS:-$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)}"

clean=0
tag=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --clean) clean=1 ;;
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
    echo "  $0 --tag v2.0.1" >&2
    echo "" >&2
    echo "Stable releases: https://github.com/eteran/nedit-ng/releases" >&2
    echo "" >&2
    echo "Policy: this project ships stable releases only." >&2
    exit 1
fi

git checkout "$tag"

if [ -r /opt/rh/gcc-toolset-14/enable ]; then
    # shellcheck disable=SC1091
    . /opt/rh/gcc-toolset-14/enable
fi

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "missing required command: $1 — install the prerequisite packages listed in this script's header" >&2
        exit 1
    }
}

need cmake
need g++
pkg-config --exists Qt5Widgets 2>/dev/null || {
    echo "Qt5Widgets not found via pkg-config — install qt5-qtbase-devel" >&2
    exit 1
}

if [ "$clean" -eq 1 ] && [ -d build ]; then
    rm -rf build
fi

cmake -B build \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS="-O2 -Wall" \
    -DBUILD_SHARED_LIBS=OFF

cmake --build build -j"$JOBS"

echo ""
echo "Build complete: $(./build/nedit-ng --version 2>/dev/null || ./build/nedit-ng -version 2>/dev/null | head -1)"
echo ""
echo "Binary size: $(ls -lh build/nedit-ng | awk '{print $5}') unstripped"
echo ""

echo "=== Packaging (run from the nedit-ng source directory) ==="
echo ""
echo "  # Binary: strip -> bzip2  (no patchelf needed — all system Qt5 libs)"
echo "  cp build/nedit-ng /tmp/nedit-ng_tmp"
echo "  strip /tmp/nedit-ng_tmp"
echo "  ls -lh /tmp/nedit-ng_tmp"
echo "  bzip2 -k /tmp/nedit-ng_tmp"
echo "  cp /tmp/nedit-ng_tmp.bz2 $BIN_DIR/nedit-ng.bz2"
echo ""
echo "  # Strip manifest + commit"
echo "  cd $REPO && ./strip_all_elf_binaries"
echo "  git add pre_built/el8.x86_64.glibc2p28/bin/nedit-ng.bz2 .strip-manifest"
echo "  git commit"
