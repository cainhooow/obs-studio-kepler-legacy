# Build Guide

This document explains how to rebuild the bundled `FFmpeg` and `OBS Studio` from source.

## Do the Scripts Download the Sources Automatically?

Yes.

The build scripts already download or update the upstream sources that they need.

They do not expect you to manually clone `obs-studio`, `FFmpeg`, `nv-codec-headers`, or the extra build-time dependencies first.

## What the Scripts Download

### FFmpeg Build Script

[`scripts/build_ffmpeg_nvenc470.sh`](../scripts/build_ffmpeg_nvenc470.sh) downloads or updates:

- `FFmpeg/FFmpeg`
- `FFmpeg/nv-codec-headers`

### OBS Build Script

[`scripts/build_obs_kepler.sh`](../scripts/build_obs_kepler.sh) downloads or updates:

- `obsproject/obs-studio`
- `FFmpeg/nv-codec-headers`
- `Mbed-TLS/mbedtls`
- `uthash.h`
- `nlohmann/json`

The OBS script also applies a few compatibility patches automatically during the build flow so this older OBS line can still build cleanly on the validated Arch environment.

## Default Build Layout

By default, sources, temporary build trees, and installed outputs are separated:

- source cache: `.cache/kepler-build/.../src`
- temporary build directories: `.cache/kepler-build/.../build`
- final local FFmpeg bundle: `.local/ffmpeg-nvenc470`
- final local OBS bundle: `.local/obs-kepler`

Typical source locations after the first build:

- `.cache/kepler-build/ffmpeg/src/FFmpeg`
- `.cache/kepler-build/ffmpeg/src/nv-codec-headers`
- `.cache/kepler-build/obs/src/obs-studio`
- `.cache/kepler-build/obs/src/nv-codec-headers`
- `.cache/kepler-build/obs/src/mbedtls`

## Recommended Build Order

Build in this order:

1. `FFmpeg`
2. `OBS Studio`

That keeps the local bundle consistent with the validated runtime layout used by the launchers.

## Standard Rebuild

From the project root:

```bash
./scripts/build_ffmpeg_nvenc470.sh
./scripts/build_obs_kepler.sh
```

After the build completes, test with:

```bash
./bin/ffmpeg-kepler-legacy -hide_banner -encoders | rg nvenc
./bin/obs-studio-kepler-legacy --version
./scripts/validate_runtime.sh
```

## Clean Rebuild From Scratch

If you want to rebuild everything from a clean state, remove the previous cache and bundle directories first:

```bash
rm -rf \
  .cache/kepler-build/ffmpeg \
  .cache/kepler-build/obs \
  .local/ffmpeg-nvenc470 \
  .local/obs-kepler
```

Then run:

```bash
./scripts/build_ffmpeg_nvenc470.sh
./scripts/build_obs_kepler.sh
```

## Minimum Command Requirements

The scripts check for these tools explicitly.

### FFmpeg Script

Required commands:

- `git`
- `make`
- `gcc`
- `pkg-config`

Optional but helpful:

- `nasm` or `yasm`

If neither `nasm` nor `yasm` is installed, the FFmpeg script automatically falls back to `--disable-x86asm`.

### OBS Script

Required commands:

- `git`
- `cmake`
- `make`
- `gcc`
- `pkg-config`
- `curl`

Note:

The scripts fetch upstream source code automatically, but they do not install missing Arch packages for you.

## Where the Final Files Go

After a successful build:

- FFmpeg is installed to `.local/ffmpeg-nvenc470`
- OBS is installed to `.local/obs-kepler`

The recommended way to run them is through the wrappers:

- `./bin/ffmpeg-kepler-legacy`
- `./bin/obs-studio-kepler-legacy`

Do not use the raw OBS binary directly unless you also provide the required local library paths yourself.

## Reusing the Cache

The scripts are designed to reuse the local source cache.

That means:

- the first build downloads the required repositories and helper files
- later builds fetch updates for the configured tag or ref
- temporary build directories are recreated as needed

This is why rebuilds are usually faster after the first run.

## Version Overrides

You can override the default build versions through environment variables.

Examples:

```bash
FFMPEG_TAG=n8.1 ./scripts/build_ffmpeg_nvenc470.sh
OBS_TAG=30.2.3 ./scripts/build_obs_kepler.sh
JOBS=4 ./scripts/build_obs_kepler.sh
```

Useful variables for the FFmpeg script:

- `WORK_DIR`
- `PREFIX`
- `NV_CODEC_TAG`
- `FFMPEG_TAG`
- `JOBS`

Useful variables for the OBS script:

- `WORK_DIR`
- `PREFIX`
- `OBS_TAG`
- `NV_CODEC_TAG`
- `MBEDTLS_TAG`
- `UTHASH_TAG`
- `NLOHMANN_JSON_TAG`
- `JOBS`

## Example: Build Into a Custom Prefix

FFmpeg:

```bash
PREFIX="$PWD/out/ffmpeg" ./scripts/build_ffmpeg_nvenc470.sh
```

OBS:

```bash
PREFIX="$PWD/out/obs" ./scripts/build_obs_kepler.sh
```

## Example: Use a Different Work Cache

FFmpeg:

```bash
WORK_DIR="$PWD/work/ffmpeg" ./scripts/build_ffmpeg_nvenc470.sh
```

OBS:

```bash
WORK_DIR="$PWD/work/obs" ./scripts/build_obs_kepler.sh
```

## Manual Source Inspection

If you want to inspect or patch the downloaded upstream sources before rebuilding, look under:

- `.cache/kepler-build/ffmpeg/src`
- `.cache/kepler-build/obs/src`

This is useful for technicians who want to audit the exact sources that were used for a local build.

## Troubleshooting Build Failures

If a build fails:

1. confirm the required commands exist
2. rerun the failing script from a terminal so you can read the error output
3. try a clean rebuild
4. verify the machine still has the runtime and development libraries that were present in the validated environment

Also see:

- [`INSTALLATION.md`](./INSTALLATION.md)
- [`TROUBLESHOOTING.md`](./TROUBLESHOOTING.md)
- [`obs-nvenc-kepler-arch.md`](./obs-nvenc-kepler-arch.md)
