#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="OBS Studio Kepler Legacy"
MODULE_NAME="v4l2loopback"
MODULE_OPTIONS=(exclusive_caps=1 "card_label=OBS Virtual Camera")
MODULES_LOAD_FILE="/etc/modules-load.d/obs-studio-kepler-legacy-v4l2loopback.conf"
MODPROBE_FILE="/etc/modprobe.d/obs-studio-kepler-legacy-v4l2loopback.conf"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/setup_virtual_camera_arch.sh --check
  sudo ./scripts/setup_virtual_camera_arch.sh --install-packages
  sudo ./scripts/setup_virtual_camera_arch.sh --load-module
  sudo ./scripts/setup_virtual_camera_arch.sh --enable-on-boot

Options:
  --check             Show the current Arch virtual camera status
  --install-packages  Install the required Arch packages
  --load-module       Load v4l2loopback now
  --enable-on-boot    Load v4l2loopback automatically at boot with OBS-friendly options
  -h, --help          Show this help message
EOF
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Please run this command as root." >&2
    exit 1
  fi
}

require_arch() {
  command -v pacman >/dev/null 2>&1 || {
    echo "This helper is intended for Arch Linux systems with pacman." >&2
    exit 1
  }
}

detect_kernel_header_packages() {
  local kernels=()
  local headers=()
  mapfile -t kernels < <(pacman -Qq | rg '^(linux|linux-lts|linux-zen|linux-hardened|linux-cachyos|linux-cachyos-lts|linux-cachyos-rc)$' || true)

  for pkg in "${kernels[@]}"; do
    case "$pkg" in
      linux)
        headers+=("linux-headers")
        ;;
      *)
        headers+=("${pkg}-headers")
        ;;
    esac
  done

  if [[ ${#headers[@]} -eq 0 ]]; then
    if pacman -Qq linux-headers >/dev/null 2>&1; then
      headers=("linux-headers")
    fi
  fi

  printf '%s\n' "${headers[@]}" | awk 'NF && !seen[$0]++'
}

package_list() {
  local headers=()
  mapfile -t headers < <(detect_kernel_header_packages)

  printf '%s\n' "${headers[@]}"
  printf '%s\n' v4l2loopback-dkms
  printf '%s\n' v4l2loopback-utils
}

print_status() {
  local headers=()
  local packages=()
  local missing=()
  mapfile -t headers < <(detect_kernel_header_packages)
  mapfile -t packages < <(package_list)

  echo "==> $PROJECT_NAME virtual camera status"
  echo "Kernel: $(uname -r)"

  echo
  echo "Expected packages:"
  printf '  %s\n' "${packages[@]}"

  for pkg in "${packages[@]}"; do
    if pacman -Q "$pkg" >/dev/null 2>&1; then
      echo "installed: $pkg"
    else
      echo "missing:   $pkg"
      missing+=("$pkg")
    fi
  done

  echo
  if modinfo "$MODULE_NAME" >/dev/null 2>&1; then
    echo "Module metadata: available"
  else
    echo "Module metadata: unavailable"
  fi

  if lsmod | rg -q "^${MODULE_NAME}\b"; then
    echo "Module loaded: yes"
  else
    echo "Module loaded: no"
  fi

  if command -v v4l2-ctl >/dev/null 2>&1; then
    echo
    echo "Video4Linux devices:"
    v4l2-ctl --list-devices 2>/dev/null || true
  fi

  echo
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Suggested install command:"
    printf '  sudo pacman -S --needed'
    printf ' %q' "${missing[@]}"
    printf '\n'
  else
    echo "Packages look good."
  fi

  if ! lsmod | rg -q "^${MODULE_NAME}\b"; then
    echo
    echo "Suggested load command:"
    echo "  sudo modprobe $MODULE_NAME exclusive_caps=1 card_label='OBS Virtual Camera'"
  fi
}

install_packages() {
  local packages=()
  require_root
  require_arch
  mapfile -t packages < <(package_list)

  pacman -S --needed "${packages[@]}"
}

load_module_now() {
  require_root
  modprobe -r "$MODULE_NAME" 2>/dev/null || true
  modprobe "$MODULE_NAME" "${MODULE_OPTIONS[@]}"
  echo "Loaded $MODULE_NAME with OBS-friendly options."
}

enable_on_boot() {
  require_root
  install -d /etc/modules-load.d /etc/modprobe.d
  printf '%s\n' "$MODULE_NAME" > "$MODULES_LOAD_FILE"
  cat >"$MODPROBE_FILE" <<EOF
options $MODULE_NAME exclusive_caps=1 card_label=OBS\ Virtual\ Camera
EOF
  echo "Created:"
  echo "  $MODULES_LOAD_FILE"
  echo "  $MODPROBE_FILE"
  echo
  echo "The module will load automatically on future boots."
}

action="${1:---check}"

case "$action" in
  --check)
    require_arch
    print_status
    ;;
  --install-packages)
    install_packages
    ;;
  --load-module)
    load_module_now
    ;;
  --enable-on-boot)
    enable_on_boot
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "Unknown option: $action" >&2
    usage >&2
    exit 1
    ;;
esac
