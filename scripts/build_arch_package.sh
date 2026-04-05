#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/build_arch_package.sh
  ./scripts/build_arch_package.sh --archive ./dist/obs-studio-kepler-legacy-<version>.tar.gz
  ./scripts/build_arch_package.sh --output-dir ./dist

Options:
  --archive PATH    Use an existing release archive instead of the default one in dist/
  --output-dir DIR  Write the built package and checksums into DIR
  -h, --help        Show this help message
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_non_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    echo "Please run build_arch_package.sh as a normal user, not as root." >&2
    exit 1
  fi
}

output_dir="${OUTPUT_DIR:-$ROOT_DIR/dist}"
archive_path=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --archive" >&2
        exit 1
      }
      archive_path="$1"
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

need_cmd makepkg
need_cmd sha256sum
need_cmd bsdtar
require_non_root

release_name="obs-studio-kepler-legacy-$PROJECT_VERSION"

if [[ -z "$archive_path" ]]; then
  archive_path="$output_dir/$release_name.tar.gz"
fi

[[ -f "$archive_path" ]] || {
  echo "Release archive not found: $archive_path" >&2
  echo "Create it first with: ./release.sh" >&2
  exit 1
}

mkdir -p "$output_dir"
rm -f \
  "$output_dir"/obs-studio-kepler-legacy-bin-debug-*.pkg.tar.zst \
  "$output_dir"/obs-studio-kepler-legacy-bin-debug-*.pkg.tar.zst.sha256

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/obs-kepler-pkg.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$work_dir/packaging"
cp -a "$ROOT_DIR/packaging/PKGBUILD" "$work_dir/packaging/"
cp -a "$ROOT_DIR/packaging/obs-studio-kepler-legacy.install" "$work_dir/packaging/"
cp -a "$ROOT_DIR/VERSION" "$work_dir/"
cp -a "$archive_path" "$work_dir/packaging/"

pushd "$work_dir/packaging" >/dev/null
mapfile -t package_paths < <(
  PKGDEST="$output_dir" \
  SRCDEST="$work_dir/srcdest" \
  SRCPKGDEST="$output_dir" \
  LOGDEST="$work_dir/logdest" \
  makepkg --packagelist
)

PKGDEST="$output_dir" \
SRCDEST="$work_dir/srcdest" \
SRCPKGDEST="$output_dir" \
LOGDEST="$work_dir/logdest" \
makepkg --force --cleanbuild --clean --nodeps --noconfirm
popd >/dev/null

for package_path in "${package_paths[@]}"; do
  [[ -f "$package_path" ]] || continue
  (cd "$output_dir" && sha256sum "$(basename -- "$package_path")" > "$(basename -- "$package_path").sha256")
  echo "Arch package created:"
  echo "  $package_path"
  echo "Checksum file created:"
  echo "  $package_path.sha256"
done
