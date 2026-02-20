# MCP Full Sweep Audit

Date: 2026-02-20
Audited by: Codex local agent
Mode: third-wave extension + report synchronization + live Archon/SurrealDB validation

## 1) Scope Checked

- Primary repo: `<TS_REPO>`
- Secondary repo: `<PY_REPO>`
- Evaluation workspace: `<STACK_ROOT>`
- Global Codex home: `/Users/<user>/.codex`
- Eval Codex home: `/Users/<user>/.codex-mcp-eval`

## 2) Safety / Baseline Verification

- `codex` binary confirmed: `/opt/homebrew/bin/codex`
- Version confirmed: `codex-cli 0.104.0`
- Original user config unchanged: `/Users/<user>/.codex/config.toml`
- Third-wave report backup created:
  - `<STACK_ROOT>/backups/report-third-wave-20260220-121119`

Repo-local trap check outcome:

- No repo-local `.codex` override used for this sweep.
- No project `.env*` override for `CODEX_HOME` was executed.

## 3) Candidate Coverage After Third Wave

Artifacts synchronized:

- `<STACK_ROOT>/report/candidates.tsv`
- `<STACK_ROOT>/report/candidate_outcomes.tsv`
- `<STACK_ROOT>/report/candidate_repo_health.tsv`
- `<STACK_ROOT>/report/candidate_static_risk.tsv`
- `<STACK_ROOT>/report/second_wave_repo_scan.tsv`
- `<STACK_ROOT>/report/second_wave_smoke.tsv`

Coverage result:

- Inventory size: `57` candidates
- Outcomes size: `57`
- Name parity: `57/57` (no missing / no extras)
- Status split:
  - `tested`: `40`
  - `evaluated`: `12`
  - `skipped`: `5`

## 4) Newly Added Third-Wave Inputs

Added candidate set (17):

- HKUDS AutoAgent
- Significant-Gravitas AutoGPT
- westonbrown Cyber-AutoAgent
- HKUDS RAG-Anything
- getzep graphiti
- ItMeDiaTech rag-cli
- Spillwave article
- SpillwaveSolutions agent-brain
- Agno docs
- EvoAgentX
- coleam00 Archon
- thedotmack claude-mem
- SurrealDB
- cbunting99 enhanced-mcp-memory
- arabold docs-mcp-server
- Docfork
- LlamaIndex MCP examples

## 5) Runtime Testing Added

Smoke runs executed and logged:

- `S1_docs_mcp_server_third`
- `S1_enhanced_mcp_memory_third`
- `S1_graphiti_mcp_third`
- `S1_surrealmcp_stdio`
- `S1_surrealmcp_http`
- `S1_archon_mcp_remote`

Deep functional runs executed and logged:

- `S1_surrealmcp_deep` (stdio CRUD/query lifecycle)
- `S1_surrealmcp_http_deep` (HTTP CRUD/query lifecycle)
- `S1_archon_mcp_remote_deep` (health/session/project create-delete)

Smoke matrix snapshot (`<STACK_ROOT>/report/second_wave_smoke.tsv`):

- rows: `63`
- `setup_ok=true`: `63`
- `exec_ok=true`: `62` (optimistic flag)
- strict successes (`mcp_calls>0 && mcp_failed==0`): `22`

Observation: smoke script still overstates success when partial MCP failures occur. Strict interpretation remains required for ranking confidence.

## 6) Maintenance + Static Risk Synchronization

GitHub metadata table (`candidate_repo_health.tsv`):

- rows: `48` (all GitHub/github-path candidates covered)
- third-wave repos appended: `12`

Static risk table (`candidate_static_risk.tsv`):

- rows: `48` (all GitHub/github-path candidates covered)
- current aggregate signals:
  - `mentions_remote_service=true`: `38/48`
  - `mentions_api_key=true`: `36/48`
  - `postinstall != '-'`: `3/48`
  - `prepare != '-'`: `12/48`

## 7) External Page Access Outcomes

- Successfully fetched/analyzed:
  - `https://docs.agno.com/`
  - `https://surrealdb.com/`
  - `https://surrealdb.com/mcp`
  - `https://docfork.com/`
  - `https://developers.llamaindex.ai/python/examples/tools/mcp/`
- Blocked by anti-bot policy:
  - `https://pub.spillwave.com/give-your-claude-code-opencode-and-codex-full-rag-over-docs-and-code-repos-edcf654407e9`
  - observed `robots` restriction / Cloudflare challenge (HTTP 403)

## 8) Recommendation Impact

After third-wave integration, top recommendation is unchanged:

1. `basicmachines-co/basic-memory`
2. `qdrant/mcp-server-qdrant`
3. `chroma-core/chroma-mcp`

Reason: new additions were mostly non-direct MCP frameworks/pages, or MCP candidates with handshake/setup reliability penalties in this environment.

Live validation note:

- `SurrealDB MCP` is now confirmed as a real and stable MCP server (stdio + HTTP).
- `Archon` is now confirmed operational end-to-end with remote Supabase, but carries higher setup/ops friction and key-format compatibility pitfalls.

## 9) Current State Notes

- `~/.codex` was not modified by this report update step.
- Report/data files were updated in place under `<STACK_ROOT>/report`.
- Temporary Archon runtime secret env file was removed after validation; template retained at `<STACK_ROOT>/tmp/archon_remote.env.example`.
- Full detail and final ranking are in:
  - `<STACK_ROOT>/report/MCP_EVAL_REPORT.md`
  - `<STACK_ROOT>/report/ARCHON_SURREAL_RUNTIME_VALIDATION.md`
