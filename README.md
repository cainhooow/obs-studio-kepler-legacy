# OBS Studio Kepler Legacy

![Arch Linux](https://img.shields.io/badge/platform-Arch%20Linux-1793D1)
![GPU](https://img.shields.io/badge/GPU-NVIDIA%20Kepler-76B900)
![NVENC](https://img.shields.io/badge/NVENC-H.264-success)
![OBS](https://img.shields.io/badge/OBS-30.2.3-orange)
![FFmpeg](https://img.shields.io/badge/FFmpeg-8.1-blue)
[![AUR package](https://img.shields.io/badge/AUR-obs--studio--kepler--legacy--bin-1793D1)](https://aur.archlinux.org/packages/obs-studio-kepler-legacy-bin)

`OBS Studio Kepler Legacy` is a compatibility-focused `OBS + FFmpeg` bundle for NVIDIA Kepler GPUs on Arch Linux.

It preserves a practical `H.264 NVENC` workflow for systems that still depend on the legacy `470.xx` NVIDIA driver branch, while keeping the runtime isolated from a normal OBS installation.

## Compatibility Matrix

| Item | Value | Status |
| --- | --- | --- |
| Project release | `30.2.3-kepler.2` | current bundle |
| OBS base | `30.2.3` | bundled |
| FFmpeg base | `8.1` | bundled |
| Primary GPU target | `GeForce GTX 660` | validated |
| Driver branch | `470.xx` | validated |
| NVENC | `H.264` | working |
| HEVC NVENC | Kepler GTX 660 | intentionally not exposed |
| Virtual camera | `linux-v4l2` + `v4l2loopback` | supported |

## Quick Install

Run the bundle directly:

```bash
./bin/obs-studio-kepler-legacy
```

Install for the current user:

```bash
./install.sh --user
obs-studio-kepler-legacy
```

Run the guided setup wizard:

```bash
./install.sh --all
```

Install from the AUR after the package is published:

```bash
paru -S obs-studio-kepler-legacy-bin
```

## Quick Validation

```bash
./scripts/validate_runtime.sh
./bin/ffmpeg-kepler-legacy -hide_banner -encoders | rg nvenc
```

## Why Not Latest OBS?

Because the goal of this project is not “latest OBS at any cost”; it is “working Kepler NVENC on Arch Linux”.

The main compatibility constraints are:

- `OBS 31.0` and newer removed Kepler NVENC support
- current Arch `ffmpeg` package lines expect a newer NVENC API than the legacy `470.xx` driver branch provides
- older GPUs can appear to support an encoder in the UI and still fail at runtime

This project deliberately keeps a known-good legacy path:

- `OBS 30.2.3`
- `FFmpeg 8.1`
- a validated Kepler-friendly NVENC stack
- isolated launchers and config paths so it can coexist with normal OBS

## What This Project Includes

- bundled `OBS Studio 30.2.3`
- bundled `FFmpeg 8.1`
- launchers renamed to avoid collisions with a normal OBS install
- isolated config, cache, and state paths
- user and system installers
- an interactive setup wizard
- build scripts that download upstream sources automatically
- ordered patch series with metadata and validation
- Arch virtual camera setup helpers
- release packaging and an optional `PKGBUILD`

## Installation Modes

### Run Directly From the Project Folder

```bash
./bin/obs-studio-kepler-legacy
./bin/ffmpeg-kepler-legacy -version
```

### Guided Setup Wizard

```bash
./install.sh --all
```

The wizard can:

- build `FFmpeg` from source
- build `OBS` from source
- clean build artifacts after the build
- install the bundle for the current user or system-wide
- check and configure Linux virtual camera support on Arch Linux
- run runtime validation

### User Install

```bash
./install.sh --user
```

### System Install

```bash
sudo ./install.sh --system
```

### Local Arch Package Install

```bash
./release.sh --arch-package --test-artifacts
sudo pacman -U dist/obs-studio-kepler-legacy-bin-*.pkg.tar.zst
```

### Install From AUR

Once the AUR package is published, Arch users can install it with an AUR helper:

```bash
paru -S obs-studio-kepler-legacy-bin
```

or:

```bash
yay -S obs-studio-kepler-legacy-bin
```

If you prefer the manual AUR workflow:

```bash
git clone https://aur.archlinux.org/obs-studio-kepler-legacy-bin.git
cd obs-studio-kepler-legacy-bin
makepkg -si
```

That installs the package under `/opt/obs-studio-kepler-legacy` and creates launchers under `/usr/bin`.

## Coexistence With Normal OBS

This bundle is intentionally safe to keep alongside a normal OBS install.

Separation is handled by:

- a different launcher name: `obs-studio-kepler-legacy`
- a different default config root: `~/.config/obs-studio-kepler-legacy/obs-studio`
- its own bundled `FFmpeg`

That keeps profiles, scene collections, and runtime state isolated by default.

## Build From Source

Yes: the build scripts download the upstream sources automatically.

Recommended order:

```bash
./scripts/build_ffmpeg_nvenc470.sh
./scripts/build_obs_kepler.sh
```

Default build layout:

- sources and temporary build trees: `.cache/kepler-build/...`
- final FFmpeg bundle: `.local/ffmpeg-nvenc470`
- final OBS bundle: `.local/obs-kepler`

Patch series are stored under:

- `patches/obs`
- `patches/ffmpeg`

and are validated before application.

## Releases And Packaging

Create a distributable archive:

```bash
./release.sh
```

That produces:

- `dist/obs-studio-kepler-legacy-<version>.tar.gz`
- `dist/obs-studio-kepler-legacy-<version>.tar.gz.sha256`

If you also want an installable Arch package and a quick artifact test pass, use:

```bash
./release.sh --arch-package --test-artifacts
```

That additionally produces:

- `dist/obs-studio-kepler-legacy-bin-<version>-1-x86_64.pkg.tar.zst`
- `dist/obs-studio-kepler-legacy-bin-<version>-1-x86_64.pkg.tar.zst.sha256`

For Arch Linux installation, use:

```bash
sudo pacman -U dist/obs-studio-kepler-legacy-bin-*.pkg.tar.zst
```

The Arch package uses ABI-level dependencies for the audio stack, so it works with either `pipewire-jack` or `jack2`.

For PulseAudio-compatible audio on Arch Linux, it also works with either `pipewire-pulse` or `pulseaudio`.

If you want PipeWire-based features such as Wayland screen capture integration, keep the `pipewire` package installed on the host system.

The optional Arch packaging recipe lives in:

- [`packaging/PKGBUILD`](packaging/PKGBUILD)
- [`packaging/README.md`](packaging/README.md)

## Quality Checks

Run the full local project checks:

```bash
./scripts/check_project.sh
```

Validate only the patch series:

```bash
./scripts/check_patch_series.sh
```

Test release artifacts:

```bash
./scripts/test_release_artifacts.sh --build-package
```

## Documentation Index

| Document | Purpose |
| --- | --- |
| [`docs/INSTALLATION.md`](docs/INSTALLATION.md) | end-user installation paths and install modes |
| [`docs/BUILDING.md`](docs/BUILDING.md) | rebuilding OBS and FFmpeg from source |
| [`docs/AUR.md`](docs/AUR.md) | preparing and publishing the AUR package |
| [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) | common runtime and setup problems |
| [`docs/VIRTUAL_CAMERA.md`](docs/VIRTUAL_CAMERA.md) | Linux virtual camera setup on Arch |
| [`docs/HARDENING.md`](docs/HARDENING.md) | security posture and carried backports |
| [`docs/obs-nvenc-kepler-arch.md`](docs/obs-nvenc-kepler-arch.md) | detailed engineering notes from the validated build |
| [`CHANGELOG.md`](CHANGELOG.md) | release history |
| [`SECURITY.md`](SECURITY.md) | support and reporting expectations |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | contribution and release workflow |

## Main Launchers

Primary launchers:

- [`bin/obs-studio-kepler-legacy`](bin/obs-studio-kepler-legacy)
- [`bin/ffmpeg-kepler-legacy`](bin/ffmpeg-kepler-legacy)

Compatibility aliases:

- [`bin/obs-studio-legacy`](bin/obs-studio-legacy)
- [`bin/ffmpeg-nvenc470`](bin/ffmpeg-nvenc470)

## Troubleshooting Overview

The most common mistakes are:

- starting the raw OBS binary instead of the wrapper
- using the system `ffmpeg` instead of the bundled one
- expecting `HEVC NVENC` on unsupported Kepler hardware
- missing `v4l2loopback` when trying to use the virtual camera
- not having `~/.local/bin` on `PATH` after a user install

Full troubleshooting steps are documented in [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md).

## Known Limitations

- this is a legacy compatibility project, not a feature-equivalent replacement for modern OBS
- it is tuned for Arch Linux and the `470.xx` Kepler workflow
- it is primarily intended for `H.264 NVENC`
- several optional components are intentionally disabled to reduce maintenance and attack surface

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
