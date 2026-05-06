#!/usr/bin/env bash
set -euo pipefail

zig_version="${ZIG_VERSION:-0.15.2}"
zig_dir="${ZIG_DIR:-/tmp/zig-x86_64-linux-${zig_version}}"
zig_tar="${ZIG_TAR:-/tmp/zig-x86_64-linux-${zig_version}.tar.xz}"
zig_url="${ZIG_URL:-https://ziglang.org/download/${zig_version}/zig-x86_64-linux-${zig_version}.tar.xz}"
zig_cache="${ZIG_GLOBAL_CACHE_DIR:-/tmp/zig-global-cache-ncdu-${zig_version//./}}"

cd "$(dirname "${BASH_SOURCE[0]}")"

if [[ ! -x "${zig_dir}/zig" ]]; then
    if [[ ! -f "${zig_tar}" ]]; then
        curl -L "${zig_url}" -o "${zig_tar}"
    fi
    tar -xf "${zig_tar}" -C "$(dirname "${zig_dir}")"
fi

"${zig_dir}/zig" build --release=fast -Dstrip --global-cache-dir "${zig_cache}"
"${zig_dir}/zig" version
zig-out/bin/ncdu --version
