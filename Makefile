PROFILE ?= full
AGENTS ?= codex,claude,opencode
CODEX_TARGET ?= both

.PHONY: help bootstrap up down status apply activate doctor versions-show versions-check versions-refresh restore

help:
	@echo "Targets:"
	@echo "  make bootstrap PROFILE=archon"
	@echo "  make up PROFILE=core|surreal|archon|docs|full"
	@echo "  make down PROFILE=..."
	@echo "  make status PROFILE=..."
	@echo "  make apply PROFILE=... AGENTS=codex,claude,opencode CODEX_TARGET=both"
	@echo "  make activate PROFILE=none|core|core-surreal|core-archon|core-docs|full"
	@echo "  make doctor PROFILE=..."
	@echo "  make versions-show|versions-check|versions-refresh"
	@echo "  make restore"

bootstrap:
	./scripts/stack_infra.sh bootstrap $(PROFILE)

up:
	./scripts/stack_infra.sh up $(PROFILE)

down:
	./scripts/stack_infra.sh down $(PROFILE)

status:
	./scripts/stack_infra.sh status $(PROFILE)

apply:
	./scripts/stack_apply.sh $(PROFILE) --agents $(AGENTS) --codex-target $(CODEX_TARGET)

activate:
	./scripts/stack_activate.sh $(PROFILE)

doctor:
	./scripts/stack_doctor.sh $(PROFILE)

versions-show:
	./scripts/stack_versions.sh show

versions-check:
	./scripts/stack_versions.sh check

versions-refresh:
	./scripts/stack_versions.sh refresh

restore:
	./scripts/restore_original.sh
