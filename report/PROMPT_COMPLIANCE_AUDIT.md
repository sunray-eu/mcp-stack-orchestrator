# Prompt Compliance Audit

Date: 2026-02-20
Scope: Verify work completed under original MCP-evaluation prompt requirements.

## Overall Verdict

Partial compliance.

What is strong:
- Candidate coverage and inventory discipline are high.
- Core artifacts, scripts, and restore path exist.
- Original `~/.codex` state remains unchanged from baseline backup.

What is not fully compliant:
- Scenario matrix execution and benchmark depth are below the required bar.
- Several process requirements are partially evidenced rather than systematically enforced.

## Requirement Matrix

| Prompt Area | Status | Evidence | Notes |
|---|---|---|---|
| Two fixed projects used | Complete | `<STACK_ROOT>/report/PLAN.md:5`, `<STACK_ROOT>/report/PLAN.md:6`, `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:26`, `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:27` | Both TS and PY paths are used in plan/report and benchmark scripts. |
| Isolated `CODEX_HOME` safety posture | Complete | `<STACK_ROOT>/report/PLAN.md:12`, `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:31` | Eval config home used. |
| Trap scan for repo-local `CODEX_HOME` / `.codex` | Partial | `<STACK_ROOT>/report/PLAN.md:26` | Scan is claimed; explicit result table is not present in final report. |
| Backup + reversible restore | Complete | `<STACK_ROOT>/report/RESTORE.md:1`, `<STACK_ROOT>/scripts/restore_original.sh:4`, `<STACK_ROOT>/scripts/restore_original.sh:19`, `<STACK_ROOT>/scripts/restore_original.sh:54` | Timestamped backups exist and restore script verifies MCP list parity. |
| Harness directories and scripts | Complete | `<STACK_ROOT>/scripts/apply_candidate.sh:1`, `<STACK_ROOT>/scripts/remove_candidate.sh:1`, `<STACK_ROOT>/scripts/run_benchmark_ts.sh:1`, `<STACK_ROOT>/scripts/run_benchmark_py.sh:1`, `<STACK_ROOT>/scripts/restore_original.sh:1` | Required scripts exist plus extra smoke helpers. |
| Scenario matrix S0..S4 per candidate (or justified pruning) | Missing | `<STACK_ROOT>/report/second_wave_smoke.tsv:1` | Smoke runs are S1-only. No systematic per-candidate S0/S2/S3/S4 execution matrix with prune rationale. |
| Benchmark realism: 3 coding tasks each repo | Missing | `<STACK_ROOT>/report/benchmark_summary.tsv:1`, `<STACK_ROOT>/scripts/run_benchmark_ts.sh:39`, `<STACK_ROOT>/scripts/run_benchmark_py.sh:39` | Benchmarks run lint/type/test/status checks, not 3 realistic code-change tasks per repo per prompt. |
| Metrics: time-to-first-correct, wrong turns, tool calls, final tests | Partial | `<STACK_ROOT>/report/codex_exec_metrics.tsv:1`, `<STACK_ROOT>/report/codex_tool_metrics.tsv:1`, `<STACK_ROOT>/report/benchmark_summary.tsv:1` | Tool-call/time metrics exist, but “time-to-first-correct-change” and wrong-turn/hallucination metrics are not consistently tied to required coding tasks. |
| Weighted scoring rubric (35/20/25/10/10) | Partial | `<STACK_ROOT>/report/PLAN.md:63`, `<STACK_ROOT>/report/candidate_outcomes.tsv:1` | Scores exist, but no reproducible weighted-calculation artifact was found. |
| Candidate inventory coverage (all listed) | Complete | `<STACK_ROOT>/report/candidates.tsv:1`, `<STACK_ROOT>/report/candidate_outcomes.tsv:1` | 40/40 items accounted for with tested/evaluated/skipped status. |
| Skip rationale quality | Complete | `<STACK_ROOT>/report/candidate_outcomes.tsv:5`, `<STACK_ROOT>/report/candidate_outcomes.tsv:6`, `<STACK_ROOT>/report/candidate_outcomes.tsv:16` | Skips are concrete and aligned with constraints. |
| LangGraph-MCP requested deep analysis | Complete | `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:66`, `<STACK_ROOT>/report/candidate_outcomes.tsv:24`, `<STACK_ROOT>/report/second_wave_smoke.tsv:54`, `<STACK_ROOT>/report/second_wave_smoke.tsv:55` | Includes default failure + compatibility retest and corrected conclusion. |
| Setup strategy (official first, local-first, docker when needed) | Partial | `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:129`, `<STACK_ROOT>/infra/docker-compose.yml:1` | Local infra attempts were made; not all install-order decisions are explicitly logged per candidate. |
| Node fallback 24->22->20 via mise | Partial | `<STACK_ROOT>/report/candidate_outcomes.tsv:19`, `<STACK_ROOT>/report/second_wave_smoke.tsv:36` | Evidence of Node22 retry exists; full ordered 24->22->20 fallback matrix not shown. |
| Workspace integrity (`git status` checks + reset between scenarios) | Partial | `<STACK_ROOT>/report/benchmark_summary.tsv:2`, `<STACK_ROOT>/report/benchmark_summary.tsv:21` | `git status` pre/post exists in benchmark runs, but no systematic per-scenario `git reset --hard`/temp-file list evidence. |
| Global/per-project/hybrid memory validation | Partial | `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:137`, `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:158`, `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:168`, `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:178` | Config supports namespaces/collections; tests exist, but explicit hybrid experiment narrative is limited. |
| Final deliverables (report, quickstart, apply, restore) | Complete | `<STACK_ROOT>/report/MCP_EVAL_REPORT.md:1`, `<STACK_ROOT>/report/QUICKSTART.md:1`, `<STACK_ROOT>/scripts/apply_recommended.sh:1`, `<STACK_ROOT>/scripts/restore_original.sh:1` | Deliverables exist and are usable. |
| Apply script safety (do not write `~/.codex` without approval) | Complete | `<STACK_ROOT>/scripts/apply_recommended.sh:45` | Explicit `--target user --yes` gate is implemented. |
| Original config preserved | Complete | Backup vs current config/mcp-list compared during audit | Current `~/.codex/config.toml` and `codex mcp list` match backup baseline. |

## Security Notes

- Sensitive material is present in backup/config artifacts by design of full-state backup. Protect these paths:
  - `<STACK_ROOT>/backups/20260220-024207/config.toml`
  - `<STACK_ROOT>/backups/20260220-024207/auth.json`
  - `<STACK_ROOT>/.secrets.env`
- Keep these files untracked and permission-restricted, and rotate tokens if they were ever exposed outside trusted local storage.

## Gap List To Reach Full Prompt Compliance

1. Execute required S0/S1/S2/S3/S4 matrix per candidate (or explicitly document pruning rationale per candidate).
2. Run the required 3 realistic coding tasks per repo (TS and PY) for baseline and selected candidate stacks.
3. Add per-task metrics: time-to-first-correct-change, wrong turns/hallucinations, tool-call deltas, and test/lint/type outcomes.
4. Implement reproducible weighted score computation script and publish scoring inputs/outputs.
5. Add explicit per-candidate Node fallback log (`24 -> 22 -> 20`) when applicable.
6. Add explicit trap-scan results section for repo-local `.env/.codex` findings in final report.
7. Add explicit per-scenario cleanup evidence (`git status`, reset policy, temp-file removal log).

## Recommended Next Execution Batch

- Prioritize top 8 candidates for full S0-S4 + coding-task benchmark completion:
  - `basic-memory`, `qdrant official`, `chroma-mcp`, `code-graph-rag-mcp`, `mcp-language-server`, `shinpr mcp-local-rag`, `doITmagic rag-code-mcp`, `deepcontext-mcp`.
- Then backfill remaining candidates with documented prune rules where redundant/non-applicable.

