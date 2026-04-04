#!/usr/bin/env bash
set -euo pipefail

list_patch_files() {
  local patches_dir="$1"

  [[ -d "$patches_dir" ]] || return 0

  find "$patches_dir" -maxdepth 1 -type f \
    \( -name '*.patch' -o -name '*.diff' \) \
    | sort
}

validate_patch_series() {
  local patches_dir="$1"
  local label="${2:-source}"
  local patch_file=""
  local patch_name=""

  [[ -d "$patches_dir" ]] || return 0

  while IFS= read -r patch_file; do
    [[ -n "$patch_file" ]] || continue

    patch_name="$(basename -- "$patch_file")"
    if [[ ! "$patch_name" =~ ^[0-9]{4}-.+\.(patch|diff)$ ]]; then
      echo "Invalid $label patch filename: $patch_name" >&2
      echo "Expected format: 0001-description.patch" >&2
      return 1
    fi
  done < <(list_patch_files "$patches_dir")
}

apply_patch_series() {
  local repo_dir="$1"
  local patches_dir="$2"
  local label="${3:-source}"
  local patch_file=""
  local patch_files=()
  local applied_any=false

  [[ -d "$patches_dir" ]] || return 0

  if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Patch target is not a git work tree: $repo_dir" >&2
    return 1
  fi

  validate_patch_series "$patches_dir" "$label"
  mapfile -t patch_files < <(list_patch_files "$patches_dir")

  if [[ "${#patch_files[@]}" -eq 0 ]]; then
    echo "==> No $label patches found in $patches_dir"
    return 0
  fi

  for patch_file in "${patch_files[@]}"; do
    [[ -n "$patch_file" ]] || continue

    echo "==> Applying $label patch $(basename -- "$patch_file")"

    if git -C "$repo_dir" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
      echo "    already applied"
      continue
    fi

    if ! git -C "$repo_dir" apply --check "$patch_file"; then
      echo "Patch validation failed: $patch_file" >&2
      return 1
    fi

    git -C "$repo_dir" apply "$patch_file"
    applied_any=true
  done

  if [[ "$applied_any" == true ]]; then
    echo "==> Completed $label patch application"
  fi
}
