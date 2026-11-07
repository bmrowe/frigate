# Local 0.18.3

Upstream has no plans for another 0.18 release, so this branch builds one. It
is the official `0.18.2` image with every file that changed on `master` since
`v0.18.2` copied over the top, plus the backport of #24663, which stops the
camera watchdog from buffering raw frames while it resets ffmpeg.

- `local/build-overlay.sh` stages the changed files and checks that the base
  image still holds the `v0.18.2` version of each file it replaces.
- `.github/workflows/local-build.yml` pushes `ghcr.io/bmrowe/frigate-unraid`.
- `.github/workflows/local-upstream-check.yml` fails every week once upstream
  publishes a release newer than `v0.18.2`. When it fails, point the Unraid
  template back at `ghcr.io/blakeblackshear/frigate:stable` and retire this
  branch.

Only Python, config and rootfs script changes can ride in the overlay. The
build fails on anything else, such as web UI or Dockerfile changes.
