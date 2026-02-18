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