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
    read -r new_branch_name </dev/tty

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
    if ! git -C "${repo_path}" worktree add -q -b "$new_branch_name" "${new_worktree_path}" "${base_branch}"; then
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