# Maintenance

## Update Cadence

- Weekly: `task quality:versions:check`
- Monthly: refresh digest pins and run doctor + smoke
- On major MCP/server release: rerun targeted validation and update report notes

## Safe Upgrade Procedure

1. Pull latest repository changes.
2. Backup configs (automatic during apply).
3. Refresh image pins:
   - `task quality:versions:refresh`
4. Restart infra:
   - `task infra:up PROFILE=full`
5. Verify:
   - `task quality:doctor PROFILE=full`

For SurrealDB upgrades (especially v3), follow `docs/SURREAL_COMPATIBILITY.md` before changing image channels.

## Archon Pinning

- Archon source pin is controlled by `ARCHON_REPO_REF` in `infra/versions.env`.
- `stack_infra.sh bootstrap archon` checks out the pinned ref.

## Recovery

- Roll back agent configs:
  - `task profile:restore`
- Stop all managed infrastructure:
  - `task infra:down PROFILE=full`

## Security Checklist

- Confirm `.secrets.env` is not committed
- Confirm `tmp/` and `logs/` are not committed
- Validate no secrets in reports before publishing updates
- Keep host filesystem mounts read-only
- Keep `~/mcp-eval` (if present) as historical eval artifacts only; run live operations from this repo.
