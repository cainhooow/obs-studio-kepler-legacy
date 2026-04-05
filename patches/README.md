# Patch Series

This directory stores local source patch series used by the build scripts.

Layout:

- `patches/obs` for `obs-studio` source patches
- `patches/ffmpeg` for `FFmpeg` source patches

Conventions:

- use unified diff patch files with `.patch` or `.diff`
- prefix filenames with a four-digit order number such as `0001-fix-name.patch`
- add a short metadata header before the diff payload
- keep one logical change per patch when possible
- generate patches relative to the upstream source tree root

Required metadata header:

```text
# Patch-Name: 0001-fix-name.patch
# Patch-Origin: upstream commit, issue, or local compatibility note
# Patch-Reason: why this project carries the patch
# Patch-Risk: low, medium, or high with a short explanation
```

The actual diff body must still begin with `diff --git ...`.

Behavior:

- `scripts/build_obs_kepler.sh` loads patches from `patches/obs`
- `scripts/build_ffmpeg_nvenc470.sh` loads patches from `patches/ffmpeg`
- `scripts/libpatches.sh` validates filenames and metadata headers before applying them
- each patch is validated with `git apply --check` before it is applied
- already-applied patches are detected and skipped
