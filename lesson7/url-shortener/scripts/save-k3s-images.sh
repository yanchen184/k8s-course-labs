#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
TAR_PATH="$DIST_DIR/url-shortener-k3s-images.tar"
IMAGES=(
  "url-shortener-api:lab"
  "url-shortener-frontend:lab"
  "postgres:15"
  "busybox:1.36"
)

missing=()
for image in "${IMAGES[@]}"; do
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    missing+=("$image")
  fi
done

if ((${#missing[@]} > 0)); then
  printf 'Missing images. Ask the instructor for a preloaded image tar, or pull/build these before saving:\n' >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 1
fi

mkdir -p "$DIST_DIR"
printf 'Saving images to %s\n' "$TAR_PATH"
docker save -o "$TAR_PATH" "${IMAGES[@]}"
printf 'Saved %s\n' "$TAR_PATH"
