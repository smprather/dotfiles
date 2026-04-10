# Git Hooks

Git hooks for this repo. They are installed automatically by `./install`.
To install manually:

```bash
cp hooks/* .git/hooks/ && chmod +x .git/hooks/*
```

## pre-commit

Scans for `.git` directories in subdirectories, removes them, and re-stages
the affected files before the commit proceeds.

**Why:** Bundled plugins (tmux, vim) include their own `.git` directories.
Committing them as-is produces "embedded git repository" warnings and can
accidentally create git submodules. This hook strips them so they're committed
as plain directories.

**Always install this hook** when working with bundled plugins — otherwise
adding a new plugin directory with its `.git` intact will cause commit warnings
or failures.
