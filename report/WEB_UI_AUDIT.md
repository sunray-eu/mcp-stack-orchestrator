# Web UI Audit and Accessibility Plan

Date: 2026-02-20 14:42:05 CET

## Scope
- Re-checked all evaluated candidates and supplemental tools for documented Web UI availability.
- Applied the same scoring baseline used in the main MCP sweep and attached scores to UI-capable entries.
- Updated runtime implementation so selected UIs and their core features are reachable from a stable local endpoint set.

## UI-Capable Candidate Matrix

| Candidate | Score | UI Type | Default UI | Evaluation | Integration Decision | Notes |
|---|---:|---|---|---|---|---|
| coleam00 Archon | 6.8 | local web app | `http://localhost:3737` | tested | integrated (full/archon) | Primary dashboard + onboarding + MCP config copy flow. |
| SurrealDB MCP | 6.7 | web app (Surrealist) | `https://app.surrealdb.com (or self-hosted Surrealist)` | tested | integrated (full/surreal) | MCP server itself has no dashboard; Surrealist is the DB UI. |
| qdrant mcp-server-qdrant | 7.7 | Qdrant dashboard | `http://localhost:6333/dashboard/` | tested | integrated (core+) | Dashboard comes from Qdrant backend, used by qdrant MCP instances. |
| ardaaltinors MemCP | 5.6 | local + cloud dashboard | `http://localhost:80 (prod docker) / http://localhost:4321 (dev)` | tested | not integrated | Feature-rich but lower reliability and heavier infra/auth complexity. |
| doobidoo mcp-memory-service | 5.4 | dashboard web app | `http://localhost:8000` | tested | not integrated | Dashboard exists; MCP startup reliability was weaker in this environment. |
| arabold docs-mcp-server | 6.2 | management web ui | `http://localhost:6280` | tested | integrated (full/docs) | Web UI, plus MCP endpoints /mcp and /sse. |
| thedotmack claude-mem | 6.2 | web viewer | `http://localhost:37777` | evaluated | not integrated | UI depends on claude-mem worker runtime; plugin-centric. |
| basicmachines basic-memory | 7.8 | cloud web app | `https://basicmemory.com` | tested | not integrated (UI) | Selected MCP server is local-first; cloud UI is optional. |
| getzep graphiti | 6.1 | managed dashboard (Zep) | `https://www.getzep.com` | tested | not integrated | Dashboard belongs to managed Zep platform; OSS Graphiti requires custom ops. |
| Significant-Gravitas AutoGPT | 4.7 | platform frontend | `http://localhost:3000` | evaluated | not integrated | Not a direct Codex MCP server; high ops overhead. |
| HKUDS AutoAgent | 4.6 | GUI mode | `http://localhost:3000` | evaluated | not integrated | Framework with UI, but not a direct MCP coding-context server. |
| westonbrown Cyber-AutoAgent | 3.9 | react terminal + observability ui | `http://localhost:3000` | skipped | not integrated | Archived/high-risk offensive-security focus. |
| ItMeDiaTech rag-cli | 5.3 | enhanced web dashboard | `project-defined (dashboard module)` | evaluated | not integrated | Plugin-centric workflow; not Codex-native MCP-first. |
| SpillwaveSolutions agent-brain | 5.6 | swagger/reDoc API ui | `http://localhost:8000/docs` | evaluated | not integrated | API docs UI available; primarily plugin/server workflow. |
| Docfork | 6.0 | hosted web app | `https://docfork.com/` | evaluated | not integrated | Cloud docs service, not local-first MCP runtime. |

## Live Endpoint Validation (Current Runtime)

| Service | URL | HTTP | Interpretation |
|---|---|---:|---|
| qdrant-api | `http://127.0.0.1:6333/healthz` | 200 | reachable |
| qdrant-dashboard | `http://127.0.0.1:6333/dashboard/` | 200 | reachable |
| archon-api | `http://127.0.0.1:18081/health` | 200 | reachable |
| archon-mcp-health | `http://127.0.0.1:18051/health` | 200 | reachable |
| archon-ui | `http://127.0.0.1:13737` | 200 | reachable |
| surreal-mcp | `http://127.0.0.1:18080/mcp` | 406 | reachable (expected probe result for MCP stream endpoint) |
| surrealdb-rpc | `http://127.0.0.1:18083/rpc` | 400 | reachable (RPC endpoint requires protocol-specific request) |
| surrealist-ui | `http://127.0.0.1:18082` | 200 | reachable |
| docs-mcp-ui | `http://127.0.0.1:16280` | 200 | reachable |
| docs-mcp-mcp | `http://127.0.0.1:16280/mcp` | 405 | endpoint exists; method not allowed for probe request |
| docs-mcp-initialize (POST) | `http://127.0.0.1:16280/mcp` | 200 | MCP initialize succeeds with streamable response |

## Implementation Changes Applied

- Added/normalized runtime containers and ports for UI visibility:
  - Qdrant dashboard via `ai-mcp-qdrant` on `6333`
  - Local SurrealDB via `ai-mcp-surrealdb` on `18083`
  - Archon UI via `ai-mcp-archon-ui` on `13737`
  - Surrealist UI via `ai-mcp-surrealist` on `18082`
  - Docs MCP web UI via `ai-mcp-docs-mcp` on `16280`
- Generated and mounted Surrealist managed config file (`<STACK_ROOT>/tmp/surrealist-instance.json`) so the local SurrealDB connection is present immediately on first load.
- Updated stack infra profile behavior so `core/full` keep UI-relevant services available while MCP endpoints remain reachable.
- Switched managed Qdrant MCP entries from local embedded paths to shared Qdrant server URL (`QDRANT_URL=http://127.0.0.1:6333`) to align MCP behavior with dashboard visibility.
- Added docs-mcp embedding env wiring (`OPENAI_API_KEY`, `DOCS_MCP_EMBEDDING_MODEL`, provider fallbacks) through generated runtime env (`<STACK_ROOT>/tmp/ai-mcp-infra.env`) so vector search is enabled in containerized docs runtime.

## Managed Runtime Endpoints

- Qdrant API: `http://127.0.0.1:6333/healthz`
- Qdrant Dashboard: `http://127.0.0.1:6333/dashboard/`
- Archon UI: `http://127.0.0.1:13737`
- Archon API health: `http://127.0.0.1:18081/health`
- Archon MCP health: `http://127.0.0.1:18051/health`
- Surreal MCP: `http://127.0.0.1:18080/mcp`
- SurrealDB RPC: `http://127.0.0.1:18083/rpc`
- Surrealist UI: `http://127.0.0.1:18082`
- Docs MCP UI: `http://127.0.0.1:16280`
- Docs MCP endpoint: `http://127.0.0.1:16280/mcp`

## Operational Commands

```bash
<STACK_ROOT>/scripts/stack_infra.sh up full
<STACK_ROOT>/scripts/stack_infra.sh status
<STACK_ROOT>/scripts/stack_infra.sh down full
```

## Notes on Non-Integrated UI Tools

- UI-only availability does not imply production MCP suitability; non-integrated tools remain excluded when they are plugin-centric, cloud-heavy, archived, or showed lower reliability in cross-project benchmarks.
- For these tools, the audit preserves exact docs references and decision rationale in `web_ui_candidates.tsv` and the master evaluation report.
