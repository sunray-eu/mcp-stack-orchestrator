# Architecture

## Goals

- Global MCP config that works across repositories without per-project hardcoding
- Local-first, low-latency retrieval and language tooling
- Optional high-context add-ons (SurrealDB MCP, Archon MCP, Code Graph MCP, and Neo4j MCP)
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
- `scripts/mcpx_code_graph_auto.sh`
  - Resolves current workspace root dynamically
  - Runs `code-graph-mcp` for on-demand structural graph analysis
- `scripts/mcpx_neo4j_auto.sh`
  - Uses local Neo4j+APOC runtime defaults (read-only by default)
  - Prefers `neo4j-mcp` binary with `go run` fallback for reproducible setup

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
- Docs MCP private source auth supported via `GITHUB_TOKEN` / `GH_TOKEN`
- Docs MCP advanced server/scraper/splitter overrides supported via `DOCS_MCP_*`
- Docs profile runs `docs-mcp` in standalone server mode (includes upstream embedded worker)
- Runtime writer omits empty `DOCS_MCP_*` values to avoid overriding upstream defaults with invalid zero/blank settings
- Generated runtime files:
  - `tmp/ai-mcp-infra.env`
  - `tmp/ai-mcp-archon.env`
  - `tmp/surrealist-instance.json`
- Runtime files are permissioned to `0600`

## Container Topology

`core`
- qdrant
- chroma
- chroma-ui

`core-code-graph`
- qdrant
- chroma
- chroma-ui
- code-graph MCP (stdio, no additional container)

`core-neo4j`
- qdrant
- chroma
- chroma-ui
- neo4j
- neo4j MCP (stdio wrapper, no separate MCP container)

`surreal`
- qdrant
- chroma
- chroma-ui
- surrealdb
- surrealmcp-compat (frontend on `:18080`)
- surrealmcp
- surrealist

`archon`
- qdrant
- chroma
- chroma-ui
- archon-server
- archon-mcp
- archon-mcp-compat (frontend on `:18051`, upstream native MCP on `:18052`)
- archon-frontend

`docs`
- qdrant
- chroma
- chroma-ui
- docs-mcp-web

`full`
- qdrant
- chroma
- chroma-ui
- neo4j
- surrealdb
- surrealmcp-compat (frontend on `:18080`)
- surrealmcp
- surrealist
- archon-server
- archon-mcp
- archon-mcp-compat (frontend on `:18051`, upstream native MCP on `:18052`)
- archon-frontend
- docs-mcp-web
- code-graph MCP + neo4j MCP (combined graph-analysis add-ons)

`full-code-graph`
- full container topology without neo4j
- code-graph MCP (stdio add-on)

`full-neo4j`
- full container topology without code-graph MCP
- neo4j
- neo4j MCP (stdio add-on)

`full-graph`
- compatibility alias of `full` graph-enabled topology

## Compatibility

- Codex: stdio + http MCP transport
- Claude Code: stdio + http MCP transport
- OpenCode: local + remote MCP server entries
- SurrealDB MCP runtime: pinned to SurrealDB `2.3.x` with a compatibility proxy for stable HTTP MCP handshake/session recovery
- Archon MCP runtime: compatibility proxy on `:18051` normalizes bootstrap/session edge-cases for strict streamable-http clients
