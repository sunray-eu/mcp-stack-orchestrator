# Maintenance

## Update Cadence

- Weekly: `./scripts/stack_versions.sh check`
- Monthly: refresh digest pins and run doctor + smoke
- On major MCP/server release: rerun targeted validation and update report notes

## Safe Upgrade Procedure

1. Pull latest repository changes.
2. Backup configs (automatic during apply).
3. Refresh image pins:
   - `./scripts/stack_versions.sh refresh`
4. Restart infra:
   - `./scripts/stack_infra.sh up full`
5. Verify:
   - `./scripts/stack_doctor.sh full`

## Archon Pinning

- Archon source pin is controlled by `ARCHON_REPO_REF` in `infra/versions.env`.
- `stack_infra.sh bootstrap archon` checks out the pinned ref.

## Recovery

- Roll back agent configs:
  - `./scripts/restore_original.sh`
- Stop all managed infrastructure:
  - `./scripts/stack_infra.sh down full`

## Security Checklist

- Confirm `.secrets.env` is not committed
- Confirm `tmp/` and `logs/` are not committed
- Validate no secrets in reports before publishing updates
- Keep host filesystem mounts read-only
