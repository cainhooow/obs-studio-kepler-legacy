# Troubleshooting

## OBS Does Not Start

### Symptom

- launcher exits immediately
- desktop entry opens nothing
- shell reports a shared library error

### Fix

Always launch this build through:

```bash
obs-studio-kepler-legacy
```

or, before installation:

```bash
./bin/obs-studio-kepler-legacy
```

Do not launch the raw binary directly from `.local/obs-kepler/bin/obs` unless you also know how to provide the local library paths.

## FFmpeg Starts But NVENC Fails

### Symptom

- `h264_nvenc` appears in the encoder list
- encoding fails with an API version error
- FFmpeg asks for a much newer driver

### Cause

You are probably using the system FFmpeg instead of the bundled one.

### Fix

Use:

```bash
ffmpeg-kepler-legacy
```

or:

```bash
./bin/ffmpeg-kepler-legacy
```

## Recording Fails With `obs-ffmpeg-mux` Shared Library Errors

### Symptom

- recording fails to start
- OBS shows an error mentioning `obs-ffmpeg-mux`
- the message includes `error while loading shared libraries`
- `libobs.so.0` or another local library cannot be opened

### Cause

The installed bundle may still contain helper binaries that were built with an absolute runpath from the original build machine.

### Fix

Apply the relocatable wrapper fix to the current bundle:

```bash
./scripts/make_bundle_relocatable.sh
```

If you already installed the bundle for your user, reinstall it so the fixed runtime is copied into the installed location:

```bash
./install.sh --user
```

If you installed it system-wide:

```bash
sudo ./install.sh --system
```

## The Launcher Name Is Not Found

### Symptom

- `command not found: obs-studio-kepler-legacy`

### Fix

Your shell probably does not include `~/.local/bin` in `PATH`.

Either:

- run the launcher with the full path, or
- add `~/.local/bin` to your shell configuration

Example:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## OBS Legacy and Normal OBS Share Nothing

This is intentional.

The legacy build uses a separate configuration root so it can coexist with a normal OBS install safely.

By default it uses:

```text
~/.config/obs-studio-kepler-legacy/obs-studio
```

## Wayland Capture Flickers In Preview Or Output

### Symptom

- GNOME top bar or KDE panel appears to flicker only inside OBS preview, recording, or stream output
- the desktop itself does not visibly flicker outside OBS

### Cause

Older bundle revisions can receive incomplete PipeWire frames on Wayland, especially on NVIDIA systems, if explicit synchronization is not negotiated correctly with the compositor.

### Fix

Use release `30.2.3-kepler.3` or newer, which backports the upstream PipeWire explicit-sync and render-path fixes used for this issue.

If you rebuild from source, rebuild the OBS bundle with:

```bash
./scripts/build_obs_kepler.sh
```

## HEVC NVENC Is Missing

### Symptom

- only H.264 NVENC is shown
- HEVC does not appear in OBS

### Cause

For the validated `GTX 660` target, that is the correct behavior.

This project intentionally hides unsupported HEVC NVENC exposure in OBS so users do not pick a codec that the hardware cannot actually encode.

## Virtual Camera Button Is Missing

### Symptom

- the OBS interface does not show virtual camera controls
- `Start Virtual Camera` is unavailable

### Cause

On Linux, OBS only registers the virtual camera output when the `v4l2loopback` kernel module is available.

If it is missing, OBS logs:

```text
v4l2loopback not installed, virtual camera not registered
```

### Fix

Run:

```bash
./scripts/setup_virtual_camera_arch.sh --check
```

Then install the required host packages and module support:

```bash
sudo ./scripts/setup_virtual_camera_arch.sh --install-packages
sudo ./scripts/setup_virtual_camera_arch.sh --load-module
```

For the full procedure, see:

- [`VIRTUAL_CAMERA.md`](./VIRTUAL_CAMERA.md)

## Virtual Camera Fails To Start

### Symptom

- the button exists, but OBS reports `Failed to start virtual camera`

### Cause

- the plugin is present, but `v4l2loopback` is not loaded correctly
- another V4L2 loopback setup may already be holding the expected device

### Fix

Try:

```bash
sudo ./scripts/setup_virtual_camera_arch.sh --load-module
./scripts/setup_virtual_camera_arch.sh --check
```

## OBS Opens in Safe Mode After a Forced Termination

### Symptom

- OBS reports an unclean shutdown
- OBS offers Safe Mode

### Fix

Delete the sentinel file:

```bash
rm -f ~/.config/obs-studio-kepler-legacy/obs-studio/safe_mode
```

## OBS Starts But Recording Quality or Performance Is Poor

Try:

- lowering output resolution
- using `720p60` or `1080p30`
- reducing filters and source complexity
- using a fast local recording disk
- lowering bitrate until stability improves

Older Kepler hardware can work well, but it is not as forgiving as newer NVENC generations.

## Desktop Shortcut Does Not Appear

### Fix

After user install, confirm the desktop entry exists:

```bash
ls ~/.local/share/applications/obs-studio-kepler-legacy.desktop
```

If your desktop environment caches launchers, log out and back in or refresh the application menu.

## Validation Checklist

Run:

```bash
./scripts/validate_runtime.sh
```

If it succeeds, the core runtime path is working.
