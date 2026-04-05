# Security Policy

## Supported Versions

| Version | Supported |
| --- | --- |
| `30.2.3-kepler.1` | Yes |

## Security Posture

This project is a compatibility-focused legacy bundle, not a security-equivalent replacement for current upstream OBS releases.

It reduces some attack surface by shipping with several optional components disabled:

- `obs-browser`
- `obs-websocket`
- `webrtc`
- `rtmps`
- the native `mpegts` SRT and RIST output path

It also carries a small set of targeted hardening backports documented in `docs/HARDENING.md`.

## What to Report

Please report:

- crashes triggered by malformed input, config, or scene collection data
- virtual camera issues that look like invalid resource handling
- packaging mistakes that expose the wrong launcher, paths, or libraries
- security-sensitive behavior that differs from what the documentation claims

## What to Expect

- fixes will be evaluated with Kepler compatibility as the first constraint
- not every upstream OBS fix can be backported safely to this legacy branch
- some classes of issues may be mitigated by keeping optional components disabled rather than backporting large feature changes
