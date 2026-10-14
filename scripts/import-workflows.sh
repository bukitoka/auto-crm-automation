#!/usr/bin/env bash
# Import every workflow in ./workflows into the running n8n container.
# Re-running updates workflows with the same id instead of duplicating them.
set -euo pipefail

CONTAINER="${CONTAINER:-auto-crm-n8n}"

# SMTP credential pointing at Mailpit (the API's docker compose), used by the email nodes.
docker exec "$CONTAINER" n8n import:credentials --separate --input=/home/node/credentials
docker exec "$CONTAINER" n8n import:workflow --separate --input=/home/node/workflows
echo "Imported. Open http://localhost:5678, review each workflow and toggle it Active."
