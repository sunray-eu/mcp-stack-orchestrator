# Scoring Model

Weighted scoring used in MCP evaluation:

- Correctness improvement: 35%
- Context quality/navigation: 20%
- Security risk: 25%
- Setup friction: 10%
- Maintenance health: 10%

## Tie-breakers

- Local-first support
- Cross-project compatibility (TypeScript + Python)
- Predictability and flake resistance
- Runtime performance (index/query/startup)

## Inputs

- Static risk scan (install scripts, command execution, network calls, credential handling)
- Repository health (last commit, releases, issue velocity)
- Smoke tests and benchmark task completion
- Infra and profile integration behavior

## Artifacts

See:

- `report/data/candidate_outcomes.tsv`
- `report/data/candidate_repo_health.tsv`
- `report/data/candidate_static_risk.tsv`
- `report/MCP_EVAL_REPORT.md`
