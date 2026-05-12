# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Dotfiles for **Electrical Engineering work environments**: multi-platform (RedHat 7/8/9, Suse, x86_64/ARM/PowerPC), offline (plugins bundled), no root access, multi-organizational (global/corp/site/project/user hierarchy). Manages Bash, Vim/Neovim, and Tmux via symlinks.

**Related project:** [EE Linux Tools](https://github.com/smprather/ee-linux-tools) - modern utilities (RipGrep, Tmux, EZA) for offline environments.

## Key Commands

**Linux:**
```bash
# Install dotfiles (copies everything — no repo references remain)
./install

# Install in dev mode (directory-level symlinks, easier for editing)
./install --dev

# Stage an install into a temp or test root instead of $HOME
./install --dest-dir /tmp/dotfiles-home

# Skip backups or vendored font installation
./install --no-backup
./install --no-fonts
./install --no-tldr-cache

# Run an explicit corp/site/user installer after global install steps
./install --post-install-hook ~/corp-dotfiles/install.sh

# Restore from backup
./install --restore-backup dotfiles_backups/backup.1

# Reload bash config after changes
exec bash
source ~/.bashrc

# Manually install repo-development git hooks
cp hooks/* .git/hooks/ && chmod +x .git/hooks/*
```

**Windows** (no elevation required — copies files):
```powershell
.\install-powershell-latest.ps1   # if starting from Windows PowerShell 5.1
.\install.ps1
```

## Repository Structure

```
bash/
  bashrc                    - Main entry point → ~/.bashrc, ~/.bash_profile, ~/.bash_login, and ~/.profile
  functions.sh              - Shared functions loaded before any layer (path_*, is_truthy, etc.)
  global/                   - Canonical config (upstream here, don't modify locally)
    config.sh               - cfg_* preference variables and defaults
    bashrc                  - PATH setup, colors, history, aliases, prompt, completions
    completions/            - bat, rg, zoxide, hyperfine, watchexec completions
    github.scop.bash-completion/  - Bundled bash-completion library (offline)
    grc/                    - Generic Colorizer binaries and configs
  corp/                     - Corporation-level overrides (user-created)
  site/                     - Site-level overrides (user-created)
  project/                  - Project-level overrides (user-created)
  user/                     - Personal overrides (user-created)

nvim/
  init.lua                  - Thin layer dispatcher (loads global→corp→site→project→user)
  lazy-lock.json            - Locked plugin versions
  lsp/                      - LSP server configs
  lua/global/               - Global layer (bundled, repo-managed)
    config.lua              - vim.g.cfg_* defaults (colorscheme, feature toggles, dpc, swap_dir)
    init.lua                - Options, keymaps, autocmds, LSP setup
    plugins/                - One .lua file per plugin (lazy.nvim specs)
    utils.lua               - Shared helpers (buf_smaller_than)
  lua/corp/                 - Corporation-level overrides (user-created, not bundled)
  lua/site/                 - Site-level overrides (user-created)
  lua/project/              - Project-level overrides (user-created)
  lua/user/                 - Personal overrides (user-created)
  after/ftplugin/           - Filetype overrides (tcl, yaml)

treesitter/
  build_parsers             - Builds all vendored nvim-treesitter parsers
  vendor/                   - Vendored nvim-treesitter and parser registry
  prebuilt/<platform>/      - Tracked parser `.so.bz2` files, queries, build metadata

vim/
  vimrc                     - Vim config → ~/.vimrc
  vim/pack/vendor/start/    - Auto-loaded plugins (nerdtree, SimpylFold, vim-liberty)
  vim/pack/vendor/opt/      - Optional plugins

tmux/
  tmux.conf                 - Tmux config → ~/.tmux.conf
  tmux-word-separators      - Expands tmux double-click word separators with emoji ranges
  tmux/vendor/plugins/      - Bundled plugins (tpm, resurrect, continuum, better-mouse-mode)

pre_built/
  <platform>/               - Platform dir, e.g. el8.x86_64.glibc2p28
    bin/*.bz2               - Compressed binaries → ~/.local/bin
    lib64/*.bz2             - Compressed shared libs → ~/.local/lib64
    runtime/                - Runtime archives (platform-matched)
      helix.tar.bz2         - Helix runtime → ~/.config/helix/runtime/
      vim92.tar.bz2         - Vim 9.2 runtime → ~/.local/share/vim/vim92/
      nvim.tar.bz2          - Neovim runtime → ~/.local/share/nvim/runtime/
      runtime_config.toml   - Runtime install metadata
    portable-python-*.tar.bz2 - BOLT-optimized Python archive (NOSTRIP — never run strip on it)
  build_scripts/            - Helper scripts (not installed)
    import-portable-python  - Package a portable-python dir → pre_built/<platform>/*.tar.bz2
    farm-versions           - Query installed binary versions (json/tsv/text output)
    build-kakoune.sh        - Build kakoune from source
    build-jq.sh             - Build jq from source
    build-ncdu.sh           - Build ncdu from source
    reproduce-llvm-build.sh - LLVM build reproduction script
  .strip-manifest           - sha256/tar-meta cache for strip_all_elf_binaries

kak/
  kakrc                     - Default kakoune config (copy of share/kak/kakrc from build); copied to ~/.config/kak/kakrc only if not already present

helix/                      - (empty; runtime archive moved to pre_built/<platform>/runtime/)

editorconfig/
  editorconfig              - → ~/.editorconfig

starship/
  starship.toml             - Starship prompt config → ~/.config/starship/starship.toml

powershell/
  Microsoft.PowerShell_profile.ps1  - PowerShell profile (aliases, coreutils wrappers, PSReadLine, Starship, zoxide, PSFzf, Invoke-PatchDOSStub)

wezterm/
  wezterm.lua               - WezTerm config

autohotkey/
  hotkeys.ahk               - Windows AutoHotKey flat script with installer-patched feature flags

hooks/
  pre-commit                - Removes embedded .git dirs before commits; installed by ./install --dev

install                     - Python 3.6-compatible Linux installer executable (shebang: #!/usr/bin/python3)
install-powershell-latest.ps1 - Windows PowerShell 5.1 bootstrapper for pwsh via winget
install.ps1                 - Windows installation script (PowerShell)
update_tmux_plugins         - Re-clones all tmux plugins listed in tmux.conf from GitHub (strips .git on next commit)
update_tldr_cache           - Bundles tealdeer pages as tldr/tldr-pages.tar.bz2 for offline installs
strip_all_elf_binaries      - Python 3.6-compatible helper that strips repo ELF payloads and normalizes tar archives to .tar.bz2
tests/install_linux_tmp_home - Runs Linux installer against a temp HOME for fresh-user smoke testing
```

## Installation Details

**Production mode** (default, no flags): Copies files from repo — no symlinks to the repo remain. Re-run `./install` after repo changes to update.
The Linux installer resolves the repo from the `install` script path, so it can be run from any current working directory. `./install` is the Python 3.6-compatible installer and checks the Python version before running.

**Dev mode** (`--dev`): File-level symlinks for nvim global layer and whole-dir symlinks for vim/tmux/starship/editorconfig. Nvim: `~/.config/nvim/` is a real directory containing `init.lua → repo/nvim/init.lua`, `lazy-lock.json → repo/nvim/lazy-lock.json`, `lsp/ → repo/nvim/lsp/`, `after/ → repo/nvim/after/`, and `lua/global/ → repo/nvim/lua/global/`; user layer dirs (`lua/corp/`, etc.) are preserved as real directories. For bash, symlinks the individual repo-managed files (`global/`, `functions.sh`, `bashrc`) while leaving user layer dirs in place. Skips backups.

**Destination mode** (`--dest-dir <dir>`): Installs into an alternate root instead of `$HOME`. Used by tests and useful for staging installs.

**No-backup mode** (`--no-backup`): Skips creating a backup before installing. Useful for clean reinstalls or automated use.

**No-fonts mode** (`--no-fonts`): Skips extracting vendored Nerd Font archives into `~/.local/share/fonts` and skips font cache refresh.

**Post-install hook** (`--post-install-hook <script>`): Runs explicit add-on hooks directly after global install steps and optional `--dev` git hooks, before automatic layer `install.sh` scripts are sourced. The option can be provided multiple times; hooks run in argument order. Hook paths are resolved before the installer changes to `$HOME`; each hook must be executable and provide its own shebang or binary format. Hook failure fails the installer. Environment passed to each hook: `DOTFILES_REPO`, `DOTFILES_HOME`, `DOTFILES_MODE` (`copy` or `dev`), `DOTFILES_BACKUP_DIR` (absolute current backup dir, or empty when backups are skipped), `DOTFILES_DEST_DIR`, `DOTFILES_NO_BACKUP`, `DOTFILES_NO_FONTS`, and `DOTFILES_NO_TLDR_CACHE`.

**Install result behavior**: Before each install area writes files, the Linux installer verifies that the target directory is writable. If not, it refuses that area with a warning, records a failed row, and continues with later areas when possible. Every normal run ends with an install results table whose success column is `yes`, `no`, or `skip`.

**Font behavior**: Linux installer extracts vendored fonts from top-level `fonts/*.zip` into `~/.local/share/fonts`. Large archives can be stored as split chunks named `*.zip.part-000`, `*.zip.part-001`, etc.; use 45 MiB chunks to stay below GitHub's 50 MB warning threshold. The installer rejoins them under `/tmp/dotfiles-fonts.*` before extraction. It generates `fonts.scale`/`fonts.dir` when `mkfontscale`/`mkfontdir` are present and refreshes fontconfig with `fc-cache`. Font discovery is fontconfig-first for normal Linux desktop apps, WSLg, and RHEL/Alma 8. Do not add `xset +fp` startup logic; X core font paths can fail when `$HOME` is not traversable by the X server. Windows Terminal reads fonts from Windows, not WSL fontconfig.

**Pre-built binary behavior**: Linux installer selects `pre_built/<platform>/` based on OS family, architecture, and libc. Preferred platform names are exact and ABI-oriented, for example `el8.x86_64.glibc2p28`. Files under `bin/*.bz2` are decompressed to `~/.local/bin` and marked executable. Files under `lib64/*.bz2` are decompressed to `~/.local/lib64`. All bz2 decompression uses `write_bz2_atomic` (temp file in same dir + `os.rename`) — this prevents SIGBUS when the running Python process has memory-mapped a shared library that is being overwritten. RPATH (`$ORIGIN/../lib64:$ORIGIN/../lib`) is pre-baked into each binary before bzip2 compression in the repo (see `pre_built/build_scripts/repatch-binaries` and `ADDING_BINARIES.md`), so no post-install patchelf step is needed — the installer is pure decompress + chmod. `$ORIGIN` is a runtime-relative token resolved by `ld.so` at load time, so baking it in the repo is identical to setting it post-install. If a running binary such as `tmux` cannot be replaced, the installer continues and prints a final retry notice telling the user to exit running instances and re-run the installer. It then runs `ldd` on installed binaries and warns about missing `.so` dependencies. If no exact platform exists, the installer may use a compatible same-arch glibc build whose glibc version is not newer than the host. The installer shebang is `#!/usr/bin/python3` and all subprocess calls use absolute paths (`_LDD`, `_UNAME`, `_GETCONF` resolved at startup via `_find_tool()`) to prevent accidentally picking up binaries currently being installed. **Never bundle glibc components** (`libc.so.6`, `libm.so.6`, `libpthread.so.0`, `libdl.so.2`, `librt.so.1`) — they must match the system's `ld-linux.so.2` exactly. The RPATH causes bundled versions to load instead of the system ones; a version mismatch between libc and the loader produces `undefined symbol: ..., version GLIBC_PRIVATE` crashes. Every EL8 target already has glibc 2.28; these libs are never needed in the bundle. Run the Python 3.6-compatible `./strip_all_elf_binaries` after adding binaries, libraries, parser grammars, or tar archives. It strips raw ELF files in place, strips ELF payloads inside standalone `.bz2`, and rewrites tar archives as `.tar.bz2`; processed tarballs are skipped on later runs when size and modification time match the strip manifest. Non-ELF `.bz2` payloads (e.g. `vim.bz2` which is a shell wrapper) are also recorded in `.strip-manifest` after first check so they are skipped as manifest hits on subsequent runs. Archives whose names match `NOSTRIP_ARCHIVE_PREFIXES` (currently `portable-python-*`) are completely skipped and never stripped — LLVM BOLT-optimized binaries must not be touched.

**Tree-sitter parser behavior**: Offline support targets Neovim v0.12+ only. The installer copies vendored `nvim-treesitter` and `treesitter-parser-registry` into `~/.local/share/nvim/dotfiles/vendor/`, then looks for prebuilt artifacts under `treesitter/prebuilt/$(uname -s lower)-$(uname -m)-<glibc|musl>/`, decompresses `parser/*.so.bz2` to installed `parser/*.so`, and copies `parser-info/`, `queries/`, `registry/`, and `build-info/` into `~/.local/share/nvim/tree-sitter-parsers/`. Neovim appends that parser directory to `runtimepath` and starts native Tree-sitter on filetype buffers. Build all supported parsers with `./treesitter/build_parsers`; prebuilt `.so.bz2`, parser-info, queries, registry cache, and `build-info/*.env` are tracked.

**tldr cache behavior**: `./update_tldr_cache` writes `tldr/tldr-pages.tar.bz2` for offline tealdeer installs. The installer accepts both `.tar.bz2` and legacy `.tar.gz`, replaces any existing `~/.cache/tealdeer/tldr-pages` unless `--no-tldr-cache` is passed, and `./strip_all_elf_binaries` normalizes tar archives to bzip2.

**Helix runtime behavior**: The installer looks for `helix.tar.bz2` in `pre_built/<platform>/runtime/` first, then falls back to the legacy path `helix/helix_runtime.tar.bz2`. It safely extracts into `~/.config/helix/`, replacing any existing `~/.config/helix/runtime`. A correct install has `~/.config/helix/runtime/tutor`. The archive contains `./runtime/...` and extracts directly to `~/.config/helix/`.

**Vim runtime behavior**: The installer looks for `vim92.tar.bz2` in `pre_built/<platform>/runtime/` first, then falls back to the legacy path `vim/runtime.tar.bz2`. It extracts to `~/.local/share/vim/`, renames the `runtime/` directory to `vim92/`, and verifies `filetype.vim` is present. A correct install has `~/.local/share/vim/vim92/filetype.vim`.

**Neovim runtime behavior**: The installer looks for `nvim.tar.bz2` in `pre_built/<platform>/runtime/`. It extracts to `~/.local/share/nvim/`, replaces any existing `~/.local/share/nvim/runtime`, and verifies `runtime/filetype.lua` is present. The release smoke gate runs the installed `nvim` headless with `--clean` and asserts that this runtime is on `runtimepath`. The Neovim config bootstraps `lazy.nvim` when available; if `lazy.nvim` is missing and `git` cannot clone it, the plugin layer is disabled cleanly so the core editor config still starts on locked-down machines.

**Portable Python behavior**: The installer looks for `portable-python-*.tar.bz2` in the platform dir. If found, it extracts to a temp dir under `/tmp` using `safe_extract_tar`, runs the bundled `install.sh --prefix ~/.local --force --no-test`, then removes `~/.local/bin/python3` and `~/.local/bin/pip3` so the system `/usr/bin/python3` wins for EDA tools. Use `python3.14` and `pip3.14` for this build. The archive must never be run through `strip_all_elf_binaries` (BOLT-optimized). To add or update a portable Python build, use `pre_built/build_scripts/import-portable-python <portable-dir>`.

**Backup behavior**: Numbered backups in `dotfiles_backups/backup.N/`. Skips files already pointing to the repo. Never overwrites existing backups.
Backups intentionally exclude font files (`*.ttf`, `*.otf`, `*.pcf`, `*.bdf`, `*.woff`, `*.woff2`, etc.) because vendored Nerd Fonts are large and reproducible.

**Tmux plugin behavior**: All bundled plugins are always copied/linked from the repo. Run `./update_tmux_plugins` to re-clone them from GitHub (pre-commit hook strips `.git` dirs on next commit).

**Tmux selection behavior**: `tmux/tmux-word-separators` is run from `tmux.conf` to append broad emoji ranges to `word-separators`. Tmux only supports literal separator characters, not Unicode classes, so keep this helper in sync with `tmux.conf` if double-click word selection starts capturing prompt icons such as Starship's read-only lock.

**Linux symlink map:**
- `~/.bashrc`, `~/.bash_profile`, `~/.bash_login`, `~/.profile` → `~/.config/bash/bashrc` → `repo/bash/bashrc`
- `~/.vimrc` → `~/.config/vim/vimrc`
- `~/.vim` → `~/.config/vim/vim`
- `~/.tmux.conf` → `~/.config/tmux/tmux.conf`
- `~/.tmux` → `~/.config/tmux/tmux`
- `~/.editorconfig` → `~/.config/editorconfig/editorconfig`
- `~/.config/starship/starship.toml` ← `repo/starship/starship.toml`
- `~/.config/helix/runtime/` ← `repo/pre_built/<platform>/runtime/helix.tar.bz2`
- `~/.local/share/vim/vim92/` ← `repo/pre_built/<platform>/runtime/vim92.tar.bz2`
- `~/.local/share/nvim/runtime/` ← `repo/pre_built/<platform>/runtime/nvim.tar.bz2`
- `~/.local/bin/python3.14` etc. ← `repo/pre_built/<platform>/portable-python-*.tar.bz2` (via install.sh)

**Windows copy destinations** (files are copied, not symlinked — re-run `.\install.ps1` after repo changes):
- `%LOCALAPPDATA%\nvim` ← `repo/nvim`
- `%USERPROFILE%\.config\wezterm\wezterm.lua` ← `repo/wezterm/wezterm.lua`
- `%USERPROFILE%\.config\starship\starship.toml` ← `repo/starship/starship.toml`
- `%USERPROFILE%\.editorconfig` ← `repo/editorconfig/editorconfig`
- `%USERPROFILE%\autohotkey\hotkeys.ahk` ← `repo/autohotkey/hotkeys.ahk`
- `%USERPROFILE%\dotkeys_config.toml` — user-local AHK feature selection config (created if missing)
- `install.ps1` patches feature flags in `%USERPROFILE%\autohotkey\hotkeys.ahk` based on the enabled feature list
- `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\hotkeys.lnk` — `.lnk` shortcut pointing directly to `AutoHotkey64.exe "%USERPROFILE%\autohotkey\hotkeys.ahk"` (AHK is not installed system-wide to avoid SentinelOne flagging). AHK is extracted to `%USERPROFILE%\AutoHotkey_*\`; if no such directory exists, the installer downloads the latest stable release from GitHub and removes `AutoHotkey32.exe`.
- `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` ← `repo/powershell/Microsoft.PowerShell_profile.ps1` (PS 5.1)
- `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` ← same (PS 7+)

## Bash Configuration Architecture

### Layer System

Files are sourced in order: `global → corp → site → project → user`. Each layer overrides the previous. Layer dirs (`bash/corp/`, `bash/site/`, `bash/project/`, `bash/user/`) are user-created, not bundled.

**Loading sequence** (see `bash/bashrc`):
1. Sources `bash/functions.sh` (shared utilities, available to all layers)
2. Sources `config.sh` per layer (sets `cfg_*` preferences)
3. Sources `bashrc` per layer (PATH, aliases, prompt, completions); each layer's `bashrc` exits early if not interactive

### Hook System

Each layer can have `global_hooks/1.sh` through `7.sh` injected at these points in `global/bashrc`:

| Hook | Execution point |
|------|----------------|
| 1.sh | After functions loaded |
| 2.sh | After GLIBC detection |
| 3.sh | After PATH setup |
| 4.sh | After prompt configuration |
| 5.sh | Before bash completions |
| 6.sh | After bash completions loaded |
| 7.sh | Late / deprecated |

### Configuration Variables (`bash/global/config.sh`)

| Variable | Default | Purpose |
|----------|---------|---------|
| `cfg_preferred_bash` | `""` | Full path to preferred bash binary; re-execs into it at startup if set, differs from current bash, and is executable |
| `cfg_preferred_ls` | `eza` | ls replacement (`eza`, `lsd`, `ls`) |
| `cfg_preferred_vi` | `nvim` | Editor (`nvim`, `vim`) |
| `cfg_preferred_cat` | `bat` | cat replacement (used by aliases) |
| `cfg_enable_grc` | `1` | Generic Colorizer |
| `cfg_enable_fzf` | `0` | fzf shell integration |
| `cfg_enable_starship` | `1` | Starship prompt (falls back to built-in prompt) |
| `cfg_enable_fastnvim` | `0` | Fast nvim mode |
| `cfg_enable_tmux_path_store` | `1` | tmux_path_store alias injection |
| `cfg_prompt_color_normal` | `$PROMPT_YELLOW` | Normal session prompt color |
| `cfg_prompt_color_farm` | `$PROMPT_RED` | Farm/LSF session prompt color |
| `cfg_prompt_include_host` | `0` | Include hostname in prompt |
| `cfg_attach_to_tmux` | `0` | Auto-attach tmux on login |
| `cfg_attach_to_tmux_with_detach_others` | `0` | Detach other clients when attaching |

### Key Functions (`bash/functions.sh`)

- `path_append`, `path_prepend`, `path_remove`, `path_trim` — PATH colon-list manipulation
- `path_prepend_if_dir`, `path_append_if_dir` — prepend/append only if directory exists
- `source_if_exists` — source a file only if readable
- `is_truthy` — boolean check (`1`/`true`/`yes`/`on`/`enabled` → true)
- `fpcmp N OP N` — floating-point comparison (`fpcmp 2.17 -gt 2.0`)
- `vercomp`, `verlte`, `verlt`, `ver_between` — version string comparison
- `array_slice` — Python-style array slicing (`array_slice 1:-1 "${arr[@]}"`)
- `join_by` — join array with delimiter
- `auto_attach_to_tmux` — attaches/creates tmux session if `cfg_attach_to_tmux` is set (available for manual call from user layer)
- `unset_bashrc_local_vars` — unsets all `_*` variables before bashrc exits

### Notable Aliases (`bash/global/bashrc`)

**Navigation:**
- `b` / `bb` / `bbb` … `bbbbbbbbbb` — `cd ..` up 1–10 levels
- `cdd` / `cddd` / `cdddd` … — cd to N-th most recently modified directory
- `cd-` — `cd -` (previous directory)
- `p` — print and save cwd to `/tmp/p_dir`; `cdp` — cd back to it
- Custom `cd()`: accepts a file path (goes to its parent), offers to create missing dirs with `mkdir -p`, runs `ls` after

**Listing:**
- `ll` / `lr` / `sl` / `rl` — all alias to `ls`
- `lh` — `human_readable=1 ls`
- `la` — `list_all=1 ls`
- `lg` — `show_group=1 ls`
- `lah` / `lha` — both size and all

**Editing:**
- `vi` / `vim` — `cfg_preferred_vi`
- `vic` — nvim with clean vimrc only
- `vii` — open most recently modified file
- `vid` — diff mode
- `fvi` — open fzf-selected file
- `v` — `nvim -n -R -` (read stdin, read-only)
- `new` — touch + chmod +x + open

**Search:**
- `g` — `rg --smart-case --search-zip --hidden --no-ignore` (falls back to `grep -r -i`)
- `sg` — same but limited to 100K files
- `gv` — inverted grep
- `gf` — fixed-string grep
- `gpy` / `gtcl` — grep Python / Tcl files
- `f` — `fd --unrestricted --full-path` (falls back to `find .`)
- `h` — `history | g`
- `hg` — `history | grep -i`
- `gah` — grep all bash history files across all PIDs

**Git:**
- `ga` — `git add [all]` then `git status`
- `gs` — `git status`
- `gc` — `git commit`
- `gp` — `git push`
- `gd` — `git d`
- `gsp` — stash, pull, pop

**Utilities:**
- `cat` — `bat --paging=never` (if bat available); `catp` — bat with paging
- `t` — `exec bash` (reload shell)
- `lns` — safe symlink (removes existing link first)
- `latest` — create/follow a `latest` symlink to a dir, then cd into it
- `w` — `type -a` (where is this defined?)
- `x` — `chmod +x`
- `rs` — rsync with progress, no `.snapshot/`
- `du` / `dum` — disk usage sorted by size (GB/MB)
- `rm` — `rm -f`
- `mkdir` — `mkdir -p`
- `we` — `watchexec --clear --poll 500`
- `extract_rpm` — `rpm2cpio | cpio -idmv`
- `zhead` — zcat + head
- `rp` — realpath (cwd if no arg)
- `gzip` / `gunzip` — pigz / unpigz
- `vnc` — start VNC server (no args) or pass through to vncserver

## Component Reference

### Tmux (`tmux/tmux.conf`)

- Prefix: `Ctrl-\`
- Pane navigation: `Shift+arrows`; Pane resize: `Prefix+arrows` (repeatable)
- Window navigation: `Ctrl+left/right`; Window reorder: `Ctrl+Shift+left/right`
- Layout presets: `Prefix+1-5`; 4-pane layout: `Prefix+o`; Reload: `Prefix+r`
- Capture pane buffer to nvim: `Prefix+v`
- Plugins: tmux-resurrect (save: `Prefix+Ctrl-s`, restore: `Prefix+Ctrl-r`), tmux-continuum (auto-save every 60min), tmux-better-mouse-mode

### PowerShell (`powershell/Microsoft.PowerShell_profile.ps1`)

Key aliases: `ls`/`lr` → eza, `vi` → nvim, `f` → fd, `cat` → bat, `g`/`grep` → rg, `b`/`bb`/`bbb` → cd up, `cdd` → cd to most recently modified dir, `gs`/`gc`/`gp`/`gd`/`ga`/`gsp` → git shortcuts, `w` → `Get-DefinitionPath`.

Integrations (conditional, cached init): zoxide (`z`/`zi`), PSFzf (`Ctrl+T` file picker, `Ctrl+R` history), Starship prompt. Falls back gracefully when tools are absent.

`Invoke-PatchDOSStub` — byte-patches the DOS stub string in an exe to change its hash, useful for bypassing SentinelOne hash-based flagging of tools like AutoHotkey.

coreutils wrappers (via Git for Windows path): `rm`, `cp`, `mv`, `diff`, `rmdir`, `mkdir`, `wc`, `sed`, `awk`, `cut`, `xargs`.

### AutoHotKey (`autohotkey/hotkeys.ahk`)

Requires AHKv2. `hotkeys.ahk` is a single flat script. `install.ps1` copies it to `%USERPROFILE%\autohotkey\hotkeys.ahk` and patches feature-flag booleans from `%USERPROFILE%\dotkeys_config.toml`.

Key hotkeys:
- `Ctrl+Alt+R` → reload script
- `Ctrl+Alt+A` → pause/resume all hotkeys
- `Ctrl+Alt+V` → toggle VPN auto-login when the Cisco VPN feature is enabled

Optional features:
- `corp-logins` — corp credential entry hotkeys using `CORP_UID` / `CORP_PASSWORD`
- `mouse-wiggle` — idle mouse nudge; set `AHK_ENABLE_MOUSE_WIGGLE=false` to suppress it
- `cisco-secure-client-vpn` — Cisco Secure Client reconnect + credential automation
- `password-manager` — `Ctrl+Alt+B` types `PWMANAGER_PASSWORD` + Enter
- `tmux-hotkeys` — `RAlt`/`RWin` zoom toggle and `Ctrl+;` last-pane toggle for tmux
- `f1f2f3-as-mouse-buttons` — F1/F2/F3 mouse remaps for mspaint/etxc/wezterm-gui
- `thinlinc-reconnect` — auto-dismiss ThinLinc "Connection error" dialogs, relaunch `tlclient.exe`, and auto-fill Server/Username/Password from `THINLINC_SERVER` / `THINLINC_USERNAME` / `THINLINC_PASSWORD` (pings the server before launching/connecting; user-initiated closes of tlclient are respected). `Ctrl+Alt+T` shows a live diagnostic (tick count, last-seen state, env, window matches, ping).

Existing `%USERPROFILE%\dotkeys_config.toml` files that still use legacy plugin IDs remain accepted by the installer and are mapped onto the flat-script feature flags.



**Layer architecture** (analogous to bash `global→corp→site→project→user`): `nvim/init.lua` is a thin dispatcher that sources `config.lua` per layer (Phase 1), bootstraps lazy.nvim (Phase 2), collects plugin specs from each layer's `plugins/` dir via `{ import = "LAYER.plugins" }` (Phase 3), then sources `init.lua` per layer (Phase 4). `vim.g.cfg_*` variables set in `global/config.lua` are the defaults; later layers override them. Plugin manager: Lazy.nvim (versions locked in `lazy-lock.json`). Key plugins: blink.cmp, snacks.nvim, gitsigns.nvim, conform.nvim, nvim-lint, nvim-treesitter, tokyonight.nvim. `vim.g.cfg_dpc` guards update-checker and notifications on offline machines. `vim.g.dotfiles_plugins_enabled` is false when lazy.nvim bootstrap fails offline — core editor still starts cleanly.

Snacks dashboard provides the no-argument `nvim` startup screen (`filetype=snacks_dashboard`). `mini.trailspace` highlights trailing whitespace with window-local matches, so dashboard cleanup must disable `vim.b.minitrailspace_disable`, turn off local `list`, and delete existing `MiniTrailspace` matches on dashboard open/update.

### Vim (`vim/vimrc`)

Native Vim 8 package management. Plugins in `vim/pack/vendor/{start,opt}/`. Basic settings: UTF-8, 4-space tabs, line numbers.

### Modern CLI Tools Expected

`eza`, `bat`, `rg` (aliased `g`), `zoxide`, `fzf`, `fd`/`fdfind`, `grc`, `pigz`

Falls back gracefully: eza → lsd → ls, bat → cat, fd → find. Handles Debian (`batcat`, `fdfind`) vs RedHat naming.

## Git Hooks

**pre-commit**: Scans for `.git` directories in subdirectories, removes them, re-stages. Required because bundled plugins (tmux, vim) include their own `.git` dirs which cause "embedded git repository" warnings.

## Common Patterns

### Add a layer override

```bash
# Create the file — it will automatically override global/
bash/user/config.sh      # cfg_* variable overrides
bash/user/bashrc         # alias/function overrides
bash/corp/global_hooks/5.sh  # hook injection at point 5
```

### Add a new bundled plugin (vim/tmux)

1. Copy plugin directory into `vim/vim/pack/vendor/start/` or `tmux/vendor/plugins/`
2. The pre-commit hook will strip `.git` dirs automatically on next commit
3. Update `install` if new symlink logic is needed

### Add a new pre-built binary

```bash
bzip2 -k mybinary
cp mybinary.bz2 pre_built/el8.x86_64.glibc2p28/bin/
./strip_all_elf_binaries          # strips, updates .strip-manifest
git add pre_built/ .strip-manifest
git commit                        # pre-commit hook re-strips and re-records
```

For shared libraries, put `.bz2` in `lib64/` instead.

### Import or update portable Python

```bash
pre_built/build_scripts/import-portable-python /path/to/portable-python-X.Y.Z-tag/
# Do NOT run strip_all_elf_binaries on the result — BOLT-optimized, already in NOSTRIP list
git add pre_built/ .strip-manifest
git commit
```

### Query installed binary versions

```bash
pre_built/build_scripts/farm-versions --format text    # aligned table
pre_built/build_scripts/farm-versions --format tsv     # for spreadsheets / README tables
pre_built/build_scripts/farm-versions --format json    # machine-readable
pre_built/build_scripts/farm-versions --missing-only   # find gaps
```

When adding a new binary, add an entry to `TOOLS` in `farm-versions` with the right strategy.

### Create a GitHub release

```bash
./release              # smoke-tests all binaries, then tags + publishes
./release --dry-run    # smoke-test only, no tag or GitHub release
./release --tag v2026.05.12   # explicit tag instead of today's date
```

`./release` runs `pre_built/build_scripts/test-prebuilt-binaries` (full temp install + probe
of every binary) before creating the tag. Blocked if any binary fails.
It also generates the binary version table from `farm-versions --format tsv` for the release notes.

GitHub auto-generates `Source code (tar.gz)` and `Source code (zip)` containing the full repo.

### History

Per-PID history files at `$XDG_RUNTIME_DIR/bash_history.$$`. Child bash inherits parent history. New shells start from most recently modified history. `HISTSIZE=10000`, `HISTCONTROL=ignorespace:erasedups`.
