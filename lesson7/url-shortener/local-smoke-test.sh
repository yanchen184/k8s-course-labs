#!/usr/bin/env bash
set -euo pipefail

NETWORK="k8s-course-urltest-$$"
PG="k8s-course-urltest-postgres-$$"
API="k8s-course-urltest-api-$$"
FE="k8s-course-urltest-frontend-$$"
GW="k8s-course-urltest-gateway-$$"
API_IMAGE="k8s-course-url-shortener-api:localtest"
FE_IMAGE="k8s-course-url-shortener-frontend:localtest"
PASS="localtest-password"
TMPDIR="$(mktemp -d)"

cleanup() {
  docker rm -f "$GW" "$FE" "$API" "$PG" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
  docker image rm "$API_IMAGE" "$FE_IMAGE" >/dev/null 2>&1 || true
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

cd "$(dirname "$0")"

docker build -q -t "$API_IMAGE" api >/dev/null
docker build -q -t "$FE_IMAGE" frontend >/dev/null
docker network create "$NETWORK" >/dev/null

docker run -d --name "$PG" --network "$NETWORK" \
  -e POSTGRES_DB=shortlinks \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD="$PASS" \
  postgres:15 >/dev/null

for i in $(seq 1 45); do
  if docker exec "$PG" pg_isready -U postgres -d shortlinks >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 45 ]; then
    echo "postgres did not become ready" >&2
    exit 1
  fi
  sleep 1
done

docker run --rm --network "$NETWORK" \
  -e POSTGRES_HOST="$PG" \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=shortlinks \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD="$PASS" \
  "$API_IMAGE" node migrate.js >/dev/null

docker run -d --name "$API" --network "$NETWORK" \
  -e POSTGRES_HOST="$PG" \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=shortlinks \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD="$PASS" \
  "$API_IMAGE" >/dev/null

docker run -d --name "$FE" --network "$NETWORK" "$FE_IMAGE" >/dev/null

cat > "$TMPDIR/default.conf" <<EOF
server {
  listen 80;
  server_name _;

  location /api/ { proxy_pass http://$API:3000/api/; }
  location /r/ { proxy_pass http://$API:3000/r/; }
  location = /health { proxy_pass http://$API:3000/health; }
  location = /ready { proxy_pass http://$API:3000/ready; }
  location / { proxy_pass http://$FE:80/; }
}
EOF

docker run -d --name "$GW" --network "$NETWORK" -p 18080:80 \
  -v "$TMPDIR/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:1.27-alpine >/dev/null

for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:18080/health >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "gateway/api did not become healthy" >&2
    docker logs "$API" >&2 || true
    docker logs "$GW" >&2 || true
    exit 1
  fi
  sleep 1
done

curl -fsS http://127.0.0.1:18080/health | grep -q 'ok'
curl -fsS http://127.0.0.1:18080/ready | grep -q 'ready'
curl -fsS http://127.0.0.1:18080/ | grep -q 'Short Link Lab'
curl -fsS -X POST http://127.0.0.1:18080/api/links \
  -H 'Content-Type: application/json' \
  -d '{"url":"https://kubernetes.io/","custom_code":"k8stest"}' | grep -q 'k8stest'
curl -fsS http://127.0.0.1:18080/api/links | grep -q 'k8stest'

redirect_location="$(
  curl -sS -o /dev/null -D - http://127.0.0.1:18080/r/k8stest |
    awk -F': ' 'tolower($1)=="location" {gsub("\r", "", $2); print $2}'
)"

if [ "$redirect_location" != "https://kubernetes.io/" ]; then
  echo "unexpected redirect: $redirect_location" >&2
  exit 1
fi

docker rm -f "$API" >/dev/null
sleep 1
docker run -d --name "$API" --network "$NETWORK" \
  -e POSTGRES_HOST="$PG" \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=shortlinks \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD="$PASS" \
  "$API_IMAGE" >/dev/null

for i in $(seq 1 30); do
  if curl -fsS http://127.0.0.1:18080/ready >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "api did not recover after container replacement" >&2
    exit 1
  fi
  sleep 1
done

curl -fsS http://127.0.0.1:18080/api/links | grep -q 'k8stest'
echo "LOCAL_SMOKE_OK gateway=http://127.0.0.1:18080 code=k8stest redirect=$redirect_location"
