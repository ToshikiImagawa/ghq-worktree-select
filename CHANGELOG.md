# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [1.1.0] - 2026-02-17

### Added
- GitHub Actions workflow for automated release creation
- Security checklist and changelog-related utilities
- Claude Code skills for changelog generation, PR creation, and PR review
- PR template optimized for this project

### Changed
- Internationalized comments and refactored logic for clarity
- English translation of README.md with symbolic link functionality
- Improved installation instructions with 2-step Homebrew installation method

## [1.0.0] - 2026-02-17

### Added
- Initial implementation of `ghq-worktree-select`
- Select repositories managed by ghq using fzf
- Select a branch from the chosen repository using fzf
- Automatically create git worktrees
- Output the created worktree path (use with cd command)
- Homebrew support (`brew install ToshikiImagawa/ghq-worktree-select/ghq-worktree-select`)
- `--version` and `--help` options

### Changed
- Streamlined installation method to focus on Homebrew

### Dependencies
- [ghq](https://github.com/x-motemen/ghq) - Repository management
- [fzf](https://github.com/junegunn/fzf) - Fuzzy finder
- git - Version control (worktree support required)
