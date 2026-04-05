#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install/common.sh
source "$ROOT_DIR/install/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./uninstall.sh --user
  sudo ./uninstall.sh --system

Options:
  --user     Remove the current user installation from ~/.local
  --system   Remove the system-wide installation from /opt and /usr/local
  -h, --help Show this help message

Environment overrides:
  INSTALL_ROOT
  BIN_DIR
  APP_DIR
  ICON_DIR
EOF
}

mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user)
      [[ -z "$mode" ]] || {
        echo "Only one uninstall mode may be selected." >&2
        exit 1
      }
      mode="user"
      ;;
    --system)
      [[ -z "$mode" ]] || {
        echo "Only one uninstall mode may be selected." >&2
        exit 1
      }
      mode="system"
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

[[ -n "$mode" ]] || {
  usage >&2
  exit 1
}

case "$mode" in
  user)
    uninstall_user_bundle
    ;;
  system)
    uninstall_system_bundle
    ;;
esac
