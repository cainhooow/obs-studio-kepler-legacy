#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${ROOT_DIR:-}" ]]; then
  ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

readonly PROJECT_VERSION_FILE="${PROJECT_VERSION_FILE:-$ROOT_DIR/VERSION}"

if [[ -z "${PROJECT_VERSION:-}" ]]; then
  if [[ -f "$PROJECT_VERSION_FILE" ]]; then
    PROJECT_VERSION="$(tr -d '\n' < "$PROJECT_VERSION_FILE")"
  else
    PROJECT_VERSION="30.2.3-kepler.4"
  fi
fi

OBS_UPSTREAM_URL="${OBS_UPSTREAM_URL:-https://github.com/obsproject/obs-studio.git}"
FFMPEG_UPSTREAM_URL="${FFMPEG_UPSTREAM_URL:-https://github.com/FFmpeg/FFmpeg.git}"
NV_CODEC_UPSTREAM_URL="${NV_CODEC_UPSTREAM_URL:-https://github.com/FFmpeg/nv-codec-headers.git}"
MBEDTLS_UPSTREAM_URL="${MBEDTLS_UPSTREAM_URL:-https://github.com/Mbed-TLS/mbedtls.git}"

OBS_TAG="${OBS_TAG:-30.2.3}"
FFMPEG_TAG="${FFMPEG_TAG:-n8.1}"

OBS_NV_CODEC_TAG_DEFAULT="${OBS_NV_CODEC_TAG_DEFAULT:-n12.1.14.0}"
FFMPEG_NV_CODEC_TAG_DEFAULT="${FFMPEG_NV_CODEC_TAG_DEFAULT:-n11.1.5.3}"

MBEDTLS_TAG_DEFAULT="${MBEDTLS_TAG_DEFAULT:-mbedtls-3.6.6}"
UTHASH_TAG_DEFAULT="${UTHASH_TAG_DEFAULT:-v2.3.0}"
NLOHMANN_JSON_TAG_DEFAULT="${NLOHMANN_JSON_TAG_DEFAULT:-v3.11.3}"
