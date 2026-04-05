#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/libpatches.sh
source "$ROOT_DIR/scripts/libpatches.sh"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.cache/kepler-build/ffmpeg}"
PREFIX="${PREFIX:-$ROOT_DIR/.local/ffmpeg-nvenc470}"
NV_CODEC_TAG="${NV_CODEC_TAG:-$FFMPEG_NV_CODEC_TAG_DEFAULT}"
JOBS="${JOBS:-$(nproc)}"

SRC_DIR="$WORK_DIR/src"
BUILD_DIR="$WORK_DIR/build"
FFNV_PREFIX="$WORK_DIR/ffnvcodec-$NV_CODEC_TAG"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

clone_or_update() {
  local url="$1"
  local dir="$2"
  local ref="$3"

  if [[ ! -d "$dir/.git" ]]; then
    git clone --filter=blob:none "$url" "$dir"
  fi

  git -C "$dir" fetch --tags origin
  git -C "$dir" checkout --detach "$ref"
}

append_if_pkg() {
  local pkg="$1"
  local flag="$2"
  if pkg-config --exists "$pkg"; then
    CONFIG_FLAGS+=("$flag")
  fi
}

need_cmd git
need_cmd make
need_cmd gcc
need_cmd pkg-config

mkdir -p "$SRC_DIR" "$BUILD_DIR" "$PREFIX"

NV_CODEC_SRC="$SRC_DIR/nv-codec-headers"
FFMPEG_SRC="$SRC_DIR/FFmpeg"

echo "==> Preparing nv-codec-headers $NV_CODEC_TAG"
clone_or_update "$NV_CODEC_UPSTREAM_URL" "$NV_CODEC_SRC" "$NV_CODEC_TAG"
rm -rf "$FFNV_PREFIX"
make -C "$NV_CODEC_SRC" PREFIX="$FFNV_PREFIX" install

export PKG_CONFIG_PATH="$FFNV_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

echo "==> Preparing FFmpeg $FFMPEG_TAG"
clone_or_update "$FFMPEG_UPSTREAM_URL" "$FFMPEG_SRC" "$FFMPEG_TAG"
apply_patch_series "$FFMPEG_SRC" "$ROOT_DIR/patches/ffmpeg" "FFmpeg"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

CONFIG_FLAGS=(
  "--prefix=$PREFIX"
  "--disable-static"
  "--enable-shared"
  "--disable-debug"
  "--disable-stripping"
  "--enable-gpl"
  "--enable-version3"
  "--enable-ffnvcodec"
  "--enable-nvenc"
  "--enable-nvdec"
  "--extra-ldflags=-Wl,-rpath,$PREFIX/lib"
  "--extra-ldexeflags=-Wl,-rpath,$PREFIX/lib"
)

append_if_pkg "gnutls" "--enable-gnutls"
append_if_pkg "libass" "--enable-libass"
append_if_pkg "freetype2" "--enable-libfreetype"
append_if_pkg "fribidi" "--enable-libfribidi"
append_if_pkg "libdav1d" "--enable-libdav1d"
append_if_pkg "libdrm" "--enable-libdrm"
append_if_pkg "opus" "--enable-libopus"
append_if_pkg "libpulse" "--enable-libpulse"
append_if_pkg "libvpx" "--enable-libvpx"
append_if_pkg "libwebp" "--enable-libwebp"
append_if_pkg "libxml-2.0" "--enable-libxml2"
append_if_pkg "x264" "--enable-libx264"
append_if_pkg "x265" "--enable-libx265"
append_if_pkg "zlib" "--enable-zlib"

if ! command -v nasm >/dev/null 2>&1 && ! command -v yasm >/dev/null 2>&1; then
  CONFIG_FLAGS+=("--disable-x86asm")
fi

echo "==> Configuring FFmpeg"
pushd "$BUILD_DIR" >/dev/null
"$FFMPEG_SRC/configure" "${CONFIG_FLAGS[@]}"

echo "==> Building FFmpeg"
make -j"$JOBS"

echo "==> Installing FFmpeg to $PREFIX"
make install
popd >/dev/null

if [[ -x "$ROOT_DIR/scripts/make_bundle_relocatable.sh" ]]; then
  "$ROOT_DIR/scripts/make_bundle_relocatable.sh" "$ROOT_DIR"
fi

export LD_LIBRARY_PATH="$PREFIX/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

echo "==> Validating NVENC encoders"
"$PREFIX/bin/ffmpeg" -hide_banner -encoders | rg "h264_nvenc|hevc_nvenc|av1_nvenc" || true

if command -v nvidia-smi >/dev/null 2>&1; then
  echo "==> Testing H.264 NVENC encode"
  "$PREFIX/bin/ffmpeg" -hide_banner -loglevel warning \
    -f lavfi -i testsrc2=size=1280x720:rate=30 -t 1 \
    -c:v h264_nvenc -f null -
fi

cat <<EOF

Build completed.

Use it like this:
  "$PREFIX/bin/ffmpeg" -hide_banner -encoders | rg nvenc

EOF
