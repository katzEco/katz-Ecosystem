.DEFAULT_GOAL := help

DC ?= docker compose

# Support both positional args (e.g. make up core) and variable (e.g. make up m=core)
TARGETS_WITH_ARGS := up down stop restart build rebuild ps logs shell restore restore-db import-db

ifeq ($(firstword $(MAKECMDGOALS)),$(filter $(firstword $(MAKECMDGOALS)),$(TARGETS_WITH_ARGS)))
  RAW_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval .PHONY: $(RAW_ARGS))
  $(eval $(RAW_ARGS):;@:)
endif

m ?=
s ?=
module ?=
MODULE ?= $(strip $(if $(m),$(m),$(if $(s),$(s),$(if $(module),$(module),$(RAW_ARGS)))))

CORE := live todo
PRO := live todo utils

# Shorthand alias mappings for service names
ifeq ($(MODULE),core)
  override MODULE := $(CORE)
endif
ifeq ($(MODULE),pro)
  override MODULE := $(PRO)
endif
ifeq ($(MODULE),detector)
  override MODULE := live
endif
ifeq ($(MODULE),live-detector)
  override MODULE := live
endif
ifeq ($(MODULE),live_detector)
  override MODULE := live
endif
ifeq ($(MODULE),postgres)
  override MODULE := db_postgres_eco
endif
ifeq ($(MODULE),redis)
  override MODULE := db_redis_eco
endif
ifeq ($(MODULE),db)
  override MODULE := db_postgres_eco db_redis_eco
endif
ifeq ($(MODULE),all)
  override MODULE :=
endif

.PHONY: help up down stop restart build rebuild ps logs shell shell-db clean pull dump backup dump-db export-db restore import-db

help: ## Show this help message
	@echo "Usage: make [target] [module]"
	@echo "       make [target] [m=<module>]"
	@echo ""
	@echo "Modules:"
	@echo "  core        -> todo + live"
	@echo "  pro         -> todo + live + utils"
	@echo "  todo        -> katz-todo"
	@echo "  live        -> katz-live-detector (aliases: detector, live_detector)"
	@echo "  utils       -> katz-utils"
	@echo "  db          -> postgres + redis (aliases: postgres, redis)"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

up: ## Start services (e.g. make up, make up core, make up utils)
	$(DC) up -d $(MODULE)

down: ## Stop & remove containers (e.g. make down, make down utils)
	@if [ -z "$(MODULE)" ]; then \
		$(DC) down; \
	else \
		$(DC) stop $(MODULE) && $(DC) rm -f $(MODULE); \
	fi

stop: ## Stop running containers (e.g. make stop, make stop todo)
	$(DC) stop $(MODULE)

restart: ## Restart services (e.g. make restart, make restart core)
	$(DC) restart $(MODULE)

build: ## Build images (e.g. make build, make build utils)
	$(DC) build $(MODULE)

rebuild: ## Rebuild images and restart (e.g. make rebuild core)
	$(DC) up -d --build $(MODULE)

ps: ## Show status of services (e.g. make ps, make ps todo)
	$(DC) ps $(MODULE)

logs: ## Follow logs (e.g. make logs, make logs live)
	$(DC) logs -f $(MODULE)

shell: ## Open shell in container (requires module, e.g. make shell todo)
	@if [ -z "$(MODULE)" ]; then echo "Error: specify module (e.g. make shell todo)"; exit 1; fi
	$(DC) exec -it $(MODULE) sh

shell-db: ## Open psql shell in postgres container
	$(DC) exec -it db_postgres_eco sh -c 'psql -U $${POSTGRES_USER:-postgres} -d $${POSTGRES_DB:-app}'

clean: ## Stop services and wipe volumes (destructive reset)
	$(DC) down -v

pull: ## Pull base images
	$(DC) pull $(MODULE)

dump: ## Dump Postgres & Redis databases to zip in backups/ (alias: backup, export-db)
	@./scripts/dump.sh

backup: dump ## Alias for dump

dump-db: dump ## Alias for dump

export-db: dump ## Alias for dump

file ?=
zip ?=
RESTORE_FILE ?= $(strip $(if $(file),$(file),$(if $(zip),$(zip),$(RAW_ARGS))))

restore: ## Restore Postgres & Redis from zip archive (default: backups/backup_latest.zip)
	@./scripts/restore.sh $(RESTORE_FILE)

restore-db: restore ## Alias for restore

import-db: restore ## Alias for restore
