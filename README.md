# ghq-worktree-select

A shell utility to select a branch from ghq-managed repositories and create/navigate to git worktrees

## Features

- Select repositories managed by ghq using fzf
- Select a branch from the chosen repository using fzf
- Automatically create git worktrees
- Output the created worktree path (use with cd command)

## Installation

### Homebrew (Recommended)

#### Method 1: Install in 2 steps (Recommended)

```bash
# 1. Add the tap (only once)
brew tap ToshikiImagawa/ghq-worktree-select

# 2. Install
brew install ghq-worktree-select
```

#### Method 2: Install with one-liner

```bash
brew install ToshikiImagawa/ghq-worktree-select/ghq-worktree-select
```

Installing via Homebrew automatically installs dependencies (ghq, fzf, git).

### Dependencies

- [ghq](https://github.com/x-motemen/ghq) - Repository management
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- git - Version control (worktree support required)

## Usage

### Basic Usage

```bash
# Select repository and branch to create worktree, then navigate to it
cd $(ghq-worktree-select)
```

### Options

```bash
ghq-worktree-select --version  # Show version information
ghq-worktree-select --help     # Show help
```

### Convenient Alias

Adding an alias to `.zshrc` or `.bashrc` is convenient:

```bash
alias gws='cd $(ghq-worktree-select)'
```

## Worktree Naming Convention

Created worktree paths follow this format:

```
{repository_path}+{branch_name}
```

Example:
- Repository: `~/ghq/github.com/user/repo`
- Branch: `feature/new-feature`
- Worktree: `~/ghq/github.com/user/repo+feature_new-feature`

(The `/` in branch names is replaced with `_`)

## Symlink Feature

Place a `.ghq-worktree-symlinks` file in the main branch to automatically create symlinks for specified files when creating worktrees for other branches.

### Configuration Example

`.ghq-worktree-symlinks`:

```
# Environment configuration files
.envrc
local.settings
.env
```

This allows sharing local configuration files from the main branch across all working branches.

### How to Use

1. Create `.ghq-worktree-symlinks` in the repository root of the main branch
2. List files to symlink, one per line
3. When creating a worktree for a working branch, symlinks are automatically created

### Notes

- Lines starting with `#` are treated as comments
- Existing files will not be overwritten (warnings will be displayed)
- Warnings will be displayed if source files don't exist, but processing continues
- Symlinks are not created when creating worktrees for the main or master branch itself

### Security Restrictions

For security reasons, the following path types are **not allowed** in `.ghq-worktree-symlinks`:

- ❌ Absolute paths (e.g., `/etc/passwd`, `/home/user/file`)
- ❌ Parent directory references (e.g., `../config`, `../../secret`)
- ❌ Paths starting with special characters (e.g., `~/.bashrc`, `$HOME/file`)

Only relative paths within the repository are allowed. Invalid paths will be skipped with a warning message.

**Example:**
```
# ✅ Valid - relative paths only
.envrc
config/local.yml
.env

# ❌ Invalid - will be rejected
/etc/hosts
../../../etc/passwd
~/.ssh/config
```

### Troubleshooting

**Symlinks not created:**
- Check that `.ghq-worktree-symlinks` is in the main/master branch
- Verify file permissions on the config file
- Ensure paths are relative and don't contain `..` or absolute paths

**To remove symlinks:**
```bash
# Find and remove symlinks in current directory
find . -type l -delete
```

## Uninstall

```bash
brew uninstall ghq-worktree-select
```

## License

MIT License

## Contributing

Issues and Pull Requests are welcome!

## Author

[Toshiki Imagawa](https://github.com/ToshikiImagawa)
