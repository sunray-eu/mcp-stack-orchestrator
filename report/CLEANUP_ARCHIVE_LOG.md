# Cleanup And Archive Log

Date: 2026-02-20

## Objective

Normalize the workspace after MCP evaluation while preserving production MCP operations.

## Backup Set

Backup root:
- `/Users/marosvarchola/mcp-eval/backups/final-cleanup-20260220-190126`

Backed up artifacts:
- full Git bundles:
  - `repos/ts-repo.bundle`
  - `repos/py-repo.bundle`
  - `repos/mcp-stack-orchestrator.bundle`
- AI agent configs:
  - `configs/codex.config.toml`
  - `configs/codex-mcp-eval.config.toml`
  - `configs/claude.json`
  - `configs/opencode.jsonc`
- archived evaluation evidence:
  - `archives/evaluation-results.tar.gz`
  - `archives/legacy-infra-config.tar.gz`
  - `archives/legacy-server-inventory.txt`
  - `archives/mcp-stack-orchestrator-source.tar.gz`

Integrity manifests:
- `SHA256SUMS.txt`
- `SHA256SUMS-archives.txt`

## Repository Cleanup

### TS repository
- switched from temporary evaluation branch to `main`
- deleted local temporary branch (`mcp-eval/<ts-repo>`)
- final state: clean working tree on `main`

### Python repository
- switched from temporary evaluation branch to `main`
- deleted local temporary branch (`mcp-eval/<py-repo>`)
- final state: clean working tree on `main`

## Legacy Workspace Pruning

Legacy evaluation workspace:
- path: `/Users/marosvarchola/mcp-eval`
- before cleanup: ~`5.1G`
- after cleanup: `22M`

Pruned directories (after archival):
- `servers/`
- `uvcache/`
- `infra/`
- `bin/`
- `tmp/`
- `logs/`
- `report/`
- `configs/`
- `scripts/`
- `artifacts/`
- removed stale secret file `.secrets.env`

Duplicate source tree cleanup:
- previous duplicate: `/Users/marosvarchola/Programming/sunray/gits/mcp-stack-orchestrator-source`
- archived and removed from active `gits` root

## Production Safety Validation

Post-cleanup runtime health check:
- command: `task quality:doctor PROFILE=full`
- result: `PASS=36 WARN=0 FAIL=0`

This confirms the production MCP stack remains intact.

## Machine-Readable Manifest

See:
- `report/data/cleanup_manifest.tsv`
