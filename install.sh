#!/usr/bin/env bash

set -e

INSTALL_DIR="${HOME}/.ghq-worktree-select"
SCRIPT_NAME="ghq-worktree-select.sh"
REPO_URL="https://github.com/ToshikiImagawa/ghq-worktree-select.git"

echo "Installing ghq-worktree-select..."

# 依存関係チェック
echo "Checking dependencies..."
DEPS=(ghq git fzf)
MISSING=()

for cmd in "${DEPS[@]}"; do
  if ! command -v "$cmd" &>/dev/null; then
    MISSING+=("$cmd")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "Error: Missing dependencies: ${MISSING[*]}" >&2
  echo "Please install the following:" >&2
  for dep in "${MISSING[@]}"; do
    case "$dep" in
      ghq)
        echo "  - ghq: https://github.com/x-motemen/ghq" >&2
        ;;
      fzf)
        echo "  - fzf: https://github.com/junegunn/fzf" >&2
        ;;
      git)
        echo "  - git: https://git-scm.com/" >&2
        ;;
    esac
  done
  exit 1
fi

# インストールディレクトリ作成
if [[ -d "$INSTALL_DIR" ]]; then
  echo "Updating existing installation..."
  cd "$INSTALL_DIR"
  git pull
else
  echo "Cloning repository..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# シェル設定ファイルを判定
SHELL_RC=""
if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -n "$BASH_VERSION" ]] || [[ "$SHELL" == *"bash"* ]]; then
  SHELL_RC="$HOME/.bashrc"
fi

# sourceコマンドを追加
SOURCE_LINE="source $INSTALL_DIR/$SCRIPT_NAME"

if [[ -n "$SHELL_RC" ]]; then
  if ! grep -qF "$SOURCE_LINE" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# ghq-worktree-select" >> "$SHELL_RC"
    echo "$SOURCE_LINE" >> "$SHELL_RC"
    echo "✓ Added to $SHELL_RC"
  else
    echo "✓ Already configured in $SHELL_RC"
  fi

  echo ""
  echo "Installation complete!"
  echo "Please restart your shell or run:"
  echo "  source $SHELL_RC"
else
  echo ""
  echo "Installation complete!"
  echo "Please add the following line to your shell configuration file:"
  echo "  $SOURCE_LINE"
fi
