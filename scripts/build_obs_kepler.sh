#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WORK_DIR:-$ROOT_DIR/.cache/kepler-build/obs}"
PREFIX="${PREFIX:-$ROOT_DIR/.local/obs-kepler}"
OBS_TAG="${OBS_TAG:-30.2.3}"
NV_CODEC_TAG="${NV_CODEC_TAG:-n12.1.14.0}"
MBEDTLS_TAG="${MBEDTLS_TAG:-mbedtls-3.6.6}"
UTHASH_TAG="${UTHASH_TAG:-v2.3.0}"
NLOHMANN_JSON_TAG="${NLOHMANN_JSON_TAG:-v3.11.3}"
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
clone_or_update "https://github.com/obsproject/obs-studio.git" "$OBS_SRC" "$OBS_TAG"
git -C "$OBS_SRC" submodule update --init --depth 1 plugins/obs-browser plugins/obs-websocket
if ! rg -q "find_package\\(Qt6GuiPrivate CONFIG REQUIRED\\)" "$OBS_SRC/UI/cmake/legacy.cmake"; then
  perl -0pi -e 's/find_package\(FFmpeg REQUIRED COMPONENTS avcodec avutil avformat\)/find_package(FFmpeg REQUIRED COMPONENTS avcodec avutil avformat)\nfind_package(Qt6GuiPrivate CONFIG REQUIRED)/' "$OBS_SRC/UI/cmake/legacy.cmake"
fi
if ! rg -q 'option\\(ENABLE_VAAPI "Enable VAAPI implementation" OFF\\)' "$OBS_SRC/plugins/obs-ffmpeg/cmake/legacy.cmake"; then
  perl -0pi -e 's/elseif\(OS_POSIX AND NOT OS_MACOS\)\n  find_package\(Libva REQUIRED\)\n  find_package\(Libpci REQUIRED\)\n  find_package\(Libdrm REQUIRED\)\n  target_sources\(obs-ffmpeg PRIVATE obs-ffmpeg-vaapi\.c vaapi-utils\.c vaapi-utils\.h\)\n  target_link_libraries\(obs-ffmpeg PRIVATE Libva::va Libva::drm LIBPCI::LIBPCI Libdrm::Libdrm\)\n\n  if\(ENABLE_NATIVE_NVENC\)/elseif(OS_POSIX AND NOT OS_MACOS)\n  option(ENABLE_VAAPI \"Enable VAAPI implementation\" OFF)\n\n  if(ENABLE_VAAPI)\n    find_package(Libva REQUIRED)\n    find_package(Libpci REQUIRED)\n    find_package(Libdrm REQUIRED)\n    target_sources(obs-ffmpeg PRIVATE obs-ffmpeg-vaapi.c vaapi-utils.c vaapi-utils.h)\n    target_link_libraries(obs-ffmpeg PRIVATE Libva::va Libva::drm LIBPCI::LIBPCI Libdrm::Libdrm)\n  endif()\n\n  if(ENABLE_NATIVE_NVENC)/' "$OBS_SRC/plugins/obs-ffmpeg/cmake/legacy.cmake"
fi
if ! rg -q 'VAAPI disabled for the Kepler-focused Arch build' "$OBS_SRC/plugins/obs-ffmpeg/obs-ffmpeg.c"; then
  perl -0pi -e 's/#if !defined\(_WIN32\) && !defined\(__APPLE__\)\n#include "vaapi-utils\.h"\n\n#define LIBAVUTIL_VAAPI_AVAILABLE\n#endif/#if 0 \/\* VAAPI disabled for the Kepler-focused Arch build \*\/\n#include "vaapi-utils.h"\n\n#define LIBAVUTIL_VAAPI_AVAILABLE\n#endif/' "$OBS_SRC/plugins/obs-ffmpeg/obs-ffmpeg.c"
fi
if ! rg -q 'HEVC disabled for the Kepler-focused Arch build' "$OBS_SRC/plugins/obs-ffmpeg/obs-ffmpeg.c"; then
  perl -0pi -e 's/#ifdef ENABLE_HEVC\n\tconst bool hevc = nvenc_codec_exists\("hevc_nvenc", "nvenc_hevc"\);\n#else\n\tconst bool hevc = false;\n#endif/const bool hevc = false; \/\* HEVC disabled for the Kepler-focused Arch build \*\//' "$OBS_SRC/plugins/obs-ffmpeg/obs-ffmpeg.c"
fi
if ! rg -q '#include <cstdint>' "$OBS_SRC/deps/json11/json11.cpp"; then
  perl -0pi -e 's/#include <cmath>\n/#include <cmath>\n#include <cstdint>\n/' "$OBS_SRC/deps/json11/json11.cpp"
fi
if ! rg -q 'use_caps_workaround' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"; then
  perl -0pi -e 's/struct virtualcam_data \{\n\tobs_output_t \*output;\n\tint device;\n\tuint32_t frame_size;\n\};/struct virtualcam_data {\n\tobs_output_t *output;\n\tint device;\n\tuint32_t frame_size;\n\tbool use_caps_workaround;\n};/' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
  perl -0pi -e 's/static bool try_connect/BOOL_PLACEHOLDER/s' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
  perl -0pi -e 's/BOOL_PLACEHOLDER/bool try_reset_output_caps(const char *device)\n{\n\tstruct v4l2_capability capability;\n\tstruct v4l2_format format;\n\tint fd;\n\n\tblog(LOG_INFO, "Attempting to reset output capability of '\\''%s'\\''", device);\n\n\tfd = open(device, O_RDWR);\n\tif (fd < 0)\n\t\treturn false;\n\n\tformat.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;\n\tif (ioctl(fd, VIDIOC_G_FMT, &format) < 0)\n\t\tgoto fail_close_reset_caps_fd;\n\n\tif (ioctl(fd, VIDIOC_S_FMT, &format) < 0)\n\t\tgoto fail_close_reset_caps_fd;\n\n\tif (ioctl(fd, VIDIOC_STREAMON, &format.type) < 0)\n\t\tgoto fail_close_reset_caps_fd;\n\n\tif (ioctl(fd, VIDIOC_STREAMOFF, &format.type) < 0)\n\t\tgoto fail_close_reset_caps_fd;\n\n\tclose(fd);\n\n\tfd = open(device, O_RDWR);\n\tif (fd < 0)\n\t\treturn false;\n\n\tif (ioctl(fd, VIDIOC_QUERYCAP, &capability) < 0)\n\t\tgoto fail_close_reset_caps_fd;\n\n\tclose(fd);\n\treturn (capability.device_caps & V4L2_CAP_VIDEO_OUTPUT) != 0;\n\nfail_close_reset_caps_fd:\n\tclose(fd);\n\treturn false;\n}\n\nstatic bool try_connect/s' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
  perl -0pi -e 's/static bool try_connect\(void \*data, const char \*device\)\n\{\n\tstruct virtualcam_data \*vcam = \(struct virtualcam_data \*\)data;\n\tstruct v4l2_format format;\n\tstruct v4l2_capability capability;\n/static bool try_connect(void *data, const char *device)\n{\n\tstatic bool use_caps_workaround = false;\n\tstruct virtualcam_data *vcam = (struct virtualcam_data *)data;\n\tstruct v4l2_capability capability;\n\tstruct v4l2_format format;\n/' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
  perl -0pi -e 's/if \(ioctl\(vcam->device, VIDIOC_QUERYCAP, &capability\) < 0\)\n\t\tgoto fail_close_device;\n\n\tformat.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;/if (ioctl(vcam->device, VIDIOC_QUERYCAP, &capability) < 0)\n\t\tgoto fail_close_device;\n\n\tif (!use_caps_workaround &&\n\t    !(capability.device_caps & V4L2_CAP_VIDEO_OUTPUT)) {\n\t\tif (!try_reset_output_caps(device))\n\t\t\tgoto fail_close_device;\n\n\t\tuse_caps_workaround = true;\n\t}\n\tvcam->use_caps_workaround = use_caps_workaround;\n\n\tformat.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;/' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
  perl -0pi -e 's/if \(ioctl\(vcam->device, VIDIOC_STREAMON, &parm\) < 0\) \{/if (vcam->use_caps_workaround &&\n\t    ioctl(vcam->device, VIDIOC_STREAMON, &format.type) < 0) {/' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
  perl -0pi -e 's/struct v4l2_streamparm parm = \{0\};\n\tparm.type = V4L2_BUF_TYPE_VIDEO_OUTPUT;\n\n\tif \(ioctl\(vcam->device, VIDIOC_STREAMOFF, &parm\) < 0\) \{/uint32_t buf_type = V4L2_BUF_TYPE_VIDEO_OUTPUT;\n\n\tif (vcam->use_caps_workaround &&\n\t    ioctl(vcam->device, VIDIOC_STREAMOFF, &buf_type) < 0) {/' "$OBS_SRC/plugins/linux-v4l2/v4l2-output.c"
fi

echo "==> Preparing nv-codec-headers $NV_CODEC_TAG"
clone_or_update "https://github.com/FFmpeg/nv-codec-headers.git" "$NV_CODEC_SRC" "$NV_CODEC_TAG"
rm -rf "$FFNV_PREFIX"
make -C "$NV_CODEC_SRC" PREFIX="$FFNV_PREFIX" install

echo "==> Preparing Mbed TLS $MBEDTLS_TAG"
clone_or_update "https://github.com/Mbed-TLS/mbedtls.git" "$MBEDTLS_SRC" "$MBEDTLS_TAG"
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
