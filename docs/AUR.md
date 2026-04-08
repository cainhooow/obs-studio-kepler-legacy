# Publishing To AUR

This project already has a local Arch package recipe under `packaging/`, but the AUR needs a separate repository layout and metadata.

Use the AUR-specific export under:

- `aur/obs-studio-kepler-legacy-bin`

Generate or refresh it from the current GitHub release with:

```bash
./scripts/sync_aur_package.sh \
  --maintainer-name "Caio Augusto" \
  --maintainer-email "augustocaio663@gmail.com" \
  --verify-source
```

That command:

- creates an AUR-ready `PKGBUILD`
- points `source=()` to the current GitHub release tarball
- injects the current archive SHA256
- copies the `.install` helper
- writes a `0BSD` `LICENSE`
- regenerates `.SRCINFO`
- optionally runs `makepkg --verifysource`

## AUR Submission Checklist

Before publishing, make sure the package follows the current AUR submission rules:

- the package is not already in the official Arch repositories
- the package name is not already taken in the AUR
- the package uses the `-bin` suffix for prebuilt deliverables
- `replaces` is not used unless this is a real rename
- `.SRCINFO` is regenerated whenever `PKGBUILD` metadata changes
- the repository contains a package source license such as `LICENSE`
- the pushed branch is `master`

## SSH Configuration

Your AUR SSH key can be isolated from your normal GitHub key. The ArchWiki example is:

```sshconfig
Host aur.archlinux.org
  IdentityFile ~/.ssh/aur
  User aur
```

On this machine, the dedicated AUR key is already located at:

```text
~/.ssh/aur
```

## Initial Publish

1. Generate the AUR package files:

```bash
cd ~/Documentos/obs-studio-legacy
./scripts/sync_aur_package.sh \
  --maintainer-name "Caio Augusto" \
  --maintainer-email "augustocaio663@gmail.com" \
  --verify-source
```

2. Clone the empty AUR repository using the package base as repository name:

```bash
GIT_SSH_COMMAND='ssh -i ~/.ssh/aur' \
git -c init.defaultBranch=master clone \
  ssh://aur@aur.archlinux.org/obs-studio-kepler-legacy-bin.git
```

If the package does not yet exist, cloning an empty repository is expected.

3. Copy the generated AUR files into the cloned repository:

```bash
rsync -av --delete \
  ~/Documentos/obs-studio-legacy/aur/obs-studio-kepler-legacy-bin/ \
  ./obs-studio-kepler-legacy-bin/
```

4. Set the Git identity you want the AUR commit to use:

```bash
cd obs-studio-kepler-legacy-bin
git config user.name "Caio Augusto"
git config user.email "augustocaio663@gmail.com"
```

5. Commit and push:

```bash
git add PKGBUILD .SRCINFO LICENSE obs-studio-kepler-legacy.install .gitignore
git commit -m "Initial import"
GIT_SSH_COMMAND='ssh -i ~/.ssh/aur' git push origin master
```

## Updating The AUR Package

For new project releases:

1. publish the GitHub release first
2. rerun `./scripts/sync_aur_package.sh`
3. copy the refreshed files into the AUR clone
4. commit with a message such as `Update to <pkgver>-1`
5. push to `master`

## Notes Specific To This Project

- `obs-studio-kepler-legacy-bin` is a valid AUR-style name because it distributes prebuilt release artifacts
- the package intentionally does not conflict with the official `obs-studio` package
- the package depends on `libjack.so=0-64`, `libpipewire-0.3.so=0-64`, and `libpulse.so=0-64` so it does not force a specific JACK or PulseAudio server implementation
- keep the host `pipewire` package installed if you rely on PipeWire-backed features such as Wayland screen capture
- note that this project intentionally hides PipeWire screen capture sources on X11 sessions
