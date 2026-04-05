#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/check_project.sh

Runs shell syntax checks, optional shellcheck, and patch-series validation.
EOF
}

collect_shell_files() {
  {
    printf '%s\n' \
      "$ROOT_DIR/install.sh" \
      "$ROOT_DIR/uninstall.sh" \
      "$ROOT_DIR/release.sh"
    find "$ROOT_DIR/bin" "$ROOT_DIR/install" "$ROOT_DIR/scripts" "$ROOT_DIR/packaging" \
      -type f \
      ! -name 'PKGBUILD' \
      ! -name '*.md'
  } | sort -u
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

mapfile -t shell_files < <(collect_shell_files)

echo "==> Running bash -n"
bash -n "${shell_files[@]}"
bash -n "$ROOT_DIR/packaging/PKGBUILD"

if command -v shellcheck >/dev/null 2>&1; then
  echo "==> Running shellcheck"
  shellcheck -x "${shell_files[@]}"
else
  echo "==> shellcheck not installed; skipping static shell lint"
fi

echo "==> Validating patch series"
"$ROOT_DIR/scripts/check_patch_series.sh"

echo "Project checks completed successfully."
