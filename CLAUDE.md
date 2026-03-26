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
.\install.ps1
```

## Repository Structure

```
bash/
  bashrc                    - Main entry point → ~/.bashrc and ~/.profile
  global/                   - Canonical config (upstream here, don't modify locally)
    config.sh               - cfg_* preference variables
    interactive.sh          - Colors, history, PATH, aliases, prompt
    functions.sh            - path_append/prepend/remove, layered_preference_source, etc.
    non_interactive.sh      - Non-interactive shell setup
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
  tmux/plugins/             - Bundled plugins (tpm, resurrect, continuum, better-mouse-mode)

editorconfig/
  editorconfig              - → ~/.editorconfig

starship/
  starship.toml             - Starship prompt config

powershell/
  Microsoft.PowerShell_profile.ps1  - PowerShell profile (aliases, coreutils wrappers, PSReadLine, Starship, zoxide, PSFzf, Invoke-PatchDOSStub)

wezterm/
  wezterm.lua               - WezTerm config

autohotkey/
  hotkeys.ahk               - Windows AutoHotKey hotkeys (VPN autologin, mouse nudge, tmux zoom, corp credential shortcuts)

hooks/
  pre-commit                - Removes embedded .git dirs before commits

install                     - Linux installation script (bash)
install.ps1                 - Windows installation script (PowerShell)
update_tmux_plugins         - Re-clones all tmux plugins listed in tmux.conf from GitHub (strips .git on next commit)
```

## Installation Details

**Production mode** (default, no flags): Copies files from repo — no symlinks to the repo remain. Re-run `./install` after repo changes to update.

**Links mode** (`--links`): Granular symlinks to specific repo files. `~/.config/bash/global` → `repo/bash/global`, individual file symlinks for nvim, vim plugins, etc. Changes in the repo take effect immediately without reinstalling.

**Dev mode** (`--dev`): Directory-level symlinks — `~/.config/bash` → `repo/bash`. Easiest when editing files frequently.

**Backup behavior**: Numbered backups in `dotfiles_backups/backup.N/`. Skips files already pointing to the repo. Never overwrites existing backups.

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
- `%USERPROFILE%\hotkeys.ahk` ← `repo/autohotkey/hotkeys.ahk`
- `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\hotkeys.lnk` — `.lnk` shortcut pointing directly to `AutoHotkey64.exe "%USERPROFILE%\hotkeys.ahk"` (AHK is not installed system-wide to avoid SentinelOne flagging). AHK is extracted to `%USERPROFILE%\AutoHotkey_*\`; if no such directory exists, the installer downloads the latest stable release from GitHub and removes `AutoHotkey32.exe`.
- `%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` ← `repo/powershell/Microsoft.PowerShell_profile.ps1` (PS 5.1)
- `%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` ← same (PS 7+)

## Bash Configuration Architecture

### Layer System

Files are sourced in order: `global → corp → site → project → user`. Each layer overrides the previous. Layer dirs (`bash/corp/`, `bash/site/`, `bash/project/`, `bash/user/`) are user-created, not bundled.

**Loading sequence** (see `bash/bashrc`):
1. Non-interactive: clears PATH/aliases/functions, sources `non_interactive.sh` per layer, exits if not interactive
2. Interactive: sources `config.sh` per layer, then `interactive.sh` per layer, then hook files

### Hook System

Each layer can have `global_hooks/1.sh` through `7.sh` injected at these points in `interactive.sh`:

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

| Variable | Values | Purpose |
|----------|--------|---------|
| `cfg_preferred_ls` | `eza`, `lsd`, `ls` | ls replacement |
| `cfg_preferred_vi` | `nvim`, `vim` | Editor |
| `cfg_preferred_cat` | `bat` | cat replacement |
| `cfg_enable_grc` | `1` | Generic Colorizer |
| `cfg_enable_fzf` | `1` | fzf integration |
| `cfg_prompt_color_normal` | color name | Normal session prompt |
| `cfg_prompt_color_farm` | color name | Farm/LSF session prompt |
| `cfg_attach_to_tmux` | `1` | Auto-attach tmux on login |
| `cfg_attach_to_tmux_with_detach_others` | `1` | Detach other clients |

### Key Functions (`bash/global/functions.sh`)

- `path_append`, `path_prepend`, `path_remove`, `path_trim` - PATH manipulation
- `layered_preference_source` - Sources a filename across all layers
- `source_if_exists` - Safe sourcing
- `is_truthy` - Boolean value checking
- `array_slice` - Python-like array slicing
- `join_by` - Join array with delimiter

### Notable Aliases (`bash/global/interactive.sh`)

- `b`, `bb`, `bbb` - `cd ..`, `cd ../..`, etc.
- `cdd` - cd to most recently modified directory
- `g` - ripgrep with smart defaults
- `vi`, `vim` - preferred editor
- `cat` - bat
- `ga` - `git add` with status display
- `lns` - safe symlink creation
- `latest` - create/follow a "latest" symlink

Custom `cd()`: accepts a file path (goes to parent), offers to create missing dirs, runs `ls` after.

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

Requires AHKv2. Corp mode activates when `CORP_UID` env var is set; reads credentials from `CORP_PASSWORD`.

Key hotkeys:
- `RAlt` / `RWin` → `Ctrl-\z` (tmux zoom toggle)
- `Ctrl+;` → `Ctrl-\;` (tmux last-pane + zoom toggle)
- `Ctrl+Alt+R` → reload script
- `Ctrl+Alt+A` → pause/resume all hotkeys
- `Ctrl+Alt+V` → toggle VPN auto-login (corp mode only)
- `Ctrl+Alt+B` → type `PWMANAGER_PASSWORD` + Enter
- `F1`/`F2`/`F3` → LMB/RMB/double-click+RMB (active in mspaint, etxc, wezterm-gui)

VPN auto-login handles: credential prompt, "secure gateway terminated" dialog, Connect button click. Mouse nudge prevents screen lock (active 8.3–120 min idle). Set `AHK_ENABLE_MOUSE_WIGGLE=false` to disable nudge.

`%USERPROFILE%\more_hotkeys.ahk` is auto-included if present (user extension point).



Kickstart.nvim base. Plugin manager: Lazy.nvim (versions locked in `lazy-lock.json`). Key plugins: blink.cmp, telescope.nvim, gitsigns.nvim, conform.nvim, nvim-lint, nvim-treesitter, lualine.nvim, tokyonight.nvim.

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
bash/user/interactive.sh # alias/function overrides
bash/corp/global_hooks/5.sh  # hook injection at point 5
```

### Add a new bundled plugin (vim/tmux)

1. Copy plugin directory into `vim/vim/pack/vendor/start/` or `tmux/tmux/plugins/`
2. The pre-commit hook will strip `.git` dirs automatically on next commit
3. Update `install` if new symlink logic is needed

### History

Per-PID history files at `$XDG_RUNTIME_DIR/bash_history.$$`. Child bash inherits parent history. New shells start from most recently modified history. `HISTSIZE=10000`, `HISTCONTROL=ignorespace:erasedups`.
