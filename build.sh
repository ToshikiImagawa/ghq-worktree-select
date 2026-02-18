#!/usr/bin/env bash
set -euo pipefail

# Create dist directory
mkdir -p dist

# Build the final script by concatenating all source files
{
  cat src/header.txt
  echo ""
  cat src/config.sh
  echo ""

  # Add functions in dependency order
  cat src/functions/00-validate-path.sh
  echo ""
  cat src/functions/10-find-existing-worktree.sh
  echo ""
  cat src/functions/20-find-main-worktree.sh
  echo ""
  cat src/functions/30-create-symlinks.sh
  echo ""
  cat src/functions/40-check-dependencies.sh
  echo ""

  # Show help function with embedded help text
  echo "# Show help"
  echo "_ghq_worktree_select_show_help() {"
  echo "  cat <<'HELP_EOF'"
  cat src/help.txt
  echo ""
  echo "HELP_EOF"
  echo "}"
  echo ""

  cat src/functions/60-main.sh
  echo ""
  cat src/alias.sh
  echo ""
  cat src/footer.txt
} > dist/ghq-worktree-select

# Make executable
chmod +x dist/ghq-worktree-select

echo "Build completed: dist/ghq-worktree-select"
