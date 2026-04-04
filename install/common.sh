#!/usr/bin/env bash
set -euo pipefail

APP_ID="obs-studio-kepler-legacy"

project_root() {
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "Please run this script as root." >&2
    exit 1
  fi
}

require_bundle() {
  local root="$1"

  [[ -x "$root/bin/obs-studio-kepler-legacy" ]] || {
    echo "Missing launcher: $root/bin/obs-studio-kepler-legacy" >&2
    exit 1
  }
  [[ -x "$root/bin/ffmpeg-kepler-legacy" ]] || {
    echo "Missing launcher: $root/bin/ffmpeg-kepler-legacy" >&2
    exit 1
  }
  [[ -x "$root/.local/obs-kepler/bin/obs" ]] || {
    echo "Missing OBS bundle at: $root/.local/obs-kepler/bin/obs" >&2
    exit 1
  }
  [[ -x "$root/.local/ffmpeg-nvenc470/bin/ffmpeg" ]] || {
    echo "Missing FFmpeg bundle at: $root/.local/ffmpeg-nvenc470/bin/ffmpeg" >&2
    exit 1
  }
}

copy_runtime_tree() {
  local root="$1"
  local install_root="$2"

  rm -rf "$install_root"
  mkdir -p "$install_root"

  cp -a "$root/.local" "$install_root/"
  cp -a "$root/bin" "$install_root/"
  cp -a "$root/docs" "$install_root/"
  cp -a "$root/README.md" "$install_root/"

  if [[ -x "$root/scripts/make_bundle_relocatable.sh" ]]; then
    "$root/scripts/make_bundle_relocatable.sh" "$install_root"
  fi
}

install_icons() {
  local root="$1"
  local icon_base="$2"
  local src_base="$root/.local/obs-kepler/share/icons/hicolor"

  mkdir -p \
    "$icon_base/128x128/apps" \
    "$icon_base/256x256/apps" \
    "$icon_base/512x512/apps" \
    "$icon_base/scalable/apps"

  cp -f "$src_base/128x128/apps/com.obsproject.Studio.png" \
    "$icon_base/128x128/apps/obs-studio-kepler-legacy.png"
  cp -f "$src_base/256x256/apps/com.obsproject.Studio.png" \
    "$icon_base/256x256/apps/obs-studio-kepler-legacy.png"
  cp -f "$src_base/512x512/apps/com.obsproject.Studio.png" \
    "$icon_base/512x512/apps/obs-studio-kepler-legacy.png"
  cp -f "$src_base/scalable/apps/com.obsproject.Studio.svg" \
    "$icon_base/scalable/apps/obs-studio-kepler-legacy.svg"
}

render_desktop_file() {
  local root="$1"
  local exec_path="$2"
  local output_path="$3"

  mkdir -p "$(dirname -- "$output_path")"
  sed "s|@EXECUTABLE@|$exec_path|g" \
    "$root/share/applications/obs-studio-kepler-legacy.desktop.in" \
    > "$output_path"
}

install_user_bundle() {
  local root="$1"
  local install_root="${INSTALL_ROOT:-$HOME/.local/opt/$APP_ID}"
  local bin_dir="${BIN_DIR:-$HOME/.local/bin}"
  local app_dir="${APP_DIR:-$HOME/.local/share/applications}"
  local icon_dir="${ICON_DIR:-$HOME/.local/share/icons/hicolor}"

  copy_runtime_tree "$root" "$install_root"

  mkdir -p "$bin_dir"
  ln -sfn "$install_root/bin/obs-studio-kepler-legacy" \
    "$bin_dir/obs-studio-kepler-legacy"
  ln -sfn "$install_root/bin/ffmpeg-kepler-legacy" \
    "$bin_dir/ffmpeg-kepler-legacy"

  render_desktop_file "$root" \
    "$bin_dir/obs-studio-kepler-legacy" \
    "$app_dir/obs-studio-kepler-legacy.desktop"
  install_icons "$root" "$icon_dir"

  cat <<EOF
User install complete.

Installed to:
  $install_root

Launchers:
  $bin_dir/obs-studio-kepler-legacy
  $bin_dir/ffmpeg-kepler-legacy

Desktop entry:
  $app_dir/obs-studio-kepler-legacy.desktop

The legacy OBS config will be stored separately from normal OBS under:
  ~/.config/obs-studio-kepler-legacy/obs-studio
EOF
}

install_system_bundle() {
  local root="$1"
  local install_root="${INSTALL_ROOT:-/opt/$APP_ID}"
  local bin_dir="${BIN_DIR:-/usr/local/bin}"
  local app_dir="${APP_DIR:-/usr/local/share/applications}"
  local icon_dir="${ICON_DIR:-/usr/local/share/icons/hicolor}"

  require_root

  copy_runtime_tree "$root" "$install_root"

  mkdir -p "$bin_dir"
  ln -sfn "$install_root/bin/obs-studio-kepler-legacy" \
    "$bin_dir/obs-studio-kepler-legacy"
  ln -sfn "$install_root/bin/ffmpeg-kepler-legacy" \
    "$bin_dir/ffmpeg-kepler-legacy"

  render_desktop_file "$root" \
    "$bin_dir/obs-studio-kepler-legacy" \
    "$app_dir/obs-studio-kepler-legacy.desktop"
  install_icons "$root" "$icon_dir"

  cat <<EOF
System install complete.

Installed to:
  $install_root

Launchers:
  $bin_dir/obs-studio-kepler-legacy
  $bin_dir/ffmpeg-kepler-legacy

Desktop entry:
  $app_dir/obs-studio-kepler-legacy.desktop
EOF
}

uninstall_user_bundle() {
  local install_root="${INSTALL_ROOT:-$HOME/.local/opt/$APP_ID}"
  local bin_dir="${BIN_DIR:-$HOME/.local/bin}"
  local app_dir="${APP_DIR:-$HOME/.local/share/applications}"
  local icon_dir="${ICON_DIR:-$HOME/.local/share/icons/hicolor}"

  rm -rf "$install_root"
  rm -f \
    "$bin_dir/obs-studio-kepler-legacy" \
    "$bin_dir/ffmpeg-kepler-legacy" \
    "$app_dir/obs-studio-kepler-legacy.desktop" \
    "$icon_dir/128x128/apps/obs-studio-kepler-legacy.png" \
    "$icon_dir/256x256/apps/obs-studio-kepler-legacy.png" \
    "$icon_dir/512x512/apps/obs-studio-kepler-legacy.png" \
    "$icon_dir/scalable/apps/obs-studio-kepler-legacy.svg"

  cat <<EOF
User install removed.

If you also want to remove the separate legacy OBS configuration, delete:
  ~/.config/obs-studio-kepler-legacy
  ~/.cache/obs-studio-kepler-legacy
  ~/.local/state/obs-studio-kepler-legacy
EOF
}

uninstall_system_bundle() {
  local install_root="${INSTALL_ROOT:-/opt/$APP_ID}"
  local bin_dir="${BIN_DIR:-/usr/local/bin}"
  local app_dir="${APP_DIR:-/usr/local/share/applications}"
  local icon_dir="${ICON_DIR:-/usr/local/share/icons/hicolor}"

  require_root

  rm -rf "$install_root"
  rm -f \
    "$bin_dir/obs-studio-kepler-legacy" \
    "$bin_dir/ffmpeg-kepler-legacy" \
    "$app_dir/obs-studio-kepler-legacy.desktop" \
    "$icon_dir/128x128/apps/obs-studio-kepler-legacy.png" \
    "$icon_dir/256x256/apps/obs-studio-kepler-legacy.png" \
    "$icon_dir/512x512/apps/obs-studio-kepler-legacy.png" \
    "$icon_dir/scalable/apps/obs-studio-kepler-legacy.svg"

  cat <<EOF
System install removed.

Per-user config and cache remain under each user's home directory unless they
delete them manually.
EOF
}
