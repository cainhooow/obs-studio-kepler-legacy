# Hardening Notes

This legacy bundle intentionally stays on `OBS Studio 30.2.3` for Kepler NVENC compatibility, but it does not stop at the raw upstream tag.

The project carries a small set of targeted hardening and robustness backports where they are low-risk, compatible with the legacy branch, and relevant to the features that are actually built and shipped here.

## Security Posture of This Bundle

This build already reduces a lot of attack surface compared to a default modern OBS package build:

- `obs-browser` is disabled
- `obs-websocket` is disabled
- `webrtc` is disabled
- `rtmps` is disabled
- the native `mpegts` SRT/RIST output path is disabled

That means several later upstream fixes for browser, websocket, Chromium, and the new `mpegts` output code are intentionally not part of this bundle because those components are not built here.

## Baseline Security Fix Already Present in 30.2.3

`OBS 30.2.3` already includes the `libnsgif` heap overflow fix that landed in `30.2.1+`.

## Additional Backports Included by This Project

The current patch series also adds these low-risk hardening backports:

- `0005-deps-opts-parser-handle-empty-option-lists.patch`
  - avoids a crash path when the option parser receives an effectively empty option list
- `0006-libobs-handle-json-null-data.patch`
  - preserves JSON `null` safely and avoids serializing a null object as a normal JSON object
- `0007-libobs-fix-pipe-posix-fd-management.patch`
  - fixes file descriptor handling in POSIX process pipes and avoids double-close / descriptor leakage edge cases
- `0008-ui-clamp-cropped-preview-sizes.patch`
  - clamps negative preview dimensions after extreme crop values and avoids integer underflow/overflow behavior in the editor preview
- `0009-linux-v4l2-avoid-closing-invalid-fds.patch`
  - prevents the virtual camera plugin from closing invalid file descriptors and potentially closing the wrong fd

## What Was Intentionally Not Backported

Some later upstream fixes were reviewed but not added here because they do not affect the shipped feature set of this bundle:

- new native `mpegts` SRT/RIST output crash fixes
  - not relevant here because the build uses `ENABLE_NEW_MPEGTS_OUTPUT=OFF`
- `obs-browser` dependency and Chromium-related fixes
  - not relevant here because browser support is disabled
- `obs-websocket` fixes
  - not relevant here because websocket support is disabled

## Maintenance Rule

For this project, a backport should usually satisfy all of the following:

- it fixes a crash, overflow, invalid input path, or resource-management bug
- it applies to a component that is actually built in this bundle
- it is small enough to audit and maintain in a legacy branch
- it does not put Kepler compatibility at risk

## Patch Locations

All source backports live in:

- `patches/obs`
- `patches/ffmpeg`
