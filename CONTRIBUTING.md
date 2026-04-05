# Contributing

Contributions are welcome, but this project intentionally favors compatibility and maintainability over feature growth.

## Before You Change Anything

- keep the target in mind: Arch Linux plus NVIDIA Kepler plus the legacy `470.xx` driver branch
- prefer small, auditable changes over large refactors
- avoid changes that risk breaking the validated `H.264 NVENC` workflow

## Development Workflow

1. Make the smallest change that solves the problem.
2. Run the local checks:

```bash
./scripts/check_project.sh
```

3. If you changed runtime behavior, also run:

```bash
./scripts/validate_runtime.sh
```

4. Update `README.md`, `CHANGELOG.md`, or the relevant guide when behavior changes.

## Patch Workflow

Source backports live under:

- `patches/obs`
- `patches/ffmpeg`

Patch files must:

- use the `0001-description.patch` naming format
- carry the required metadata header documented in `patches/README.md`
- stay focused on one logical change when possible
- apply cleanly to the configured upstream tag

After editing a patch series, run:

```bash
./scripts/check_patch_series.sh
```

## Release Workflow

When preparing a new project release:

1. update `VERSION`
2. update `CHANGELOG.md`
3. run `./scripts/check_project.sh`
4. run `./release.sh`

## Scope Boundaries

Please avoid:

- enabling `obs-browser`, `obs-websocket`, or other components intentionally disabled in this bundle
- replacing the isolated launcher/config model with the default upstream names
- adding backports that are large, invasive, or difficult to audit in a legacy branch
