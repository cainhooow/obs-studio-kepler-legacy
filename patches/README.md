# Patch Series

This directory stores local source patch series used by the build scripts.

Layout:

- `patches/obs` for `obs-studio` source patches
- `patches/ffmpeg` for `FFmpeg` source patches

Conventions:

- use unified diff patch files with `.patch` or `.diff`
- prefix filenames with a four-digit order number such as `0001-fix-name.patch`
- keep one logical change per patch when possible
- generate patches relative to the upstream source tree root

Behavior:

- `scripts/build_obs_kepler.sh` loads patches from `patches/obs`
- `scripts/build_ffmpeg_nvenc470.sh` loads patches from `patches/ffmpeg`
- `scripts/libpatches.sh` validates filenames before applying them
- each patch is validated with `git apply --check` before it is applied
- already-applied patches are detected and skipped
