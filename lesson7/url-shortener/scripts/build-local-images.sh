#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf 'Building url-shortener-api:lab from %s\n' "$ROOT_DIR/api"
docker build -t url-shortener-api:lab "$ROOT_DIR/api"

printf 'Building url-shortener-frontend:lab from %s\n' "$ROOT_DIR/frontend"
docker build -t url-shortener-frontend:lab "$ROOT_DIR/frontend"

printf '\nBuilt local lab images:\n'
docker image ls --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' \
  | grep -E '^(url-shortener-api|url-shortener-frontend)[[:space:]]+lab[[:space:]]' || true
