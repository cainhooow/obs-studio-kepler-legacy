#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

wrap_binary() {
  local target="$1"
  local library_path_expr="$2"
  local real_target="${target}.real"

  [[ -e "$target" ]] || return 0

  if [[ ! -e "$real_target" ]]; then
    mv "$target" "$real_target"
  fi

  cat >"$target" <<EOF
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="\${BASH_SOURCE[0]}"
while [[ -L "\$SCRIPT_PATH" ]]; do
  SCRIPT_DIR="\$(cd -P -- "\$(dirname -- "\$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="\$(readlink "\$SCRIPT_PATH")"
  [[ "\$SCRIPT_PATH" != /* ]] && SCRIPT_PATH="\$SCRIPT_DIR/\$SCRIPT_PATH"
done
BIN_DIR="\$(cd -P -- "\$(dirname -- "\$SCRIPT_PATH")" && pwd)"
PREFIX="\$(cd -- "\$BIN_DIR/.." && pwd)"
ROOT_DIR="\$(cd -- "\$PREFIX/../.." && pwd)"
export LD_LIBRARY_PATH="${library_path_expr}\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
exec "\$BIN_DIR/$(basename -- "$real_target")" "\$@"
EOF

  chmod +x "$target" "$real_target"
}

OBS_PREFIX="$ROOT_DIR/.local/obs-kepler"
FFMPEG_PREFIX="$ROOT_DIR/.local/ffmpeg-nvenc470"

wrap_binary \
  "$OBS_PREFIX/bin/obs" \
  "\$PREFIX/lib:\$ROOT_DIR/.local/ffmpeg-nvenc470/lib"

wrap_binary \
  "$OBS_PREFIX/bin/obs-ffmpeg-mux" \
  "\$PREFIX/lib:\$ROOT_DIR/.local/ffmpeg-nvenc470/lib"

wrap_binary \
  "$FFMPEG_PREFIX/bin/ffmpeg" \
  "\$PREFIX/lib"

wrap_binary \
  "$FFMPEG_PREFIX/bin/ffprobe" \
  "\$PREFIX/lib"

wrap_binary \
  "$FFMPEG_PREFIX/bin/ffplay" \
  "\$PREFIX/lib"

echo "Bundle relocation wrappers applied under: $ROOT_DIR"
