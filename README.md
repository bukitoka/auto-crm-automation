# auto-crm-automation

n8n workflows for **Auto CRM**. n8n runs in Docker and talks to the CRM API over HTTP:

```
Auto CRM API ──(signed webhook: contact.created, deal.won, …)──► n8n workflow
n8n workflow ──(X-API-Key)──► Auto CRM API  (score lead, create task, list tasks, create lead)
```

## Setup

```bash
cp .env.example .env
# set N8N_ENCRYPTION_KEY (openssl rand -hex 32)
# set AUTO_CRM_API_KEY = AUTOMATION_API_KEY from auto-crm-api/.env

docker compose up -d                 # n8n → http://localhost:5678 (create the owner account)
./scripts/import-workflows.sh        # load the Mailpit SMTP credential + ./workflows into n8n
```

Then in the n8n UI: open each workflow and toggle it **Active**. The email nodes already use the
**Mailpit SMTP** credential (`credentials/mailpit-smtp.json` → `host.docker.internal:1026`, the Mailpit
from `auto-crm-api`'s docker compose), so notifications land in http://localhost:8026. For production,
edit that credential to point at your real SMTP provider. Finally subscribe the webhook workflows to CRM events —
either from the CRM UI (**Automations** page) or with:

```bash
./scripts/register-webhooks.sh
```

## Workflows

| File | Trigger | What it does |
| --- | --- | --- |
| `01-new-lead-ai-scoring` | CRM event `contact.created` | If status is `lead` → `POST /ai/contacts/{id}/score` → if score ≥ 70, create a high-priority follow-up task due tomorrow. |
| `02-deal-won-notification` | CRM event `deal.won` | Formats a message and emails the team (swap the email node for Slack/Telegram if you prefer). |
| `03-daily-overdue-tasks-digest` | Every day 08:00 | `GET /tasks?overdue=true` → groups by assignee → emails a digest (skips when nothing is overdue). |
| `04-web-form-lead-intake` | n8n hosted form `/form/auto-crm/contact-us` | Sends the submission to `POST /integrations/leads`, which creates a lead and fires `contact.created` — so workflow 01 scores it automatically. |

Webhook URLs (when active): `http://localhost:5678/webhook/auto-crm/contact-created`,
`http://localhost:5678/webhook/auto-crm/deal-won`.
While testing in the editor ("Listen for test event"), use `/webhook-test/...` instead.

## Webhook payload

Every CRM event is a `POST` with JSON:

```json
{ "event": "deal.won", "occurred_at": "2026-10-13T08:00:00Z", "data": { "...": "the deal / contact / task" } }
```

Headers: `X-AutoCRM-Event` and `X-AutoCRM-Signature: sha256=<hex>` — an HMAC-SHA256 of the raw
body using the subscription secret (shown once when you create the subscription). The starter
workflows run on localhost and don't verify it; when you expose n8n publicly, verify the
signature in a Code node (enable the Webhook node's *Raw Body* option and allow the `crypto` module
with `NODE_FUNCTION_ALLOW_BUILTIN=crypto`).

## Editing workflows

Build/change workflows in the UI, then save them back to git:

```bash
./scripts/export-workflows.sh   # writes to ./workflows/exported/
```

## Notes

- `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` lets workflows read `$env.AUTO_CRM_API_URL` / `$env.AUTO_CRM_API_KEY`.
  For production, prefer n8n credentials (e.g. a *Header Auth* credential for `X-API-Key`).
- `host.docker.internal` is how the container reaches the API running on your machine.
- Ideas for more workflows: `deal.stage_changed` → Slack channel, `task.created` → calendar event,
  weekly AI pipeline report, Gmail trigger → `/ai/extract-contact` → new contact.
