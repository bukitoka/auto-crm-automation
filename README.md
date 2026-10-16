# Auto CRM automation

n8n workflows that react to things happening in the CRM. The CRM sends signed webhooks to n8n
(a new contact, a won deal), and n8n calls the CRM API back with an API key.

## Run it

```bash
cp .env.example .env
# Set N8N_ENCRYPTION_KEY (openssl rand -hex 32)
# Set AUTO_CRM_API_KEY to the AUTOMATION_API_KEY from auto-crm-api/.env

docker compose up -d
./scripts/import-workflows.sh
```

Open http://localhost:5678, create the owner account, and switch each workflow to Active. Then
subscribe the workflows to CRM events, either on the CRM's Automations page or with
`./scripts/register-webhooks.sh` (it asks for an admin login).

Emails from the workflows go to Mailpit (http://localhost:8026). For real email, edit the Mailpit
SMTP credential in n8n.

## The workflows

| Workflow | When | What it does |
| --- | --- | --- |
| New lead scoring | A contact is created | Scores new leads with AI and creates a follow-up task for hot ones (score 70+) |
| Deal won | A deal is won | Emails the team |
| Overdue digest | Every day at 08:00 | Emails a digest of overdue tasks, grouped by person (skipped when nothing is overdue) |
| Web form intake | Someone fills in the n8n form | Creates a lead in the CRM, which then gets scored |

## Good to know

- Webhook requests carry an `X-AutoCRM-Signature` header (HMAC-SHA256 of the body with the
  subscription secret). The starter workflows don't check it; add that before exposing n8n
  publicly.
- When testing a webhook in the editor ("Listen for test event"), use the `/webhook-test/...` URL.
- After changing workflows in the UI, run `./scripts/export-workflows.sh` and commit the JSON.
- `host.docker.internal` is how the container reaches the API running on your machine.
