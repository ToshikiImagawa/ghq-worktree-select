#!/usr/bin/env bash
# ghq-worktree-select - Select a branch from ghq-managed repositories and create a worktree

# Version information
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

Creating a new branch:
  Select "+ Create new branch..." from the branch list to create a new branch
  and worktree. You'll be prompted for the new branch name and base branch.

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

# Check dependencies
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

# Find existing worktree path
_find_existing_worktree() {
  local worktree_list="$1"
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
  done <<< "$worktree_list"

  echo ""
}

# Find main branch worktree path
_find_main_worktree() {
  local worktree_list="$1"
  local repo_path="$2"
  local main_worktree

  # Search for main branch
  main_worktree=$(_find_existing_worktree "$worktree_list" "main")
  if [[ -n "$main_worktree" ]]; then
    echo "$main_worktree"
    return 0
  fi

  # Search for master branch
  main_worktree=$(_find_existing_worktree "$worktree_list" "master")
  if [[ -n "$main_worktree" ]]; then
    echo "$main_worktree"
    return 0
  fi

  # Return repository root if not found
  echo "$repo_path"
}

# Validate file path for security
_validate_path() {
  local path="$1"

  # Reject absolute paths
  if [[ "$path" =~ ^/ ]]; then
    return 1
  fi

  # Reject parent directory references
  if [[ "$path" =~ \.\. ]]; then
    return 1
  fi

  # Reject paths starting with special characters
  if [[ "$path" =~ ^[~\$] ]]; then
    return 1
  fi

  return 0
}

# Create symlinks
_create_symlinks() {
  local main_worktree="$1"
  local target_worktree="$2"
  local config_file="${main_worktree}/.ghq-worktree-symlinks"

  # Skip if config file doesn't exist
  if [[ ! -f "$config_file" ]]; then
    return 0
  fi

  # Check if config file is readable
  if [[ ! -r "$config_file" ]]; then
    echo "warning: cannot read config file: ${config_file}" >&2
    return 1
  fi

  while IFS= read -r file || [[ -n "$file" ]]; do
    # Skip comment lines and empty lines
    [[ "$file" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${file// /}" ]] && continue

    # Validate file path for security
    if ! _validate_path "$file"; then
      echo "warning: invalid path in config (security risk): ${file}" >&2
      continue
    fi

    local source_file="${main_worktree}/${file}"
    local target_file="${target_worktree}/${file}"

    # Warn if source file doesn't exist
    if [[ ! -e "$source_file" ]]; then
      echo "warning: source file not found: ${source_file}" >&2
      continue
    fi

    # Skip if target is already a symlink to the same source
    if [[ -L "$target_file" ]]; then
      local link_target
      link_target=$(readlink "$target_file")
      if [[ "$link_target" == "$source_file" ]]; then
        continue
      fi
    fi

    # Warn if target already exists
    if [[ -e "$target_file" || -L "$target_file" ]]; then
      echo "warning: target already exists, skipping: ${target_file}" >&2
      continue
    fi

    # Create parent directory
    local target_dir
    target_dir=$(dirname "$target_file")
    if [[ ! -d "$target_dir" ]]; then
      if ! mkdir -p "$target_dir" 2>/dev/null; then
        echo "warning: failed to create directory: ${target_dir} (permission denied or invalid path)" >&2
        continue
      fi
    fi

    # Create symlink
    if ! ln -s "$source_file" "$target_file" 2>/dev/null; then
      echo "warning: failed to create symlink: ${target_file} -> ${source_file} (permission denied or invalid path)" >&2
    fi
  done < "$config_file"
}

# Main function
ghq-worktree-select() {
  # Handle options
  if [[ "$1" == "--version" ]]; then
    echo "ghq-worktree-select version ${GHQ_WORKTREE_SELECT_VERSION}"
    return 0
  fi

  if [[ "$1" == "--help" ]]; then
    _ghq_worktree_select_show_help
    return 0
  fi

  # Check dependencies
  _ghq_worktree_select_check_dependencies || return 1

  # 1. Select repository
  local repo
  repo=$(ghq list | fzf \
    --prompt="Repository> " \
    --preview "git -C \$(ghq root)/{} log --oneline -10 --color=always 2>/dev/null || echo 'No git repo'")

  if [[ -z "$repo" ]]; then
    return 1
  fi

  local repo_path
  repo_path="$(ghq root)/${repo}"

  # 2. Select branch (with option to create new branch)
  local branch
  branch=$(
    {
      echo "+ Create new branch..."
      git -C "${repo_path}" branch --format='%(refname:short)'
    } | fzf \
      --prompt="Branch> " \
      --preview "
        if [[ {} == '+ Create new branch...' ]]; then
          echo 'Create a new branch and worktree'
        else
          git -C '${repo_path}' log --oneline -20 --color=always {}
        fi
      "
  )

  if [[ -z "$branch" ]]; then
    return 1
  fi

  # 2.5. Handle new branch creation
  if [[ "$branch" == "+ Create new branch..." ]]; then
    # Get new branch name from user
    echo -n "New branch name> " >&2
    read -r new_branch_name

    # Validate input is not empty
    if [[ -z "$new_branch_name" ]]; then
      echo "error: branch name is required" >&2
      return 1
    fi

    # Validate branch name format
    if ! git check-ref-format "refs/heads/$new_branch_name" &>/dev/null; then
      echo "error: invalid branch name: $new_branch_name" >&2
      return 1
    fi

    # Check if branch already exists
    if git -C "${repo_path}" show-ref --verify --quiet "refs/heads/$new_branch_name"; then
      echo "error: branch already exists: $new_branch_name" >&2
      return 1
    fi

    # Select base branch
    local base_branch
    base_branch=$(git -C "${repo_path}" branch --format='%(refname:short)' | fzf \
      --prompt="Base branch> " \
      --preview "git -C '${repo_path}' log --oneline -20 --color=always {}")

    if [[ -z "$base_branch" ]]; then
      return 1
    fi

    # Generate worktree path for new branch
    local repo_base_path="${repo_path}"
    repo_base_path=${repo_base_path%+*}
    local new_worktree_path="${repo_base_path}+${new_branch_name//\//_}"

    # Check if directory already exists
    if [[ -d "$new_worktree_path" ]]; then
      echo "error: ${new_worktree_path} already exists" >&2
      return 1
    fi

    # Create new worktree with new branch
    if ! git -C "${repo_path}" worktree add -b "$new_branch_name" "${new_worktree_path}" "${base_branch}"; then
      return 1
    fi

    # Create symlinks (except for main/master branch)
    if [[ "$new_branch_name" != "main" && "$new_branch_name" != "master" ]]; then
      local worktree_list
      worktree_list=$(git -C "$repo_path" worktree list --porcelain 2>/dev/null)
      local main_worktree
      main_worktree=$(_find_main_worktree "$worktree_list" "$repo_path")
      _create_symlinks "$main_worktree" "$new_worktree_path"
    fi

    echo "${new_worktree_path}"
    return 0
  fi

  # 3. Get worktree list (cache)
  local worktree_list
  worktree_list=$(git -C "$repo_path" worktree list --porcelain 2>/dev/null)

  # 4. Generate worktree path
  local repo_base_path="${repo_path}"
  repo_base_path=${repo_base_path%+*}
  local worktree_path="${repo_base_path}+${branch//\//_}"

  # 5. Check for existing worktree
  local existing_worktree
  existing_worktree=$(_find_existing_worktree "$worktree_list" "$branch")
  if [[ -n "$existing_worktree" ]]; then
    echo "$existing_worktree"
    return 0
  fi

  # 6. Check for existing directory (just in case)
  if [[ -d "$worktree_path" ]]; then
    echo "warning: ${worktree_path} already exists" >&2
    echo "${worktree_path}"
    return 0
  fi

  # 7. Create worktree
  git -C "${repo_path}" worktree add -q "${worktree_path}" "${branch}" || return 1

  # 8. Create symlinks (except for main/master branch)
  if [[ "$branch" != "main" && "$branch" != "master" ]]; then
    local main_worktree
    main_worktree=$(_find_main_worktree "$worktree_list" "$repo_path")
    _create_symlinks "$main_worktree" "$worktree_path"
  fi

  echo "${worktree_path}"
}

# Alias function (optional)
gws() {
  local worktree_path
  worktree_path=$(ghq-worktree-select)
  if [[ -n "$worktree_path" ]]; then
    cd "$worktree_path" || return 1
  fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ghq-worktree-select "$@"
fi
