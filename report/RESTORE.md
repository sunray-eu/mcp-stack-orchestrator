# Restore Guide

Use the restore script:

```bash
<STACK_ROOT>/scripts/restore_original.sh
```

Optional explicit backup path:

```bash
<STACK_ROOT>/scripts/restore_original.sh <STACK_ROOT>/backups/<backup_dir>
```

The script restores (when present in backup):

- `/Users/<user>/.codex/config.toml`
- `/Users/<user>/.codex-mcp-eval/config.toml`
- `/Users/<user>/.claude.json`
- `/Users/<user>/.config/opencode/opencode.jsonc`

It also stops managed infra stacks:

- `<STACK_ROOT>/scripts/stack_infra.sh down full`
- `<STACK_ROOT>/infra/docker-compose.yml`
- `<STACK_ROOT>/servers/coleam00-Archon/docker-compose.yml`

Post-restore snapshots are written under:

- `<STACK_ROOT>/logs/`
