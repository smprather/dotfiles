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

Use `rg` first. Use `bash -n install` and `bash -n bash/global/bashrc` after shell edits. For Neovim config checks in this sandbox, use temporary writable state/cache dirs:

```bash
XDG_CACHE_HOME=/tmp/codex-nvim-cache XDG_STATE_HOME=/tmp/codex-nvim-state nvim --headless +qa
```

## Lessons Learned

- Do not use `xset +fp ~/.local/share/fonts` from shell startup. Even with valid `fonts.dir`, X may reject user-home paths such as `/home/mylesp` when the home directory is `700`. Use fontconfig (`fc-cache`) for modern Linux apps and WSLg.
- Vendored fonts belong in `~/.local/share/fonts`. Generate `fonts.scale`/`fonts.dir` when `mkfontscale`/`mkfontdir` exist, but rely on `fc-cache` for actual desktop app discovery.
- Font archives over normal GitHub size limits should be split as `vendor/fonts/Name.zip.part-000`, `Name.zip.part-001`, etc. The installer rejoins split archives under `/tmp` before unzipping. Keep chunks below 100 MB.
- WSL Windows Terminal does not read WSL fontconfig. Fonts must also be installed on the Windows side for Windows Terminal UI selection.
- Do not backup font files during pre-install backups; vendored Nerd Font archives are large. Backup uses `rsync` with font-extension excludes.
- `Snacks.nvim` provides the no-argument Neovim dashboard. Its dashboard buffer has filetype `snacks_dashboard`.
- `mini.trailspace` highlights trailing whitespace via window-local matches. Disabling only by filetype can race with dashboard rendering. For Snacks dashboard, set `vim.b.minitrailspace_disable = true`, `list = false`, and delete existing `MiniTrailspace` matches on dashboard open/update.
- Project Codex config lives in `.codex/config.toml`; this project sets `approval_policy = "never"` and default caveman full style through `developer_instructions`.
