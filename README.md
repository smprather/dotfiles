# Purpose

Dotfiles for **Electrical Engineering work environments** — and anyone who
wants an opinionated, modern, layered shell setup on Linux or Windows.

Built on 30+ years of EE workflow experience. Designed to be adopted
without modification and overridden without forking.

# What's Included

| Component | Description |
|-----------|-------------|
| **Bash** | Layered config (global→corp→site→project→user), modern aliases, fzf/zoxide/eza/bat integration |
| **Neovim** | Kickstart.nvim base, Lazy.nvim, LSP, treesitter, locked plugin versions |
| **Vim** | Bundled plugins (NERDTree, SimpylFold), no internet required |
| **Tmux** | Bundled plugins (resurrect, continuum, better-mouse-mode), `Ctrl-\` prefix |
| **PowerShell** | Aliases, Unix coreutils wrappers, PSReadLine, Starship, zoxide, PSFzf |
| **WezTerm** | Terminal config |
| **Starship** | Cross-shell prompt config installed to `~/.config/starship/starship.toml` |
| **AutoHotKey** | Flat AHK script with optional features enabled via `dotkeys_config.toml` |
| **EditorConfig** | Consistent formatting across editors |

# Design Goals

**Multi-platform** — RedHat 7/8/9, Suse, x86_64/ARM/PowerPC, Windows

**Offline-first** — plugins are bundled; no internet required at install time

**No root** — installs entirely to `$HOME`; no package manager or sudo needed

**Layered** — configuration precedence from lowest to highest:
Global → Corp → Site → Project → User

Each layer can override the previous without touching upstream files, so
personal customizations survive future updates to the base config.

**Opinionated but escapable** — sensible defaults out of the box;
every preference is a `cfg_*` variable you can override in your user layer.

# Installation

**Linux:**
```bash
./install
```
The Linux installer can be invoked from outside the repo root. `./install` is a
small Bash shim that runs the Python 3.6-compatible implementation in
`install.py`.

Vendored Nerd Fonts from top-level `fonts/` are installed to
`~/.local/share/fonts` and refreshed with
fontconfig (`fc-cache`) when available. This works for normal Linux desktop
apps on RedHat/Alma/RHEL 8 and for WSLg Linux GUI apps. Windows Terminal reads
fonts from Windows, so WSL terminal fonts must also be installed on the Windows
side. Large font archives may be stored as `*.zip.part-*`; the installer
rejoins them in `/tmp` before extracting. Use `./install --no-fonts` to skip
font installation.

Platform-matched pre-built Linux binaries from `pre_built/<platform>/bin/*.gz`
are decompressed into `~/.local/bin`; matching `lib64/*.gz` files go to
`~/.local/lib64`. Platform directories use names like
`el8.x86_64.glibc2p28`. The installer uses vendored `patchelf` to set
`$ORIGIN/../lib64:$ORIGIN/../lib` RPATHs on installed dynamic binaries.
Run `./strip_pre_built` after adding binaries or libraries to remove debug
symbols and recompress the vendored payloads.

Optional corporate/site add-ons can be chained after the global install:
```bash
./install --post-install-hook ~/corp-dotfiles/install.sh
```
`--post-install-hook` can be provided multiple times; hooks run in argument
order. Each hook runs with `bash` and receives `DOTFILES_REPO`,
`DOTFILES_HOME`, `DOTFILES_MODE`, `DOTFILES_BACKUP_DIR`,
`DOTFILES_NO_BACKUP`, and `DOTFILES_NO_FONTS`.

Vendored `nvim-treesitter`, the parser registry, and matching prebuilt
Tree-sitter parsers/queries are installed for offline Neovim v0.12+ use.
Build or refresh the full parser set with `./treesitter/build_parsers`.

Linux install smoke testing can simulate a fresh user by installing into a temp
home:
```bash
./tests/install_linux_tmp_home
```

Repo git hooks are installed only in development mode:
```bash
./install --dev
```

**Windows** (PowerShell, no elevation required):
```powershell
.\install.ps1
```
> If scripts are blocked, search: [windows enable running powershell scripts](https://www.google.com/search?q=windows+enable+running+powershell+scripts)

If you're starting from the default Windows PowerShell 5.1, run this first:
```powershell
.\install-powershell-latest.ps1
```
Then rerun `.\install.ps1` from PowerShell 7 (`pwsh`).

Windows AutoHotKey notes:
- `install.ps1` creates `%USERPROFILE%\dotkeys_config.toml` to choose which AutoHotKey features are enabled.
- The installer patches those feature flags into `%USERPROFILE%\autohotkey\hotkeys.ahk` after copying it.
- Current feature IDs: `corp-logins`, `mouse-wiggle`, `cisco-secure-client-vpn`, `password-manager`, `tmux-hotkeys`, `f1f2f3-as-mouse-buttons`, `thinlinc-reconnect`.

See [CLAUDE.md](CLAUDE.md) for full details: `--dev`, `--links`, `--no-backup`,
backup/restore, layer overrides, and Windows copy destinations.

# Related

[EE Linux Tools](https://github.com/smprather/ee-linux-tools) — companion
repo providing pre-built modern CLI binaries (RipGrep, Tmux, EZA, etc.)
for offline/locked-down Linux environments.
