# Architecture

## Goals

- Global MCP config that works across repositories without per-project hardcoding
- Local-first, low-latency retrieval and language tooling
- Optional high-context add-ons (SurrealDB MCP and Archon MCP)
- Reproducible infra with digest pinning where practical

## Core Components

1. Agent config orchestrator
- `scripts/stack_apply.py`
- Applies profile from `configs/mcp_stack_manifest.json`
- Supports Codex, Claude Code, OpenCode
- Backs up user configs before modification

2. Infra orchestrator
- `scripts/stack_infra.sh`
- Brings services up/down per profile
- Generates runtime env files from `.secrets.env`
- Bootstraps Archon source repository when needed

3. Dynamic wrappers
- `scripts/mcpx_qdrant_auto.sh`
  - Auto-selects project collection based on workspace
  - Supports global/workspace/manual modes
- `scripts/mcpx_lsp_auto.sh`
  - Auto-detects TS/Python workspace markers
  - Chooses matching language server command

4. Validation and operations
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
- surrealmcp
- surrealist

`archon`
- qdrant
- archon-server
- archon-mcp
- archon-frontend

`docs`
- qdrant
- docs-mcp-web

## Compatibility

- Codex: stdio + http MCP transport
- Claude Code: stdio + http MCP transport
- OpenCode: local + remote MCP server entries
