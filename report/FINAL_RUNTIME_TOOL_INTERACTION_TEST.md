# Final Runtime Tool Interaction Test

Date: 2026-02-20  
Profile under test: `full`  
Scope: runtime validation of active production stack MCPs in this session.

## Stack Under Test

- `mcpx-basic-memory`
- `mcpx-qdrant`
- `mcpx-chroma`
- `mcpx-lsp`
- `mcpx-surrealdb-http`
- `mcpx-archon-http`

Infra/runtime endpoints validated before/after tests:
- Qdrant API + dashboard
- Archon API + MCP + UI
- SurrealDB + Surreal MCP + Surrealist UI
- Docs MCP UI

## Method

1. Direct MCP tool calls in this session for feature coverage.
2. Cross-tool integration flows (memory -> retrieval -> workflow documenting).
3. Stress/perf sampling on runtime endpoints and vector operations.
4. Cleanup verification for temporary test artifacts.

Data artifacts:
- `report/data/final_runtime_feature_matrix.tsv`
- `report/data/final_runtime_perf.tsv`
- `report/data/final_runtime_tool_fit.tsv`
- `report/data/post_interrupt_mcp_validation.tsv`
- Historical support metrics: `report/data/codex_exec_metrics.tsv`, `report/data/codex_tool_metrics.tsv`

## Coverage Summary

Feature status counts from runtime matrix:
- `pass`: 70
- `pass_with_limit`: 3
- `fail_expected`: 5
- `fail`: 3

Interpretation:
- Core stack is functionally usable end-to-end.
- Most failures are known/expected constraints (missing auth, local backend limitations, invalid test inputs).
- Three actionable reliability/quality defects were reproduced and should guide tool selection.

## Post-Interruption Revalidation (2026-02-20)

Additional direct MCP checks were executed after model/alignment fixes:
- Archon direct MCP calls were rerun in-session (`rag_get_available_sources`, `rag_search_knowledge_base`, `rag_search_code_examples`, project/task/document create/list/delete).
- Archon orchestrator sync was verified by restarting `archon` profile and confirming all expected credentials were auto-synced:
  - `LLM_PROVIDER=openai`
  - `MODEL_CHOICE=gpt-5.2`
  - `EMBEDDING_PROVIDER=openai`
  - `EMBEDDING_MODEL=text-embedding-3-large`
  - `USE_AGENTIC_RAG=true`
  - `USE_HYBRID_SEARCH=true`
  - `USE_RERANKING=true`
  - `USE_CONTEXTUAL_EMBEDDINGS=true`
- Surreal and Archon MCP adapters were revalidated and fixed in this session:
  - `mcpx-surrealdb-http` now passes by connecting to SurrealDB via docker DNS endpoint `http://surrealdb:8000` (from MCP container context).
  - `mcpx-archon-http` now passes through `archon-mcp-compat` on `:18051` (native Archon MCP on `:18052`), which normalizes bootstrap/session/content-type edge-cases.

## Key Findings by Tool

### 1) `mcpx-lsp`
- Strength: best source-of-truth code navigation and symbol correctness for active coding.
- Validation: TS and PY startup probes succeeded; historical definition tasks are passing.
- Caveat: warmup cost exists, especially for large TS workspaces.

### 2) `mcpx-qdrant`
- Strength: fastest semantic recall for snippets/decisions; strong companion to LSP.
- Validation: store/find successful; stress search p95 ~3.3ms.
- Defect: metadata payload rejected by wrapper schema in current runtime (text-only path reliable).

### 3) `mcpx-basic-memory`
- Strength: robust durable project notes and narrative memory; great for long-horizon context.
- Validation: CRUD/edit/search/context/canvas/project lifecycle all exercised.
- Defect: `fetch` appears bound to `main` and fails for non-main project entities.

### 4) `mcpx-chroma`
- Strength: stable local vector fallback with metadata filtering and lifecycle operations.
- Validation: create/add/query/filter/update/rename/delete all succeeded.
- Limitation: `fork_collection` not implemented on local backend.

### 5) `mcpx-archon-http`
- Strength: workflow system (projects/tasks/documents/versions) with good operational UX.
- Validation:
  - full lifecycle calls passed; restore/version flows verified.
  - revalidation passed via direct MCP tools in this session (not HTTP-only scripting).
  - post-restart sync validation proved model/provider settings are consistently enforced by orchestrator.
  - direct `health_check`, `session_info`, and RAG source/tool calls now succeed through compatibility endpoint `http://127.0.0.1:18051/mcp`.
- Limits:
  - RAG calls return empty until sources are ingested.
  - Invalid page fetch returns backend 500 (needs better error handling upstream).
  - Upload validator can reject `.toml`/`.json` MIME types depending on endpoint/parser path.

### 6) `mcpx-surrealdb-http`
- Strength: expressive structured operations (create/insert/select/update/upsert/delete/query/relate) when tool transport is healthy.
- Validation:
  - Surreal MCP server and SurrealDB backend are healthy.
  - direct MCP tool calls in this session passed (`connect_endpoint`, `create`, `select`, `query`) after using endpoint `http://surrealdb:8000` (container DNS).
  - data was verified in Surrealist UI.
- Reliability issue observed:
  - Surreal MCP can return `429 Rate limit exceeded` under burst interactions; keep backoff in place for high-volume calls.
- Cloud API operations correctly failed without auth token (expected).

## Cross-Tool Interaction Tests

### Flow A: Memory -> Retrieval -> Workflow
- `basic-memory` note created/read/edited.
- distilled text stored to `qdrant` and retrieved by semantic query.
- retrieved output captured in `chroma` and ranked correctly.
- summary persisted as Archon document in a temporary project.
- cleanup completed.

Result: pass.

### Flow B: Workspace-aware dynamic behavior
- `mcpx-qdrant` wrapper dry-run proved automatic collection mapping by workspace slug for TS/PY repos.
- `mcpx-lsp` wrapper probe confirmed language server auto selection and workspace derivation.

Result: pass.

## Performance and Stress Results

Source: `report/data/final_runtime_perf.tsv`

Highlights:
- Qdrant API health p95: ~2.4ms
- Archon API health p95: ~5.3ms
- Archon MCP health p95: ~23.3ms
- Surreal MCP health p95: ~2.6ms (outside burst condition)
- Qdrant vector stress:
  - upsert batches (100x5) avg ~3.9ms
  - search x100 avg ~2.8ms, p95 ~3.3ms
- SurrealDB SQL probe:
  - 0/50 success with tested auth flow in this probe (fast failures)

Refresh loop (`label=refresh_20260220-184129`) was executed after compatibility fixes:
- Qdrant API health p95: ~15.3ms
- Archon API health p95: ~7.6ms
- Archon MCP health p95: ~42.8ms
- Archon MCP direct tool-call (health_check) p95: ~29.4ms
- Surreal MCP initialize p95: ~3.3ms
- Qdrant vector stress:
  - upsert batches (100x10) avg ~3.4ms, p95 ~6.1ms
  - search x200 avg ~1.6ms, p95 ~2.2ms

Notes:
- Endpoint health latencies are strong.
- Archon MCP latency is predictably higher than plain health probes because tool-call path includes MCP bootstrap/session handling.
- Throughput bottleneck was not raw endpoint speed; it was Surreal MCP rate-limiting/transport behavior during heavy tool bursts.

## What To Use For What (Final)

Use this routing order by task type:

1. Code navigation/refactor correctness: `mcpx-lsp` first.
2. Quick semantic recall during coding: `mcpx-qdrant`.
3. Durable decision logs and project memory: `mcpx-basic-memory`.
4. Local vector fallback / metadata retrieval experiments: `mcpx-chroma`.
5. Task/project/document/version governance: `mcpx-archon-http`.
6. Structured graph/record workflows and custom SurrealQL: `mcpx-surrealdb-http` (with burst/backoff guardrails).

## Reliability Guardrails (Recommended)

1. Keep `core` as default for active coding loops; use `full` when workflow/context depth is needed.
2. Add client-level retry/backoff for Surreal MCP to avoid 429 burst failures.
3. For `mcpx-surrealdb-http`, use docker DNS endpoint `http://surrealdb:8000` when calling `connect_endpoint` from the MCP server context.
4. Prefer `search_notes/read_note` over `fetch` for non-main basic-memory projects until fetch behavior is fixed.
5. Use `qdrant` text-store path or patch wrapper metadata schema before relying on metadata filters.
6. Treat Archon RAG as opt-in: ingest sources before expecting useful retrieval.

## Conclusion

The full stack is production-usable and provides clear role separation:
- `LSP + Qdrant + Basic-memory` is the highest-value fast loop.
- `Archon` adds high-value workflow memory/traceability and is now safer to operate due startup auto-sync of model/provider settings.
- `Archon` compatibility endpoint (`archon-mcp-compat`) is required for strict clients that call tools before initialize.
- `Chroma` is a reliable local fallback.
- `SurrealDB MCP` is now stable in this stack with compatibility + version pinning; keep burst/backoff guardrails.
