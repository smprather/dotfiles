# Copilot Instructions

Dotfiles for Electrical Engineering work environments: multi-platform (RedHat 7/8/9, Suse, x86_64/ARM/PowerPC), offline-first (plugins bundled), no-root installs, with a layered configuration hierarchy (global → corp → site → project → user).

## Key Commands

```bash
# Linux install (copies files — no repo references remain)
./install

# Install with file-level symlinks (repo changes take effect immediately)
./install --links

# Install with directory-level symlinks (easiest for editing)
./install --dev

# Restore from numbered backup
./install --restore-backup dotfiles_backups/backup.1

# Reload bash after changes
exec bash

# Install repo-development git hooks manually
cp hooks/* .git/hooks/ && chmod +x .git/hooks/*

# Smoke-test a fresh Linux home install
./tests/install_linux_tmp_home
```

```powershell
# Windows install (copies files, no elevation required)
.\install.ps1
```

Use `bash -n install` and `bash -n bash/global/bashrc` after shell edits.
`./tests/install_linux_tmp_home` runs the Linux installer against a temp `HOME`
with temp XDG cache/state dirs, then smoke-tests offline Tree-sitter with
headless Neovim.

## Architecture

### Bash Layer System

`bash/bashrc` is the single entry point (symlinked to `~/.bashrc` and `~/.profile`). It sources files in layer order across five layers: `global → corp → site → project → user`. Each layer directory lives under `~/.config/bash/` after install.

Loading sequence (`bash/bashrc`):
1. Sources `bash/functions.sh` (shared utilities available to all layers)
2. Sources `config.sh` per layer (sets `cfg_*` preferences)
3. Sources `bashrc` per layer; each exits early if not interactive

`source_if_exists <path>` is used throughout for safe optional sourcing.

The `bash/global/` directory is the canonical upstream; the other layer dirs (`corp/`, `site/`, `project/`, `user/`) are user-created and not committed to this repo.

### Hook Injection Points

Each layer can inject code into `global/bashrc` via numbered files in `<layer>/global_hooks/`:

| File | Injection point |
|------|----------------|
| `1.sh` | After functions loaded |
| `2.sh` | After GLIBC detection |
| `3.sh` | After PATH setup |
| `4.sh` | After prompt configuration |
| `5.sh` | Before bash completions |
| `6.sh` | After bash completions loaded |
| `7.sh` | Late / deprecated |

### Install Modes

- **Production** (default): copies files; re-run `./install` to pick up repo changes
- **`--links`**: file/dir-level symlinks to repo; `~/.config/bash/global` → `repo/bash/global`; changes take effect immediately
- **`--dev`**: directory-level symlinks for nvim/vim/tmux/editorconfig; for bash, symlinks individual repo-managed files (`global/`, `functions.sh`, `bashrc`) while preserving user layer dirs as real directories
- **`--no-backup`**: skip backup creation (useful for clean reinstalls or automation)
- **`--no-fonts`**: skip vendored font extraction and font cache refresh
- **`--post-install-hook <script>`**: run an explicit corp/site/user add-on installer after global install steps

Backups are numbered (`dotfiles_backups/backup.N/`). The installer skips targets already pointing into the repo and never overwrites an existing backup.
Backups intentionally exclude font files because vendored Nerd Font archives are large and reproducible.

Repo git hooks are installed only by `./install --dev`; normal end-user installs skip them.

### Bundled Plugins

Tmux and Vim plugins are vendored in-tree (no internet required):
- `tmux/vendor/plugins/` — tpm, resurrect, continuum, better-mouse-mode
- `vim/vim/pack/vendor/start/` — nerdtree, SimpylFold, vim-liberty (auto-loaded)
- `vim/vim/pack/vendor/opt/` — optional plugins

Run `./update_tmux_plugins` to re-clone all tmux plugins from GitHub (pre-commit hook strips `.git` dirs on the next commit).

Neovim uses Lazy.nvim with versions locked in `nvim/lazy-lock.json`.

Tree-sitter offline support targets Neovim v0.12+ only. Vendored
`nvim-treesitter` and `treesitter-parser-registry` live under
`treesitter/vendor/`; prebuilt parsers, parser-info, queries, and registry cache
live under `treesitter/prebuilt/<platform>/`, where platform is
`$(uname -s lower)-$(uname -m)-<glibc|musl>`. Build or refresh the full parser
set with `./treesitter/build_parsers`. The installer copies matching artifacts
to `~/.local/share/nvim/tree-sitter-parsers/`.

## Key Conventions

### Variable Naming in Bash

- `cfg_*` variables are user-facing preferences defined in `config.sh` per layer.
- Variables prefixed with `_` are treated as bashrc-local and cleaned up by `unset_bashrc_local_vars` (in `functions.sh`) before bashrc exits. `cfg_*` are intentionally retained so aliases/functions can reference them at runtime.

### Pre-commit Hook

`hooks/pre-commit` scans for nested `.git` directories (from bundled plugins), removes them, and re-stages. Install this hook when developing this repo or working with bundled plugins. Normal end-user installs do not need repo git hooks. The hook runs `git add -A` after cleanup, so review staged files after it runs.

### Adding a Bundled Plugin

1. Copy the plugin directory into `vim/vim/pack/vendor/start/` or `tmux/vendor/plugins/`
2. The pre-commit hook strips `.git` dirs automatically on next commit
3. Update `install` / `install.ps1` if new symlink/copy logic is needed

### Overriding Configuration

Create layer files that will be automatically picked up — no changes to `bash/global/` needed:
```bash
bash/user/config.sh       # cfg_* variable overrides
bash/user/bashrc          # alias/function overrides
bash/corp/global_hooks/3.sh  # inject code after PATH setup
```

### Tool Fallback Pattern

The bash config gracefully degrades when modern tools are absent:
- `eza` → `lsd` → `ls`
- `bat` → `cat`
- `fd` / `fdfind` → `find`

Handles distro naming differences: `batcat` (Debian) vs `bat` (RedHat), `fdfind` vs `fd`.

### Windows

Files are **copied**, not symlinked. Re-run `.\install.ps1` after repo changes. AutoHotKey (`AutoHotkey64.exe`) is extracted to `%USERPROFILE%\AutoHotkey_*\` rather than installed system-wide (avoids SentinelOne flagging); if no such directory exists, the installer auto-downloads the latest stable release from GitHub and removes `AutoHotkey32.exe`. The PowerShell profile includes `Invoke-PatchDOSStub` — a byte-patcher that changes an exe's DOS stub string to alter its hash, useful as a SentinelOne bypass for flagged binaries like AHK.
