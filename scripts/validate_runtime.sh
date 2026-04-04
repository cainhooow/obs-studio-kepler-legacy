#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OBS_CMD="$ROOT_DIR/bin/obs-studio-kepler-legacy"
FFMPEG_CMD="$ROOT_DIR/bin/ffmpeg-kepler-legacy"

if [[ ! -x "$OBS_CMD" ]]; then
  echo "Missing OBS launcher: $OBS_CMD" >&2
  exit 1
fi

if [[ ! -x "$FFMPEG_CMD" ]]; then
  echo "Missing FFmpeg launcher: $FFMPEG_CMD" >&2
  exit 1
fi

echo "==> Versions"
"$OBS_CMD" --version
"$FFMPEG_CMD" -version | head -n 1

if command -v nvidia-smi >/dev/null 2>&1; then
  echo
  echo "==> NVIDIA driver"
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
else
  echo
  echo "==> NVIDIA driver"
  echo "nvidia-smi not found; skipping driver summary"
fi

echo
echo "==> FFmpeg NVENC encode test"
"$FFMPEG_CMD" \
  -hide_banner -loglevel error \
  -f lavfi -i testsrc2=size=640x360:rate=30 -t 1 \
  -c:v h264_nvenc -f null -

echo
echo "==> Linux virtual camera status"
if [[ -f "$ROOT_DIR/.local/obs-kepler/lib/obs-plugins/linux-v4l2.so" ]]; then
  echo "linux-v4l2 plugin: present"
else
  echo "linux-v4l2 plugin: missing"
fi

if command -v modinfo >/dev/null 2>&1 && modinfo v4l2loopback >/dev/null 2>&1; then
  echo "v4l2loopback metadata: available"
else
  echo "v4l2loopback metadata: unavailable"
fi

if command -v lsmod >/dev/null 2>&1 && lsmod | rg -q '^v4l2loopback\b'; then
  echo "v4l2loopback module: loaded"
else
  echo "v4l2loopback module: not loaded"
fi

if command -v v4l2-ctl >/dev/null 2>&1; then
  echo
  echo "Visible V4L2 devices:"
  v4l2-ctl --list-devices 2>/dev/null || true
fi

echo
echo "Validation completed successfully."
