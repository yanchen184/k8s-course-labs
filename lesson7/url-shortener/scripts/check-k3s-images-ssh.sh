#!/usr/bin/env bash
set -euo pipefail

IMAGES=(
  "url-shortener-api:lab"
  "url-shortener-frontend:lab"
  "postgres:15"
  "busybox:1.36"
)

if [[ -z "${K3S_NODES:-}" ]]; then
  printf 'K3S_NODES is required. Example:\n' >&2
  printf '  K3S_NODES="user@192.168.56.10 user@192.168.56.11" %s\n' "$0" >&2
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
  printf '\nChecking %s\n' "$node"
  if ((${#ssh_opts[@]} > 0)); then
    image_list="$(ssh "${ssh_opts[@]}" "$node" "sudo -n k3s ctr images list -q")"
  else
    image_list="$(ssh "$node" "sudo -n k3s ctr images list -q")"
  fi
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
