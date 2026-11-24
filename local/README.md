# Local 0.18.3+

Upstream's `v0.18.3` does not carry blakeblackshear/frigate#24663, which stops
the camera watchdog from buffering raw frames while it resets ffmpeg. That fix
is on `master`, headed for 0.19. This branch is the official `0.18.3` image
with that one backport copied over the top.

Earlier this branch also carried every `master` change since `v0.18.2`, because
upstream had said there would be no further 0.18 release. `v0.18.3` shipped
most of those anyway, so the overlay is now a single file.

- `local/build-overlay.sh` stages the changed files and checks that the base
  image still holds the `v0.18.3` version of every file it replaces.
- `.github/workflows/local-build.yml` pushes `ghcr.io/bmrowe/frigate-unraid`.
- `.github/workflows/local-upstream-check.yml` runs weekly and fails either
  when upstream ships a release carrying #24663 (retire this branch and point
  the Unraid template back at `ghcr.io/blakeblackshear/frigate:stable`) or when
  a newer release appears without it (rebase the overlay onto that tag).

Only Python, config and rootfs script changes can ride in the overlay. The
build fails on anything else, such as web UI or Dockerfile changes.

## Rebasing onto a new upstream tag

    git checkout -B local-<tag> <tag>
    git cherry-pick -x <the #24663 commit> <the local tooling commits>
    # update BASE_TAG and BASE_IMAGE in local-build.yml and
    # local-upstream-check.yml; get the digest with:
    #   docker manifest inspect ghcr.io/blakeblackshear/frigate:<version>
