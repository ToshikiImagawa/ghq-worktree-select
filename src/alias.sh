# Alias function (optional)
gws() {
  local worktree_path
  worktree_path=$(ghq-worktree-select)
  if [[ -n "$worktree_path" ]]; then
    cd "$worktree_path" || return 1
  fi
}