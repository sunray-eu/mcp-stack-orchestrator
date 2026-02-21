# Research-Grade Final Report: MCP Stack Evaluation, Hardening, and Post-Evaluation Normalization

Date: 2026-02-21
Authoring mode: reproducible engineering study
Scope: end-to-end MCP evaluation + productionization + cleanup/archival controls

## Abstract

This report presents a structured, reproducible evaluation of MCP servers and agent-integration pathways under a security-first local-development posture. The study covers candidate discovery, static risk analysis, runtime validation, dual-language project applicability, final stack synthesis, stress testing, and post-evaluation normalization. The resulting production profile is a layered MCP architecture centered on `basic-memory`, `qdrant`, `chroma`, `lsp`, and optional workflow/graph extensions (`Archon`, `SurrealDB`, `code-graph`, `neo4j/mcp`) behind compatibility guards. Final operational integrity remained intact after cleanup: runtime doctor checks returned `PASS=36, WARN=0, FAIL=0`.

## 1. Research Questions

1. Which MCP tools improve coding correctness and context quality with acceptable operational risk?
2. Can one global (non-project-hardcoded) setup support both TS and Python repositories effectively?
3. What compatibility hardening is required for reliable multi-client operation (Codex/Claude/OpenCode)?
4. How can evaluation residue be cleaned and archived without disrupting production MCP runtime?

## 2. Experimental Design

### 2.1 Projects Under Test

To comply with confidentiality constraints, the benchmarked codebases are anonymized:
- **TS-Repo-A**
- **PY-Repo-B**

Both were used for comparative validation and dynamic workspace routing checks.

### 2.2 Candidate Universe and Coverage

Candidate inventory outcomes (from `report/data/candidate_outcomes.tsv`):
- total entries: `65`
- `tested`: `45`
- `evaluated` (non-MCP / workflow frameworks): `15`
- `skipped` (unsupported/unsafe/non-actionable): `5`

### 2.3 Scoring Model

Each candidate was scored on a 0–10 scale under weighted criteria:
- correctness impact
- context/navigation quality
- security posture
- setup friction
- maintenance health

Empirical mean score across all entries: `5.651`.

Top observed scores:
1. `basic-memory` (`7.8`)
2. `qdrant mcp-server-qdrant` (`7.7`)
3. `chroma-mcp` (`7.6`)
4. `code-graph-rag-mcp` (`7.5`) and `neo4j/mcp` (`7.5`)

## 3. Methodological Controls

### 3.1 Safety Controls

- isolated evaluation home and controlled MCP configs
- startup/runtime verification before any scoring
- strict “untrusted code until inspected” posture for third-party MCP candidates
- staged rollout with backup/restore before global config mutations

### 3.2 Reproducibility Controls

- deterministic script entrypoints via Taskfile wrappers
- machine-readable data under `report/data/*.tsv`
- archived runtime artifacts and checksum manifests
- post-change health validation (`task quality:doctor PROFILE=full`)

## 4. Runtime Hardening Results

### 4.1 Compatibility Hardening Achievements

#### SurrealDB MCP

Issue class:
- transport/session fragility across client initialization patterns
- endpoint confusion between host-loopback and container-network context

Mitigation:
- compatibility proxy (`surrealmcp-compat`) as stable frontend endpoint
- docker DNS endpoint usage for DB connectivity from MCP context (`http://surrealdb:8000`)
- SurrealDB pinned to `2.3.x` line pending v3 MCP compatibility maturity

Result:
- direct in-session MCP CRUD/query calls succeeded
- Surrealist UI verified local data visibility

#### Archon MCP

Issue class:
- strict streamable-http client edge cases (tools call before session bootstrap)

Mitigation:
- compatibility sidecar (`archon-mcp-compat`) on public endpoint
- native Archon MCP moved behind internal upstream endpoint
- auto-bootstrap/session normalization and content-type normalization

Result:
- in-session direct MCP tool calls (`health_check`, `session_info`, retrieval calls) succeeded consistently

### 4.2 Stress Refresh (Fresh Run)

Fresh label: `refresh_20260220-184129` (appended via `task quality:stress`)

Key results (from `report/data/final_runtime_perf.tsv`):
- qdrant API probe p95: `15.281 ms`
- archon API probe p95: `7.574 ms`
- archon MCP health probe p95: `42.827 ms`
- archon MCP tool-call p95: `29.447 ms`
- surreal MCP initialize p95: `3.257 ms`
- qdrant upsert (100x10) p95: `6.078 ms`
- qdrant search (200 req) p95: `2.200 ms`

Interpretation:
- direct MCP tool-call path introduces expected overhead beyond plain health probes
- retrieval/vector workloads remained fast and stable
- compatibility layers preserved availability under mixed client behavior

## 5. Final Production Recommendation (Reasoned)

### 5.1 Default and Extended Profiles

- **Default (`core`)**: `basic-memory + qdrant + chroma + lsp`
- **Extended (`full`)**: `core + Archon + SurrealDB + docs UI/runtime`
- **Optional graph profiles**: `core-code-graph`, `full-code-graph`, `core-neo4j`, `full-neo4j`, `full-graph`

Reasoning:
- default path optimizes coding speed/correctness ratio
- extended path enables richer governance, memory graph, structured workflows, and operational dashboards

### 5.2 Tool-to-Task Allocation

- Symbol correctness/refactors: `mcpx-lsp`
- Fast semantic recall: `mcpx-qdrant`
- Durable engineering memory: `mcpx-basic-memory`
- Local vector fallback and filtering: `mcpx-chroma`
- Workflow/project/document governance: `mcpx-archon-http`
- Structured record/graph operations: `mcpx-surrealdb-http`
- Structural code graph analysis: `mcpx-code-graph` (optional)
- Graph database schema/query reasoning: `mcpx-neo4j` (optional, read-only default)

### 5.3 Why Not “Always Use Everything Equally”

A single undifferentiated tool path increases latency and ambiguity. The measured evidence supports **task-based routing** rather than symmetric tool use, preserving speed for tight coding loops while retaining high-context options when required.

## 6. Post-Evaluation Cleanup and Archival (Completed)

### 6.1 Branch Cleanup in Evaluated Repositories

- TS-Repo-A: temporary evaluation branch removed; repository on clean `main`
- PY-Repo-B: temporary evaluation branch removed; repository on clean `main`

### 6.2 Full Backup Completed

Backup root:
- `/Users/marosvarchola/mcp-eval/backups/final-cleanup-20260220-190126`

Includes:
- full Git bundles for TS/PY/orchestrator repos
- AI agent configs (Codex eval/global, Claude, OpenCode)
- archived evaluation evidence
- SHA-256 integrity manifests

### 6.3 Legacy Workspace Reduction

Legacy evaluation directory (`/Users/marosvarchola/mcp-eval`):
- before: ~`5.1G`
- after prune/archive: `22M`

This removed stale evaluation payload while preserving restorable archives.

## 7. Threats to Validity

1. **Client-transport heterogeneity**: MCP clients differ in initialization behavior. Mitigated with compatibility sidecars.
2. **Temporal ecosystem drift**: upstream MCP/server versions evolve quickly. Mitigated with version pinning and check scripts.
3. **Benchmark locality**: latency reflects this host/network profile. Mitigated by publishing scripts and raw metrics for rerun.
4. **Feature skew across candidates**: not all tools target identical use-cases. Mitigated by category-aware scoring and skip rationale.

## 8. Reproducibility Protocol

1. `task infra:up PROFILE=full`
2. `task quality:doctor PROFILE=full`
3. `task quality:stress`
4. inspect `report/data/final_runtime_perf.tsv`
5. compare profile behavior via `task profile:apply PROFILE=core|full`

## 9. Conclusion

The resulting MCP platform is production-ready under measured constraints:
- high-utility default coding stack
- optional high-context extensions with compatibility hardening
- validated cross-client operability
- explicit cleanup/backup/archival controls

This closes the evaluation lifecycle with both operational readiness and forensic traceability.

## 10. References (Internal Artifacts)

- `report/MCP_EVAL_REPORT.md`
- `report/FINAL_PRODUCTION_RECOMMENDATION.md`
- `report/FINAL_RUNTIME_TOOL_INTERACTION_TEST.md`
- `report/ARCHON_SURREAL_RUNTIME_VALIDATION.md`
- `report/DEPLOYMENT_STATUS.md`
- `report/CLEANUP_ARCHIVE_LOG.md`
- `report/data/candidate_outcomes.tsv`
- `report/data/final_runtime_perf.tsv`
- `report/data/cleanup_manifest.tsv`
