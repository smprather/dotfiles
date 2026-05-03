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

# Install with symlinks to repo instead of copies (easier for editing)
./install --links

# Install in dev mode (directory-level symlinks, easier for editing)
./install --dev

# Skip backups or vendored font installation
./install --no-backup
./install --no-fonts

# Restore from backup
./install --restore-backup dotfiles_backups/backup.1

# Reload bash config after changes
exec bash
source ~/.bashrc

# Manually install git hooks
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
  bashrc                    - Main entry point → ~/.bashrc and ~/.profile
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
  init.lua                  - Neovim config (Kickstart.nvim based, ~64KB)
  lazy-lock.json            - Locked plugin versions
  lsp/                      - LSP server configs
  lua/kickstart/plugins/    - Kickstart plugin configs
  lua/custom/plugins/init.lua  - User plugin customizations
  after/ftplugin/           - Filetype overrides (tcl, yaml)

vim/
  vimrc                     - Vim config → ~/.vimrc
  vim/pack/vendor/start/    - Auto-loaded plugins (nerdtree, SimpylFold, vim-liberty)
  vim/pack/vendor/opt/      - Optional plugins

tmux/
  tmux.conf                 - Tmux config → ~/.tmux.conf
  tmux/vendor/plugins/      - Bundled plugins (tpm, resurrect, continuum, better-mouse-mode)

editorconfig/
  editorconfig              - → ~/.editorconfig

starship/
  starship.toml             - Starship prompt config

powershell/
  Microsoft.PowerShell_profile.ps1  - PowerShell profile (aliases, coreutils wrappers, PSReadLine, Starship, zoxide, PSFzf, Invoke-PatchDOSStub)

wezterm/
  wezterm.lua               - WezTerm config

autohotkey/
  hotkeys.ahk               - Windows AutoHotKey flat script with installer-patched feature flags

hooks/
  pre-commit                - Removes embedded .git dirs before commits

install                     - Linux installation script (bash)
install-powershell-latest.ps1 - Windows PowerShell 5.1 bootstrapper for pwsh via winget
install.ps1                 - Windows installation script (PowerShell)
update_tmux_plugins         - Re-clones all tmux plugins listed in tmux.conf from GitHub (strips .git on next commit)
```

## Installation Details

**Production mode** (default, no flags): Copies files from repo — no symlinks to the repo remain. Re-run `./install` after repo changes to update.

**Links mode** (`--links`): File/directory-level symlinks to specific repo paths. `~/.config/bash/global` → `repo/bash/global`, `~/.config/nvim/init.lua` → `repo/nvim/init.lua`, etc. Changes in the repo take effect immediately without reinstalling.

**Dev mode** (`--dev`): Directory-level symlinks for nvim/vim/tmux/editorconfig (e.g. `~/.config/nvim` → `repo/nvim`). For bash, symlinks the individual repo-managed files (`global/`, `functions.sh`, `bashrc`) while leaving user layer dirs (`corp/`, `site/`, etc.) in place as real directories. Skips backups.

**No-backup mode** (`--no-backup`): Skips creating a backup before installing. Useful for clean reinstalls or automated use.

**No-fonts mode** (`--no-fonts`): Skips extracting vendored Nerd Font archives into `~/.local/share/fonts` and skips font cache refresh.

**Font behavior**: Linux installer extracts vendored fonts from `vendor/fonts/*.zip` into `~/.local/share/fonts`. Large archives can be stored as split chunks named `*.zip.part-000`, `*.zip.part-001`, etc.; the installer rejoins them under `/tmp/dotfiles-fonts.*` before extraction. It generates `fonts.scale`/`fonts.dir` when `mkfontscale`/`mkfontdir` are present and refreshes fontconfig with `fc-cache`. Font discovery is fontconfig-first for normal Linux desktop apps, WSLg, and RHEL/Alma 8. Do not add `xset +fp` startup logic; X core font paths can fail when `$HOME` is not traversable by the X server. Windows Terminal reads fonts from Windows, not WSL fontconfig.

**Backup behavior**: Numbered backups in `dotfiles_backups/backup.N/`. Skips files already pointing to the repo. Never overwrites existing backups.
Backups intentionally exclude font files (`*.ttf`, `*.otf`, `*.pcf`, `*.bdf`, `*.woff`, `*.woff2`, etc.) because vendored Nerd Fonts are large and reproducible.

**Tmux plugin behavior**: All bundled plugins are always copied/linked from the repo. Run `./update_tmux_plugins` to re-clone them from GitHub (pre-commit hook strips `.git` dirs on next commit).

**Linux symlink map:**
- `~/.bashrc` → `~/.config/bash/bashrc` → `repo/bash/bashrc`
- `~/.profile` → same as above
- `~/.vimrc` → `~/.config/vim/vimrc`
- `~/.vim` → `~/.config/vim/vim`
- `~/.tmux.conf` → `~/.config/tmux/tmux.conf`
- `~/.tmux` → `~/.config/tmux/tmux`
- `~/.editorconfig` → `~/.config/editorconfig/editorconfig`

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



Kickstart.nvim base. Plugin manager: Lazy.nvim (versions locked in `lazy-lock.json`). Key plugins: blink.cmp, snacks.nvim, gitsigns.nvim, conform.nvim, nvim-lint, nvim-treesitter, lualine.nvim, tokyonight.nvim.

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

### History

Per-PID history files at `$XDG_RUNTIME_DIR/bash_history.$$`. Child bash inherits parent history. New shells start from most recently modified history. `HISTSIZE=10000`, `HISTCONTROL=ignorespace:erasedups`.
