#!/bin/bash
# GNU Stow-based installation for dotfiles
# Uses stow's --dotfiles option to handle dot- prefix conversion

set -e

# Check for stow
if ! command -v stow >/dev/null; then
    echo "Error: This script requires GNU Stow."
    echo "Install it with: sudo apt install stow (or sudo yum install stow)"
    exit 1
fi

repo_dir=$(git rev-parse --show-toplevel)
echo "Dotfiles repo directory: $repo_dir"
echo ""

# Backup existing files
backup_dir="$HOME/dotfiles_backups/backup.$(date +%Y%m%d_%H%M%S)"
echo "Backing up existing dotfiles to: $backup_dir"
mkdir -p "$backup_dir"

# Backup files that will be replaced
for file in .bashrc .profile .vimrc .tmux.conf .tmux .editorconfig; do
    if [[ -e "$HOME/$file" && ! -L "$HOME/$file" ]]; then
        echo "  Backing up: ~/$file"
        cp -a "$HOME/$file" "$backup_dir/"
        rm -f "$HOME/$file"
    fi
done

# Backup config directories
for dir in .config/bash .config/nvim .config/tmux .config/editorconfig; do
    if [[ -d "$HOME/$dir" && ! -L "$HOME/$dir" ]]; then
        echo "  Backing up: ~/$dir"
        mkdir -p "$backup_dir/$(dirname $dir)"
        cp -a "$HOME/$dir" "$backup_dir/$dir"
        rm -rf "$HOME/$dir"
    fi
done

echo ""
echo "Running GNU Stow with --dotfiles option..."
echo "This automatically converts dot-bashrc → .bashrc, etc."
echo ""

cd "$repo_dir"

# Ensure .config directory exists
mkdir -p "$HOME/.config"

# Stow each package with --dotfiles option
# The --dotfiles flag makes dot-bashrc → .bashrc, dot-vimrc → .vimrc, etc.
for package in bash vim tmux editorconfig; do
    echo "  Stowing: $package"
    stow --dotfiles --verbose --target="$HOME" "$package" 2>&1 | grep -v "BUG in find_stowed_path" || true
done

# Nvim needs to go to .config
echo "  Stowing: nvim → ~/.config/"
stow --dotfiles --verbose --target="$HOME/.config" nvim 2>&1 | grep -v "BUG in find_stowed_path" || true

echo ""
echo "✓ Symlinks created!"
echo ""
echo "What just happened:"
echo "  - GNU Stow created symlinks from your home directory to the repo"
echo "  - The --dotfiles option converted dot-bashrc → .bashrc automatically"
echo "  - Your dot- prefixed source files remain visible in the repo"
echo ""
echo "Stow mapping:"
echo "  bash/dot-bashrc     → ~/.bashrc"
echo "  vim/dot-vimrc       → ~/.vimrc"
echo "  tmux/dot-tmux.conf  → ~/.tmux.conf"
echo "  tmux/dot-tmux/      → ~/.tmux/"
echo "  editorconfig/dot-editorconfig → ~/.editorconfig"
echo "  nvim/               → ~/.config/nvim/"
echo ""
echo "To see what's stowed: stow --dotfiles -nv bash"
echo "To remove (unstow):   cd $repo_dir && stow --dotfiles -D -t ~ bash"

# Special handling for .profile (needs to point to .bashrc)
echo ""
echo "Creating .profile symlink to .bashrc..."
ln -sf "$HOME/.bashrc" "$HOME/.profile"

# Install git hooks
echo ""
echo "Installing git hooks..."
if [[ -d "$repo_dir/hooks" ]]; then
    for hook in "$repo_dir/hooks"/*; do
        if [[ -f "$hook" && ! "$hook" =~ README ]]; then
            hook_name=$(basename "$hook")
            cp "$hook" "$repo_dir/.git/hooks/$hook_name"
            chmod +x "$repo_dir/.git/hooks/$hook_name"
            echo "  Installed: $hook_name"
        fi
    done
fi

# Tmux plugins (if online)
if curl -fsLI http://github.com >/dev/null 2>&1; then
    echo ""
    echo "GitHub is reachable, installing/updating Tmux plugins..."
    if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
        "$HOME/.tmux/plugins/tpm/bin/install_plugins"
        "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
    else
        echo "  TPM not found, skipping plugin installation"
    fi
fi

echo ""
echo "✓ All done!"
echo ""
echo "The --dotfiles feature keeps your repo clean with visible 'dot-' files"
echo "while creating proper hidden dotfiles in your home directory."
