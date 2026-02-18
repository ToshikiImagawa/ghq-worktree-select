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