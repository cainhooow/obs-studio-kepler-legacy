#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

is_elf() {
  local target="$1"
  [[ -f "$target" ]] || return 1
  file -Lb "$target" | grep -q '^ELF'
}

set_rpath() {
  local target="$1"
  local rpath="$2"

  is_elf "$target" || return 0
  patchelf --set-rpath "$rpath" "$target"
}

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

set_rpath "$OBS_PREFIX/bin/obs.real" '$ORIGIN/../lib'
set_rpath "$OBS_PREFIX/bin/obs-ffmpeg-mux.real" '$ORIGIN/../lib:$ORIGIN/../../ffmpeg-nvenc470/lib'

if [[ -d "$OBS_PREFIX/lib" ]]; then
  while IFS= read -r -d '' target; do
    set_rpath "$target" '$ORIGIN:$ORIGIN/../../ffmpeg-nvenc470/lib'
  done < <(find "$OBS_PREFIX/lib" -maxdepth 1 -type f \( -name '*.so' -o -name '*.so.*' \) -print0)
fi

if [[ -d "$OBS_PREFIX/lib/obs-plugins" ]]; then
  while IFS= read -r -d '' target; do
    set_rpath "$target" '$ORIGIN/..:$ORIGIN/../../../ffmpeg-nvenc470/lib'
  done < <(find "$OBS_PREFIX/lib/obs-plugins" -maxdepth 1 -type f -name '*.so' -print0)
fi

if [[ -d "$OBS_PREFIX/lib/obs-scripting" ]]; then
  while IFS= read -r -d '' target; do
    set_rpath "$target" '$ORIGIN/..:$ORIGIN/../../../ffmpeg-nvenc470/lib'
  done < <(find "$OBS_PREFIX/lib/obs-scripting" -maxdepth 1 -type f -name '*.so' -print0)
fi

set_rpath "$FFMPEG_PREFIX/bin/ffmpeg.real" '$ORIGIN/../lib'
set_rpath "$FFMPEG_PREFIX/bin/ffprobe.real" '$ORIGIN/../lib'
set_rpath "$FFMPEG_PREFIX/bin/ffplay.real" '$ORIGIN/../lib'

if [[ -d "$FFMPEG_PREFIX/lib" ]]; then
  while IFS= read -r -d '' target; do
    set_rpath "$target" '$ORIGIN'
  done < <(find "$FFMPEG_PREFIX/lib" -maxdepth 1 -type f \( -name '*.so' -o -name '*.so.*' \) -print0)
fi

echo "Bundle relocation wrappers applied under: $ROOT_DIR"
