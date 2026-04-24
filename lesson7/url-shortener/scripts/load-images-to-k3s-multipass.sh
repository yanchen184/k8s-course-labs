#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAR_PATH="${IMAGE_TAR:-$ROOT_DIR/dist/url-shortener-k3s-images.tar}"
REMOTE_TAR="/tmp/url-shortener-k3s-images.tar"

if [[ ! -f "$TAR_PATH" ]]; then
  printf 'Image tar not found: %s\n' "$TAR_PATH" >&2
  printf 'Run ./scripts/save-k3s-images.sh first, or set IMAGE_TAR=/path/to/url-shortener-k3s-images.tar\n' >&2
  exit 1
fi

if [[ -n "${K3S_NODES:-}" ]]; then
  # shellcheck disable=SC2206
  nodes=(${K3S_NODES})
else
  if ! command -v multipass >/dev/null 2>&1; then
    printf 'multipass command not found. Set K3S_NODES and install Multipass, or import images manually on each node.\n' >&2
    exit 1
  fi
  nodes=()
  while IFS= read -r node; do
    [[ -n "$node" ]] && nodes+=("$node")
  done < <(multipass list --format csv | awk -F, 'NR > 1 && $1 ~ /k3s/ && $2 == "Running" { print $1 }')
fi

if ((${#nodes[@]} == 0)); then
  printf 'No running k3s Multipass nodes found. Set K3S_NODES="k3s-master k3s-worker1" if needed.\n' >&2
  exit 1
fi

for node in "${nodes[@]}"; do
  printf '\nLoading images into %s\n' "$node"
  multipass transfer "$TAR_PATH" "$node:$REMOTE_TAR"
  multipass exec "$node" -- sudo k3s ctr images import "$REMOTE_TAR"
done

printf '\nImages imported into %s\n' "${nodes[*]}"
