# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository designed for **Electrical Engineering work environments** with these constraints:

- **Multi-platform**: RedHat 7/8/9, Suse, x86_64, ARM, PowerPC
- **Offline**: Limited or no internet access (explains why plugins/completions are bundled)
- **No root access**: Can't install packages to system directories
- **Multi-organizational**: Supports corporate/site/team/user hierarchy

The repository manages shell (Bash), editor (Vim/Neovim), and terminal multiplexer (Tmux) configurations using symlinks. It's designed to be opinionated (30 years of EE experience) while allowing flexible overrides without breaking future updates.

**Related project:** [EE Linux Tools](https://github.com/smprather/ee-linux-tools) - provides modern utilities (RipGrep, Tmux, EZA) for offline environments.

## Installation

**Primary installation command:**
```bash
./install.sh --verbose
```

**Force installation (removes existing directories):**
```bash
./install.sh --verbose --unsafe
```

The installation script:
- Backs up existing configs to `dotfiles_backups/backup.N/` with relative paths preserved
- Creates symlinks in `~/.config/` pointing to repo directories
- Creates rc file symlinks from `dot-*rc` files in repo:
  - `~/.bashrc` → `bash/dot-bashrc`
  - `~/.vimrc` → `vim/dot-vimrc`
  - `~/.profile` → `.config/bash/dot-bashrc`
  - `~/.tmux.conf` → `tmux/dot-tmux.conf`
  - `~/.editorconfig` → `editorconfig/dot-editorconfig`
- Auto-installs/updates tmux plugins via TPM (only if github.com is reachable)

## Bash Configuration Architecture

### Layered Preference System

The bash configuration uses a sophisticated **layered override system** that sources files in this order:

```
global → corp → site → team → user
```

Each layer can override the previous layer. This design accommodates the multi-organizational EE environment where configurations need to cascade from global standards down to personal preferences. Implemented in `bash/dot-bashrc`:

```bash
layered_preference_source() {
    local bash_file=""
    local layer=""
    for layer in global corp site team user; do
        bash_file="$BASHRC_CONFIG_ROOT_DIR/$layer/$1"
        [[ -f "$bash_file" ]] && source "$bash_file"
    done
}
```

**Layers:**
- `global/` - Global/canonical configuration (shouldn't be modified locally, designed to be upstreamed)
- `corp/` - Corporation/organization-specific settings
- `site/` - Site-specific settings (datacenter, lab, etc.)
- `team/` - Team-specific settings
- `user/` - Personal overrides

This layering allows EE teams to maintain shared standards while preserving individual customization.

### Bash Loading Order

When bash starts (see `bash/dot-bashrc`):

1. **Non-interactive section** (always runs):
   - Clears PATH, aliases, functions
   - Sources `non_interactive.sh` from each layer
   - Exits if not interactive (`[[ $- != *i* ]]`)

2. **Interactive section** (only for interactive shells):
   - Sources `config.sh` from each layer (contains `cfg_*` variables)
   - Sources `interactive.sh` from each layer (main interactive setup)
   - Hook system: Each layer can have `global_hooks/1.sh` through `global_hooks/7.sh` for extension points

### Key Global Files

- `bash/dot-bashrc` - Main entry point, sets up layered sourcing
- `bash/global/config.sh` - Configuration variables (`cfg_preferred_ls`, `cfg_preferred_vi`, etc.)
- `bash/global/interactive.sh` - Main interactive setup (colors, history, PATH, aliases, prompt)
- `bash/global/functions.sh` - Utility functions (path manipulation, version comparison, array slicing)

### Hook System

Each layer (global, corp, site, team, user) can have its own `global_hooks/` directory with numbered hook files (1.sh through 7.sh). These are sourced at specific points during initialization, allowing each organizational level to inject custom behavior.

### Configuration Variables

Key `cfg_*` variables in `config.sh`:
- `cfg_preferred_ls` - "eza", "lsd", or "ls"
- `cfg_preferred_vi` - "nvim" or "vim"
- `cfg_preferred_cat` - "bat"
- `cfg_enable_grc` - "1" to enable Generic Colorizer
- `cfg_enable_fzf` - "1" to enable fzf integration
- `cfg_prompt_color_normal` - Prompt color for normal sessions
- `cfg_prompt_color_farm` - Prompt color for farm/LSF sessions

## Tmux Configuration

**Config file:** `tmux/dot-tmux.conf` (symlinked to `~/.tmux.conf`)

**Key bindings:**
- Prefix: `Ctrl-\` (not the default `Ctrl-b`)
- Pane navigation: `Shift + arrows`
- Window navigation: `Ctrl + left/right`
- Layout presets: `Prefix + 1-5` (even-horizontal, even-vertical, main-horizontal, main-vertical, tiled)
- Resize panes: `Prefix + arrow keys` (repeatable)
- Reload config: `Prefix + r`

**Features:**
- Vi-mode key bindings
- Mouse support (tmux-better-mouse-mode)
- Session persistence (tmux-resurrect + tmux-continuum)
- Auto-saves every 60 minutes
- Restores sessions on startup
- History limit: 10,000 lines

**Plugins managed by TPM:**
- tmux-resurrect - Save: `Prefix + Ctrl-s`, Restore: `Prefix + Ctrl-r`
- tmux-continuum - Automatic session saving/restoration
- tmux-better-mouse-mode - Enhanced mouse handling

## Neovim Configuration

**Config file:** `nvim/init.lua` (single ~64KB file based on Kickstart.nvim)

**Plugin manager:** Lazy.nvim with locked versions in `nvim/lazy-lock.json`

**Major plugins:**
- blink.cmp - Completion engine
- telescope.nvim - Fuzzy finder
- gitsigns.nvim - Git integration
- conform.nvim - Code formatting
- nvim-lint - Linting
- nvim-treesitter - Syntax parsing
- lualine.nvim - Status line
- tokyonight.nvim - Colorscheme

## Vim Configuration

**Config file:** `vim/dot-vimrc` (symlinked to `~/.vimrc`)

Uses vim-plug plugin manager with SuperTab for completion. Basic settings: UTF-8, 4-space tabs.

## Modern CLI Tools

The dotfiles expect these modern CLI tools to be installed:

- `eza` - Modern `ls` replacement (preferred)
- `bat` - Modern `cat` with syntax highlighting
- `rg` (ripgrep) - Fast code search (aliased as `g`)
- `zoxide` - Smarter cd command
- `fzf` - Fuzzy finder
- `fd` (fdfind on Debian) - Modern find
- `grc` - Generic Colorizer
- `pigz` - Parallel gzip (aliased as `gzip`)

Shell completions are sourced from:
- `bash/global/completions/*.bash` - Custom completions (bat, rg, zoxide, hyperfine, watchexec)
- `bash/global/github.scop.bash-completion/` - Large bash-completion library (bundled for offline environments)

## Helper Functions

Key functions from `bash/global/functions.sh`:

- `path_append`, `path_prepend`, `path_remove`, `path_trim` - PATH manipulation
- `layered_preference_source` - Sources files across all layers
- `source_if_exists` - Safe sourcing
- `is_truthy` - Boolean value checking
- `array_slice` - Python-like array slicing
- `join_by` - Join array with delimiter

## Custom Aliases & Functions

Notable aliases from `bash/global/interactive.sh`:

- `b`, `bb`, `bbb`, etc. - Navigate up directories (`cd ..`, `cd ../..`, etc.)
- `cdd` - cd to most recently modified directory
- `g` - ripgrep with smart defaults
- `vi`, `vim` - Aliased to preferred editor (`$cfg_preferred_vi`)
- `cat` - Aliased to bat
- `ga` - `git add` with status display
- `lns` - Safe symlink creation (removes existing symlink first)
- `latest` - Create/follow a "latest" symlink to most recent directory

Custom `cd()` function:
- Can cd to a file (goes to parent directory)
- Offers to create non-existent directories
- Runs `ls` after changing directories

## Multi-Platform Support

The configuration detects and adapts to different platforms:

- **GLIBC version detection**: `bash/global/interactive.sh` detects GLIBC version (e.g., for RH7 compatibility)
- **Tool availability**: Falls back gracefully when modern tools aren't available (eza → lsd → ls, bat → cat, fd → find)
- **Architecture support**: Works on x86_64, ARM, and PowerPC
- **Distribution variations**: Handles Debian/Ubuntu (`batcat`, `fdfind`) vs RedHat naming conventions

## History Management

Bash history is per-shell-session with intelligent inheritance:

- History files: `$XDG_RUNTIME_DIR/bash_history.$$` (per-PID)
- Child bash inherits parent's history
- New shells start with most recently modified history
- Settings: `HISTSIZE=10000`, `HISTCONTROL=ignorespace:erasedups`

## Design Philosophy

**Opinionated but flexible**: The global layer represents 30 years of EE workflow experience and provides an opinionated "way of working". However:
- Users can override anything via the layer system without breaking future updates
- Improvements should be discussed and upstreamed to the global layer
- The goal is shared standards with room for customization

**Offline-first**: All dependencies (completions, plugins) are bundled because target environments have limited/no internet access. The install script intelligently checks for github.com connectivity and only attempts to download/update tmux plugins if the network is available.

**No root required**: All installations use `~/.local`, `~/.config`, and home directory symlinks since users can't access system directories.

**Naming convention**: Configuration files in the repo use a `dot-` prefix (e.g., `dot-bashrc`, `dot-vimrc`) to distinguish them from their installed locations (`.bashrc`, `.vimrc`). This makes the repo structure clearer and avoids hidden files in git.

## Common Development Patterns

### Adding a New Layer Override

To add corp/site/team/user-specific config:

1. Layer directories already exist: `bash/corp/`, `bash/site/`, `bash/team/`, `bash/user/`
2. Add your override file: `bash/user/config.sh` or `bash/user/interactive.sh`
3. Variables/functions will override the global layer

### Adding Hook Extensions

Each layer has a `global_hooks/` directory for numbered hook files:

```bash
# Hook locations by layer
bash/global/global_hooks/1.sh  # Global early hook
bash/corp/global_hooks/5.sh    # Corp-specific hook at position 5
bash/user/global_hooks/7.sh    # User late hook (after completions)
```

Hook execution points in `bash/global/interactive.sh`:
- `1.sh` - Early in interactive setup (after functions loaded)
- `2.sh` - After GLIBC detection
- `3.sh` - After PATH setup
- `4.sh` - After prompt configuration
- `5.sh` - Before bash completions
- `6.sh` - After bash completions loaded
- `7.sh` - Late in interactive setup (deprecated hooks)

### Testing Bash Changes

```bash
# Reload bash config
exec bash

# Or just source it
source ~/.bashrc
```

## Installation Features

### Offline Support

The `install.sh` script includes intelligent offline detection:

```bash
if curl -fsLI http://github.com >/dev/null; then
    # Only install/update tmux plugins if github.com is reachable
    ~/.tmux/plugins/tpm/bin/install_plugins
    ~/.tmux/plugins/tpm/bin/update_plugins all
fi
```

This allows the dotfiles to work fully in offline environments, with tmux plugins already bundled in the repo. Plugin updates only occur when internet connectivity is available.

### Backup Safety

Before any installation, the script:
- Creates numbered backups (`dotfiles_backups/backup.1/`, `backup.2/`, etc.)
- Preserves relative paths in backups
- Never overwrites existing backup directories

## Repository Structure

```
bash/
  dot-bashrc       - Main entry point (symlinked to ~/.bashrc)
  global/          - Global configuration (canonical)
    config.sh
    interactive.sh
    functions.sh
    global_hooks/  - Hook injection points (1.sh through 7.sh)
    completions/   - Custom completions (bat, rg, zoxide, etc.)
    github.scop.bash-completion/  - Bundled bash-completion library
    grc/           - Generic Colorizer configs
  corp/            - Corporation-level overrides
    global_hooks/  - Corp-level hook overrides
  site/            - Site-level overrides
    global_hooks/  - Site-level hook overrides
  team/            - Team-level overrides
    global_hooks/  - Team-level hook overrides
  user/            - Personal overrides
    global_hooks/  - User-level hook overrides

nvim/
  init.lua         - Neovim config (Kickstart.nvim based)
  lazy-lock.json   - Locked plugin versions

vim/
  dot-vimrc        - Vim config (symlinked to ~/.vimrc)

tmux/
  dot-tmux.conf    - Tmux config (symlinked to ~/.tmux.conf)
  dot-tmux/        - Tmux runtime directory
  plugins/         - Bundled tmux plugins (tpm, resurrect, continuum, better-mouse-mode)

editorconfig/
  dot-editorconfig - Universal editor settings (symlinked to ~/.editorconfig)

install.sh         - Installation script with offline support
.gitignore         - Ignores dotfiles_backups/
CLAUDE.md          - This file
README.md          - Project purpose and design goals
