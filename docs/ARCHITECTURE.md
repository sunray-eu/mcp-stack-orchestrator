# Architecture

## Goals

- Global MCP config that works across repositories without per-project hardcoding
- Local-first, low-latency retrieval and language tooling
- Optional high-context add-ons (SurrealDB MCP and Archon MCP)
- Reproducible infra with digest pinning where practical

## Core Components

1. Taskfile orchestration layer
- `Taskfile.yml` + `.taskfiles/*`
- Stable operator interface for infra/profile/quality/agents workflows
- Keeps scripts as runtime engines, not user-facing primary entrypoints

2. Agent config orchestrator
- `scripts/stack_apply.py`
- Applies profile from `configs/mcp_stack_manifest.json`
- Supports Codex, Claude Code, OpenCode
- Backs up user configs before modification

3. Infra orchestrator
- `scripts/stack_infra.sh`
- Brings services up/down per profile
- Generates runtime env files from `.secrets.env`
- Bootstraps Archon source repository when needed

4. Dynamic wrappers
- `scripts/mcpx_qdrant_auto.sh`
  - Auto-selects project collection based on workspace
  - Supports global/workspace/manual modes
- `scripts/mcpx_lsp_auto.sh`
  - Auto-detects TS/Python workspace markers
  - Chooses matching language server command

5. AGENTS scaffolding
- `scripts/agents_scaffold.py`
- Templates in `templates/agents/`
- Layered global/company/project guidance generation

6. Validation and operations
- `scripts/stack_doctor.sh` for health and config checks
- `scripts/stack_versions.sh` for image pin inspection and refresh
- `scripts/restore_original.sh` for rollback

## Data and Secrets Flow

- Secrets source: `.secrets.env` (never committed)
- Generated runtime files:
  - `tmp/ai-mcp-infra.env`
  - `tmp/ai-mcp-archon.env`
  - `tmp/surrealist-instance.json`
- Runtime files are permissioned to `0600`

## Container Topology

`core`
- qdrant

`surreal`
- qdrant
- surrealdb
- surrealmcp-compat (frontend on `:18080`)
- surrealmcp
- surrealist

`archon`
- qdrant
- archon-server
- archon-mcp
- archon-mcp-compat (frontend on `:18051`, upstream native MCP on `:18052`)
- archon-frontend

`docs`
- qdrant
- docs-mcp-web

## Compatibility

- Codex: stdio + http MCP transport
- Claude Code: stdio + http MCP transport
- OpenCode: local + remote MCP server entries
- SurrealDB MCP runtime: pinned to SurrealDB `2.3.x` with a compatibility proxy for stable HTTP MCP handshake/session recovery
- Archon MCP runtime: compatibility proxy on `:18051` normalizes bootstrap/session edge-cases for strict streamable-http clients
