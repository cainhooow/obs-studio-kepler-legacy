#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/libpatches.sh
source "$ROOT_DIR/scripts/libpatches.sh"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/check_patch_series.sh
  ./scripts/check_patch_series.sh --keep-work-dir
  ./scripts/check_patch_series.sh --work-dir /tmp/obs-kepler-checks

Options:
  --keep-work-dir  Do not delete the temporary checkout directory
  --work-dir DIR   Reuse or create the given working directory
  -h, --help       Show this help message
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

clone_clean_checkout() {
  local url="$1"
  local dir="$2"
  local ref="$3"

  rm -rf "$dir"
  git clone --filter=blob:none "$url" "$dir" >/dev/null 2>&1
  git -C "$dir" checkout --detach "$ref" >/dev/null 2>&1
}

validate_series_against_ref() {
  local label="$1"
  local url="$2"
  local ref="$3"
  local repo_dir="$4"
  local patches_dir="$5"
  local patch_files=()

  validate_patch_series "$patches_dir" "$label"
  mapfile -t patch_files < <(list_patch_files "$patches_dir")

  if [[ "${#patch_files[@]}" -eq 0 ]]; then
    echo "==> No $label patches to validate"
    return 0
  fi

  echo "==> Validating $label patch series against $ref"
  clone_clean_checkout "$url" "$repo_dir" "$ref"
  apply_patch_series "$repo_dir" "$patches_dir" "$label"
  git -C "$repo_dir" diff --check
}

keep_work_dir=false
work_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --keep-work-dir)
      keep_work_dir=true
      ;;
    --work-dir)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --work-dir" >&2
        exit 1
      }
      work_dir="$1"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

need_cmd git

if [[ -z "$work_dir" ]]; then
  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/obs-kepler-patch-check.XXXXXX")"
elif [[ ! -d "$work_dir" ]]; then
  mkdir -p "$work_dir"
fi

if [[ "$keep_work_dir" != true ]]; then
  trap 'rm -rf "$work_dir"' EXIT
fi

validate_series_against_ref \
  "OBS" \
  "$OBS_UPSTREAM_URL" \
  "$OBS_TAG" \
  "$work_dir/obs-studio" \
  "$ROOT_DIR/patches/obs"

validate_series_against_ref \
  "FFmpeg" \
  "$FFMPEG_UPSTREAM_URL" \
  "$FFMPEG_TAG" \
  "$work_dir/ffmpeg" \
  "$ROOT_DIR/patches/ffmpeg"

echo "Patch series validation completed successfully."
