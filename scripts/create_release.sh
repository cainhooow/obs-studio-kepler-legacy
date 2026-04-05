#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=install/common.sh
source "$ROOT_DIR/install/common.sh"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"

usage() {
  cat <<'EOF'
Usage:
  ./release.sh
  ./release.sh --skip-checks
  ./release.sh --output-dir ./dist

Options:
  --skip-checks     Skip ./scripts/check_project.sh before packaging
  --output-dir DIR  Write the release archive and checksum into DIR
  -h, --help        Show this help message
EOF
}

copy_release_item() {
  local source_path="$1"
  local target_dir="$2"

  [[ -e "$source_path" ]] || return 0
  cp -a "$source_path" "$target_dir/"
}

output_dir="${OUTPUT_DIR:-$ROOT_DIR/dist}"
skip_checks=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-checks)
      skip_checks=true
      ;;
    --output-dir)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --output-dir" >&2
        exit 1
      }
      output_dir="$1"
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

require_bundle "$ROOT_DIR"

if [[ "$skip_checks" != true ]]; then
  "$ROOT_DIR/scripts/check_project.sh"
fi

if [[ -x "$ROOT_DIR/scripts/make_bundle_relocatable.sh" ]]; then
  "$ROOT_DIR/scripts/make_bundle_relocatable.sh" "$ROOT_DIR"
fi

mkdir -p "$output_dir"

release_name="obs-studio-kepler-legacy-$PROJECT_VERSION"
staging_root="$(mktemp -d "${TMPDIR:-/tmp}/${release_name}.XXXXXX")"
staging_dir="$staging_root/$release_name"

trap 'rm -rf "$staging_root"' EXIT

mkdir -p "$staging_dir"

copy_release_item "$ROOT_DIR/.local" "$staging_dir"
copy_release_item "$ROOT_DIR/bin" "$staging_dir"
copy_release_item "$ROOT_DIR/docs" "$staging_dir"
copy_release_item "$ROOT_DIR/install" "$staging_dir"
copy_release_item "$ROOT_DIR/packaging" "$staging_dir"
copy_release_item "$ROOT_DIR/patches" "$staging_dir"
copy_release_item "$ROOT_DIR/scripts" "$staging_dir"
copy_release_item "$ROOT_DIR/share" "$staging_dir"
copy_release_item "$ROOT_DIR/.gitignore" "$staging_dir"
copy_release_item "$ROOT_DIR/CHANGELOG.md" "$staging_dir"
copy_release_item "$ROOT_DIR/CONTRIBUTING.md" "$staging_dir"
copy_release_item "$ROOT_DIR/README.md" "$staging_dir"
copy_release_item "$ROOT_DIR/SECURITY.md" "$staging_dir"
copy_release_item "$ROOT_DIR/VERSION" "$staging_dir"
copy_release_item "$ROOT_DIR/install.sh" "$staging_dir"
copy_release_item "$ROOT_DIR/release.sh" "$staging_dir"
copy_release_item "$ROOT_DIR/uninstall.sh" "$staging_dir"

archive_path="$output_dir/$release_name.tar.gz"
checksum_path="$archive_path.sha256"

tar -C "$staging_root" -czf "$archive_path" "$release_name"
(cd "$output_dir" && sha256sum "$(basename -- "$archive_path")" > "$(basename -- "$checksum_path")")

echo "Release archive created:"
echo "  $archive_path"
echo "Checksum file created:"
echo "  $checksum_path"
