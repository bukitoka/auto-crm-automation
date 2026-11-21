.DEFAULT_GOAL := help
.PHONY: help dev stop status logs import export register check

help: ## Show available targets
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z0-9_-]+:.*## / {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev: ## Start the local n8n container
	docker compose up -d

stop: ## Stop the local n8n container
	docker compose stop

status: ## Show local container status
	docker compose ps

logs: ## Follow local container logs
	docker compose logs -f

import: ## Import workflows into the running n8n container
	./scripts/import-workflows.sh

export: ## Export workflows from the running n8n container
	./scripts/export-workflows.sh

register: ## Register CRM webhooks (prompts for super admin login)
	./scripts/register-webhooks.sh

check: ## Validate the local Compose config and shell syntax
	docker compose config --quiet
	@for script in scripts/*.sh; do bash -n "$$script" || exit 1; done
