# MCP Stack Orchestrator

Reproducible evaluation artifacts and production-grade orchestration for a multi-agent MCP stack across Codex, Claude Code, and OpenCode.

## What This Repository Provides

- Repeatable MCP infra orchestration with Docker (`qdrant`, `surrealdb`, `surrealmcp`, `surrealist`, `docs-mcp`, optional `Archon`)
- Global dynamic MCP profiles for multiple agents (`core`, `core-surreal`, `core-archon`, `full`)
- Workspace-aware wrappers for Qdrant collection routing and LSP selection
- Safety-first config rollout with backups and one-command restore
- Full research outputs and scoring artifacts from large MCP candidate sweeps

## Scope

This repo is intended for developers who want:

1. High-correctness coding context (vector memory + LSP + optional graph/workflow servers)
2. Fast local-first operation with controlled optional cloud dependencies
3. A maintainable way to enable/disable MCP stacks per runtime profile

## Repository Layout

- `scripts/` operational scripts (`stack_infra.sh`, `stack_apply.sh`, `stack_activate.sh`, `stack_doctor.sh`, `restore_original.sh`)
- `infra/` docker compose and pinned image versions
- `configs/` MCP profile manifest and per-project override template
- `report/` detailed evaluation, benchmarks, risk scans, and recommendation outputs
- `docs/` architecture, maintenance policy, and scoring model

## Quick Start

1. Clone and enter repo.
2. Copy secrets template:
   - `cp .secrets.env.example .secrets.env`
   - Fill only required keys (for `docs` and `archon` profiles).
3. Start infra:
   - `./scripts/stack_infra.sh up core`
4. Apply MCP profile to agents:
   - `./scripts/stack_apply.sh core --agents codex,claude,opencode --codex-target both`
5. Run health checks:
   - `./scripts/stack_doctor.sh core`

For full stack (SurrealDB + Archon + docs-mcp):

- `./scripts/stack_activate.sh full`

## Profiles

- `none`: remove managed MCP profile, stop managed infra
- `core`: `basic-memory + qdrant + chroma + lsp`
- `core-surreal`: `core + surrealdb MCP`
- `core-archon`: `core + archon MCP`
- `full`: `core + surrealdb MCP + archon MCP`

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

## Common Commands

- `make help`
- `make up PROFILE=core`
- `make apply PROFILE=core`
- `make doctor PROFILE=core`
- `make down PROFILE=full`
- `make restore`

## License

MIT License. See `LICENSE`.
