#!/usr/bin/env bash
# Export workflows edited in the n8n UI back into ./workflows so they can be committed.
# Exported files are named by workflow id; rename them if you like.
set -euo pipefail

CONTAINER="${CONTAINER:-auto-crm-n8n}"

docker exec "$CONTAINER" sh -c 'rm -rf /tmp/export && n8n export:workflow --all --separate --pretty --output=/tmp/export'
docker cp "$CONTAINER:/tmp/export/." ./workflows/exported/
echo "Exported to ./workflows/exported/"
