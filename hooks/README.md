# Git Hooks

This directory contains git hooks for the dotfiles repository.

## Installation

To install the hooks, run:

```bash
cp hooks/* .git/hooks/
chmod +x .git/hooks/*
```

Or use the provided install script (if one exists).

## Available Hooks

### pre-commit

**Purpose:** Removes `.git` directories from embedded repositories before committing.

**Why:** When bundling external dependencies (like tmux plugins) for offline environments, we include the full plugin directories but don't want to track their git history. This hook automatically strips out the `.git` directories, converting them from git submodules to regular directories.

**What it does:**
1. Finds all `.git` directories in subdirectories (not the root)
2. Removes them
3. Re-stages the affected files

This prevents "embedded git repository" warnings when committing bundled dependencies.
