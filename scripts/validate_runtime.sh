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
echo "Validation completed successfully."
