#!/bin/sh
set -eu

cd "$(dirname "$0")"

MAKE=${MAKE:-gmake}
CXX=${CXX:-}

if [ -z "${KAKOUNE_SKIP_GCC_TOOLSET_14:-}" ] && [ -r /opt/rh/gcc-toolset-14/enable ]; then
    # shellcheck disable=SC1091
    . /opt/rh/gcc-toolset-14/enable
fi

if [ -z "$CXX" ]; then
    if command -v g++ >/dev/null 2>&1; then
        CXX=g++
    elif command -v clang++ >/dev/null 2>&1; then
        CXX=clang++
    else
        CXX=c++
    fi
fi

if ! command -v "$MAKE" >/dev/null 2>&1; then
    MAKE=make
fi

exec "$MAKE" CXX="$CXX" "$@"
