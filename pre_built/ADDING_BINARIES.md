# Adding Pre-Built Binaries

Reference for the build machine and the full workflow for adding a new binary.

## Build Machine

**AlmaLinux 8.10**, x86_64, glibc 2.28, running as WSL2 on Windows.
Platform directory: `el8.x86_64.glibc2p28`

```
uname -r  → 6.6.87.2-microsoft-standard-WSL2
ldd --version → ldd (GNU libc) 2.28
gcc --version → gcc 8.5.0
```

User has `sudo` (wheel group). Enabled repos: appstream, baseos, epel, extras, powertools,
docker-ce-stable, gh-cli, rpmfusion-free-updates, rpmfusion-nonfree-updates.

### Notable devel packages already installed

X11 full stack, cairo, pango, readline, ncurses, libpng, freetype, fontconfig, bzip2, expat,
uuid, zlib, libwebp, libtiff, libjpeg-turbo, glib2, harfbuzz, fribidi, pixman, pcre/pcre2,
openssl, elfutils, libxml2, xxhash, lz4, zstd, libevent.

**Not available anywhere** (not in appstream/baseos/epel/powertools):
- `libgd-devel` — must build libgd from source if gd-based terminals needed

## Workflow

### 1. Get the binary

**From repo RPM** (easiest):
```bash
sudo dnf install -y <package>
which <binary>
```

**From source** (when repo version is too old or has unwanted deps):
```bash
cd /tmp
curl -L -o src.tar.gz <url>
tar xzf src.tar.gz && cd <srcdir>
./configure --prefix=/tmp/<name>-install [options]
make -j$(nproc) && make install
```

### 2. Audit dependencies

```bash
ldd /path/to/binary
```

Compare against already-bundled libs in `lib64/`. Anything already there: free.
Anything missing: decide whether to bundle or accept as system dependency.

**NEVER bundle these glibc components** — they must match the system's `ld-linux.so.2` exactly
or you get `undefined symbol: _dl_audit_symbind_alt, version GLIBC_PRIVATE` style crashes:
- `libc.so.6`
- `libm.so.6`
- `libpthread.so.0`
- `libdl.so.2`
- `librt.so.1`

These are always present on any EL8 system. Bundling them causes glibc/loader version mismatch.
If they're in `lib64/` from a previous mistake, remove them and purge from `~/.local/lib64` on
deployed systems.

**Safe to bundle**: anything that isn't glibc — libz, libpng, libX11, libreadline, libncurses,
libfreetype, libfontconfig, libevent, libxxhash, etc.

**libstdc++.so.6 and libgcc_s.so.1**: present on all EL8 systems. Don't bundle — no other
binaries in this repo do, and version mismatches with C++ code are subtle.

### 3. Minimize the dep chain

Before bundling 30 libs, check if the binary can be built with fewer features:

- **Qt5**: brings ICU (~75 MB), SSL, kerberos, GL — never worth it for home-dir installs
- **cairo + pango**: ~15 extra libs. Fine for a dedicated workstation, too heavy for ~4 GB quotas
- **libgd**: not in any EL8 repo; if needed, build from source or skip gd-based terminals
- **Lua**: adds `liblua-5.3.so`; usually optional (`--without-lua`)

For gnuplot specifically: `--without-qt --without-cairo --without-lua --with-x --with-readline=gnu`
gives dumb, x11, svg, postscript, eps, epslatex — enough for EE plotting. Only 2 new libs
(readline, ncurses).

### 4. Bundle the binary

```bash
REPO=/path/to/dotfiles
BIN_DIR="$REPO/pre_built/el8.x86_64.glibc2p28/bin"
LIB_DIR="$REPO/pre_built/el8.x86_64.glibc2p28/lib64"

# Binary — order: strip → patchelf → compress. CRITICAL: always strip BEFORE patchelf.
# patchelf reorganizes ELF segments to fit the new RPATH string; strip after patchelf
# sees .dynstr outside a PT_LOAD segment and corrupts the binary (symptom: "no version
# information available" or symbol lookup errors at runtime).
# $ORIGIN is resolved by ld.so at load time, so baking it in the repo is identical to
# post-install patchelf. Pre-patching means the installer is pure decompress + chmod;
# no patchelf needed on the destination (avoids NFS lock issues on running binaries).
cp /path/to/binary /tmp/mytool_tmp
/usr/bin/strip /tmp/mytool_tmp
~/.local/bin/patchelf --set-rpath '$ORIGIN/../lib64:$ORIGIN/../lib' /tmp/mytool_tmp
bzip2 -k /tmp/mytool_tmp
cp /tmp/mytool_tmp.bz2 "$BIN_DIR/mytool.bz2"

# Shared lib — filename must be the SONAME (ldd shows "libfoo.so.3 => ...")
# Libs don't need patchelf.
cp /lib64/libfoo.so.3.x.y /tmp/libfoo_tmp
bzip2 -k /tmp/libfoo_tmp
cp /tmp/libfoo_tmp.bz2 "$LIB_DIR/libfoo.so.3.bz2"
```

The installer decompresses `bin/*.bz2` → `~/.local/bin` and `lib64/*.bz2` → `~/.local/lib64`.
RPATH is pre-baked into each binary in the repo (see above), so no post-install patchelf is needed.

### 5. Strip

```bash
./strip_all_elf_binaries
```

Strips debug symbols from new `.bz2` payloads and records them in `.strip-manifest` so they're
skipped on subsequent runs. Typical savings: 60–75% size reduction before compression.
Never run on `portable-python-*.tar.bz2` (BOLT-optimized, in NOSTRIP list).

### 6. Update farm-versions

Add an entry to `TOOLS` in `pre_built/build_scripts/farm-versions`. Entries are
`(binary_name, display_name, homepage, version_strategy)`.

Common strategies:
```python
# Standard --version flag
strategy_flag(["--version"], r"toolname ([0-9]+\.[0-9]+\.[0-9]+)")

# Try multiple approaches
strategy_first(
    strategy_strings(r"toolname ([0-9]+\.[0-9]+\.[0-9]+)"),
    strategy_flag(["--version"], r"([0-9]+\.[0-9]+\.[0-9]+)"),
)

# Custom extraction (e.g. gnuplot: "6.0 patchlevel 2" → "6.0.2")
lambda binary: (lambda m: re.sub(r" patchlevel ", ".", m.group(1)) if m else None)(
    re.search(r"toolname ([0-9]+\.[0-9]+ patchlevel [0-9]+)", _run([binary, "--version"])))
```

### 7. Verify and commit

```bash
# Smoke-test decompressed binary
bunzip2 -k -c pre_built/el8.x86_64.glibc2p28/bin/mytool.bz2 > /tmp/t && chmod +x /tmp/t
ldd /tmp/t | grep "not found"   # must be empty
/tmp/t --version

# Check farm-versions picks it up
pre_built/build_scripts/farm-versions --format text

git add pre_built/el8.x86_64.glibc2p28/bin/mytool.bz2 \
        pre_built/el8.x86_64.glibc2p28/lib64/libnew*.bz2 \
        pre_built/build_scripts/farm-versions \
        .strip-manifest
git commit
```

## Gnuplot build notes (6.0.2, added 2026-05-10)

Built from source to avoid Qt5 dep chain. Configure flags used:
```bash
./configure \
  --prefix=/tmp/gnuplot-install \
  --without-qt \
  --without-lua \
  --without-cairo \
  --without-libcerf \
  --with-readline=gnu \
  --with-x
```

New libs bundled: `libreadline.so.7`, `libncurses.so.6`.
Runtime data (`share/gnuplot/6.0/`) not bundled — binary works without it for core terminals
(svg, postscript, x11, dumb all tested OK). If help or color palettes are needed later,
package `share/gnuplot/` as `gnuplot-runtime.tar.bz2` and add installer support.

## Disk quota considerations

Home directory quotas on EE systems are typically small (~4–10 GB). Rough sizes after stripping:

| Category           | Example                          | Approx size |
|--------------------|----------------------------------|-------------|
| Rust/Go binaries   | rg, fd, bat, eza, starship       | 0.5–3 MB    |
| C binaries         | gnuplot, htop, tmux              | 0.3–1.5 MB  |
| Qt5 bundle         | gnuplot with qt                  | ~150 MB     |
| Cairo+pango chain  | gnuplot with cairo               | ~15 MB      |
| ICU alone          | (pulled by Qt5)                  | ~75 MB      |
| Portable Python    | python3.14                       | ~40 MB      |
| Treesitter parsers | all platforms                    | ~20 MB      |

Future: consider splitting pre_built into lightweight (→ `~/.local`) and heavyweight
(→ shared filesystem, symlinked from `~/.local`). See memory file `project_prebuilt_bifurcation.md`.
