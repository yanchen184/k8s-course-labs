#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAR_PATH="${IMAGE_TAR:-$ROOT_DIR/dist/url-shortener-k3s-images.tar}"
REMOTE_TAR="${REMOTE_IMAGE_TAR:-/tmp/url-shortener-k3s-images.tar}"

if [[ ! -f "$TAR_PATH" ]]; then
  printf 'Image tar not found: %s\n' "$TAR_PATH" >&2
  printf 'Run ./scripts/save-k3s-images.sh first, or set IMAGE_TAR=/path/to/url-shortener-k3s-images.tar\n' >&2
  exit 1
fi

if [[ -z "${K3S_NODES:-}" ]]; then
  printf 'K3S_NODES is required. Example:\n' >&2
  printf '  K3S_NODES="student@192.168.56.10 student@192.168.56.11" %s\n' "$0" >&2
  exit 1
fi

# shellcheck disable=SC2206
nodes=(${K3S_NODES})
if [[ -n "${SSH_OPTS:-}" ]]; then
  # shellcheck disable=SC2206
  ssh_opts=(${SSH_OPTS})
else
  ssh_opts=()
fi

for node in "${nodes[@]}"; do
  printf '\nLoading images into %s\n' "$node"
  if ((${#ssh_opts[@]} > 0)); then
    scp "${ssh_opts[@]}" "$TAR_PATH" "$node:$REMOTE_TAR"
    ssh "${ssh_opts[@]}" "$node" "sudo -n k3s ctr images import $REMOTE_TAR"
  else
    scp "$TAR_PATH" "$node:$REMOTE_TAR"
    ssh "$node" "sudo -n k3s ctr images import $REMOTE_TAR"
  fi
done

printf '\nImages imported into %s\n' "${nodes[*]}"
