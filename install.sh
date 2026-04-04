#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/install/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh --user
  sudo ./install.sh --system
  ./install.sh --all
  ./install.sh --clean-build-artifacts

Options:
  --user                   Install for the current user under ~/.local
  --system                 Install system-wide under /opt and /usr/local
  --all                    Run the interactive setup wizard
  --clean-build-artifacts  Remove cached source/build trees under .cache/kepler-build
  -h, --help               Show this help message

Environment overrides:
  INSTALL_ROOT
  BIN_DIR
  APP_DIR
  ICON_DIR
EOF
}

mode=""
run_all=false
clean_build_artifacts=false
clean_build_artifacts_explicit=false

ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local reply=""

  while true; do
    if [[ "$default" == "y" ]]; then
      read -r -p "$prompt [Y/n] " reply || exit 1
      reply="${reply:-y}"
    else
      read -r -p "$prompt [y/N] " reply || exit 1
      reply="${reply:-n}"
    fi

    case "${reply,,}" in
      y|yes)
        return 0
        ;;
      n|no)
        return 1
        ;;
    esac

    echo "Please answer y or n."
  done
}

choose_install_mode() {
  local reply=""

  echo >&2
  echo "Install mode:" >&2
  echo "  1) Current user (recommended)" >&2
  echo "  2) System-wide" >&2
  echo "  3) Skip installation" >&2

  while true; do
    read -r -p "Choose [1/2/3] (default: 1): " reply || exit 1
    reply="${reply:-1}"

    case "$reply" in
      1)
        printf '%s\n' "user"
        return 0
        ;;
      2)
        printf '%s\n' "system"
        return 0
        ;;
      3)
        printf '%s\n' "skip"
        return 0
        ;;
    esac

    echo "Please choose 1, 2, or 3."
  done
}

run_root_script() {
  local script_path="$1"
  shift

  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$script_path" "$@"
  else
    sudo "$script_path" "$@"
  fi
}

run_install_mode() {
  local install_mode="$1"

  case "$install_mode" in
    user)
      require_bundle "$ROOT_DIR"
      install_user_bundle "$ROOT_DIR"
      ;;
    system)
      require_bundle "$ROOT_DIR"
      if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        install_system_bundle "$ROOT_DIR"
      else
        sudo "$ROOT_DIR/install.sh" --system
      fi
      ;;
    skip)
      echo "Skipping bundle installation."
      ;;
    *)
      echo "Unknown install mode: $install_mode" >&2
      exit 1
      ;;
  esac
}

run_all_wizard() {
  local install_mode=""
  local vcam_check_output=""
  local built_ffmpeg=false
  local built_obs=false
  local cleanup_targets=()

  if [[ ! -t 0 ]]; then
    echo "The --all wizard requires an interactive terminal." >&2
    exit 1
  fi

  echo "OBS Studio Kepler Legacy setup wizard"
  echo
  echo "This mode can build FFmpeg, build OBS, install the bundle, configure"
  echo "virtual camera support on Arch Linux, and run validation."

  echo
  if ask_yes_no "Build FFmpeg from source?" "y"; then
    "$ROOT_DIR/scripts/build_ffmpeg_nvenc470.sh"
    built_ffmpeg=true
  else
    echo "Skipping FFmpeg build."
  fi

  echo
  if ask_yes_no "Build OBS from source?" "y"; then
    "$ROOT_DIR/scripts/build_obs_kepler.sh"
    built_obs=true
  else
    echo "Skipping OBS build."
  fi

  echo
  if ask_yes_no "Install the bundle now?" "y"; then
    install_mode="$(choose_install_mode)"
    run_install_mode "$install_mode"
  else
    echo "Skipping bundle installation."
  fi

  if [[ -x "$ROOT_DIR/scripts/setup_virtual_camera_arch.sh" ]] &&
     command -v pacman >/dev/null 2>&1; then
    echo
    if ask_yes_no "Check or configure Linux virtual camera support?" "y"; then
      vcam_check_output="$("$ROOT_DIR/scripts/setup_virtual_camera_arch.sh" --check)"
      printf '%s\n' "$vcam_check_output"

      if grep -q "missing:   v4l2loopback-dkms" <<<"$vcam_check_output" ||
         grep -q "missing:   v4l2loopback-utils" <<<"$vcam_check_output"; then
        echo
        if ask_yes_no "Install the missing virtual camera packages?" "n"; then
          run_root_script "$ROOT_DIR/scripts/setup_virtual_camera_arch.sh" --install-packages
        fi
      fi

      echo
      if ask_yes_no "Load the v4l2loopback module now?" "n"; then
        run_root_script "$ROOT_DIR/scripts/setup_virtual_camera_arch.sh" --load-module
      fi

      echo
      if ask_yes_no "Enable v4l2loopback automatically on boot?" "n"; then
        run_root_script "$ROOT_DIR/scripts/setup_virtual_camera_arch.sh" --enable-on-boot
      fi
    else
      echo "Skipping virtual camera setup."
    fi
  fi

  echo
  if ask_yes_no "Run runtime validation now?" "y"; then
    "$ROOT_DIR/scripts/validate_runtime.sh"
  else
    echo "Skipping runtime validation."
  fi

  if [[ "$built_ffmpeg" == true || "$built_obs" == true ]]; then
    if [[ "$built_ffmpeg" == true ]]; then
      cleanup_targets+=("ffmpeg")
    fi
    if [[ "$built_obs" == true ]]; then
      cleanup_targets+=("obs")
    fi

    echo
    if [[ "$clean_build_artifacts_explicit" == true ]]; then
      cleanup_build_artifacts "$ROOT_DIR" "${cleanup_targets[@]}"
    elif ask_yes_no "Remove downloaded sources and temporary build artifacts now?" "n"; then
      cleanup_build_artifacts "$ROOT_DIR" "${cleanup_targets[@]}"
    else
      echo "Keeping build artifacts under: $ROOT_DIR/.cache/kepler-build"
    fi
  fi

  echo
  echo "All selected setup steps are complete."
}

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
    --all)
      run_all=true
      ;;
    --clean-build-artifacts)
      clean_build_artifacts=true
      clean_build_artifacts_explicit=true
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

if [[ "$run_all" == true ]]; then
  run_all_wizard
  exit 0
fi

if [[ -z "$mode" && "$clean_build_artifacts" == true ]]; then
  cleanup_build_artifacts "$ROOT_DIR"
  exit 0
fi

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

if [[ "$clean_build_artifacts" == true ]]; then
  cleanup_build_artifacts "$ROOT_DIR"
fi
