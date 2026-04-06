# Changelog

All notable changes to this project will be documented in this file.

## 30.2.3-kepler.3 - 2026-04-06

Wayland/PipeWire capture stability update for NVIDIA systems.

### Added

- upstream PipeWire explicit-sync backports for OBS `30.2.3`
- upstream PipeWire render-technique and syncobj follow-up fixes needed for the explicit-sync path
- local legacy-build compatibility patch for `libdrm`

### Changed

- `build_obs_kepler.sh` now injects `libdrm` compiler and linker flags via `pkg-config` on Arch Linux
- the OBS bundle now links `libobs-opengl` against `libdrm`, enabling the explicit-sync backport at runtime

### Fixed

- reduced incomplete-frame flicker in Wayland PipeWire captures on NVIDIA, including GNOME top bar and KDE panel artifacts seen in OBS preview/output
- fixed legacy OBS source builds on Arch that otherwise failed to compile the explicit-sync backport because `drm.h` was not on the compiler include path

## 30.2.3-kepler.2 - 2026-04-05

Release packaging correction.

### Added

- installable Arch package output in `dist/*.pkg.tar.zst`
- release artifact validation script for tarballs, checksums, and Arch package metadata

### Changed

- `release.sh` can now build the Arch package and run artifact tests in one pass
- documentation now clearly distinguishes the generic `.tar.gz` bundle from the `pacman -U` package artifact
- Arch packaging disables split debug output for this prebuilt bundle

## 30.2.3-kepler.1 - 2026-04-05

Initial public project release.

### Added

- bundled `OBS Studio 30.2.3` runtime configured for Kepler-compatible NVENC
- bundled `FFmpeg 8.1` runtime configured for legacy `470.xx` NVENC compatibility
- isolated launchers: `obs-studio-kepler-legacy` and `ffmpeg-kepler-legacy`
- user and system installers
- Arch Linux virtual camera helper scripts and documentation
- release packaging via `./release.sh`
- optional Arch `PKGBUILD`
- automated project checks and GitHub Actions workflow
- structured patch metadata and validation

### Changed

- moved local compatibility backports into ordered patch series under `patches/`
- documented the full build, install, troubleshooting, hardening, and release workflow

### Hardening

- added low-risk OBS backports for empty option parsing, JSON null handling, POSIX pipe fd management, preview clamping, Linux virtual camera fd handling, and empty scene collection rejection
