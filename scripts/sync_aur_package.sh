#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/sync_aur_package.sh
  ./scripts/sync_aur_package.sh --verify-source
  ./scripts/sync_aur_package.sh --maintainer-name "Caio Augusto" --maintainer-email "augustocaio663@gmail.com"

Options:
  --maintainer-name VALUE   Maintainer name used in the AUR PKGBUILD header
  --maintainer-email VALUE  Maintainer email used in the AUR PKGBUILD header
  --output-dir PATH         Target AUR package directory
  --verify-source           Run makepkg --verifysource after generating files
  -h, --help                Show this help message
EOF
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

obfuscate_email() {
  local value="$1"
  value="${value//@/ at }"
  value="${value//./ dot }"
  printf '%s\n' "$value"
}

maintainer_name="${AUR_MAINTAINER_NAME:-Caio Augusto}"
maintainer_email="${AUR_MAINTAINER_EMAIL:-augustocaio663@gmail.com}"
package_base="${AUR_PACKAGE_BASE:-obs-studio-kepler-legacy-bin}"
output_dir="${AUR_OUTPUT_DIR:-$ROOT_DIR/aur/$package_base}"
verify_source=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --maintainer-name)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --maintainer-name" >&2
        exit 1
      }
      maintainer_name="$1"
      ;;
    --maintainer-email)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --maintainer-email" >&2
        exit 1
      }
      maintainer_email="$1"
      ;;
    --output-dir)
      shift
      [[ $# -gt 0 ]] || {
        echo "Missing value for --output-dir" >&2
        exit 1
      }
      output_dir="$1"
      ;;
    --verify-source)
      verify_source=true
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
need_cmd install
need_cmd cp

release_tag="v$PROJECT_VERSION"
archive_name="obs-studio-kepler-legacy-$PROJECT_VERSION.tar.gz"
source_url="https://github.com/cainhooow/obs-studio-kepler-legacy/releases/download/$release_tag/$archive_name"
dist_checksum_file="$ROOT_DIR/dist/$archive_name.sha256"

if [[ -f "$dist_checksum_file" ]]; then
  source_sha256="$(awk 'NR == 1 { print $1 }' "$dist_checksum_file")"
else
  need_cmd curl
  source_sha256="$(curl -fsSL "$source_url.sha256" | awk 'NR == 1 { print $1 }')"
fi

[[ -n "$source_sha256" ]] || {
  echo "Unable to determine SHA256 for $archive_name" >&2
  exit 1
}

maintainer_header_email="$(obfuscate_email "$maintainer_email")"

install -dm755 "$output_dir"
cp "$ROOT_DIR/packaging/obs-studio-kepler-legacy.install" \
  "$output_dir/obs-studio-kepler-legacy.install"

cat >"$output_dir/PKGBUILD" <<EOF
# Maintainer: $maintainer_name <$maintainer_header_email>

pkgname=$package_base
_bundlever='$PROJECT_VERSION'
pkgver=\${_bundlever//-/_}
pkgrel=1
pkgdesc='Legacy OBS Studio + FFmpeg bundle for NVIDIA Kepler GPUs on Arch Linux'
arch=('x86_64')
url='https://github.com/cainhooow/obs-studio-kepler-legacy'
license=('GPL-2.0-or-later')
options=('!debug' '!strip')
depends=(
  'alsa-lib'
  'bash'
  'curl'
  'gcc-libs'
  'glibc'
  'libjack.so=0-64'
  'libpipewire-0.3.so=0-64'
  'libpulse.so=0-64'
  'libdrm'
  'libx11'
  'libxcomposite'
  'libxdamage'
  'libxfixes'
  'libxinerama'
  'libxkbcommon'
  'libxrandr'
  'libxcb'
  'qt6-base'
  'wayland'
)
optdepends=(
  'jack2: native JACK server implementation'
  'pipewire: PipeWire daemon and desktop integration for Wayland capture and related features'
  'pipewire-jack: PipeWire JACK replacement'
  'pipewire-pulse: PipeWire PulseAudio replacement'
  'pulseaudio: PulseAudio server implementation'
  'v4l2loopback-dkms: Linux virtual camera kernel module'
  'v4l2loopback-utils: virtual camera control utilities'
)
provides=('obs-studio-kepler-legacy')
conflicts=('obs-studio-kepler-legacy')
install='obs-studio-kepler-legacy.install'
source=(
  "\$pkgname-\$_bundlever.tar.gz::$source_url"
)
sha256sums=(
  '$source_sha256'
)

package() {
  local bundle_dir="\${srcdir}/obs-studio-kepler-legacy-\${_bundlever}"
  local install_root="\${pkgdir}/opt/obs-studio-kepler-legacy"
  local icon_src="\${bundle_dir}/.local/obs-kepler/share/icons/hicolor"

  install -dm755 "\${install_root}" "\${pkgdir}/usr/bin" \
    "\${pkgdir}/usr/share/applications" \
    "\${pkgdir}/usr/share/icons/hicolor/128x128/apps" \
    "\${pkgdir}/usr/share/icons/hicolor/256x256/apps" \
    "\${pkgdir}/usr/share/icons/hicolor/512x512/apps" \
    "\${pkgdir}/usr/share/icons/hicolor/scalable/apps"

  cp -a "\${bundle_dir}/.local" "\${install_root}/"
  cp -a "\${bundle_dir}/bin" "\${install_root}/"
  cp -a "\${bundle_dir}/docs" "\${install_root}/"
  cp -a "\${bundle_dir}/patches" "\${install_root}/"
  cp -a "\${bundle_dir}/scripts" "\${install_root}/"
  cp -a "\${bundle_dir}/share" "\${install_root}/"
  cp -a "\${bundle_dir}/CHANGELOG.md" "\${install_root}/"
  cp -a "\${bundle_dir}/README.md" "\${install_root}/"
  cp -a "\${bundle_dir}/SECURITY.md" "\${install_root}/"
  cp -a "\${bundle_dir}/VERSION" "\${install_root}/"

  ln -s "/opt/obs-studio-kepler-legacy/bin/obs-studio-kepler-legacy" \
    "\${pkgdir}/usr/bin/obs-studio-kepler-legacy"
  ln -s "/opt/obs-studio-kepler-legacy/bin/ffmpeg-kepler-legacy" \
    "\${pkgdir}/usr/bin/ffmpeg-kepler-legacy"

  sed "s|@EXECUTABLE@|/usr/bin/obs-studio-kepler-legacy|g" \
    "\${bundle_dir}/share/applications/obs-studio-kepler-legacy.desktop.in" \
    > "\${pkgdir}/usr/share/applications/obs-studio-kepler-legacy.desktop"

  install -m644 "\${icon_src}/128x128/apps/com.obsproject.Studio.png" \
    "\${pkgdir}/usr/share/icons/hicolor/128x128/apps/obs-studio-kepler-legacy.png"
  install -m644 "\${icon_src}/256x256/apps/com.obsproject.Studio.png" \
    "\${pkgdir}/usr/share/icons/hicolor/256x256/apps/obs-studio-kepler-legacy.png"
  install -m644 "\${icon_src}/512x512/apps/com.obsproject.Studio.png" \
    "\${pkgdir}/usr/share/icons/hicolor/512x512/apps/obs-studio-kepler-legacy.png"
  install -m644 "\${icon_src}/scalable/apps/com.obsproject.Studio.svg" \
    "\${pkgdir}/usr/share/icons/hicolor/scalable/apps/obs-studio-kepler-legacy.svg"
}
EOF

cat >"$output_dir/LICENSE" <<'EOF'
Copyright Arch Linux Contributors

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted.

THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
EOF

cat >"$output_dir/.gitignore" <<'EOF'
*
!.gitignore
!.SRCINFO
!LICENSE
!PKGBUILD
!obs-studio-kepler-legacy.install
EOF

(
  cd "$output_dir"
  makepkg --printsrcinfo > .SRCINFO
  if [[ "$verify_source" == true ]]; then
    makepkg --verifysource
  fi
)

rm -rf \
  "$output_dir/pkg" \
  "$output_dir/src" \
  "$output_dir/$package_base-$PROJECT_VERSION.tar.gz"

echo "AUR package files updated under: $output_dir"
