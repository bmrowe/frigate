#!/usr/bin/env bash
# Stage the files that changed since the base release into local/overlay/,
# mapped to where they live in the official image, after checking that the
# base image still holds the base release's version of every file we replace.
#
# Usage: local/build-overlay.sh <base-git-tag> <base-image-ref>
set -euo pipefail

BASE_TAG="$1"
BASE_IMAGE="$2"
OUT="local/overlay"

rm -rf "$OUT"
mkdir -p "$OUT"

map_path() {
  case "$1" in
    docker/main/rootfs/*) echo "/${1#docker/main/rootfs/}" ;;
    frigate/*) echo "/opt/frigate/$1" ;;
    *) return 1 ;;
  esac
}

fail=0
checks=()
while IFS=$'\t' read -r status path; do
  case "$path" in
    docs/* | frigate/test/* | local/* | .github/*) continue ;;
  esac
  if [ "$status" != "M" ] && [ "$status" != "A" ]; then
    echo "::error::$path is '$status' since $BASE_TAG; only added or modified files are supported"
    fail=1
    continue
  fi
  if ! target=$(map_path "$path"); then
    echo "::error::$path is not under frigate/ or docker/main/rootfs/; an overlay can't carry it"
    fail=1
    continue
  fi
  if [ "$status" = "M" ]; then
    checks+=("$(git show "$BASE_TAG:$path" | sha256sum | cut -d' ' -f1)  $target")
  else
    checks+=("absent  $target")
  fi
  mkdir -p "$OUT$(dirname "$target")"
  cp "$path" "$OUT$target"
  echo "overlay: $path -> $target"
done < <(git diff --name-status "$BASE_TAG" HEAD)

[ "$fail" = 0 ] || exit 1
[ "${#checks[@]}" -gt 0 ] || { echo "::error::nothing changed since $BASE_TAG"; exit 1; }

# Every replaced file must match the base release byte for byte, and every
# added file must not already exist, or we'd be patching the wrong release.
printf '%s\n' "${checks[@]}" | docker run --rm -i --entrypoint sh "$BASE_IMAGE" -c '
  rc=0
  while read -r want target; do
    if [ "$want" = absent ]; then
      [ ! -e "$target" ] || { echo "base image already has $target"; rc=1; }
    else
      have=$(sha256sum "$target" 2>/dev/null | cut -d" " -f1)
      [ "$have" = "$want" ] || { echo "base image $target does not match the base release"; rc=1; }
    fi
  done
  exit $rc'

short=$(git rev-parse --short=7 HEAD)
mkdir -p "$OUT/opt/frigate/frigate"
echo "VERSION = \"${BASE_TAG#v}-local.$short\"" > "$OUT/opt/frigate/frigate/version.py"
echo "version: ${BASE_TAG#v}-local.$short"
