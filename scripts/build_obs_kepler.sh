#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/libpatches.sh
source "$ROOT_DIR/scripts/libpatches.sh"
# shellcheck source=scripts/project-versions.sh
source "$ROOT_DIR/scripts/project-versions.sh"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.cache/kepler-build/obs}"
PREFIX="${PREFIX:-$ROOT_DIR/.local/obs-kepler}"
NV_CODEC_TAG="${NV_CODEC_TAG:-$OBS_NV_CODEC_TAG_DEFAULT}"
MBEDTLS_TAG="${MBEDTLS_TAG:-$MBEDTLS_TAG_DEFAULT}"
UTHASH_TAG="${UTHASH_TAG:-$UTHASH_TAG_DEFAULT}"
NLOHMANN_JSON_TAG="${NLOHMANN_JSON_TAG:-$NLOHMANN_JSON_TAG_DEFAULT}"
JOBS="${JOBS:-$(nproc)}"

SRC_DIR="$WORK_DIR/src"
BUILD_DIR="$WORK_DIR/build"
DEPS_PREFIX="$WORK_DIR/deps"
FFNV_PREFIX="$DEPS_PREFIX/ffnvcodec-$NV_CODEC_TAG"
MBEDTLS_PREFIX="$DEPS_PREFIX/$MBEDTLS_TAG"
UTHASH_INCLUDE="$DEPS_PREFIX/include"
NLOHMANN_INCLUDE="$DEPS_PREFIX/include/nlohmann"

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
  git -C "$dir" reset --hard "$ref"
  git -C "$dir" clean -fdx
}

need_cmd git
need_cmd cmake
need_cmd make
need_cmd gcc
need_cmd pkg-config
need_cmd curl

mkdir -p "$SRC_DIR" "$BUILD_DIR" "$DEPS_PREFIX" "$PREFIX" "$UTHASH_INCLUDE"
mkdir -p "$NLOHMANN_INCLUDE"

OBS_SRC="$SRC_DIR/obs-studio"
NV_CODEC_SRC="$SRC_DIR/nv-codec-headers"
MBEDTLS_SRC="$SRC_DIR/mbedtls"

echo "==> Preparing OBS $OBS_TAG"
clone_or_update "$OBS_UPSTREAM_URL" "$OBS_SRC" "$OBS_TAG"
git -C "$OBS_SRC" submodule update --init --depth 1 plugins/obs-browser plugins/obs-websocket
apply_patch_series "$OBS_SRC" "$ROOT_DIR/patches/obs" "OBS"

echo "==> Preparing nv-codec-headers $NV_CODEC_TAG"
clone_or_update "$NV_CODEC_UPSTREAM_URL" "$NV_CODEC_SRC" "$NV_CODEC_TAG"
rm -rf "$FFNV_PREFIX"
make -C "$NV_CODEC_SRC" PREFIX="$FFNV_PREFIX" install

echo "==> Preparing Mbed TLS $MBEDTLS_TAG"
clone_or_update "$MBEDTLS_UPSTREAM_URL" "$MBEDTLS_SRC" "$MBEDTLS_TAG"
git -C "$MBEDTLS_SRC" submodule update --init --depth 1 framework
rm -rf "$WORK_DIR/mbedtls-build" "$MBEDTLS_PREFIX"
cmake -S "$MBEDTLS_SRC" -B "$WORK_DIR/mbedtls-build" \
  -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$MBEDTLS_PREFIX" \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_TESTING=OFF \
  -DENABLE_PROGRAMS=OFF
cmake --build "$WORK_DIR/mbedtls-build" --parallel "$JOBS"
cmake --install "$WORK_DIR/mbedtls-build"

echo "==> Preparing uthash $UTHASH_TAG"
curl -fsSL "https://raw.githubusercontent.com/troydhanson/uthash/${UTHASH_TAG}/src/uthash.h" \
  -o "$UTHASH_INCLUDE/uthash.h"

echo "==> Preparing nlohmann/json $NLOHMANN_JSON_TAG"
curl -fsSL "https://raw.githubusercontent.com/nlohmann/json/${NLOHMANN_JSON_TAG}/single_include/nlohmann/json.hpp" \
  -o "$NLOHMANN_INCLUDE/json.hpp"
curl -fsSL "https://raw.githubusercontent.com/nlohmann/json/${NLOHMANN_JSON_TAG}/single_include/nlohmann/json_fwd.hpp" \
  -o "$NLOHMANN_INCLUDE/json_fwd.hpp"

export PKG_CONFIG_PATH="$FFNV_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
export CPLUS_INCLUDE_PATH="$DEPS_PREFIX/include${CPLUS_INCLUDE_PATH:+:$CPLUS_INCLUDE_PATH}"

# OBS 30.2.x still uses the legacy build system. On Arch, libdrm headers live
# under /usr/include/libdrm, and the explicit-sync backport needs both the
# include path and libdrm link flags to be visible to the generated build.
drm_cflags="$(pkg-config --cflags libdrm)"
drm_libs="$(pkg-config --libs libdrm)"
export CFLAGS="${drm_cflags}${CFLAGS:+ $CFLAGS}"
export CXXFLAGS="${drm_cflags}${CXXFLAGS:+ $CXXFLAGS}"
export LDFLAGS="${drm_libs}${LDFLAGS:+ $LDFLAGS}"

rm -rf "$BUILD_DIR"

echo "==> Configuring OBS"
cmake -S "$OBS_SRC" -B "$BUILD_DIR" \
  -G "Unix Makefiles" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="$PREFIX" \
  -DCMAKE_PREFIX_PATH="$MBEDTLS_PREFIX;$FFNV_PREFIX" \
  -DUthash_INCLUDE_DIR="$UTHASH_INCLUDE" \
  -DFFnvcodec_INCLUDE_DIR="$FFNV_PREFIX/include" \
  -DENABLE_BROWSER=OFF \
  -DENABLE_WEBSOCKET=OFF \
  -DENABLE_WEBRTC=OFF \
  -DENABLE_RTMPS=OFF \
  -DENABLE_WHATSNEW=OFF \
  -DENABLE_RNNOISE=OFF \
  -DENABLE_NEW_MPEGTS_OUTPUT=OFF \
  -DENABLE_QSV11=OFF \
  -DENABLE_VAAPI=OFF \
  -DENABLE_AJA=OFF \
  -DENABLE_DECKLINK=OFF \
  -DENABLE_VLC=OFF \
  -DENABLE_VST=OFF \
  -DENABLE_SNDIO=OFF \
  -DENABLE_LIBFDK=OFF \
  -DENABLE_SCRIPTING=OFF \
  -DENABLE_NVAFX=OFF \
  -DENABLE_NVVFX=OFF \
  -DBUILD_TESTS=OFF \
  -DOBS_COMPILE_DEPRECATION_AS_WARNING=ON \
  -DCALM_DEPRECATION=ON

echo "==> Building OBS"
cmake --build "$BUILD_DIR" --parallel "$JOBS"

echo "==> Installing OBS to $PREFIX"
cmake --install "$BUILD_DIR"

if [[ -x "$ROOT_DIR/scripts/make_bundle_relocatable.sh" ]]; then
  "$ROOT_DIR/scripts/make_bundle_relocatable.sh" "$ROOT_DIR"
fi

cat <<EOF

Build completed.

Run it like this:
  "$PREFIX/bin/obs" --help

If NVENC does not appear in the OBS encoder options, start OBS from a terminal and inspect the log output.

EOF
