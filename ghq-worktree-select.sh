#!/usr/bin/env bash
# ghq-worktree-select - ghq管理下のリポジトリからブランチを選択してworktreeを作成

# バージョン情報
GHQ_WORKTREE_SELECT_VERSION="1.0.0"

# ヘルプ表示
_ghq_worktree_select_show_help() {
  cat <<EOF
ghq-worktree-select - ghq管理下のリポジトリからブランチを選択してworktreeを作成

使い方:
  ghq-worktree-select    リポジトリとブランチを選択してworktreeパスを出力
  gws                    ghq-worktree-selectを実行してディレクトリを移動

オプション:
  --version              バージョン情報を表示
  --help                 このヘルプを表示

必要な依存関係:
  - ghq: リポジトリ管理
  - fzf: ファジーファインダー
  - git: バージョン管理 (worktree対応版)
EOF
}

# 依存関係チェック
_ghq_worktree_select_check_dependencies() {
  local deps=(ghq git fzf)
  local missing=()

  for cmd in "${deps[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: Missing dependencies: ${missing[*]}" >&2
    echo "Please install: ${missing[*]}" >&2
    return 1
  fi
}

# メイン関数
ghq-worktree-select() {
  # オプション処理
  if [[ "$1" == "--version" ]]; then
    echo "ghq-worktree-select version ${GHQ_WORKTREE_SELECT_VERSION}"
    return 0
  fi

  if [[ "$1" == "--help" ]]; then
    _ghq_worktree_select_show_help
    return 0
  fi

  # 依存関係チェック
  _ghq_worktree_select_check_dependencies || return 1

  # 1. リポジトリを選択
  local repo=$(ghq list | fzf \
    --prompt="Repository> " \
    --preview 'git -C $(ghq root)/{} log --oneline -10 --color=always 2>/dev/null || echo "No git repo"')

  if [[ -z "$repo" ]]; then
    return 1
  fi

  local repo_path="$(ghq root)/${repo}"

  # 2. ブランチを選択
  local branch=$(git -C "${repo_path}" branch --format='%(refname:short)' | fzf \
    --prompt="Branch> " \
    --preview "git -C '${repo_path}' log --oneline -20 --color=always {}")

  if [[ -z "$branch" ]]; then
    return 1
  fi

  # 3. worktreeパスを生成
  local repo_base_path="${repo_path}"
  repo_base_path=${repo_base_path%+*}
  local worktree_path="${repo_base_path}+${branch//\//_}"

  # 4. 既存チェック
  if [[ -d "$worktree_path" ]]; then
    echo "warning: ${worktree_path} already exists" >&2
    echo "${worktree_path}"
    return 0
  fi

  # 5. worktree作成
  git -C "${repo_path}" worktree add -q "${worktree_path}" "${branch}" || return 1
  echo "${worktree_path}"
}

# エイリアス関数（オプション）
gws() {
  local worktree_path=$(ghq-worktree-select)
  if [[ -n "$worktree_path" ]]; then
    cd "$worktree_path" || return 1
  fi
}

# スクリプトが直接実行された場合はメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ghq-worktree-select "$@"
fi
