# Arch Packaging

This directory contains an optional `PKGBUILD` for users who prefer to install the release bundle with `makepkg`.

Important:

- `obs-studio-kepler-legacy-<version>.tar.gz` is a generic release bundle, not a pacman package
- `pacman -U` expects a real package file such as `*.pkg.tar.zst`

## Supported Flow

1. Create a release archive from the project root:

```bash
./release.sh
```

Or create both the release archive and an installable Arch package:

```bash
./release.sh --arch-package --test-artifacts
```

2. Copy the generated archive from `dist/` into this directory:

```bash
cp dist/obs-studio-kepler-legacy-*.tar.gz packaging/
```

3. Build and install the package:

```bash
cd packaging
makepkg -si
```

If you already generated the package into `dist/`, you can install it directly with:

```bash
sudo pacman -U dist/obs-studio-kepler-legacy-bin-*.pkg.tar.zst
```

## What the Package Installs

- the full runtime bundle under `/opt/obs-studio-kepler-legacy`
- launchers under `/usr/bin`
- a desktop entry under `/usr/share/applications`
- icons under `/usr/share/icons/hicolor`

## Notes

- this is a local packaging recipe, not an official upstream Arch package
- the package is intentionally named `obs-studio-kepler-legacy-bin` so it can coexist with the normal `obs-studio` package
- Linux virtual camera support still depends on the host `v4l2loopback` module
