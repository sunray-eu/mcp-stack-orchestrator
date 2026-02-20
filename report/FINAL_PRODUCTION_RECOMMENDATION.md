# Final Production MCP Recommendation

Date: 2026-02-20

## Final Ranking (from full sweep)

1. `basicmachines-co/basic-memory` (best memory quality + low friction)
2. `qdrant/mcp-server-qdrant` (best local semantic retrieval)
3. `chroma-core/chroma-mcp` (stable local vector fallback)
4. `isaacphi/mcp-language-server` (best practical code navigation quality)
5. `SurrealDB MCP` (validated, robust; backend/tooling role)
6. `Archon` (validated, high-context workflow; high setup cost)

## Final Production Decision

Use a **profiled stack** instead of one static config:

- `core` (recommended default): qdrant-backed retrieval + baseline MCP servers with dashboard visibility.
- `full`: includes `core + SurrealDB MCP + Archon MCP + docs-mcp web/MCP runtime`.

This lets you keep correctness and speed in normal coding, while enabling heavy context workflows on demand.

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
- `mcpx-surrealdb-http`
- `mcpx-archon-http`

Legacy managed names retained only for automatic cleanup during profile re-apply:
- `mcpx-qdrant-global`
- `mcpx-qdrant-project-a`
- `mcpx-qdrant-project-b`
- `mcpx-lsp-py`
- `mcpx-lsp-ts`

UI/infra services started by `stack_infra.sh` (profile-dependent):
- `ai-mcp-qdrant`
- `ai-mcp-surreal-mcp`
- `ai-mcp-surrealist`
- `ai-mcp-archon-server`
- `ai-mcp-archon-mcp`
- `ai-mcp-archon-ui`
- `ai-mcp-docs-mcp`

## Standardized Stack Manifest

Canonical config source:
- `<STACK_ROOT>/configs/mcp_stack_manifest.json`

Profile applier:
- `<STACK_ROOT>/scripts/stack_apply.sh`

Infra manager:
- `<STACK_ROOT>/scripts/stack_infra.sh`

Version manager:
- `<STACK_ROOT>/scripts/stack_versions.sh`

Stack health doctor:
- `<STACK_ROOT>/scripts/stack_doctor.sh`

One-command activator (infra + profile):
- `<STACK_ROOT>/scripts/stack_activate.sh`

## Infra Lifecycle

Start full infra (Qdrant + Surreal + Archon + Docs MCP web):

```bash
<STACK_ROOT>/scripts/stack_infra.sh up full
```

Stop full infra:

```bash
<STACK_ROOT>/scripts/stack_infra.sh down full
```

Status:

```bash
<STACK_ROOT>/scripts/stack_infra.sh status
<STACK_ROOT>/scripts/stack_doctor.sh full
<STACK_ROOT>/scripts/stack_versions.sh show
<STACK_ROOT>/scripts/stack_versions.sh check
```

## Profile Lifecycle

Apply `core` to all agents:

```bash
<STACK_ROOT>/scripts/stack_apply.sh core --agents codex,claude,opencode --codex-target both
```

Apply `full` to all agents:

```bash
<STACK_ROOT>/scripts/stack_apply.sh full --agents codex,claude,opencode --codex-target both
```

Disable managed MCP stack (keep non-managed MCPs untouched):

```bash
<STACK_ROOT>/scripts/stack_apply.sh none --agents codex,claude,opencode --codex-target both
```

## When To Use Which Profile

- Use `core` when implementing/refactoring/debugging inside TS+PY repos.
- Use `full` when you need additional memory/workflow layers (Archon task/doc graph + Surreal-backed operations + docs-mcp UI/runtime).

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
- Archon UI: `http://127.0.0.1:13737`
- Surrealist UI: `http://127.0.0.1:18082`
- Docs MCP UI: `http://127.0.0.1:16280`

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
- No secrets are printed by stack scripts.
- Qdrant MCP instances now share `QDRANT_URL=http://127.0.0.1:6333` with per-server `COLLECTION_NAME` isolation, enabling dashboard visibility without data-file lock collisions.
- Managed infra image refs are centralized and digest-pinned in `<STACK_ROOT>/infra/versions.env`.

Upgrade procedure:

```bash
<STACK_ROOT>/scripts/stack_versions.sh check
<STACK_ROOT>/scripts/stack_versions.sh refresh
<STACK_ROOT>/scripts/stack_infra.sh up full
<STACK_ROOT>/scripts/stack_doctor.sh full
```

## Restore

One-command full restore:

```bash
<STACK_ROOT>/scripts/restore_original.sh
```

Or explicit backup:

```bash
<STACK_ROOT>/scripts/restore_original.sh <STACK_ROOT>/backups/<backup_dir>
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
