# New Wave MCP Evaluation Addendum (2026-02-21)

This addendum covers the extra repository set requested after the prior sweep and folds outcomes into:

- `report/data/candidates.tsv`
- `report/data/candidate_repo_health.tsv`
- `report/data/candidate_static_risk.tsv`
- `report/data/candidate_outcomes.tsv`
- `report/data/second_wave_smoke.tsv`
- `report/data/new_wave_compat_probes.tsv`

## Candidate Set

1. `thakkaryash94/chroma-ui`
2. `danyQe/codebase-mcp`
3. `NgoTaiCo/mcp-codebase-index`
4. `entrepeneur4lyf/code-graph-mcp`
5. `CodeGraphContext/CodeGraphContext`
6. `ChrisRoyse/CodeGraph`
7. `ADORSYS-GIS/experimental-code-graph`
8. `neo4j/mcp`

## Runtime Smoke Summary

| Candidate | Runtime status | Notes |
|---|---|---|
| `entrepeneur4lyf/code-graph-mcp` | pass (TS + PY) | Passed `get_usage_guide` and `analyze_codebase` calls under Codex MCP. |
| `neo4j/mcp` | pass | Passed `get-schema` using local `Neo4j 5.26.19 + APOC` in read-only mode. |
| `CodeGraphContext/CodeGraphContext` | pass (compat) | Works with legacy newline JSON-RPC transport; fails only against framed stdio clients without adapter. |
| `danyQe/codebase-mcp` | pass (compat) | Works with legacy newline JSON-RPC transport; requires separate FastAPI backend for full functionality. |
| `NgoTaiCo/mcp-codebase-index` | pass (compat) | Works when stdout logs are redirected off protocol channel; still requires valid Gemini+Qdrant credentials for healthy indexing. |
| `thakkaryash94/chroma-ui` | n/a | Useful GUI, not an MCP server. |
| `ChrisRoyse/CodeGraph` | n/a | Analyzer platform; MCP component not production-ready as a standalone Codex MCP. |
| `ADORSYS-GIS/experimental-code-graph` | n/a | Experimental fork; no stable Codex-ready MCP distribution path observed. |

## Scoring Outcome (0–10)

| Candidate | Status | Score | Decision |
|---|---|---:|---|
| `neo4j/mcp` | tested | 7.5 | Recommended optional graph profile (not default). |
| `entrepeneur4lyf/code-graph-mcp` | tested | 7.2 | Recommended optional graph profile (not default). |
| `CodeGraphContext/CodeGraphContext` | tested | 6.0 | Viable only via protocol compatibility adapter; keep out of default profile. |
| `danyQe/codebase-mcp` | tested | 5.3 | Transport can be adapted, but backend+proxy dual-process flow keeps setup friction high. |
| `NgoTaiCo/mcp-codebase-index` | tested | 5.1 | Transport/logging can be adapted, but it still depends on valid Gemini+Qdrant credentials. |
| `ChrisRoyse/CodeGraph` | evaluated | 4.9 | Not recommended as MCP server in current form. |
| `ADORSYS-GIS/experimental-code-graph` | evaluated | 4.4 | Not recommended. |
| `thakkaryash94/chroma-ui` | evaluated | 3.8 | Optional human GUI only, out of MCP profile scope. |

## Compatibility Root Cause Findings

- `CodeGraphContext` and `codebase-mcp` use legacy newline JSON-RPC over stdio rather than framed `Content-Length` transport expected by stricter MCP clients.
- `mcp-codebase-index` uses SDK stdio transport but emits frequent runtime logs to stdout, contaminating the protocol channel for strict framed clients.
- All three can be made operational with compatibility handling, but the additional adapter/guardrails increase maintenance overhead compared to native-compatible servers.

## Neo4j MCP: What It Is and When It Helps

`neo4j/mcp` is the official MCP bridge for Neo4j graph databases. It is most useful when:

- you already maintain a graph model (code graph, architecture graph, dependency graph),
- you need natural-language to graph-query translation (`NL -> Cypher`) with deterministic read paths,
- you want explicit schema-aware graph exploration from an AI agent.

It is not a default stack fit for all coding loops because it requires additional graph infrastructure and ingestion discipline. In this repository it is added as an optional profile path, not as the default baseline.

## Integration Decision

No default-stack replacement was justified by this wave. The default production recommendation remains unchanged.

What was integrated:

- Optional code-graph profile support in orchestrator manifest/scripts (`core-code-graph`, `full-code-graph`) via `mcpx-code-graph`.
- Optional Neo4j profile support in orchestrator manifest/scripts (`core-neo4j`, `full-neo4j`, `full-graph`) via `mcpx-neo4j`.
- New-wave findings and scores merged into all canonical TSV datasets and master report.
