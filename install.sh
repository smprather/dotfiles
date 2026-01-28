#!/bin/bash
if ! command -v rsync >/dev/null; then
    echo "Error: This script requires rsync."
    exit 1
fi

# Parse command line arguments for --restore-backup
if [[ "$1" == "--restore-backup" ]]; then
    if [[ -z "$2" ]]; then
        echo "Error: --restore-backup requires a backup directory path"
        echo "Usage: $0 --restore-backup <backup_dir>"
        echo "Example: $0 --restore-backup dotfiles_backups/backup.1"
        exit 1
    fi

    backup_dir="$2"

    if [[ ! -d "$backup_dir" ]]; then
        echo "Error: Backup directory not found: $backup_dir"
        exit 1
    fi

    echo "Restoring dotfiles from backup: $backup_dir"
    echo ""

    # Remove current symlinks
    echo "Removing current symlinks..."
    for file in ~/.bashrc ~/.profile ~/.vimrc ~/.tmux.conf ~/.editorconfig; do
        if [[ -L "$file" ]]; then
            echo "  Removing symlink: $file"
            rm -f "$file"
        fi
    done

    for dir in ~/.tmux ~/.vim ~/.config/bash ~/.config/nvim ~/.config/tmux ~/.config/editorconfig; do
        if [[ -L "$dir" ]]; then
            echo "  Removing symlink: $dir"
            rm -f "$dir"
        fi
    done

    # Restore files from backup
    echo ""
    echo "Restoring files from backup..."
    cd "$backup_dir"

    # Use rsync to restore with relative paths preserved
    if ls -A . 2>/dev/null | grep -q .; then
        rsync -av --no-relative ./ "$HOME/"
        echo ""
        echo "✓ Backup restored successfully!"
        echo ""
        echo "Restored from: $backup_dir"
    else
        echo "Error: Backup directory is empty"
        exit 1
    fi

    exit 0
fi

lns() {
    local unsafe=false
    local verbose=false
    local args=()

    # Parse arguments to extract --unsafe and --verbose flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --unsafe)
                unsafe=true
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done

    # Check if we have at least 2 arguments (target and link_name)
    if [[ ${#args[@]} -lt 2 ]]; then
        echo "Error: lns requires at least 2 arguments (target and link_name)" >&2
        return 1
    fi

    # Get the last argument (the link name)
    local link_name="${args[@]: -1}"

    # Check if link_name exists
    if [[ -e "$link_name" || -L "$link_name" ]]; then
        if [[ -d "$link_name" && ! -L "$link_name" ]]; then
            # It's a directory (not a symlink to a directory)
            if [[ "$unsafe" == false ]]; then
                echo "Error: '$link_name' exists as a directory and cannot be removed (use --unsafe to override)" >&2
                exit 1
            else
                # Remove directory with --unsafe
                if [[ "$verbose" == true ]]; then
                    echo "rm -rf '$link_name'" >&2
                fi
                if ! rm -rf "$link_name" 2>/dev/null; then
                    echo "Error: Failed to remove directory '$link_name' (permission denied or other error)" >&2
                    exit 1
                fi
            fi
        else
            # It's a file or a symlink (including symlink to directory)
            if [[ "$verbose" == true ]]; then
                echo "rm -f '$link_name'" >&2
            fi
            if ! rm -f "$link_name" 2>/dev/null; then
                echo "Error: Failed to remove '$link_name' (permission denied or other error)" >&2
                exit 1
            fi
        fi
    fi

    # Create the symbolic link with remaining arguments
    if [[ "$verbose" == true ]]; then
        echo "ln -s ${args[*]}" >&2
    fi
    ln -s "${args[@]}"
}

mkdirn() {
    local base_dir="$1"
    local target_dir="$base_dir"
    local counter=1

    # If base directory doesn't exist, create it
    if [[ ! -e "$target_dir" ]]; then
        mkdir -p "$target_dir"
        echo "$target_dir"
        return 0
    fi

    # Find next available name with .<N> suffix
    while [[ -e "$target_dir" ]]; do
        target_dir="${base_dir}.${counter}"
        ((counter++))
    done

    mkdir -p "$target_dir"
    echo "$target_dir"
}

repo_dir=$(git rev-parse --show-toplevel)
echo "Dotfiles repo base directory: $repo_dir"

echo "Changing directory to ~"
cd ~

backup_dir=$(mkdirn "dotfiles_backups/backup")
echo "Making backups in: $backup_dir"

for x in \
    .bashrc \
    .vimrc \
    .vim \
    .tmux \
    .tmux.conf \
    .config/nvim \
    .config/bash \
    .config/tmux \
    .config/editorconfig \
    ; do

    if [[ -r $x && ! -L $x ]]; then
        echo "  rsync -a --relative $x $backup_dir/"
        rsync -a --relative $x $backup_dir/
        echo "  rm -fr $x"
        rm -fr $x
    fi
done

mkdir -p .config

for config_dir in \
    bash \
    nvim \
    tmux \
    editorconfig \
    ; do

    lns --verbose $repo_dir/$config_dir .config/$config_dir
done

for rc_file_tool in \
    bash \
    vim; do

    lns --verbose $repo_dir/$rc_file_tool/dot-${rc_file_tool}rc .${rc_file_tool}rc
done

lns --verbose .config/bash/dot-bashrc .profile
lns --verbose .config/tmux/dot-tmux.conf .tmux.conf
lns --verbose .config/tmux/dot-tmux .tmux
lns --verbose .config/editorconfig/dot-editorconfig .editorconfig

# Install git hooks
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
else
    echo "  No hooks directory found, skipping"
fi

if curl -fsLI http://github.com >/dev/null; then
    echo "Looks like github.com is reachable"
    echo "  Installing/updating Tmux plugins
    ~/.tmux/plugins/tpm/bin/install_plugins
    ~/.tmux/plugins/tpm/bin/update_plugins all
fi

