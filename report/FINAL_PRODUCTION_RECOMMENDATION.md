# Final Production MCP Recommendation

Date: 2026-02-21

## Final Ranking (from full sweep)

1. `basicmachines-co/basic-memory` (best memory quality + low friction)
2. `qdrant/mcp-server-qdrant` (best local semantic retrieval)
3. `chroma-core/chroma-mcp` (stable local vector fallback)
4. `isaacphi/mcp-language-server` (best practical code navigation quality)
5. `SurrealDB MCP` (validated, robust; backend/tooling role)
6. `Archon` (validated, high-context workflow; high setup cost)
7. `entrepeneur4lyf/code-graph-mcp` (new-wave tested add-on; strong structural analysis)
8. `neo4j/mcp` (new-wave tested add-on; robust graph query bridge when Neo4j+APOC is available)

## Final Production Decision

Use a **profiled stack** instead of one static config:

- `core` (recommended default): qdrant-backed retrieval + baseline MCP servers with dashboard visibility.
- `full`: includes `core + code-graph MCP + neo4j MCP + SurrealDB MCP + Archon MCP + docs-mcp web/MCP runtime`.
- `core-code-graph`: `core + code-graph MCP` (optional structural-analysis profile).
- `full-code-graph`: compatibility variant of `full` without neo4j MCP/runtime.
- `core-neo4j`: `core + neo4j MCP` (optional graph-query profile).
- `full-neo4j`: compatibility variant of `full` without code-graph MCP.
- `full-graph`: compatibility alias of the maximum graph-analysis profile (`same server set as full`).

This lets you keep correctness and speed in normal coding, while enabling heavy context workflows on demand.

## DX Normalization Update (2026-02-20)

- Primary operator interface is now Taskfile-based (`task ...`) for consistent day-2 operations.
- Shell scripts remain as internal runtime engines but are no longer the primary user surface.
- Added layered AGENTS scaffolding (`global -> company -> project`) with reusable prompts and generator:
  - `task agents:init ...`
  - `task agents:render ...`
- Added duplicate stack detection command:
  - `task env:where`
- Surreal compatibility policy and v3 migration TODO are now explicitly documented in:
  - `docs/SURREAL_COMPATIBILITY.md`

## Runtime Delta (Latest Full Interaction Test)

Latest exhaustive runtime validation artifact:
- `<STACK_ROOT>/report/FINAL_RUNTIME_TOOL_INTERACTION_TEST.md`

Key updates from the final in-session tool interaction pass:
- `mcpx-lsp` remains the most reliable correctness anchor for symbol-level coding work.
- `mcpx-qdrant` remains best for low-latency semantic recall, but current wrapper metadata input is still constrained.
- `mcpx-basic-memory` is stable for project memory, but `fetch` on non-main projects should be avoided (use `search_notes` + `read_note`).
- `mcpx-chroma` is stable for local vector workflows; local backend still does not support `fork_collection`.
- `mcpx-archon-http` lifecycle features are solid; RAG is only useful after explicit source ingestion.
- `mcpx-surrealdb-http` is now stable in this stack with the compatibility layer and SurrealDB version pinning:
  - `surrealmcp-compat` handles OAuth discovery probes + stale-session recovery
  - SurrealDB runtime pinned to `2.3.10` for current SurrealMCP WS compatibility
  - real in-session CRUD/query tool calls validated

Operational recommendation remains unchanged:
- Default to `core` during active coding.
- Switch to `full` for workflow-heavy context layers (Archon/Surreal/docs UI).

## Current Applied State (already executed)

Applied profile: `full`

Applied to:
- `/Users/<user>/.codex/config.toml`
- `/Users/<user>/.codex-mcp-eval/config.toml`
- `/Users/<user>/.claude.json`
- `/Users/<user>/.config/opencode/opencode.jsonc`

Managed MCP names:
- `mcpx-basic-memory`
- `mcpx-qdrant`
- `mcpx-chroma`
- `mcpx-lsp`
- `mcpx-code-graph`
- `mcpx-neo4j`
- `mcpx-surrealdb-http`
- `mcpx-archon-http`
- `mcpx-docs-mcp-http`

Legacy managed names retained only for automatic cleanup during profile re-apply:
- `mcpx-qdrant-global`
- `mcpx-qdrant-project-a`
- `mcpx-qdrant-project-b`
- `mcpx-lsp-py`
- `mcpx-lsp-ts`

UI/infra services started by `task infra:up` (profile-dependent):
- `ai-mcp-qdrant`
- `ai-mcp-chroma`
- `ai-mcp-chroma-ui`
- `ai-mcp-neo4j` (enabled by `full`, `core-neo4j`, `full-neo4j`, `full-graph`)
- `ai-mcp-surreal-mcp`
- `ai-mcp-surrealist`
- `ai-mcp-archon-server`
- `ai-mcp-archon-mcp`
- `ai-mcp-archon-mcp-compat`
- `ai-mcp-archon-ui`
- `ai-mcp-docs-mcp`

## Standardized Stack Manifest

Canonical config source:
- `<STACK_ROOT>/configs/mcp_stack_manifest.json`

Profile applier:
- `<STACK_ROOT>/scripts/stack_apply.sh`
- Primary operator entrypoint: `task profile:apply`

Infra manager:
- `<STACK_ROOT>/scripts/stack_infra.sh`
- Primary operator entrypoint: `task infra:up|down|status`

Version manager:
- `<STACK_ROOT>/scripts/stack_versions.sh`
- Primary operator entrypoint: `task quality:versions:*`

Stack health doctor:
- `<STACK_ROOT>/scripts/stack_doctor.sh`
- Primary operator entrypoint: `task quality:doctor`

One-command activator (infra + profile):
- `<STACK_ROOT>/scripts/stack_activate.sh`
- Primary operator entrypoint: `task profile:activate`

## Infra Lifecycle

Start full infra (Qdrant + Chroma + Chroma UI + Neo4j + Surreal + Archon + Docs MCP web):

```bash
task infra:up PROFILE=full
```

Stop full infra:

```bash
task infra:down PROFILE=full
```

Status:

```bash
task infra:status
task quality:doctor PROFILE=full
task quality:versions:show
task quality:versions:check
```

## Profile Lifecycle

Apply `core` to all agents:

```bash
task profile:apply PROFILE=core AGENTS=codex,claude,opencode CODEX_TARGET=both
```

Apply `full` to all agents:

```bash
task profile:apply PROFILE=full AGENTS=codex,claude,opencode CODEX_TARGET=both
```

Apply graph-enabled optional profiles:

```bash
task profile:apply PROFILE=core-code-graph AGENTS=codex,claude,opencode CODEX_TARGET=both
task profile:apply PROFILE=full-code-graph AGENTS=codex,claude,opencode CODEX_TARGET=both
task profile:apply PROFILE=core-neo4j AGENTS=codex,claude,opencode CODEX_TARGET=both
task profile:apply PROFILE=full-neo4j AGENTS=codex,claude,opencode CODEX_TARGET=both
task profile:apply PROFILE=full-graph AGENTS=codex,claude,opencode CODEX_TARGET=both
```

Disable managed MCP stack (keep non-managed MCPs untouched):

```bash
task profile:apply PROFILE=none AGENTS=codex,claude,opencode CODEX_TARGET=both
```

## When To Use Which Profile

- Use `core` when implementing/refactoring/debugging inside TS+PY repos.
- Use `full` as the maximum-context profile (includes graph add-ons + workflow layers + docs runtime).
- Use `core-code-graph` or `full-code-graph` only when you need structural graph analysis and want to avoid running Neo4j.
- Use `core-neo4j`/`full-neo4j` when relationship-heavy graph queries are required and you do not need local code-graph MCP simultaneously.
- Use `full-graph` only as compatibility alias where existing automation expects it.

## Global Dynamic Behavior

- `mcpx-qdrant` derives collection name from current workspace root by default (`proj-<repo-slug>`).
- `mcpx-lsp` derives workspace root from current working directory and auto-selects Python vs TypeScript LSP based on repo markers.
- No project-specific MCP entries are required in global agent configs.

Per-repo overrides (only when needed):
- Place `.mcp-stack.env` in repository root.
- Example template: `<STACK_ROOT>/configs/mcp-stack.env.example`
- Wrapper parsing is strict `KEY=VALUE` data only (no shell execution).

## Web UI Endpoints (Always-On in `full`)

- Qdrant dashboard: `http://127.0.0.1:6333/dashboard/`
- Chroma UI: `http://127.0.0.1:18110`
- Archon UI: `http://127.0.0.1:13737`
- Surrealist UI: `http://127.0.0.1:18082`
- Docs MCP UI: `http://127.0.0.1:16280`
- Neo4j Browser (`full` and Neo4j-enabled profiles): `http://127.0.0.1:17474`

Live status snapshot:
- `<STACK_ROOT>/report/ui_endpoint_status.tsv`
- `<STACK_ROOT>/report/WEB_UI_AUDIT.md`
- `<STACK_ROOT>/report/web_ui_candidates.tsv`

## Security and Operational Notes

- Archon uses Supabase credentials from `<STACK_ROOT>/.secrets.env`.
- Runtime env is generated at `<STACK_ROOT>/tmp/ai-mcp-archon.env` with `chmod 600`.
- Docs MCP embedding provider env is generated at `<STACK_ROOT>/tmp/ai-mcp-infra.env` with `chmod 600`.
- Surrealist connection config is generated at `<STACK_ROOT>/tmp/surrealist-instance.json` with `chmod 600` (no static credentials in checked-in config).
- Docs MCP vector search is now enabled through `OPENAI_API_KEY` (and optional `DOCS_MCP_EMBEDDING_MODEL`, defaulting to `text-embedding-3-small` when unspecified).
- Docker MCP filesystem strategy (best balance for indexing + safety):
  - Read-only host root mount: `/` -> `/hostfs`
  - Read-only direct user path mount: `/Users` -> `/Users`
  - This enables direct indexing of local repo files while preventing in-container writes to host filesystem.
  - Mount sources are configurable via `MCP_HOST_FS_ROOT` and `MCP_HOST_FS_USERS` in `<STACK_ROOT>/.secrets.env`.
- Neo4j MCP policy:
  - Default wrapper mode is read-only (`NEO4J_READ_ONLY=true`).
  - Local dev runtime uses `neo4j:5.26.19` + APOC and exposes Browser on `127.0.0.1:17474`.
  - Enable only for graph-centric tasks (`core-neo4j`, `full-neo4j`, `full-graph`) to avoid unnecessary infra overhead.
- No secrets are printed by stack scripts.
- Qdrant MCP instances now share `QDRANT_URL=http://127.0.0.1:6333` with per-server `COLLECTION_NAME` isolation, enabling dashboard visibility without data-file lock collisions.
- Managed infra image refs are centralized and digest-pinned in `<STACK_ROOT>/infra/versions.env`.
- Surreal runtime compatibility policy:
  - Keep SurrealDB pinned to `2.3.x` for current SurrealMCP builds.
  - Use `surrealmcp-compat` on `127.0.0.1:18080` as the MCP endpoint; direct backend SurrealMCP remains on `127.0.0.1:18084`.
  - Track v3 migration readiness in `docs/SURREAL_COMPATIBILITY.md` and re-test before changing channels.
- Archon MCP transport compatibility policy:
  - Keep `mcpx-archon-http` pointed at `127.0.0.1:18051/mcp` (compat endpoint).
  - Native Archon MCP runs on `127.0.0.1:18052`; `archon-mcp-compat` handles bootstrap/session edge-cases for clients that call tools before initialize.

Upgrade procedure:

```bash
task quality:versions:check
task quality:versions:refresh
task infra:up PROFILE=full
task quality:doctor PROFILE=full
```

## Restore

One-command full restore:

```bash
task profile:restore
```

Or explicit backup:

```bash
task profile:restore BACKUP=<STACK_ROOT>/backups/<backup_dir>
```

## Documentation Rechecked (official/primary)

- Basic Memory: https://github.com/basicmachines-co/basic-memory
- Qdrant MCP Server: https://github.com/qdrant/mcp-server-qdrant
- Qdrant Web UI: https://qdrant.tech/documentation/web-ui/
- Chroma MCP: https://github.com/chroma-core/chroma-mcp
- MCP Language Server: https://github.com/isaacphi/mcp-language-server
- SurrealDB MCP: https://surrealdb.com/mcp
- Surrealist docs: https://surrealdb.com/docs/surrealist
- SurrealDB MCP CLI runtime flags: `docker run --rm surrealdb/surrealmcp:latest start --help`
- Archon: https://github.com/coleam00/Archon
- Docs MCP Server: https://github.com/arabold/docs-mcp-server
- Claude MCP CLI: `claude mcp --help`
- Codex MCP CLI: `codex mcp --help`
- OpenCode MCP CLI: `opencode mcp --help`


## Naming Standard

- Container prefix: `ai-mcp-*`
- Supabase project name: `ai-mcp-archon`
- Managed MCP server names: `mcpx-*`
