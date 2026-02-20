# Archon + SurrealDB Runtime Validation

Date: 2026-02-20

## Scope
- SurrealDB MCP: `https://surrealdb.com/mcp`
- Archon MCP: `https://github.com/coleam00/Archon`
- Supabase project used for Archon: `gydtkaqliotvwasgyubw` (`ai-mcp-archon`, previously `mcp-eval-archon`)

## Latest Runtime Update (2026-02-20, post-interruption)

- Archon was revalidated using direct MCP tools in this session (not only raw HTTP scripts):
  - retrieval calls (`rag_get_available_sources`, `rag_search_knowledge_base`, `rag_search_code_examples`)
  - workflow CRUD (`manage_project`, `manage_task`, `manage_document`, `find_*`)
- Orchestrator `archon` startup path now actively syncs model/embedding/rag settings on every `up archon`:
  - `LLM_PROVIDER`, `MODEL_CHOICE`, `EMBEDDING_PROVIDER`, `EMBEDDING_MODEL`
  - `USE_AGENTIC_RAG`, `USE_HYBRID_SEARCH`, `USE_RERANKING`, `USE_CONTEXTUAL_EMBEDDINGS`
- Archon MCP runtime now includes `archon-mcp-compat` on `:18051` with native Archon MCP on `:18052`:
  - normalizes headers/content-type for strict MCP clients
  - auto-recovers stale/uninitialized session flows by bootstrap+retry
  - verified in-session by successful `mcpx-archon-http` tool calls
- Verified after restart that Archon credentials hold:
  - `MODEL_CHOICE=gpt-5.2`
  - `EMBEDDING_MODEL=text-embedding-3-large`
- SurrealDB MCP is now fixed end-to-end in-session:
  - stale MCP session IDs are recovered by a local compatibility proxy (`surrealmcp-compat`)
  - OAuth authorization-server probe paths now return proper JSON metadata + `Content-Type`
  - runtime pinned to SurrealDB `2.3.10` compatibility image (SurrealDB `3.0.0` caused WS subprotocol mismatch with current SurrealMCP)
  - real MCP tool calls succeeded (`connect_endpoint`, `use_namespace`, `use_database`, `create`, `select`, `update`, `query`, `disconnect_endpoint`)
  - Surrealist UI (`127.0.0.1:18082`) query execution confirms visible local data

## SurrealDB MCP (Official)

### What was validated
- Stdio transport server startup and tool discovery.
- HTTP transport server startup (`/mcp`) and tool discovery.
- Deep functional lifecycle in both transports:
  - `connect_endpoint(memory)`
  - namespace + database selection
  - `create` / `select` / `update` / `delete`
  - `query` verification after delete

### Results
- Stdio smoke: `setup_ok=true`, `exec_ok=true`, `mcp_calls=4`, `mcp_failed=0`
  - run id: `S1_surrealmcp_stdio`
- HTTP smoke: `setup_ok=true`, `exec_ok=true`, `mcp_calls=4`, `mcp_failed=0`
  - run id: `S1_surrealmcp_http`
- Deep stdio test: `mcp_calls=16`, `mcp_failed=0`
  - log: `<STACK_ROOT>/logs/codex/S1_surrealmcp_deep.jsonl`
- Deep HTTP test: `mcp_calls=14`, `mcp_failed=0`
  - log: `<STACK_ROOT>/logs/codex/S1_surrealmcp_http_deep.jsonl`

### Notes
- Cloud-organization tools require auth token; local functional mode works without cloud auth.
- Practical coding-context gain is moderate unless Surreal is used as a backing store for memory/RAG workflows.

## Archon MCP (Remote Supabase)

### Infra/bootstrap work completed
- Created dedicated Supabase project via MCP.
- Applied full Archon `migration/complete_setup.sql` by sectioned migrations (`section_01`..`section_13`).
- Verified resulting schema:
  - 11 Archon tables created (`archon_*`)
  - search functions (`match_*`, `hybrid_search_*`) present

### Key compatibility finding
- `sb_secret_*` key failed Archon startup with `Invalid API key`.
- Archon Python client path required legacy JWT-style `service_role` key.
- Retrieved `service_role` key from Supabase Management API using account token and restarted successfully.

### Runtime validation
- MCP smoke at `http://127.0.0.1:18051/mcp`:
  - `setup_ok=true`, `exec_ok=true`, `mcp_calls=2`, `mcp_failed=0`
  - run id: `S1_archon_mcp_remote`
- Deep MCP workflow:
  - `health_check` and `session_info` succeeded
  - created project `ai-mcp-archon-temp`, verified via list call, deleted it
  - `mcp_calls=16`, `mcp_failed=0`
  - log: `<STACK_ROOT>/logs/codex/S1_archon_mcp_remote_deep.jsonl`

### Notes
- Setup friction is high (multi-container build + remote Supabase + key format caveat).
- Once configured correctly, tool quality and context surface are strong.

## Verdict (Worth It?)

- SurrealDB MCP: technically solid and reliable, but best as an optional backend layer, not a top standalone coding-context accelerator.
- Archon MCP: worth setting up if you want deep project/task/doc/RAG workflow and accept higher setup and ops complexity; orchestrator sync automation now reduces drift and operational mistakes.

## Artifacts
- Smoke matrix: `<STACK_ROOT>/report/second_wave_smoke.tsv`
- Main ranking/report: `<STACK_ROOT>/report/MCP_EVAL_REPORT.md`
- Outcomes table: `<STACK_ROOT>/report/candidate_outcomes.tsv`
