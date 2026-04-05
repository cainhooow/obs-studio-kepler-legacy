#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/test_release_artifacts.sh
  ./scripts/test_release_artifacts.sh --build-package
  ./scripts/test_release_artifacts.sh --runtime-smoke
  ./scripts/test_release_artifacts.sh --archive ./dist/obs-studio-kepler-legacy-<version>.tar.gz
  ./scripts/test_release_artifacts.sh --package ./dist/obs-studio-kepler-legacy-bin-<version>-1-x86_64.pkg.tar.zst

Options:
  --archive PATH    Test the given release archive
  --package PATH    Test the given Arch package
  --build-package   Build the Arch package first if one is not present
  --runtime-smoke   Run ffmpeg/obs version checks from an extracted tarball
  -h, --help        Show this help message
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

archive_path=""
package_path=""
build_package=false
runtime_smoke=false

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
    --package)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --package" >&2
        exit 1
      }
      package_path="$1"
      ;;
    --build-package)
      build_package=true
      ;;
    --runtime-smoke)
      runtime_smoke=true
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

need_cmd tar
need_cmd sha256sum
need_cmd bsdtar

release_name="obs-studio-kepler-legacy-$PROJECT_VERSION"
package_name="obs-studio-kepler-legacy-bin-${PROJECT_VERSION//-/_}-1-x86_64.pkg.tar.zst"

if [[ -z "$archive_path" ]]; then
  archive_path="$ROOT_DIR/dist/$release_name.tar.gz"
fi

[[ -f "$archive_path" ]] || {
  echo "Release archive not found: $archive_path" >&2
  exit 1
}

[[ -f "$archive_path.sha256" ]] || {
  echo "Release checksum not found: $archive_path.sha256" >&2
  exit 1
}

echo "==> Verifying release archive checksum"
(cd "$(dirname -- "$archive_path")" && sha256sum -c "$(basename -- "$archive_path").sha256")

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/obs-kepler-release-test.XXXXXX")"
trap 'rm -rf "$work_dir"' EXIT

echo "==> Inspecting release archive contents"
tar -C "$work_dir" -xzf "$archive_path"

extracted_root="$work_dir/$release_name"

[[ -x "$extracted_root/bin/obs-studio-kepler-legacy" ]]
[[ -x "$extracted_root/bin/ffmpeg-kepler-legacy" ]]
[[ -x "$extracted_root/install.sh" ]]
[[ -f "$extracted_root/packaging/PKGBUILD" ]]
[[ -x "$extracted_root/scripts/check_project.sh" ]]
[[ -x "$extracted_root/.local/obs-kepler/bin/obs" ]]
[[ -x "$extracted_root/.local/ffmpeg-nvenc470/bin/ffmpeg" ]]

echo "==> Release archive structure looks correct"

if [[ "$runtime_smoke" == true ]]; then
  echo "==> Running runtime smoke tests from the extracted release"
  "$extracted_root/bin/ffmpeg-kepler-legacy" -version >/dev/null
  "$extracted_root/bin/obs-studio-kepler-legacy" --version >/dev/null
fi

if [[ -z "$package_path" ]]; then
  package_path="$ROOT_DIR/dist/$package_name"
fi

if [[ ! -f "$package_path" && "$build_package" == true ]]; then
  "$ROOT_DIR/scripts/build_arch_package.sh" --archive "$archive_path"
fi

if [[ -f "$package_path" ]]; then
  need_cmd pacman
  echo "==> Verifying Arch package checksum"
  if [[ -f "$package_path.sha256" ]]; then
    (cd "$(dirname -- "$package_path")" && sha256sum -c "$(basename -- "$package_path").sha256")
  else
    echo "No checksum file found for package; skipping checksum verification"
  fi

  echo "==> Inspecting Arch package metadata"
  pacman -Qip "$package_path" >/dev/null
  package_listing="$(pacman -Qlp "$package_path")"
  grep -Eq '/usr/bin/obs-studio-kepler-legacy$' <<<"$package_listing"
  grep -Eq '/opt/obs-studio-kepler-legacy/.local/obs-kepler/bin/obs$' <<<"$package_listing"
else
  echo "==> No Arch package found; skipping package checks"
fi

echo "Release artifact tests completed successfully."
