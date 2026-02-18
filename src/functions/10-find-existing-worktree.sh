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