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