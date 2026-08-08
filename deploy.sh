#!/bin/sh
#
# Deploy the Sapio server to any host over SSH.
#
#   ./deploy.sh user@host                 redeploy code, keep remote data
#   ./deploy.sh user@host --with-data     also push local ./data (first install only)
#
# Requires on the target: docker, the compose plugin, and your SSH key.

set -eu

TARGET="${1:-}"
WITH_DATA="${2:-}"
REMOTE_DIR="sapio-server"
HERE="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$TARGET" ]; then
    echo "usage: ./deploy.sh user@host [--with-data]" >&2
    exit 1
fi

if [ ! -f "$HERE/.env" ]; then
    echo "missing .env - copy .env.example and fill in the secrets" >&2
    exit 1
fi

echo "==> checking $TARGET"
ssh "$TARGET" 'docker compose version >/dev/null 2>&1' || {
    echo "docker compose plugin is missing on $TARGET" >&2
    exit 1
}

echo "==> syncing source"
ssh "$TARGET" "mkdir -p $REMOTE_DIR/data/db $REMOTE_DIR/data/uploads"
rsync -az --delete \
    --exclude .git \
    --exclude node_modules \
    --exclude build \
    --exclude .cache \
    --exclude .tmp \
    --exclude data \
    --exclude .env \
    "$HERE/" "$TARGET:$REMOTE_DIR/"

echo "==> syncing secrets"
rsync -az "$HERE/.env" "$TARGET:$REMOTE_DIR/.env"

# Data is never deleted remotely - only ever added to, and only when asked.
if [ "$WITH_DATA" = "--with-data" ]; then
    echo "==> pushing local data (this can take a while)"
    rsync -az --info=progress2 "$HERE/data/" "$TARGET:$REMOTE_DIR/data/"
fi

echo "==> building and starting"
ssh "$TARGET" "cd $REMOTE_DIR && docker compose up -d --build"

echo "==> status"
ssh "$TARGET" "cd $REMOTE_DIR && docker compose ps"
