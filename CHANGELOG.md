# Changelog

All notable changes to this project will be documented in this file.

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
