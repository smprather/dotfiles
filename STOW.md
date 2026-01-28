# GNU Stow Installation Method

This repository supports installation via GNU Stow as an alternative to the custom `install.sh` script.

## What is GNU Stow?

GNU Stow is a symlink farm manager that makes it easy to manage dotfiles. It creates symlinks from your home directory to files in the repository.

## Why Use Stow?

**Pros:**
- Industry-standard tool, well-maintained
- Simple and predictable symlink management
- Easy to unstow (remove all symlinks)
- Works perfectly with the `dot-` prefix via `--dotfiles` option
- Less custom code to maintain

**Cons:**
- Requires stow to be installed
- May not be available on all systems (especially older RHEL)
- Less control over the installation process

## The --dotfiles Option

Stow's `--dotfiles` option is perfect for this repo's naming convention:
- Files named `dot-bashrc` → stowed as `.bashrc`
- Files named `dot-vimrc` → stowed as `.vimrc`
- Keeps repo files visible (not hidden) while creating proper dotfiles in home directory

This is exactly why the `dot-` prefix was chosen!

## Installation

```bash
# Install stow (if not available)
sudo apt install stow    # Debian/Ubuntu
sudo yum install stow    # RHEL/CentOS
brew install stow        # macOS

# Run the stow-based installer
./install-stow.sh

# Restore from a backup (if needed)
./install-stow.sh --restore-backup dotfiles_backups/backup.1
```

## How It Works

The `install-stow.sh` script:

1. Backs up existing dotfiles to `~/dotfiles_backups/backup.TIMESTAMP/`
2. Uses `stow --dotfiles` to create symlinks:
   ```bash
   bash/dot-bashrc     → ~/.bashrc
   vim/dot-vimrc       → ~/.vimrc
   tmux/dot-tmux.conf  → ~/.tmux.conf
   tmux/dot-tmux/      → ~/.tmux/
   nvim/               → ~/.config/nvim/
   ```
3. Installs git hooks
4. Installs tmux plugins (if online)

## Manual Stow Commands

```bash
# From the dotfiles repo directory

# Stow a specific package
stow --dotfiles --target="$HOME" bash

# Preview what would be stowed (dry-run)
stow --dotfiles --no --verbose --target="$HOME" bash

# Unstow (remove symlinks)
stow --dotfiles --delete --target="$HOME" bash

# Restow (unstow + stow, useful after updates)
stow --dotfiles --restow --target="$HOME" bash

# Stow all packages at once
for pkg in bash vim tmux editorconfig; do
    stow --dotfiles -t "$HOME" "$pkg"
done
stow --dotfiles -t "$HOME/.config" nvim
```

## Directory Structure

Stow expects packages to mirror the target directory structure:

```
dotfiles/
├── bash/
│   ├── dot-bashrc           # → ~/.bashrc
│   ├── global/
│   ├── corp/
│   └── ...
├── vim/
│   └── dot-vimrc            # → ~/.vimrc
├── tmux/
│   ├── dot-tmux.conf        # → ~/.tmux.conf
│   └── dot-tmux/            # → ~/.tmux/
├── nvim/                    # → ~/.config/nvim/
│   ├── init.lua
│   └── ...
└── editorconfig/
    └── dot-editorconfig     # → ~/.editorconfig
```

## Comparison: install.sh vs install-stow.sh

| Feature | install.sh | install-stow.sh |
|---------|-----------|-----------------|
| Dependencies | rsync, bash | stow, rsync, bash |
| Availability | Universal | May not be on old systems |
| Symlink creation | Custom logic | GNU Stow |
| Code complexity | ~210 lines | ~180 lines |
| Unstow support | Manual removal | `stow -D` |
| Restow support | Re-run script | `stow -R` |
| Backup restore | `--restore-backup` | `--restore-backup` |
| Standard tool | No | Yes |

## Restoring from Backup

Both install scripts create timestamped backups before making changes. You can restore from any backup:

```bash
# List available backups
ls -la ~/dotfiles_backups/

# Restore from a specific backup
./install-stow.sh --restore-backup ~/dotfiles_backups/backup.20260128_123456
# or with relative path
./install-stow.sh --restore-backup dotfiles_backups/backup.1
```

**What the restore does:**
1. Removes all current symlinks (created by either install script)
2. Copies backed-up files back to their original locations
3. Preserves directory structure from backup

**Note:** The same `--restore-backup` flag works with both `install.sh` and `install-stow.sh`.

## Troubleshooting

**Stow complains about existing files:**
- The install script backs up existing files first
- If running stow manually, remove or backup conflicting files

**Stow not available:**
- Use the original `install.sh` instead
- Or install stow from source (it's portable)

**Want to switch from install.sh to stow:**
1. Unstow manually (remove existing symlinks)
2. Run `./install-stow.sh`

**Want to switch from stow to install.sh:**
1. `stow --dotfiles -D -t ~ bash vim tmux editorconfig`
2. `stow --dotfiles -D -t ~/.config nvim`
3. Run `./install.sh`

## References

- [GNU Stow Manual](https://www.gnu.org/software/stow/manual/stow.html)
- [Using GNU Stow to manage dotfiles](https://brandon.invergo.net/news/2012-05-26-using-gnu-stow-to-manage-your-dotfiles.html)
- [Stow --dotfiles documentation](https://www.gnu.org/software/stow/manual/stow.html#Dotfiles)
