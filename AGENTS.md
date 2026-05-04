# Agent Notes

Scope: entire repository.

## Commit Rule

Before every commit, sync the project Markdown docs that help agents cold-start:

- `README.md` for user-facing behavior and install options.
- `CLAUDE.md` for detailed repository architecture and operational notes.
- `AGENTS.md` for current agent rules, repo-specific pitfalls, and lessons learned.

Do this before staging the commit so the docs match the code being committed.

## Cold Start

This repository is offline-first, no-root dotfiles for EE Linux/Windows environments. Prefer changes that preserve RedHat/Alma/RHEL 7/8/9, Suse, WSL, Windows PowerShell, and locked-down corporate machines.

Use `rg` first. Use `bash -n install`, `python3 -m py_compile install.py`, and `bash -n bash/global/bashrc` after installer/shell edits. For Neovim config checks in this sandbox, use temporary writable state/cache dirs:

```bash
XDG_CACHE_HOME=/tmp/codex-nvim-cache XDG_STATE_HOME=/tmp/codex-nvim-state nvim --headless +qa
```

## Lessons Learned

- Do not use `xset +fp ~/.local/share/fonts` from shell startup. Even with valid `fonts.dir`, X may reject user-home paths such as `/home/mylesp` when the home directory is `700`. Use fontconfig (`fc-cache`) for modern Linux apps and WSLg.
- Vendored fonts belong in `~/.local/share/fonts`. Generate `fonts.scale`/`fonts.dir` when `mkfontscale`/`mkfontdir` exist, but rely on `fc-cache` for actual desktop app discovery.
- Font archives live under top-level `fonts/`. Archives over normal GitHub size limits should be split as `fonts/Name.zip.part-000`, `Name.zip.part-001`, etc. The installer rejoins split archives under `/tmp` before unzipping. Use 45 MiB chunks to stay below GitHub's 50 MB warning threshold.
- Pre-built Linux binaries live under `pre_built/<platform>/`, for example `pre_built/el8.x86_64.glibc2p28/`. Installer decompresses `bin/*.gz` to `~/.local/bin` and `lib64/*.gz` to `~/.local/lib64`, then uses vendored `patchelf` to set `RPATH=$ORIGIN/../lib64:$ORIGIN/../lib` on dynamic executables. Prefer this over global `LD_LIBRARY_PATH`. Installer runs `ldd` afterward and warns about missing `.so` dependencies.
- Use `./strip_pre_built` after adding pre-built binaries or libs; it strips ELF payloads inside `pre_built/**/*.gz` and recompresses with deterministic gzip metadata.
- WSL Windows Terminal does not read WSL fontconfig. Fonts must also be installed on the Windows side for Windows Terminal UI selection.
- Do not backup font files during pre-install backups; vendored Nerd Font archives are large. Backup uses `rsync` with font-extension excludes.
- `Snacks.nvim` provides the no-argument Neovim dashboard. Its dashboard buffer has filetype `snacks_dashboard`.
- `mini.trailspace` highlights trailing whitespace via window-local matches. Disabling only by filetype can race with dashboard rendering. For Snacks dashboard, set `vim.b.minitrailspace_disable = true`, `list = false`, and delete existing `MiniTrailspace` matches on dashboard open/update.
- Tree-sitter offline support targets Neovim v0.12+ only. Vendored `nvim-treesitter` and `treesitter-parser-registry` live under `treesitter/vendor/`; prebuilt parsers, parser-info, queries, and registry cache live under `treesitter/prebuilt/<platform>/`, where platform is `$(uname -s lower)-$(uname -m)-<glibc|musl>`. Build all supported parsers with `./treesitter/build_parsers`; installer copies vendor plugins to `~/.local/share/nvim/dotfiles/vendor/` and matching parser artifacts to `~/.local/share/nvim/tree-sitter-parsers/`.
- `tests/install_linux_tmp_home` simulates a fresh Linux user by running the real installer with a temp `HOME`, temp XDG cache/state dirs, test `--post-install-hook` scripts, and `--no-fonts`, then smoke-tests offline Tree-sitter with headless Neovim.
- Project Codex config lives in `.codex/config.toml`; this project sets `approval_policy = "never"` and default caveman full style through `developer_instructions`.
- Corp/site/user add-ons can be invoked explicitly with `./install --post-install-hook <script>`. Multiple hooks are allowed and run in argument order. Hooks run after global install steps and optional `--dev` git hooks, before automatic layer `install.sh` scripts, with `DOTFILES_*` environment variables including `DOTFILES_BACKUP_DIR`.
- Linux installer manages Starship at `~/.config/starship/starship.toml`; dev mode symlinks the `starship/` directory.
- Linux installer is implemented in Python 3.6-compatible `install.py`; `install` is only a Bash shim. It resolves the repo from the script path and must work when invoked from outside the repo root; `tests/install_linux_tmp_home` runs it from `/tmp` to catch regressions.
- Bash startup converges `~/.bashrc`, `~/.bash_profile`, `~/.bash_login`, and `~/.profile` onto `~/.config/bash/bashrc`. Keep the non-exported `DOTFILES_BASHRC_SOURCED` guard so accidental double-sourcing in one shell returns immediately without blocking exec into a preferred bash.
