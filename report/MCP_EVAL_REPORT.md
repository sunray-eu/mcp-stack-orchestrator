# MCP Evaluation Report

## Executive Summary

Production rollout and cross-agent standardized profile deployment are documented in `<STACK_ROOT>/report/FINAL_PRODUCTION_RECOMMENDATION.md`.

Fourth-wave expansion is complete: **8 additional repositories** were analyzed and merged into the same scoring pipeline (on top of the previous 17-library wave), with live runtime smoke coverage added for viable MCP entries. The recommendation for correctness + speed + context quality remains:

1. `basicmachines-co/basic-memory`
2. `qdrant/mcp-server-qdrant`
3. `chroma-core/chroma-mcp`

Why this still wins after broader coverage:

- Highest tested scores with stable local-first behavior across both target repos.
- Better reliability than framework/plugin-heavy alternatives that are not Codex-native MCP servers.
- Lower setup friction and lower operational risk than multi-service orchestration stacks.

## Scope and Guardrails

Projects tested:

- TS: `<TS_REPO>`
- PY: `<PY_REPO>`

Safety controls enforced:

- Isolated evaluation home: `CODEX_HOME=/Users/<user>/.codex-mcp-eval`
- Original config retained and backups preserved in `<STACK_ROOT>/backups/`
- Local-first bias; external creds only where local alternatives were not practical

## Fourth-Wave Coverage Added

New **tested** entries:
- `entrepeneur4lyf code-graph-mcp` (tested, 7.2)
- `CodeGraphContext CodeGraphContext` (tested, 5.4)
- `danyQe codebase-mcp` (tested, 4.7)
- `NgoTaiCo mcp-codebase-index` (tested, 4.6)
- `neo4j mcp` (tested, 7.5)

New **evaluated** entries:
- `thakkaryash94 chroma-ui` (evaluated, 3.8)
- `ChrisRoyse CodeGraph` (evaluated, 4.9)
- `ADORSYS-GIS experimental-code-graph` (evaluated, 4.4)

Notes:

- `neo4j/mcp` was validated against local `Neo4j 5.26.19 + APOC` and passed read-only schema smoke (`get-schema`).
- `code-graph-mcp` passed Codex smoke on both TS and PY target repositories (guide + analysis calls).
- `CodeGraphContext`, `codebase-mcp`, and `mcp-codebase-index` all failed MCP initialize handshake in this Codex runtime profile despite startup-path retries.
- `chroma-ui` is useful as a GUI but is not an MCP server candidate.

## Third-Wave Coverage Added

New **tested** entries:
- `getzep graphiti` (tested, 6.1)
- `cbunting99 enhanced-mcp-memory` (tested, 5.8)
- `arabold docs-mcp-server` (tested, 6.2)
- `coleam00 Archon` (tested, 6.8)
- `SurrealDB MCP` (tested, 6.7)

New **evaluated** entries:
- `HKUDS AutoAgent` (evaluated, 4.6)
- `Significant-Gravitas AutoGPT` (evaluated, 4.7)
- `HKUDS RAG-Anything` (evaluated, 5.0)
- `ItMeDiaTech rag-cli` (evaluated, 5.3)
- `SpillwaveSolutions agent-brain` (evaluated, 5.6)
- `Agno docs` (evaluated, 5.2)
- `EvoAgentX` (evaluated, 4.9)
- `thedotmack claude-mem` (evaluated, 6.2)
- `Docfork` (evaluated, 6.0)
- `LlamaIndex MCP examples` (evaluated, 6.1)

New **skipped** entries:
- `westonbrown Cyber-AutoAgent` (skipped, 3.9)
- `Spillwave article` (skipped, 0.0)

Notes:

- `Spillwave article` was not machine-fetchable due Cloudflare/robots restrictions in this environment.
- `graphiti`, `enhanced-mcp-memory`, and `docs-mcp-server` were smoke-tested but showed MCP initialize/handshake instability under this Codex run profile.
- Several additions (`AutoAgent`, `AutoGPT`, `EvoAgentX`, `RAG-Anything`, `Agno docs`, `LlamaIndex MCP examples`) are useful ecosystem components but not direct Codex MCP server candidates.

Focused live validation artifact:

- `<STACK_ROOT>/report/ARCHON_SURREAL_RUNTIME_VALIDATION.md` (full SurrealDB MCP and Archon remote-Supabase run details)

Web UI focused follow-up artifacts:

- `<STACK_ROOT>/report/WEB_UI_AUDIT.md`
- `<STACK_ROOT>/report/web_ui_candidates.tsv`
- `<STACK_ROOT>/report/ui_endpoint_status.tsv`

UI-focused runtime integration update:

- `full` profile now keeps UI-capable services reachable (`qdrant dashboard`, `archon ui`, `surrealist`, `docs-mcp ui`) with live endpoint checks in `stack_infra.sh status`.

## Dataset Status

- Candidate inventory: **65**
- Outcomes rows: **65**
- Status distribution: `tested=45`, `evaluated=15`, `skipped=5`
- Name parity between inventory and outcomes: **1:1**

Smoke dataset snapshot (`<STACK_ROOT>/report/second_wave_smoke.tsv`):

- Rows: `69`
- `setup_ok=true`: `69`
- `exec_ok=true`: `65`
- Strict success (`mcp_calls>0 && mcp_failed==0`): `25`

## Ranked Recommendation

Top tested scores (overall):

1. `basicmachines basic-memory` — `7.8`
2. `qdrant mcp-server-qdrant` — `7.7`
3. `chroma-core chroma-mcp` — `7.6`
4. `er77 code-graph-rag-mcp` — `7.5`
5. `neo4j mcp` — `7.5`
6. `shinpr mcp-local-rag` — `7.4`
7. `MCP servers memory ref` — `7.4`
8. `isaacphi mcp-language-server` — `7.3`
9. `entrepeneur4lyf code-graph-mcp` — `7.2`
10. `doITmagic rag-code-mcp` — `7.1`

Validated but not in default top-3 stack:

- `coleam00 Archon` (`6.8`): strong high-context project/task workflow MCP when you accept heavy setup and remote Supabase dependency.
- `SurrealDB MCP` (`6.7`): robust local MCP runtime with excellent reliability; best treated as an optional backend/tooling layer, not a primary coding-context engine by itself.
- `neo4j mcp` (`7.5`): excellent official graph-query MCP bridge when you need NL-to-Cypher introspection against a maintained Neo4j knowledge graph.

## Category Winners

- Best memory (project/global hybrid): `basicmachines-co/basic-memory`
- Best local semantic retrieval: `qdrant/mcp-server-qdrant`
- Best namespace-ready vector store fallback: `chroma-core/chroma-mcp`
- Best graph/refactor context: `er77/code-graph-rag-mcp`
- Best practical LSP bridge: `isaacphi/mcp-language-server`
- Best docs-context (local-first candidate): `arabold/docs-mcp-server` (feature-strong, but startup reliability needs tuning)
- Best high-context workflow stack (if you accept heavy setup): `coleam00/Archon`
- Best non-MCP process method: `BMAD-METHOD`

## Security and Reliability Findings

From updated static + runtime artifacts:

- `45/56` GitHub candidates mention outbound remote service usage in docs/code signals.
- `40/56` mention API-key/token style credential flows.
- `3/56` include explicit `postinstall` scripts.
- `13/56` include non-trivial `prepare` scripts.
- Handshake fragility remains the largest runtime failure mode for lower-ranked MCPs.

High-signal issues in the added wave:

- `getzep/graphiti`: rich MCP surface but initialize closed in current smoke path.
- `cbunting99/enhanced-mcp-memory`: repeated startup timeout during MCP initialize.
- `arabold/docs-mcp-server`: active/feature-rich, but timed out in Codex MCP startup handshake in this test path.
- `coleam00/Archon`: compelling MCP concept with successful live validation, but high setup burden (Supabase + multi-service stack) and key format compatibility risk (requires legacy `service_role` JWT for current Python client path).

## What Changed Results Most

1. Distinguishing direct Codex-usable MCP servers from broader agent frameworks/plugins prevented false “high” rankings for non-direct integrations.
2. Applying strict runtime interpretation (`mcp_failed==0`) highlighted reliability gaps hidden by optimistic smoke `exec_ok` flags.
3. Maintenance quality alone (stars/activity) did not translate to coding utility when setup friction and MCP handshake reliability were weak.

## Recommended Final Configuration

Default (fast + stable):

- `basic-memory` + `qdrant` (global + per-project collections)
- `lsp-py` enabled by default
- TS LSP and graph/RAG-heavy servers on demand

```toml
[mcp_servers.basic-memory-global]
command = "uvx"
args = ["basic-memory", "mcp"]
startup_timeout_sec = 90

[mcp_servers.basic-memory-global.env]
BASIC_MEMORY_FORCE_LOCAL = "true"

[mcp_servers.qdrant-global]
command = "uvx"
args = ["mcp-server-qdrant"]
startup_timeout_sec = 120

[mcp_servers.qdrant-global.env]
COLLECTION_NAME = "global"
EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
QDRANT_URL = "http://127.0.0.1:6333"

[mcp_servers.qdrant-project-a]
command = "uvx"
args = ["mcp-server-qdrant"]
startup_timeout_sec = 120

[mcp_servers.qdrant-project-a.env]
COLLECTION_NAME = "ts-repo"
EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
QDRANT_URL = "http://127.0.0.1:6333"

[mcp_servers.qdrant-project-b]
command = "uvx"
args = ["mcp-server-qdrant"]
startup_timeout_sec = 120

[mcp_servers.qdrant-project-b.env]
COLLECTION_NAME = "py-repo"
EMBEDDING_MODEL = "sentence-transformers/all-MiniLM-L6-v2"
QDRANT_URL = "http://127.0.0.1:6333"

[mcp_servers.lsp-py]
command = "/Users/<user>/go/bin/mcp-language-server"
args = ["--workspace", "<PY_REPO>", "--lsp", "/opt/homebrew/bin/pyright-langserver", "--", "--stdio"]
startup_timeout_sec = 90
```

Optional on-demand additions:

- `er77/code-graph-rag-mcp` for impact/refactor analysis sessions
- `entrepeneur4lyf/code-graph-mcp` for local structural graph/context analysis with low setup friction
- `neo4j/mcp` for NL-to-Cypher graph introspection when a Neo4j+APOC knowledge graph is already part of your workflow
- `doITmagic/rag-code-mcp` when local Ollama + Qdrant pipeline is active
- `coleam00/Archon` for high-context project/task/doc workflow sessions (remote Supabase + Docker stack required)
- `surrealdb/surrealmcp` when you need robust local MCP-backed data operations or a custom memory backend

Integrated optional production profiles in the orchestrator:
- `core-code-graph`, `full-code-graph` (code-graph add-on)
- `core-neo4j`, `full-neo4j`, `full-graph` (Neo4j graph-query add-on, read-only by default)

Required env var names (only):

- `BASIC_MEMORY_FORCE_LOCAL`
- `QDRANT_URL`
- `COLLECTION_NAME`
- `EMBEDDING_MODEL`
- `SUPABASE_URL` (Archon optional profile)
- `SUPABASE_SERVICE_KEY` (Archon optional profile; legacy JWT-style `service_role` key currently required by tested runtime path)

## Restore / Rollback

One-command restore:

```bash
bash <STACK_ROOT>/scripts/restore_original.sh <backup_dir>
```

If `<backup_dir>` is omitted, the script falls back to `<STACK_ROOT>/.latest-backup-path` when available.

## Full Comparison Table

| Candidate | Category | Status | Score | Decision summary |
|---|---|---|---:|---|
| shinpr mcp-local-rag | memory-rag | tested | 7.4 | Strong local RAG quality; first-run handshake timeout required startup_timeout tuning; no native namespace isolation. |
| yikizi mcp-local-rag | memory-rag | tested | 7.0 | Global npm install path worked with stable status tool calls; overlaps shinpr feature set but usable. |
| chroma-core chroma-mcp | memory-rag | tested | 7.6 | Fast and reliable local persistent vector store with collection namespaces; broad embedding support. |
| marlian claude-qdrant-mcp | memory-rag | skipped | 5.8 | Unofficial Qdrant wrapper; intentionally not tested further because official qdrant server is available and preferred. |
| mhalder qdrant-mcp-server | memory-rag | skipped | 6.2 | Reasonable project but redundant with official qdrant server tested successfully. |
| doITmagic rag-code-mcp | memory-rag | tested | 7.1 | After local Ollama+Qdrant setup, MCP tools were discoverable and callable; docs search needs extra local config. |
| joinQuantish codebase-rag | memory-rag | tested | 4.8 | Built/tested in multiple command variants but MCP initialize consistently closed during handshake. |
| qdrant mcp-server-qdrant | memory-rag | tested | 7.7 | Official implementation; reliable cross-project retrieval and now dashboard-visible via shared `QDRANT_URL`. |
| er77 code-graph-rag-mcp | memory-rag | tested | 7.5 | Source build succeeded and rich graph/semantic toolset worked; strong context quality at moderate setup cost. |
| MCP servers memory ref | memory | tested | 7.4 | Simple persistent memory graph; very low setup friction; no project namespace isolation by default. |
| memory-graph | memory | tested | 6.8 | Local memory graph server started and read/status calls worked; broader feature surface than basic-memory. |
| puliczek mcp-memory | memory | tested | 6.2 | Cloudflare remote endpoint worked in authenticated mode; transport/auth variants were sensitive and not fully local-first. |
| basicmachines basic-memory | memory | tested | 7.8 | Best memory UX for coding notes; supports project-scoped operations; local-first with optional cloud. |
| ardaaltinors MemCP | memory | tested | 5.6 | Local infra and MCP endpoint can run, but auth/API-key flow returned 500 locally and authenticated tool calls were high-latency. |
| MemCP website | memory | skipped | 0.0 | Not an MCP server repository; informational website only. |
| doobidoo mcp-memory-service | memory | tested | 5.4 | Feature-rich but stdio and HTTP startup handshakes repeatedly failed in this environment. |
| st3v3nmw sourcerer-mcp | repo-search | tested | 6.8 | Server starts cleanly and status tool works with real key path; useful semantic search pending indexing. |
| tecnomanu pampa | memory | tested | 5.1 | Attempted default and Node22 paths; MCP initialize closed during handshake. |
| Wildcard deepcontext-mcp | repo-search | tested | 6.9 | Local and credentialed runs both exposed working status/search tools; requires indexing step for real value. |
| jbenshetler mcp-ragex | repo-search | tested | 6.3 | Feature-rich tool surface, but MCP discovery was flaky and daemon/status behavior was inconsistent. |
| adam-hanna semantic-search-mcp | repo-search | tested | 6.7 | Local startup and status calls were stable; practical repo semantic search primitive. |
| oculairmedia Letta-MCP-server | memory-agent | tested | 6.4 | Local Letta deployment plus log-tuning produced stable tool discovery; heavier infra and operational complexity. |
| esxr langgraph-mcp | workflow | evaluated | 5.0 | Local-first runtime tested deeply: default deps fail (`langchain.chains` missing under langchain 1.x), but local boot succeeds after compatibility pin (`langchain<1` + `langchain-community`). Still an MCP-client orchestration template, not a standalone Codex MCP server. |
| ceorkm kratos-mcp | memory | tested | 6.6 | Status and memory tools are available; full behavior depends on project/storage initialization. |
| pi22by7 In-Memoria | memory | tested | 7.0 | With real credentials, health/status calls succeeded and broad intelligence toolset was exposed. |
| eslint MCP docs | linting | tested | 4.8 | Official and easy setup but failed on TS repo (`scopeManager.addGlobals`), and not useful for Python repo. |
| tuannvm codex-mcp-server | wrapper | tested | 4.5 | Works, but wraps Codex inside Codex (extra latency and recursion risk) with limited net coding benefit. |
| lastmile-ai mcp-agent | workflow | tested | 4.4 | `mcp-agent dev serve` and minimal script modes repeatedly timed out or closed during initialize. |
| nosolosoft opencode-mcp | wrapper | tested | 5.2 | Server health and tool listing worked, but it is still a wrapper layer with overlap and added risk. |
| teabranch agentic-developer-mcp | workflow | tested | 5.4 | Source server started and tools worked, but orchestration focus offers limited direct context benefit. |
| Tritlo lsp-mcp | lsp | tested | 5.2 | Both npm and source-build variants failed MCP initialize handshake in this environment. |
| uplinq mcp-typescript | lsp | tested | 4.2 | Startup crashes with completion capability mismatch; not stable for production Codex use. |
| mizchi lsmcp | lsp | tested | 6.6 | TypeScript-focused LSP bridge exposed rich tools and capability checks successfully. |
| isaacphi mcp-language-server | lsp | tested | 7.3 | Excellent context quality when configured with direct language-server binaries; setup friction and TS timeout risk. |
| mseep lsp-mcp | lsp | tested | 5.0 | Repeated handshake timeouts in discovery calls. |
| jonrad lsp-mcp | lsp | tested | 5.1 | Handshake timeouts in this environment despite reasonable project maturity. |
| Stryk91 lsp-mcp-rs | lsp | tested | 4.6 | Server process starts but transport closes before usable MCP interaction. |
| beixiyo vsc-lsp-mcp | lsp | tested | 4.8 | VSCode extension architecture; standalone run outside VSCode host closed handshake. |
| alexwohletz language-server-mcp | lsp | tested | 5.0 | Source build and local binary checks passed, but MCP initialize response closed repeatedly. |
| BMAD-METHOD | method | evaluated | 6.5 | Useful non-MCP process framework for planning/review; not a direct MCP runtime tool. |
| HKUDS AutoAgent | workflow-framework | evaluated | 4.6 | General autonomous-agent framework, not a Codex MCP server; heavy credential footprint and broad execution surface reduce local coding utility. |
| Significant-Gravitas AutoGPT | workflow-framework | evaluated | 4.7 | Large agent platform with strong maintenance, but not a direct MCP server for Codex and high setup/ops overhead. |
| westonbrown Cyber-AutoAgent | workflow-framework | skipped | 3.9 | Archived offensive-security agent project; not MCP-first and out-of-scope/high-risk for normal coding workflows. |
| HKUDS RAG-Anything | rag-framework | evaluated | 5.0 | Active multimodal RAG framework but not an MCP server; useful concepts, limited direct Codex integration value. |
| getzep graphiti | memory-graph | tested | 6.1 | Includes experimental MCP server with rich graph memory features; strong project health but handshake/setup friction remained in this Codex environment. |
| ItMeDiaTech rag-cli | workflow-plugin | evaluated | 5.3 | Claude plugin with optional MCP component; productivity-focused but plugin-centric and not cleanly Codex-native. |
| Spillwave article | method | skipped | 0.0 | Article page could not be fetched due Cloudflare/robots restrictions in this environment. |
| SpillwaveSolutions agent-brain | workflow-plugin | evaluated | 5.6 | RAG system centered on Claude plugin commands; promising architecture but not a direct Codex MCP-first workflow. |
| Agno docs | method | evaluated | 5.2 | Agent framework documentation only (not an MCP server candidate), useful for orchestration patterns. |
| EvoAgentX | workflow-framework | evaluated | 4.9 | Self-evolving agent framework, not a Codex MCP server; requires broader model/tool orchestration beyond this benchmark focus. |
| coleam00 Archon | memory-workflow | tested | 6.8 | Fully validated with remote Supabase bootstrap and live MCP operations (health/session/project create-delete); high context utility but heavy setup and key compatibility friction (requires legacy service_role JWT, not sb_secret). |
| thedotmack claude-mem | memory-plugin | evaluated | 6.2 | Popular persistent-memory plugin with MCP tools, but integration is primarily Claude-plugin oriented rather than direct Codex MCP setup. |
| SurrealDB | memory-backend | tested | 6.7 | Official Surreal MCP validated in both stdio and HTTP modes with deep CRUD/query checks (0 MCP failures); strong local reliability, moderate coding-context impact unless used as a backing memory store. |
| cbunting99 enhanced-mcp-memory | memory | tested | 5.8 | Feature-rich MCP memory server and easy uvx launch, but repeated initialize handshake timeouts reduced reliability score. |
| arabold docs-mcp-server | docs-context | tested | 6.2 | Strong grounded-docs concept with active maintenance and local modes; in-session Codex handshake timeouts prevented stable tool execution. |
| Docfork | docs-context | evaluated | 6.0 | MCP docs-context SaaS with good freshness claims, but cloud-first service and limited local/offline control lower risk-adjusted score. |
| LlamaIndex MCP examples | method | evaluated | 6.1 | Useful MCP integration examples and client patterns, but reference docs rather than a standalone server candidate. |
| thakkaryash94 chroma-ui | method-ui | evaluated | 3.8 | Helpful Chroma GUI for humans, but not an MCP server and not directly useful for Codex MCP routing. |
| danyQe codebase-mcp | repo-assistant | tested | 4.7 | Interesting architecture, but initialize handshake failed in this environment and backend+proxy dual-process setup adds friction. |
| NgoTaiCo mcp-codebase-index | repo-search | tested | 4.6 | Relevant idea, but handshake failed repeatedly; default path requires Gemini + Qdrant API credentials. |
| entrepeneur4lyf code-graph-mcp | repo-graph | tested | 7.2 | Clean local-first MCP with successful smoke calls on both TS and PY targets; strong optional structural analysis add-on. |
| CodeGraphContext CodeGraphContext | repo-graph | tested | 5.4 | Rich graph capabilities, but startup path was protocol-incompatible for stable Codex MCP handshake in this run profile. |
| ChrisRoyse CodeGraph | repo-graph-platform | evaluated | 4.9 | Analyzer platform with MCP-adjacent module; bundled MCP implementation is not production-ready for Codex workflows. |
| ADORSYS-GIS experimental-code-graph | repo-graph-platform | evaluated | 4.4 | Experimental fork with lower maintenance activity and no stable Codex-ready MCP distribution path. |
| neo4j mcp | graph-db | tested | 7.5 | Official Neo4j MCP passed local read-only schema smoke cleanly; excellent graph bridge when Neo4j+APOC infra is justified. |
