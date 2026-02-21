# MCP Stack Orchestrator

Reproducible evaluation artifacts and production-grade orchestration for a multi-agent MCP stack across Codex, Claude Code, and OpenCode.

## What This Repository Provides

- Repeatable MCP infra orchestration with Docker (`qdrant`, `surrealdb`, `surrealmcp`, `surrealmcp-compat`, `surrealist`, `docs-mcp` standalone, optional `Archon` + `archon-mcp-compat`)
- Global dynamic MCP profiles for multiple agents (`core`, `core-surreal`, `core-archon`, `full`)
- Workspace-aware wrappers for Qdrant collection routing and LSP selection
- Taskfile-first operator workflow (`task ...`) with shell scripts as internal runtime engines
- AGENTS scaffolding generator with layered global/company/project guidelines
- Canonical always-on engineering policy (`guidelines/global/engineering-always.md`)
- Safety-first config rollout with backups and one-command restore
- Full research outputs and scoring artifacts from large MCP candidate sweeps

## Scope

This repo is intended for developers who want:

1. High-correctness coding context (vector memory + LSP + optional graph/workflow servers)
2. Fast local-first operation with controlled optional cloud dependencies
3. A maintainable way to enable/disable MCP stacks per runtime profile

## Repository Layout

- `Taskfile.yml` + `.taskfiles/` primary DX command surface
- `scripts/` runtime engines (`stack_infra.sh`, `stack_apply.sh`, `stack_activate.sh`, `stack_doctor.sh`, `restore_original.sh`)
- `infra/` docker compose and pinned image versions
- `configs/` MCP profile manifest and per-project override template
- `guidelines/` global baseline AI guidelines
- `templates/agents/` AGENTS/guidelines/prompt templates
- `report/` detailed evaluation, benchmarks, risk scans, and recommendation outputs
- `docs/` architecture, maintenance policy, AGENTS workflow, and compatibility notes
- `docs/MCP_CONFIGURATION_REFERENCE.md` complete MCP configuration matrix with upstream source links

## Quick Start

1. Clone and enter repo.
2. Install tooling + hooks:
   - `task setup`
2. Copy secrets template:
   - `cp .secrets.env.example .secrets.env`
   - Fill only required keys (for `docs` and `archon` profiles).
   - For private GitHub indexing in `docs-mcp`, set `GITHUB_TOKEN` (or `GH_TOKEN`).
   - Leave optional `DOCS_MCP_*` keys unset unless needed (do not set blank values).
3. Start infra:
   - `task infra:up PROFILE=core`
4. Apply MCP profile to agents:
   - `task profile:apply PROFILE=core AGENTS=codex,claude,opencode CODEX_TARGET=both`
5. Run health checks:
   - `task quality:doctor PROFILE=core`

For full stack (SurrealDB + Archon + docs-mcp):

- `task profile:activate PROFILE=full`

## Profiles

- `none`: remove managed MCP profile, stop managed infra
- `core`: `basic-memory + qdrant + chroma + lsp`
- `core-surreal`: `core + surrealdb MCP`
- `core-archon`: `core + archon MCP`
- `full`: `core + surrealdb MCP + archon MCP`

## SurrealDB Compatibility Note

- Current validated production path uses SurrealDB `2.3.10` + `surrealmcp-compat` for stable HTTP MCP behavior.
- A dedicated v3 upgrade TODO/process is tracked in `docs/SURREAL_COMPATIBILITY.md`.

## Security Model

- Third-party MCP servers are treated as untrusted until evaluated
- Runtime credentials are loaded from `.secrets.env` and written to temp runtime files with `0600` permissions
- Host filesystem mounts are read-only by default for MCP containers
- Config rollout always creates backups before writing user agent configs

## Research and Evidence

- Primary report: `report/MCP_EVAL_REPORT.md`
- Final recommendation: `report/FINAL_PRODUCTION_RECOMMENDATION.md`
- Runtime and UI validation: `report/ARCHON_SURREAL_RUNTIME_VALIDATION.md`, `report/WEB_UI_AUDIT.md`
- Candidate data tables: `report/data/*.tsv`
- AGENTS layering and generator workflow: `docs/AGENTS_GUIDE.md`

## Common Commands

- `task help`
- `task infra:up PROFILE=core`
- `task profile:apply PROFILE=core`
- `task quality:doctor PROFILE=core`
- `task quality:stress` (append fresh runtime perf loop to `report/data/final_runtime_perf.tsv`)
- `task infra:down PROFILE=full`
- `task profile:restore`
- `task env:where` (prints canonical vs legacy duplicate stack paths)
- `task agents:init REPO=/path/to/repo COMPANY=example-co PROJECT=example-api LANGUAGE=typescript PROFILE=core`
- `task agents:onboard REPO=/path/to/repo COMPANY=example-co PROJECT=example-api LANGUAGE=typescript PROFILE=core`

Legacy compatibility:
- `make` targets remain available as wrappers around `task` commands.

## Canonical Path

- Canonical runtime/orchestration path is this repository.
- Legacy evaluation harness path (`$HOME/mcp-eval`) may still exist as a duplicate; keep it read-only for historical artifacts.
- Use `task env:where` to detect duplicates on your machine.

## License

MIT License. See `LICENSE`.
