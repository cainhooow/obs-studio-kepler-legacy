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

## HEVC NVENC Is Missing

### Symptom

- only H.264 NVENC is shown
- HEVC does not appear in OBS

### Cause

For the validated `GTX 660` target, that is the correct behavior.

This project intentionally hides unsupported HEVC NVENC exposure in OBS so users do not pick a codec that the hardware cannot actually encode.

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
