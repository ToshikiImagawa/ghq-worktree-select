#!/usr/bin/env bash
set -euo pipefail

echo "=== ghq-worktree-select Test Suite ==="
echo ""

# Test 1: Version check
echo "[1/5] Testing --version option..."
version_output=$(./dist/ghq-worktree-select --version)
if [[ "$version_output" == "ghq-worktree-select version 1.2.0" ]]; then
  echo "✓ Version check passed"
else
  echo "✗ Version check failed: $version_output"
  exit 1
fi
echo ""

# Test 2: Help check
echo "[2/5] Testing --help option..."
help_output=$(./dist/ghq-worktree-select --help | head -1)
if [[ "$help_output" == *"ghq-worktree-select"* ]]; then
  echo "✓ Help check passed"
else
  echo "✗ Help check failed"
  exit 1
fi
echo ""

# Test 3: Load functions
echo "[3/5] Testing function definitions..."
source ./dist/ghq-worktree-select
if declare -f ghq-worktree-select >/dev/null && \
   declare -f _validate_path >/dev/null && \
   declare -f _create_symlinks >/dev/null; then
  echo "✓ Function definitions passed"
else
  echo "✗ Function definitions failed"
  exit 1
fi
echo ""

# Test 4: Path validation function
echo "[4/5] Testing _validate_path function..."
# Valid paths
if _validate_path "relative/path" && \
   _validate_path ".envrc" && \
   _validate_path "config/local.yml"; then
  echo "✓ Valid paths accepted"
else
  echo "✗ Valid paths rejected"
  exit 1
fi

# Invalid paths (intentionally testing literal ~, not expansion)
# shellcheck disable=SC2088
if ! _validate_path "/absolute/path" && \
   ! _validate_path "../parent" && \
   ! _validate_path "~/.ssh/config" && \
   ! _validate_path "\$HOME/file"; then
  echo "✓ Invalid paths rejected"
else
  echo "✗ Invalid paths accepted"
  exit 1
fi
echo ""

# Test 5: Dependency check
echo "[5/5] Testing dependency check..."
if _ghq_worktree_select_check_dependencies; then
  echo "✓ All dependencies available"
else
  echo "✗ Missing dependencies"
  exit 1
fi
echo ""

echo "=== All tests passed! ==="
echo ""
echo "To test the new branch creation feature interactively:"
echo "  1. Run: ./dist/ghq-worktree-select"
echo "  2. Select a repository"
echo "  3. Select '+ Create new branch...'"
echo "  4. Enter a branch name (e.g., 'test/new-feature')"
echo "  5. Select a base branch"
echo "  6. Verify the worktree is created and the path is output"
