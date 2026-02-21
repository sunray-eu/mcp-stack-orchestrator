# MCP Configuration Reference

This document is the canonical configuration matrix for the MCP servers used by this orchestrator.
It is intentionally split by:

- Global runtime secrets in `.secrets.env` (infra/runtime-wide)
- Per-repository overrides in `.mcp-stack.env` (workspace-scoped)
- Agent profile wiring in `configs/mcp_stack_manifest.json`

## Active MCP Servers (Managed Profiles)

- `mcpx-basic-memory` (stdio, local-first notes/knowledge graph)
- `mcpx-qdrant` (stdio wrapper, semantic memory)
- `mcpx-chroma` (stdio, local persistent vector fallback)
- `mcpx-lsp` (stdio wrapper, symbol-safe navigation/refactor)
- `mcpx-surrealdb-http` (HTTP MCP via local SurrealMCP compat)
- `mcpx-archon-http` (HTTP MCP via local Archon compat)
- `mcpx-docs-mcp-http` (HTTP MCP via local docs-mcp container)

## Source Documentation (Upstream)

- Basic Memory: <https://github.com/basicmachines-co/basic-memory>
- Qdrant MCP: <https://github.com/qdrant/mcp-server-qdrant>
- Chroma MCP: <https://github.com/chroma-core/chroma-mcp>
- MCP Language Server: <https://github.com/isaacphi/mcp-language-server>
- SurrealMCP: <https://github.com/surrealdb/surrealmcp>
- Archon: <https://github.com/coleam00/Archon>
- Docs MCP Server: <https://github.com/arabold/docs-mcp-server>
- Docs MCP config reference: <https://github.com/arabold/docs-mcp-server/blob/main/docs/setup/configuration.md>

## Runtime Secrets (`.secrets.env`)

Use `.secrets.env.example` as the template.

### Shared / Infra

- `MCP_HOST_FS_ROOT`, `MCP_HOST_FS_USERS`
- Surreal runtime:
  - `SURREALDB_ROOT_USER`, `SURREALDB_ROOT_PASS`
  - `SURREALDB_DEFAULT_NS`, `SURREALDB_DEFAULT_DB`
  - `SURREALDB_RPC_PORT`, `SURREALDB_WS_HOST`
  - `SURREALIST_CONNECTION_NAME`
  - `SURREAL_MCP_SERVER_URL`, `SURREAL_MCP_RATE_LIMIT_RPS`, `SURREAL_MCP_RATE_LIMIT_BURST`

### Docs MCP provider/auth keys

- OpenAI:
  - `OPENAI_API_KEY`, `OPENAI_ORG_ID`, `OPENAI_API_BASE`
- Google:
  - `GOOGLE_API_KEY`, `GOOGLE_APPLICATION_CREDENTIALS`
- AWS:
  - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `BEDROCK_AWS_REGION`
- Azure OpenAI:
  - `AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_API_INSTANCE_NAME`
  - `AZURE_OPENAI_API_DEPLOYMENT_NAME`, `AZURE_OPENAI_API_VERSION`
- GitHub scraping auth (private repos / higher limits):
  - `GITHUB_TOKEN` (preferred), `GH_TOKEN` (fallback/alias)
- Runtime mode:
  - `DOCS_MCP_ENABLE_WORKER=true|false` (default `false`, standalone server mode)

### Docs MCP advanced passthrough (`DOCS_MCP_*`)

The stack forwards documented high-signal options for app/server/auth/scraper/splitter/embeddings/db/assembly:
Only non-empty values are forwarded to runtime env to preserve upstream defaults and avoid invalid blank/zero overrides.

- App:
  - `DOCS_MCP_CONFIG`, `DOCS_MCP_STORE_PATH`, `DOCS_MCP_APP_STORE_PATH`
  - `DOCS_MCP_APP_TELEMETRY_ENABLED`, `DOCS_MCP_APP_READ_ONLY`
- Server:
  - `DOCS_MCP_PUBLIC_PORT` (host port, default `16280`)
  - `DOCS_MCP_SERVER_PROTOCOL`, `DOCS_MCP_SERVER_HOST`, `DOCS_MCP_SERVER_HEARTBEAT_MS`
  - `DOCS_MCP_SERVER_PORTS_DEFAULT`, `DOCS_MCP_SERVER_PORTS_WORKER`
  - `DOCS_MCP_SERVER_PORTS_MCP`, `DOCS_MCP_SERVER_PORTS_WEB`
- Auth:
  - `DOCS_MCP_AUTH_ENABLED`, `DOCS_MCP_AUTH_ISSUER_URL`, `DOCS_MCP_AUTH_AUDIENCE`
- Scraper:
  - `DOCS_MCP_SCRAPER_MAX_PAGES`, `DOCS_MCP_SCRAPER_MAX_DEPTH`, `DOCS_MCP_SCRAPER_MAX_CONCURRENCY`
  - `DOCS_MCP_SCRAPER_PAGE_TIMEOUT_MS`, `DOCS_MCP_SCRAPER_BROWSER_TIMEOUT_MS`
  - `DOCS_MCP_SCRAPER_FETCHER_MAX_RETRIES`, `DOCS_MCP_SCRAPER_FETCHER_BASE_DELAY_MS`
  - `DOCS_MCP_SCRAPER_DOCUMENT_MAX_SIZE`
- Splitter:
  - `DOCS_MCP_SPLITTER_MIN_CHUNK_SIZE`, `DOCS_MCP_SPLITTER_PREFERRED_CHUNK_SIZE`, `DOCS_MCP_SPLITTER_MAX_CHUNK_SIZE`
- Embeddings / DB / Assembly:
  - `DOCS_MCP_EMBEDDINGS_BATCH_SIZE`, `DOCS_MCP_EMBEDDINGS_VECTOR_DIMENSION`
  - `DOCS_MCP_DB_MIGRATION_MAX_RETRIES`
  - `DOCS_MCP_ASSEMBLY_MAX_CHUNK_DISTANCE`, `DOCS_MCP_ASSEMBLY_MAX_PARENT_CHAIN_DEPTH`
  - `DOCS_MCP_ASSEMBLY_CHILD_LIMIT`, `DOCS_MCP_ASSEMBLY_PRECEDING_SIBLINGS_LIMIT`, `DOCS_MCP_ASSEMBLY_SUBSEQUENT_SIBLINGS_LIMIT`

### Archon profile

- Required:
  - `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`
- Optional:
  - `HOST`, `LOG_LEVEL`
  - `GITHUB_PAT_TOKEN` (used by Archon runtime env bootstrap)
  - `ARCHON_LLM_PROVIDER`, `ARCHON_MODEL_CHOICE`
  - `ARCHON_EMBEDDING_PROVIDER`, `ARCHON_EMBEDDING_MODEL`
  - `ARCHON_USE_AGENTIC_RAG`, `ARCHON_USE_HYBRID_SEARCH`
  - `ARCHON_USE_RERANKING`, `ARCHON_USE_CONTEXTUAL_EMBEDDINGS`

## Per-Repository Overrides (`.mcp-stack.env`)

These are parsed as strict `KEY=VALUE` lines by wrapper scripts.

### `mcpx-qdrant` wrapper (`scripts/mcpx_qdrant_auto.sh`)

- Collection behavior:
  - `MCP_QDRANT_COLLECTION_MODE=workspace|global|manual`
  - `MCP_QDRANT_COLLECTION=<name>`
- Backend:
  - `QDRANT_URL`, `QDRANT_API_KEY`, `QDRANT_LOCAL_PATH`
- Embeddings/tool hints:
  - `EMBEDDING_PROVIDER`, `EMBEDDING_MODEL`
  - `TOOL_STORE_DESCRIPTION`, `TOOL_FIND_DESCRIPTION`
- FastMCP:
  - `FASTMCP_LOG_LEVEL`, `FASTMCP_DEBUG`
- Debug:
  - `MCP_QDRANT_DRY_RUN=1`

### `mcpx-lsp` wrapper (`scripts/mcpx_lsp_auto.sh`)

- Selection:
  - `MCP_LSP_MODE=auto|python|typescript`
  - `MCP_LSP_PREFERENCE=python|typescript`
  - `MCP_LSP_FALLBACK=python|typescript`
- Binaries:
  - `MCP_LANGUAGE_SERVER_BIN`
  - `MCP_TS_LSP`, `MCP_PY_LSP`
- Logging:
  - `MCP_LSP_LOG_LEVEL` (forwarded to `LOG_LEVEL` for `mcp-language-server`)

## Agent Profile Wiring

`configs/mcp_stack_manifest.json` is the single source for:

- Managed server IDs
- Profile composition (`core`, `core-surreal`, `core-archon`, `full`)
- Per-agent transport wiring (Codex/Claude/OpenCode)

Operational flow:

1. `task infra:up PROFILE=<profile>`
2. `task profile:apply PROFILE=<profile> AGENTS=codex,claude,opencode`
3. `task quality:doctor PROFILE=<profile>`

## Validation Checklist

After any MCP config change:

1. `task infra:up PROFILE=full`
2. `task quality:doctor PROFILE=full`
3. `CODEX_HOME="$HOME/.codex" codex mcp list`
4. `CODEX_HOME="$HOME/.codex-mcp-eval" codex mcp list`
5. `claude mcp list`
6. `opencode mcp list`
