# Virtual Camera on Arch Linux

Yes: this OBS build already includes Linux virtual camera support.

The relevant plugin is `linux-v4l2.so`, and it contains the `virtualcam_output` implementation used by OBS on Linux.

## Why It May Not Appear

On Linux, OBS only registers the virtual camera output when the `v4l2loopback` kernel module is available.

If that module is not installed, OBS logs this warning:

```text
v4l2loopback not installed, virtual camera not registered
```

That means the OBS build is fine, but the system-side virtual camera backend is missing.

## Arch Linux Requirements

Install:

- `v4l2loopback-dkms`
- `v4l2loopback-utils`
- the matching kernel headers for your installed kernel

Examples:

- `linux` requires `linux-headers`
- `linux-lts` requires `linux-lts-headers`
- `linux-zen` requires `linux-zen-headers`

## Quick Check

From the project root:

```bash
./scripts/setup_virtual_camera_arch.sh --check
```

This reports:

- your running kernel
- the expected Arch packages
- whether the packages are installed
- whether `v4l2loopback` metadata is available
- whether the module is currently loaded
- visible Video4Linux devices, when `v4l2-ctl` is available

## Install the Required Packages

If you want the helper to install them:

```bash
sudo ./scripts/setup_virtual_camera_arch.sh --install-packages
```

If you prefer to do it yourself, the typical Arch command is:

```bash
sudo pacman -S --needed linux-headers v4l2loopback-dkms v4l2loopback-utils
```

Replace `linux-headers` with the matching headers package if you use another kernel.

## Load the Module Now

```bash
sudo ./scripts/setup_virtual_camera_arch.sh --load-module
```

This loads:

```text
v4l2loopback exclusive_caps=1 card_label='OBS Virtual Camera'
```

The `exclusive_caps=1` option is the common Linux OBS virtual camera setup that works better with browser and conferencing applications.

## Enable It on Boot

If you want the module available automatically after every reboot:

```bash
sudo ./scripts/setup_virtual_camera_arch.sh --enable-on-boot
```

This creates:

- `/etc/modules-load.d/obs-studio-kepler-legacy-v4l2loopback.conf`
- `/etc/modprobe.d/obs-studio-kepler-legacy-v4l2loopback.conf`

## After Setup

Start OBS:

```bash
obs-studio-kepler-legacy
```

Then use the OBS virtual camera button:

- `Start Virtual Camera`

Applications such as browsers, video-call tools, or chat clients should then see:

- `OBS Virtual Camera`

## Validate on This Project

The main runtime validation script now reports the Linux virtual camera status as an informational section:

```bash
./scripts/validate_runtime.sh
```

It does not fail the full runtime validation if virtual camera is not configured, because NVENC recording and virtual camera are independent features.

## Common Problems

### Virtual Camera Button Is Missing

Cause:

- `v4l2loopback` is not installed, so OBS does not register the output

Fix:

```bash
./scripts/setup_virtual_camera_arch.sh --check
sudo ./scripts/setup_virtual_camera_arch.sh --install-packages
```

### Virtual Camera Is Registered But Fails to Start

Cause:

- the module is installed but not loaded

Fix:

```bash
sudo ./scripts/setup_virtual_camera_arch.sh --load-module
```

### Apps Do Not See `OBS Virtual Camera`

Try:

- restarting the target application after starting the virtual camera
- confirming the module is loaded with `lsmod | rg '^v4l2loopback\\b'`
- checking available devices with `v4l2-ctl --list-devices`
- enabling the module on boot if you want it consistently available
