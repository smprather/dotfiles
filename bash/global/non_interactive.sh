# Non-interactive shell setup.
# Keep this minimal and deterministic for automation contexts.

# Prepend a directory to PATH only if it exists and is not already present.
path_prepend_if_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) PATH="$dir:$PATH" ;;
    esac
}

# Append a directory to PATH only if it exists and is not already present.
path_append_if_dir() {
    local dir="$1"
    [[ -d "$dir" ]] || return 0
    case ":$PATH:" in
        *":$dir:"*) ;;
        *) PATH="$PATH:$dir" ;;
    esac
}

# If PATH is empty for any reason, initialize a minimal fallback.
if [[ -z "${PATH:-}" ]]; then
    PATH="/usr/local/bin:/bin:/usr/bin:/usr/sbin"
fi

# Keep the standard system bins present.
path_prepend_if_dir "/usr/sbin"
path_prepend_if_dir "/usr/bin"
path_prepend_if_dir "/bin"
path_prepend_if_dir "/usr/local/bin"

# Add common user-level bins used by local tooling.
path_prepend_if_dir "$HOME/.cargo/bin"
path_prepend_if_dir "$HOME/.local/bin"
path_prepend_if_dir "$HOME/.opencode/bin"
path_prepend_if_dir "$HOME/node_modules/.bin"

# Include Node toolchain bin if already known.
if [[ -n "${NVM_BIN:-}" ]]; then
    path_prepend_if_dir "$NVM_BIN"
fi

# Keep Codex-bundled tools available as a fallback if local tools are missing.
path_append_if_dir "$HOME/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/path"

export PATH
unset -f path_prepend_if_dir
unset -f path_append_if_dir
