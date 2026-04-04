#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/install/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh --user
  sudo ./install.sh --system

Options:
  --user     Install for the current user under ~/.local
  --system   Install system-wide under /opt and /usr/local
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
        echo "Only one install mode may be selected." >&2
        exit 1
      }
      mode="user"
      ;;
    --system)
      [[ -z "$mode" ]] || {
        echo "Only one install mode may be selected." >&2
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

require_bundle "$ROOT_DIR"

case "$mode" in
  user)
    install_user_bundle "$ROOT_DIR"
    ;;
  system)
    install_system_bundle "$ROOT_DIR"
    ;;
esac
