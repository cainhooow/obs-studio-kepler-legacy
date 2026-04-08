# Installation Guide

This document explains the supported ways to use this project:

- run it directly from the extracted project folder
- install it from the AUR
- use the interactive setup wizard
- install it for the current user
- install it system-wide
- install it as a local Arch package

The primary installer entrypoint is:

```bash
./install.sh --user
```

or:

```bash
sudo ./install.sh --system
```

The guided setup entrypoint is:

```bash
./install.sh --all
```

That mode can walk a user through:

- building FFmpeg from source
- building OBS from source
- optionally removing downloaded sources and temporary build artifacts after the build
- installing the bundle
- checking or configuring Arch Linux virtual camera support
- running runtime validation

If you want the installer to clean build artifacts automatically without asking, use:

```bash
./install.sh --all --clean-build-artifacts
```

If you want a versioned release archive first, create one with:

```bash
./release.sh
```

## 1. Run Directly From the Project Folder

This is the safest way to test the bundle before installing anything.

From the project root:

```bash
./bin/obs-studio-kepler-legacy
./bin/ffmpeg-kepler-legacy -hide_banner -encoders | rg nvenc
```

This mode:

- does not overwrite your system OBS package
- keeps legacy OBS configuration separate from normal OBS
- is ideal for first-run testing

## 2. Install for the Current User

This installs the project under your home directory and does not require root.

From the project root:

```bash
./install.sh --user
```

Default user install locations:

- runtime bundle: `~/.local/opt/obs-studio-kepler-legacy`
- launchers: `~/.local/bin/obs-studio-kepler-legacy` and `~/.local/bin/ffmpeg-kepler-legacy`
- desktop entry: `~/.local/share/applications/obs-studio-kepler-legacy.desktop`

After installation, launch it with:

```bash
obs-studio-kepler-legacy
```

If `~/.local/bin` is not on your `PATH`, either:

- launch it with the full path, or
- add `~/.local/bin` to your shell profile

## 3. Install System-Wide

This installs the bundle under `/opt` and creates launchers under `/usr/local/bin`.

From the project root:

```bash
sudo ./install.sh --system
```

Default system install locations:

- runtime bundle: `/opt/obs-studio-kepler-legacy`
- launchers: `/usr/local/bin/obs-studio-kepler-legacy` and `/usr/local/bin/ffmpeg-kepler-legacy`
- desktop entry: `/usr/local/share/applications/obs-studio-kepler-legacy.desktop`

## 4. Install From AUR

The easiest Arch Linux install path is:

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

That installs the bundle under `/opt/obs-studio-kepler-legacy` and creates launchers under `/usr/bin`.

## 5. Install With makepkg

If you prefer an Arch package workflow, use the optional local `PKGBUILD`.

Recommended Arch Linux install:

```bash
./release.sh --arch-package --test-artifacts
sudo pacman -U dist/obs-studio-kepler-legacy-bin-*.pkg.tar.zst
```

For the JACK dependency on Arch Linux, either of these is valid:

- `pipewire-jack`
- `jack2`

For the PulseAudio-compatible audio layer on Arch Linux, either of these is valid:

- `pipewire-pulse`
- `pulseaudio`

For PipeWire-based features such as Wayland screen capture integration, keep the `pipewire` package installed on the host system.

On X11 sessions, this project intentionally hides the PipeWire screen capture sources. They are only exposed on Wayland sessions, where the portal screencast path is suitable for continuous capture.

Manual package build from the project root:

```bash
./release.sh
cp dist/obs-studio-kepler-legacy-*.tar.gz packaging/
cd packaging
makepkg -si
```

That package installs the bundle under `/opt/obs-studio-kepler-legacy` and creates launchers under `/usr/bin`.

## Virtual Camera on Linux

This project already includes the OBS Linux virtual camera plugin.

On Arch Linux, you still need the `v4l2loopback` kernel module on the host system for the virtual camera output to be registered.

See:

- [`VIRTUAL_CAMERA.md`](./VIRTUAL_CAMERA.md)

## 6. Separate Configuration

This project intentionally keeps its OBS configuration separate from a normal OBS install.

By default, legacy OBS stores configuration here:

```text
~/.config/obs-studio-kepler-legacy/obs-studio
```

This makes it possible to keep:

- the current Arch OBS package
- a separate Kepler-compatible OBS build

on the same machine without sharing scene collections and profiles by default.

## 7. Environment Overrides

If you want to move the legacy config directories somewhere else, you can override them:

```bash
OBS_STUDIO_KEPLER_LEGACY_CONFIG_BASE=/some/path/config \
OBS_STUDIO_KEPLER_LEGACY_CACHE_BASE=/some/path/cache \
OBS_STUDIO_KEPLER_LEGACY_STATE_BASE=/some/path/state \
./bin/obs-studio-kepler-legacy
```

## 8. Validate the Bundle

To run a quick validation:

```bash
./scripts/validate_runtime.sh
```

This checks:

- OBS launcher startup
- FFmpeg launcher startup
- NVIDIA driver visibility
- a real `h264_nvenc` encode test
- Linux virtual camera status as an informational check

To test the release artifacts themselves:

```bash
./scripts/test_release_artifacts.sh --build-package
```

## 9. Build or Rebuild From Source

Yes: the provided build scripts already download the upstream sources automatically.

They populate a local source cache under:

- `.cache/kepler-build/ffmpeg`
- `.cache/kepler-build/obs`

Typical rebuild flow from the project root:

```bash
./scripts/build_ffmpeg_nvenc470.sh
./scripts/build_obs_kepler.sh
```

If you build through the installer wizard, it can remove cached source/build trees afterwards while keeping the final local bundle under:

- `.local/ffmpeg-nvenc470`
- `.local/obs-kepler`

For the full build guide, including cache locations, clean rebuilds, and environment overrides, see:

- [`BUILDING.md`](./BUILDING.md)

## 10. Uninstall

### User Install

```bash
./uninstall.sh --user
```

### System Install

```bash
sudo ./uninstall.sh --system
```

If you also want to remove the separate runtime state, delete:

```bash
rm -rf \
  ~/.config/obs-studio-kepler-legacy \
  ~/.cache/obs-studio-kepler-legacy \
  ~/.local/state/obs-studio-kepler-legacy
```
