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
| **WezTerm** | Terminal config + one-click Corp SSH shortcut |
| **Starship** | Cross-shell prompt config |
| **AutoHotKey** | VPN autologin (Cisco Secure Client), mouse nudge, tmux zoom hotkeys |
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

**Windows** (PowerShell, no elevation required):
```powershell
.\install.ps1
```
> If scripts are blocked, search: [windows enable running powershell scripts](https://www.google.com/search?q=windows+enable+running+powershell+scripts)

See [CLAUDE.md](CLAUDE.md) for full details: dev mode, `--links` mode,
backup/restore, layer overrides, and Windows copy destinations.

# Related

[EE Linux Tools](https://github.com/smprather/ee-linux-tools) — companion
repo providing pre-built modern CLI binaries (RipGrep, Tmux, EZA, etc.)
for offline/locked-down Linux environments.
