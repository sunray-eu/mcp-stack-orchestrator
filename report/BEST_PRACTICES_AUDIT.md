# MCP/Infra Best-Practices Audit

Date: 2026-02-20

## Scope
- Full managed MCP stack under `<STACK_ROOT>`
- Runtime infra orchestration (`stack_infra.sh`, Docker Compose, Archon override)
- Multi-agent profile management (`stack_apply.py`, manifest-driven MCP rollout)
- Operations hygiene (restore flow, version pinning, health checks, update path)

## Current Stack Status
- Runtime profile validated: `full`
- Health command: `<STACK_ROOT>/scripts/stack_doctor.sh full`
- Result at audit time: `PASS=36 WARN=0 FAIL=0`
- Surrealist auto-connection validation: passed (managed runtime connection + query execution)

## Hardening Changes Applied In This Pass

1. Centralized image/version control
- Added `<STACK_ROOT>/infra/versions.env`
- Migrated compose image refs to env-driven variables
- Digest-pinned Surreal and docs-mcp images for reproducibility

2. Added explicit version lifecycle tooling
- Added `<STACK_ROOT>/scripts/stack_versions.sh`
- Supported commands:
  - `show` (configured refs + local digest visibility)
  - `check` (pinned digest freshness against upstream channels)
  - `refresh` (pull latest channels and rewrite digest pins)
  - `pull` (pull resolved compose images)

3. Removed static Surrealist credential coupling
- `stack_infra.sh` now generates runtime file:
  - `<STACK_ROOT>/tmp/surrealist-instance.json`
- File permissions: `600`
- `docker-compose.yml` now mounts `SURREALIST_INSTANCE_FILE`
- Credentials and defaults are now runtime-driven from `.secrets.env` (or safe defaults)

4. Improved infra configurability
- SurrealDB command now uses runtime env variables for:
  - root user/password
  - default namespace/database
  - external RPC port
- Added env template entries in:
  - `<STACK_ROOT>/infra/.env.example`

5. Added operational doctor checks
- Added `<STACK_ROOT>/scripts/stack_doctor.sh`
- Checks:
  - required commands
  - syntax validity of key scripts
  - compose resolution with versions/runtime env files
  - secrets/runtime file permissions
  - codex eval managed-MCP coverage for selected profile
  - endpoint health per profile

6. Strengthened restore path
- `restore_original.sh` now cleans:
  - `ai-mcp-surrealdb`
  - `<STACK_ROOT>/tmp/surrealist-instance.json`

7. Global dynamic MCP profile (no project-specific global entries)
- Replaced per-project entries with:
  - `mcpx-qdrant` (runtime project collection inference)
  - `mcpx-lsp` (runtime workspace/language inference)
- Added wrappers:
  - `<STACK_ROOT>/scripts/mcpx_qdrant_auto.sh`
  - `<STACK_ROOT>/scripts/mcpx_lsp_auto.sh`
- Added optional repo-local override file contract:
  - `.mcp-stack.env` (template: `<STACK_ROOT>/configs/mcp-stack.env.example`)

## Best-Practices Assessment

### Security
- Strengths:
  - Host filesystem mounts are read-only (`/hostfs`, `/Users`)
  - Runtime secret/env files are chmod `600`
  - Surrealist config is generated at runtime instead of static checked-in credentials
- Residual risk:
  - User-global agent config files (`~/.codex/config.toml`, `~/.config/opencode/opencode.jsonc`) still contain non-managed external tokens for unrelated MCP providers.
  - This is outside managed `mcpx-*` scope but should be rotated/migrated to env-var references.

### Maintainability
- Strengths:
  - Manifest-driven profile application
  - Dedicated activation/apply/restore scripts
  - New doctor + version scripts reduce manual drift
  - Version matrix now centralized
- Residual risk:
  - Archon base compose is upstream-managed and includes build-from-source behavior; upstream changes can alter runtime characteristics.

### Configurability
- Strengths:
  - Profile-based stack (`core`, `core-surreal`, `core-archon`, `core-docs`, `full`)
  - Runtime overrides via `.secrets.env`
  - SurrealDB/Surrealist parameters configurable without compose edits

### Upgradeability
- Strengths:
  - Digest pinning for reproducibility
  - Explicit `check`/`refresh` workflow for controlled upgrades
  - Post-upgrade doctor validation command

## Operational Standard (Recommended)

1. Start stack
```bash
<STACK_ROOT>/scripts/stack_infra.sh up full
```

2. Validate health
```bash
<STACK_ROOT>/scripts/stack_doctor.sh full
```

3. Check for upgrades
```bash
<STACK_ROOT>/scripts/stack_versions.sh check
```

4. Apply upgrades (when needed)
```bash
<STACK_ROOT>/scripts/stack_versions.sh refresh
<STACK_ROOT>/scripts/stack_infra.sh up full
<STACK_ROOT>/scripts/stack_doctor.sh full
```

5. Roll back if needed
```bash
<STACK_ROOT>/scripts/restore_original.sh
```

## Conclusion
- Managed MCP + infra setup is now in a strong production-operational state for local AI coding workflows:
  - reproducible image refs
  - scripted health verification
  - explicit upgrade path
  - reversible restore
  - runtime-generated sensitive connection config
- Remaining high-priority action is security hygiene for non-managed tokens in user-global agent configs.
