# OBS + NVENC on the GTX 660 (Arch Linux)

Quick summary:

- The `GTX 660` is a `Kepler` GPU.
- `OBS Studio 31.0.0` and newer removed NVENC support for Kepler GPUs.
- `OBS 30.2.x` is the last OBS line that still supports Kepler NVENC.
- On this system, Arch `ffmpeg 8.1` already exposes `h264_nvenc`, but it fails at runtime because it was built against `Video Codec SDK 13.0`, while driver `470.256.02` only provides `NVENC API 11.1`.

Version choices:

- OBS: `30.2.3`
- FFmpeg: `8.1`
- `nv-codec-headers` for FFmpeg: `11.1.5.3`
- `nv-codec-headers` for OBS: `12.1.14.0`

Why two header versions are used:

- `ffmpeg 8.1` can be built against `ffnvcodec 11.1.5.3`, which matches the legacy `470.xx` driver branch.
- `OBS 30.2.3` expects headers in the `12.0 <= version < 12.2` range, but it still contains a compatibility path that falls back to `NVENC API 11.1` at runtime on Kepler GPUs.

Included build scripts:

- `scripts/build_ffmpeg_nvenc470.sh`
- `scripts/build_obs_kepler.sh`

What the OBS build script patches:

- downloads `nlohmann/json v3.11.3` locally because the current Arch build environment does not provide it automatically for this older OBS line
- adds `#include <cstdint>` to `json11.cpp` so it builds cleanly with the current toolchain
- disables the VAAPI code path in `obs-ffmpeg`, because `OBS 30.2.3` does not build cleanly against `ffmpeg 8.1` there and VAAPI is not needed for this GTX 660 NVENC target
- disables `HEVC NVENC` exposure in OBS, because the `GTX 660` does not support that codec in hardware even if FFmpeg exposes the encoder symbol

Usage:

```bash
./scripts/build_ffmpeg_nvenc470.sh
./scripts/build_obs_kepler.sh
```

After building FFmpeg:

```bash
"$PWD/.local/ffmpeg-nvenc470/bin/ffmpeg" -hide_banner -encoders | rg nvenc
```

If you want to test a real encode:

```bash
"$PWD/.local/ffmpeg-nvenc470/bin/ffmpeg" \
  -f lavfi -i testsrc2=size=1280x720:rate=30 -t 1 \
  -c:v h264_nvenc -f null -
```

After building OBS:

```bash
"$PWD/.local/obs-kepler/bin/obs"
```

Validation completed on this machine:

- the custom `ffmpeg` in `.local/ffmpeg-nvenc470` initializes `h264_nvenc` successfully on the `GTX 660`
- the OBS build in `.local/obs-kepler` starts as `OBS 30.2.3-modified`
- the OBS log reports `NVENC supported`
- the encoder listed by OBS is `jim_nvenc`

Note:

- the current `obs-studio` package in the Arch `extra` repository is `32.1.0-2`, but that line is already outside the Kepler NVENC support window
