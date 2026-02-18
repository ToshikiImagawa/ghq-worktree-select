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