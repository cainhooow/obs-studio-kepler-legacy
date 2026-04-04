# OBS Studio Kepler Legacy

`OBS Studio Kepler Legacy` is a compatibility-focused OBS + FFmpeg bundle for NVIDIA Kepler GPUs on Arch Linux, especially systems that still rely on the legacy `470.xx` driver branch.

It is designed for users who need a practical, working `H.264 NVENC` workflow on hardware that is no longer served well by current upstream OBS releases and current Arch Linux multimedia packages.

## Why This Project Exists

Modern OBS and modern Arch FFmpeg packages are a poor fit for older Kepler systems:

- OBS `31.0.0` and newer removed Kepler NVENC support
- the current Arch FFmpeg package line expects a newer NVENC API than the `470.xx` driver branch provides
- older GPUs can end up showing an encoder in a menu that fails at runtime

This project packages a known-good compatibility path for that exact situation.

## Validated Target

This bundle was validated on:

- Arch Linux
- NVIDIA `470.256.02`
- Intel `i7-4790`
- NVIDIA `GeForce GTX 660`

Expected working result:

- OBS starts normally through the provided launcher
- OBS reports `NVENC supported`
- OBS exposes `NVIDIA NVENC H.264`
- the bundled FFmpeg completes a real `h264_nvenc` encode test

## Included Components

- OBS Studio `30.2.3`
- FFmpeg `8.1`
- build scripts for OBS and FFmpeg
- a separate launcher name to avoid collisions with a normal OBS install
- separate config/cache/state paths so legacy OBS can coexist with current OBS
- user and system installers
- desktop integration template
- installation and troubleshooting guides

## Important Compatibility Notes

- This project targets `H.264 NVENC`
- `HEVC NVENC` is intentionally hidden in OBS for the validated GTX 660 target
- The launcher name is `obs-studio-kepler-legacy`, not `obs`, so it can coexist with a normal OBS package
- The legacy build stores its own settings separately from the normal OBS config by default
- Linux virtual camera support is included through `linux-v4l2`, but it requires the system `v4l2loopback` module

## Quick Start

If you only want to test the bundle before installing it:

```bash
./bin/obs-studio-kepler-legacy
./bin/ffmpeg-kepler-legacy -hide_banner -encoders | rg nvenc
```

To run a quick validation:

```bash
./scripts/validate_runtime.sh
```

## Installation

Three usage modes are supported:

- run directly from the extracted project folder
- use the interactive setup wizard
- install for the current user
- install system-wide

### Interactive Setup Wizard

```bash
./install.sh --all
```

This guided mode can:

- build FFmpeg from source
- build OBS from source
- optionally remove downloaded sources and temporary build artifacts afterwards
- install the bundle
- check and configure Linux virtual camera support on Arch Linux
- run runtime validation

It prompts before each step so users can skip anything they do not want.

If you want cleanup to happen automatically, use:

```bash
./install.sh --all --clean-build-artifacts
```

### User Install

```bash
./install.sh --user
```

After that, launch with:

```bash
obs-studio-kepler-legacy
```

### System Install

```bash
sudo ./install.sh --system
```

After that, launch with:

```bash
obs-studio-kepler-legacy
```

For full instructions, see:

- [`docs/INSTALLATION.md`](docs/INSTALLATION.md)

## Coexistence With Normal OBS

This project is intentionally safe to use alongside a normal OBS installation from Arch packages or another source.

The separation happens in two ways:

- the launcher name is different: `obs-studio-kepler-legacy`
- the default config root is different: `~/.config/obs-studio-kepler-legacy/obs-studio`

That means you can keep:

- a modern OBS install for newer hardware or testing
- this legacy Kepler build for real NVENC usage on older hardware

without sharing the same default profiles and scene collections.

## Main Launchers

Primary launchers:

- [`bin/obs-studio-kepler-legacy`](bin/obs-studio-kepler-legacy)
- [`bin/ffmpeg-kepler-legacy`](bin/ffmpeg-kepler-legacy)

Compatibility aliases:

- [`bin/obs-studio-legacy`](bin/obs-studio-legacy)
- [`bin/ffmpeg-nvenc470`](bin/ffmpeg-nvenc470)

The recommended names for real use and installation are:

- `obs-studio-kepler-legacy`
- `ffmpeg-kepler-legacy`

## Project Layout

```text
obs-studio-legacy/
├── .cache/                    # Local build cache
├── .local/                    # Local runtime bundle
├── bin/                       # End-user launchers
├── docs/                      # Installation, troubleshooting, notes
├── install/                   # Shared installer helper files
├── patches/                   # Source patch series for OBS/FFmpeg
├── scripts/                   # Build and validation scripts
├── share/                     # Desktop integration templates
├── .gitignore
├── install.sh                 # Main installer entrypoint
├── uninstall.sh               # Main uninstaller entrypoint
└── README.md
```

## Runtime Isolation

The OBS launcher sets dedicated XDG directories so the legacy build can stay isolated from a normal OBS installation.

Default locations:

- config: `~/.config/obs-studio-kepler-legacy`
- cache: `~/.cache/obs-studio-kepler-legacy`
- state: `~/.local/state/obs-studio-kepler-legacy`

Environment overrides are supported:

```bash
OBS_STUDIO_KEPLER_LEGACY_CONFIG_BASE=/some/config/root \
OBS_STUDIO_KEPLER_LEGACY_CACHE_BASE=/some/cache/root \
OBS_STUDIO_KEPLER_LEGACY_STATE_BASE=/some/state/root \
./bin/obs-studio-kepler-legacy
```

## Building From Source

This project includes the exact build scripts used to generate the validated bundle.

Yes: the build scripts download the upstream sources automatically.

They clone or fetch the required repositories into the local cache under:

- `.cache/kepler-build/ffmpeg`
- `.cache/kepler-build/obs`

They then build and install into:

- `.local/ffmpeg-nvenc470`
- `.local/obs-kepler`

Recommended build order:

1. build FFmpeg first
2. build OBS second

Build FFmpeg:

```bash
./scripts/build_ffmpeg_nvenc470.sh
```

Build OBS:

```bash
./scripts/build_obs_kepler.sh
```

If you want a full guide, including clean rebuilds, cache locations, source locations, and environment overrides, see:

- [`docs/BUILDING.md`](docs/BUILDING.md)

The default install destinations for the built bundle are:

- `.local/ffmpeg-nvenc470`
- `.local/obs-kepler`

The source compatibility fixes are stored as patch files under:

- `patches/obs`
- `patches/ffmpeg`

The build scripts validate and apply those patch series automatically.

Patch order is controlled by the filename prefix, so new patches should follow the `0001-description.patch` naming scheme documented in:

- [`patches/README.md`](patches/README.md)

## Extra Documentation

Installation guide:

- [`docs/INSTALLATION.md`](docs/INSTALLATION.md)

Troubleshooting guide:

- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

Build guide:

- [`docs/BUILDING.md`](docs/BUILDING.md)

Virtual camera guide:

- [`docs/VIRTUAL_CAMERA.md`](docs/VIRTUAL_CAMERA.md)

Hardening guide:

- [`docs/HARDENING.md`](docs/HARDENING.md)

Engineering/build note:

- [`docs/obs-nvenc-kepler-arch.md`](docs/obs-nvenc-kepler-arch.md)

## Troubleshooting Overview

The most common issues are:

- launching the raw OBS binary instead of the wrapper
- using the system FFmpeg instead of the bundled FFmpeg
- expecting HEVC NVENC on unsupported Kepler hardware
- not having `~/.local/bin` in `PATH` after a user install

Full troubleshooting steps are documented in:

- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)

## Validation

To verify the bundle on a target system:

```bash
./scripts/validate_runtime.sh
```

This checks:

- OBS launcher version
- FFmpeg launcher version
- NVIDIA driver visibility, when `nvidia-smi` is available
- a real one-second `h264_nvenc` encode
- Linux virtual camera status as an informational check

## Uninstall

User install:

```bash
./uninstall.sh --user
```

System install:

```bash
sudo ./uninstall.sh --system
```

If you also want to remove the isolated runtime state:

```bash
rm -rf \
  ~/.config/obs-studio-kepler-legacy \
  ~/.cache/obs-studio-kepler-legacy \
  ~/.local/state/obs-studio-kepler-legacy
```

## Known Limitations

- This is a legacy compatibility project, not a current upstream OBS replacement
- It is tuned for Arch Linux and a Kepler + `470.xx` driver workflow
- It is primarily intended for `H.264 NVENC`
- It does not try to emulate support for hardware features your GPU does not actually have

## Intended Audience

This project is a good fit if you are:

- a user keeping an older NVIDIA system alive
- an Arch Linux user who wants a separate legacy OBS install
- a technician or hobbyist helping someone with a Kepler system
- someone who needs a reproducible fallback for older NVENC hardware

It is probably not the right fit if you:

- use a modern NVIDIA GPU with current drivers
- want the latest OBS features
- want a distro-native package-manager-only setup with no compatibility tradeoffs

## Summary

If you need a real, working OBS + FFmpeg NVENC workflow on a Kepler system such as a GTX 660, this project gives you a practical compatibility bundle with:

- a renamed launcher for coexistence
- isolated configuration
- user and system installers
- bundled FFmpeg with a working legacy NVENC path
- reproducible build scripts
- documentation for both end users and technical users
