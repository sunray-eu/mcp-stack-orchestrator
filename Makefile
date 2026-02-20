PROFILE ?= full
AGENTS ?= codex,claude,opencode
CODEX_TARGET ?= both

.PHONY: help bootstrap up down status apply activate doctor versions-show versions-check versions-refresh restore setup check

help:
	@task --list-all

bootstrap:
	@task infra:bootstrap PROFILE=$(PROFILE)

up:
	@task infra:up PROFILE=$(PROFILE)

down:
	@task infra:down PROFILE=$(PROFILE)

status:
	@task infra:status PROFILE=$(PROFILE)

apply:
	@task profile:apply PROFILE=$(PROFILE) AGENTS=$(AGENTS) CODEX_TARGET=$(CODEX_TARGET)

activate:
	@task profile:activate PROFILE=$(PROFILE)

doctor:
	@task quality:doctor PROFILE=$(PROFILE)

versions-show:
	@task quality:versions:show

versions-check:
	@task quality:versions:check

versions-refresh:
	@task quality:versions:refresh

restore:
	@task profile:restore

setup:
	@task setup

check:
	@task quality:check
