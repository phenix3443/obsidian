#!/usr/bin/env bash
set -euo pipefail

OLD_IMAGE="zkmelabs/moca-storage-provider:v1.0.0-alpha.1"
NEW_IMAGE="ghcr.io/mocachain/moca-storage-provider:1.2.0-rc5"
COMPOSE="/data/moca/compose-sp.yaml"
SERVICE="sp"

usage() {
  cat <<EOF
Usage: $0 [options]

Upgrade moca-storage-provider image on a testnet SP node.
Run this script directly on the target host (via ssh).

Options:
  -o OLD_IMAGE   Old image to replace (default: $OLD_IMAGE)
  -n NEW_IMAGE   New image to deploy  (default: $NEW_IMAGE)
  -f COMPOSE     Path to compose file (default: $COMPOSE)
  -s SERVICE     Compose service name (default: $SERVICE)
  -c             Clean old log files (moca-sp.log.*) to free disk
  -h             Show this help

Example:
  ssh test-sp0 'bash -s' < $0
  ssh test-sp0 'bash -s -- -c' < $0
EOF
  exit 0
}

CLEAN_LOGS=false

while getopts "o:n:f:s:ch" opt; do
  case $opt in
    o) OLD_IMAGE="$OPTARG" ;;
    n) NEW_IMAGE="$OPTARG" ;;
    f) COMPOSE="$OPTARG" ;;
    s) SERVICE="$OPTARG" ;;
    c) CLEAN_LOGS=true ;;
    h) usage ;;
    *) usage ;;
  esac
done

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

log "=== Upgrade started on $(hostname) ==="
log "Old image: $OLD_IMAGE"
log "New image: $NEW_IMAGE"
log "Compose:   $COMPOSE"
log "Service:   $SERVICE"

if [[ ! -f "$COMPOSE" ]]; then
  log "ERROR: compose file not found: $COMPOSE"
  exit 1
fi

CONTAINER_NAME=$(docker ps --filter "ancestor=$OLD_IMAGE" --format "{{.Names}}" | head -1)
if [[ -z "$CONTAINER_NAME" ]]; then
  CONTAINER_NAME=$(docker ps --filter "label=com.docker.compose.service=$SERVICE" --format "{{.Names}}" | head -1)
fi

if [[ -z "$CONTAINER_NAME" ]]; then
  log "WARNING: no running container found for old image or service=$SERVICE, proceeding anyway"
  VOLUME_PATH=""
else
  log "Container: $CONTAINER_NAME"
  VOLUME_PATH=$(docker inspect "$CONTAINER_NAME" --format '{{range .Mounts}}{{if eq .Destination "/app"}}{{.Source}}{{end}}{{end}}')
  log "Volume:    $VOLUME_PATH"
fi

log "--- Step 1: Backup compose file ---"
cp -a "$COMPOSE" "$COMPOSE.bak.$(date +%Y%m%d%H%M%S)"

if [[ -n "$VOLUME_PATH" ]]; then
  log "--- Step 2: chown data volume to uid 1000 ---"
  chown -R 1000:1000 "$VOLUME_PATH"
  rm -f "$VOLUME_PATH/moca-sp.log"

  if [[ "$CLEAN_LOGS" == true ]]; then
    log "--- Step 2a: Clean old log files ---"
    rm -f "$VOLUME_PATH"/moca-sp.log.*
  fi
fi

log "--- Step 3: Update image ---"
sed -i "s|$OLD_IMAGE|$NEW_IMAGE|g" "$COMPOSE"

log "--- Step 4: Fix command (remove moca-sp prefix, add --log.std) ---"
sed -i 's|command: moca-sp --config config.toml|command: --config config.toml --log.std|' "$COMPOSE"

log "--- Step 5: Fix healthcheck (new image has no curl) ---"
sed -i 's|test: \["CMD", "curl", "-f", "http://localhost:9033/health"\]|test: ["CMD-SHELL", "bash -c '"'"'echo > /dev/tcp/127.0.0.1/9033'"'"'"]|' "$COMPOSE"

log "--- Step 6: Verify compose changes ---"
grep -n 'image:\|command:\|test:' "$COMPOSE" | head -5

log "--- Step 7: Pull and restart ---"
cd "$(dirname "$COMPOSE")"
docker compose -f "$COMPOSE" pull "$SERVICE"
docker compose -f "$COMPOSE" up -d "$SERVICE"

log "--- Step 8: Wait for healthcheck (60s) ---"
sleep 60
docker ps --filter "name=moca-sp" --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"

STATUS=$(docker inspect --format='{{.State.Health.Status}}' "$(docker ps --filter "label=com.docker.compose.service=$SERVICE" --format "{{.Names}}" | head -1)" 2>/dev/null || echo "unknown")
log "Health status: $STATUS"

if [[ "$STATUS" == "healthy" ]]; then
  log "=== Upgrade succeeded ==="
else
  log "WARNING: container is not healthy yet (status=$STATUS), check logs:"
  log "  docker compose -f $COMPOSE logs --tail=50 $SERVICE"
fi
