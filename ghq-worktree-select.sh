#!/usr/bin/env bash
# ghq-worktree-select - ghq管理下のリポジトリからブランチを選択してworktreeを作成

# バージョン情報
GHQ_WORKTREE_SELECT_VERSION="1.1.0"

# Show help
_ghq_worktree_select_show_help() {
  cat <<EOF
ghq-worktree-select - Select a branch from ghq-managed repositories and create a worktree

Usage:
  ghq-worktree-select    Select repository and branch, then output worktree path
  gws                    Execute ghq-worktree-select and move to the directory

Options:
  --version              Show version information
  --help                 Show this help

Symlink feature:
  Place a .ghq-worktree-symlinks file in the main branch to automatically
  create symlinks for specified files when creating worktrees for other branches.

  Example (.ghq-worktree-symlinks):
    # Environment configuration files
    .envrc
    local.settings
    .env

Dependencies:
  - ghq: Repository management
  - fzf: Fuzzy finder
  - git: Version control (worktree support required)
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

# 既存のワークツリーパスを検索
_find_existing_worktree() {
  local repo_path="$1"
  local branch="$2"
  local current_worktree=""
  local current_branch=""

  while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.+)$ ]]; then
      current_worktree="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^branch\ refs/heads/(.+)$ ]]; then
      current_branch="${BASH_REMATCH[1]}"
      if [[ "$current_branch" == "$branch" ]]; then
        echo "$current_worktree"
        return 0
      fi
    fi
  done < <(git -C "$repo_path" worktree list --porcelain 2>/dev/null)

  echo ""
}

# mainブランチのワークツリーパスを検索
_find_main_worktree() {
  local repo_path="$1"
  local main_worktree

  # mainブランチを検索
  main_worktree=$(_find_existing_worktree "$repo_path" "main")
  if [[ -n "$main_worktree" ]]; then
    echo "$main_worktree"
    return 0
  fi

  # masterブランチを検索
  main_worktree=$(_find_existing_worktree "$repo_path" "master")
  if [[ -n "$main_worktree" ]]; then
    echo "$main_worktree"
    return 0
  fi

  # 見つからない場合はリポジトリルートを返す
  echo "$repo_path"
}

# シンボリックリンクを作成
_create_symlinks() {
  local main_worktree="$1"
  local target_worktree="$2"
  local config_file="${main_worktree}/.ghq-worktree-symlinks"

  # 設定ファイルが存在しない場合はスキップ
  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  while IFS= read -r file || [[ -n "$file" ]]; do
    # コメント行と空行をスキップ
    [[ "$file" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${file// /}" ]] && continue

    local source_file="${main_worktree}/${file}"
    local target_file="${target_worktree}/${file}"

    # ソースファイルが存在しない場合は警告
    if [[ ! -e "$source_file" ]]; then
      echo "warning: source file not found: ${source_file}" >&2
      continue
    fi

    # ターゲットが既存のシンボリックリンク（同じソース）の場合はスキップ
    if [[ -L "$target_file" ]]; then
      local link_target
      link_target=$(readlink "$target_file")
      if [[ "$link_target" == "$source_file" ]]; then
        continue
      fi
    fi

    # ターゲットが既存のファイル/ディレクトリの場合は警告
    if [[ -e "$target_file" || -L "$target_file" ]]; then
      echo "warning: target already exists, skipping: ${target_file}" >&2
      continue
    fi

    # シンボリックリンクを作成
    ln -s "$source_file" "$target_file" 2>/dev/null || {
      echo "warning: failed to create symlink: ${target_file}" >&2
    }
  done < "$config_file"
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
  local repo
  repo=$(ghq list | fzf \
    --prompt="Repository> " \
    --preview "git -C \$(ghq root)/{} log --oneline -10 --color=always 2>/dev/null || echo 'No git repo'")

  if [[ -z "$repo" ]]; then
    return 1
  fi

  local repo_path
  repo_path="$(ghq root)/${repo}"

  # 2. ブランチを選択
  local branch
  branch=$(git -C "${repo_path}" branch --format='%(refname:short)' | fzf \
    --prompt="Branch> " \
    --preview "git -C '${repo_path}' log --oneline -20 --color=always {}")

  if [[ -z "$branch" ]]; then
    return 1
  fi

  # 3. worktreeパスを生成
  local repo_base_path="${repo_path}"
  repo_base_path=${repo_base_path%+*}
  local worktree_path="${repo_base_path}+${branch//\//_}"

  # 4. 既存ワークツリーをチェック
  local existing_worktree
  existing_worktree=$(_find_existing_worktree "$repo_path" "$branch")
  if [[ -n "$existing_worktree" ]]; then
    echo "$existing_worktree"
    return 0
  fi

  # 5. 既存ディレクトリチェック（念のため）
  if [[ -d "$worktree_path" ]]; then
    echo "warning: ${worktree_path} already exists" >&2
    echo "${worktree_path}"
    return 0
  fi

  # 6. worktree作成
  git -C "${repo_path}" worktree add -q "${worktree_path}" "${branch}" || return 1

  # 7. シンボリックリンク作成（mainブランチ以外の場合）
  if [[ "$branch" != "main" && "$branch" != "master" ]]; then
    local main_worktree
    main_worktree=$(_find_main_worktree "$repo_path")
    _create_symlinks "$main_worktree" "$worktree_path"
  fi

  echo "${worktree_path}"
}

# エイリアス関数（オプション）
gws() {
  local worktree_path
  worktree_path=$(ghq-worktree-select)
  if [[ -n "$worktree_path" ]]; then
    cd "$worktree_path" || return 1
  fi
}

# スクリプトが直接実行された場合はメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ghq-worktree-select "$@"
fi
