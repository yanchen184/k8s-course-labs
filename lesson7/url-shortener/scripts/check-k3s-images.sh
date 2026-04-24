#!/usr/bin/env bash
set -euo pipefail

IMAGES=(
  "url-shortener-api:lab"
  "url-shortener-frontend:lab"
  "postgres:15"
  "busybox:1.36"
)

if [[ -n "${K3S_NODES:-}" ]]; then
  # shellcheck disable=SC2206
  nodes=(${K3S_NODES})
else
  if ! command -v multipass >/dev/null 2>&1; then
    printf 'multipass command not found. Set K3S_NODES="k3s-master k3s-worker1" if needed.\n' >&2
    exit 1
  fi
  nodes=()
  while IFS= read -r node; do
    [[ -n "$node" ]] && nodes+=("$node")
  done < <(multipass list --format csv | awk -F, 'NR > 1 && $1 ~ /k3s/ && $2 == "Running" { print $1 }')
fi

if ((${#nodes[@]} == 0)); then
  printf 'No running k3s Multipass nodes found.\n' >&2
  exit 1
fi

for node in "${nodes[@]}"; do
  printf '\nChecking %s\n' "$node"
  image_list="$(multipass exec "$node" -- sudo k3s ctr images list -q)"
  for image in "${IMAGES[@]}"; do
    name="${image%%:*}"
    tag="${image##*:}"
    if grep -Eq "(^|/)$name:$tag$" <<<"$image_list"; then
      printf '  OK      %s\n' "$image"
    else
      printf '  MISSING %s\n' "$image" >&2
      exit 1
    fi
  done
done
