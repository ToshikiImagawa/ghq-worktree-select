#!/usr/bin/env bash
set -euo pipefail

# Get version from argument or extract from config.sh
VERSION="${1:-$(grep 'GHQ_WORKTREE_SELECT_VERSION=' src/config.sh | cut -d'"' -f2)}"

# Generate archive name
ARCHIVE_NAME="ghq-worktree-select-${VERSION}.tar.gz"

echo "==> Packaging ghq-worktree-select ${VERSION}"

# Check if dist/ghq-worktree-select exists
if [[ ! -f dist/ghq-worktree-select ]]; then
  echo "error: dist/ghq-worktree-select not found. Run ./build.sh first." >&2
  exit 1
fi

# Clean up previous dist-release directory
rm -rf dist-release

# Create temporary directory for distribution
mkdir -p dist-release/ghq-worktree-select

# Copy the built script
cp dist/ghq-worktree-select dist-release/ghq-worktree-select/

# Create tar.gz (with proper structure for Homebrew)
cd dist-release
tar -czf "../${ARCHIVE_NAME}" ghq-worktree-select/
cd ..

# Clean up temporary directory
rm -rf dist-release

# Verify archive contents
echo ""
echo "==> Archive contents:"
tar -tzf "${ARCHIVE_NAME}"

echo ""
echo "==> Created: ${ARCHIVE_NAME}"
echo "==> Size: $(du -h "${ARCHIVE_NAME}" | cut -f1)"
