# MCP Evaluation Plan (Sweep Refresh)

Date: 2026-02-20

## Objective
- Re-audit all existing MCP evaluation artifacts for completeness, correctness, and safety.
- Verify the prior session covered every required candidate and highlight anything still unverified.
- Keep original Codex state restorable at all times.

## Fixed Project Scope
- TypeScript: `<TS_REPO>`
- Python: `<PY_REPO>`

## Safety Controls
- Isolated eval home only: `CODEX_HOME=/Users/<user>/.codex-mcp-eval`
- Fresh backup created: `<STACK_ROOT>/backups/20260220-114717`
- Repo-local trap scan performed:
  - no `CODEX_HOME` in project env files
  - no project `.codex/` directories in either repo
- Secrets are kept in `<STACK_ROOT>/.secrets.env`; only variable names are referenced in reports.

## What Was Re-verified In This Sweep
- Codex runtime and baseline:
  - `which codex` and `codex --version` captured
  - default and eval MCP lists captured
- Artifact inventory consistency:
  - `candidates.tsv` URLs matched the full required input list with no missing or extra entries
  - every candidate in `candidates.tsv` exists in `candidate_outcomes.tsv`
- Existing report quality:
  - `MCP_EVAL_REPORT.md`
  - `PROMPT_COMPLIANCE_AUDIT.md`
  - `candidate_*` and `second_wave_*` TSV datasets
- Docker and infra state:
  - active/exited containers and compose projects
  - running ports and leftover runtime services

## Spot Revalidation Added In This Sweep
- Strict reruns on top recommendations:
  - `S1_basic_memory_rerun` (clean success)
  - `S1_chroma_rerun` (clean success)
  - `S1_qdrant_rerun` + `S1_qdrant_rerun_strict` (functional success with one failed sub-call before final success)
- Eval config was restored back to pre-rerun snapshot:
  - `<STACK_ROOT>/backups/eval-config-pre-rerun-20260220-115159.toml`

## Third-Wave Extension (Completed)
- Added and evaluated 17 additional requested libraries/pages.
- Updated synchronized datasets:
  - `<STACK_ROOT>/report/candidates.tsv`
  - `<STACK_ROOT>/report/candidate_outcomes.tsv`
  - `<STACK_ROOT>/report/candidate_repo_health.tsv`
  - `<STACK_ROOT>/report/candidate_static_risk.tsv`
  - `<STACK_ROOT>/report/second_wave_repo_scan.tsv`
  - `<STACK_ROOT>/report/second_wave_smoke.tsv`
- Post-extension totals:
  - candidates: `57`
  - outcomes: `57`
  - statuses: `tested=40`, `evaluated=12`, `skipped=5`
- Third-wave smoke runs completed for:
  - `S1_docs_mcp_server_third`
  - `S1_enhanced_mcp_memory_third`
  - `S1_graphiti_mcp_third`
  - `S1_surrealmcp_stdio`
  - `S1_surrealmcp_http`
  - `S1_archon_mcp_remote`
- Deep runtime validation completed for:
  - `S1_surrealmcp_deep` (stdio functional CRUD/query lifecycle)
  - `S1_surrealmcp_http_deep` (HTTP functional CRUD/query lifecycle)
  - `S1_archon_mcp_remote_deep` (health/session/project create-delete)

## Remaining Gap Work (For Full Prompt Compliance)
1. Run true S0/S1/S2/S3/S4 matrix per selected finalists with explicit per-candidate prune rationale.
2. Replace synthetic/smoke-only checks with 3 realistic coding tasks per repo (TS and PY), including wrong-turn metrics.
3. Tighten smoke success criteria:
   - current `exec_ok` can be true even with multiple failed MCP calls.
4. Produce reproducible weighted score calculation artifact from raw component scores.
5. Standardize node fallback evidence (`24 -> 22 -> 20`) per failing Node candidate.
6. Add explicit cleanup ledger after each scenario (`git status`, reset operation, temp file removal).

## Next Execution Batch
1. Update smoke scripts to require at least one successful MCP tool call with `call_ok=true`.
2. Re-run top 8 candidates on both repos using realistic coding tasks:
   - `basic-memory`, `qdrant mcp-server-qdrant`, `chroma-mcp`, `code-graph-rag-mcp`, `mcp-language-server`, `shinpr mcp-local-rag`, `rag-code-mcp`, `deepcontext-mcp`
3. Recompute ranking and regenerate `MCP_EVAL_REPORT.md` after strict metrics pass.
