#!/usr/bin/env bash
# Subscribe the n8n webhook workflows to Auto CRM events.
# Managing webhooks is super admin only, so this logs in with the super admin account (not the n8n API key).
# The CRM API runs on your machine, so it reaches n8n at localhost:5678.
#
# Usage: ./scripts/register-webhooks.sh            (production webhook URLs, workflow must be Active)
#        WEBHOOK_PREFIX=webhook-test ./scripts/register-webhooks.sh   (n8n "test" URLs while editing)
set -euo pipefail

API_URL="${CRM_API_URL:-http://localhost:8000/api/v1}"
N8N_URL="${N8N_URL:-http://localhost:5678}"
PREFIX="${WEBHOOK_PREFIX:-webhook}"

read -rp "CRM super admin email: " ADMIN_EMAIL
read -rsp "CRM super admin password: " ADMIN_PASSWORD
echo

TOKEN=$(curl -sSf -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\": \"$ADMIN_EMAIL\", \"password\": \"$ADMIN_PASSWORD\"}" |
  python3 -c 'import json, sys; print(json.load(sys.stdin)["access_token"])')

subscribe() {
  local event="$1" path="$2"
  echo "→ $event  ⇒  $N8N_URL/$PREFIX/$path"
  curl -sS -X POST "$API_URL/webhooks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"event\": \"$event\", \"target_url\": \"$N8N_URL/$PREFIX/$path\", \"is_active\": true}"
  echo
}

subscribe "contact.created" "auto-crm/contact-created"
subscribe "deal.won" "auto-crm/deal-won"
