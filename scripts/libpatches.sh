#!/usr/bin/env bash
set -euo pipefail

PATCH_METADATA_FIELDS=(
  "Patch-Name"
  "Patch-Origin"
  "Patch-Reason"
  "Patch-Risk"
)

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

    validate_patch_metadata "$patch_file" "$label"
  done < <(list_patch_files "$patches_dir")
}

find_patch_payload_start() {
  local patch_file="$1"
  local start_line=""

  start_line="$(grep -n -m1 '^diff --git ' "$patch_file" | cut -d: -f1 || true)"
  if [[ -z "$start_line" ]]; then
    echo "Patch payload is missing a unified diff body: $patch_file" >&2
    return 1
  fi

  printf '%s\n' "$start_line"
}

validate_patch_metadata() {
  local patch_file="$1"
  local label="${2:-source}"
  local patch_name
  local start_line=""
  local preamble=""
  local field=""

  patch_name="$(basename -- "$patch_file")"
  start_line="$(find_patch_payload_start "$patch_file")"

  if (( start_line <= 1 )); then
    echo "Missing metadata header in $label patch: $patch_name" >&2
    echo "Expected comment lines for: ${PATCH_METADATA_FIELDS[*]}" >&2
    return 1
  fi

  preamble="$(sed -n "1,$((start_line - 1))p" "$patch_file")"

  for field in "${PATCH_METADATA_FIELDS[@]}"; do
    if ! grep -Eq "^# ${field}: .+" <<<"$preamble"; then
      echo "Missing ${field} metadata in $label patch: $patch_name" >&2
      return 1
    fi
  done
}

write_patch_payload() {
  local patch_file="$1"
  local output_file="$2"
  local start_line=""

  start_line="$(find_patch_payload_start "$patch_file")"
  tail -n +"$start_line" "$patch_file" > "$output_file"
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

    local payload_file=""
    payload_file="$(mktemp "${TMPDIR:-/tmp}/$(basename -- "$patch_file").XXXXXX")"
    write_patch_payload "$patch_file" "$payload_file"

    if git -C "$repo_dir" apply --reverse --check "$payload_file" >/dev/null 2>&1; then
      echo "    already applied"
      rm -f "$payload_file"
      continue
    fi

    if ! git -C "$repo_dir" apply --check "$payload_file"; then
      rm -f "$payload_file"
      echo "Patch validation failed: $patch_file" >&2
      return 1
    fi

    git -C "$repo_dir" apply "$payload_file"
    rm -f "$payload_file"
    applied_any=true
  done

  if [[ "$applied_any" == true ]]; then
    echo "==> Completed $label patch application"
  fi
}
