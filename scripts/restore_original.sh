#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKUP_PATH="${1:-}"

pick_latest_backup() {
  for f in \
    "$STACK_ROOT/.latest-stack-apply-backup" \
    "$STACK_ROOT/.latest-final-rollout-backup" \
    "$STACK_ROOT/.latest-stack-rollout-backup" \
    "$STACK_ROOT/.latest-backup-path" \
    "$HOME/mcp-eval/.latest-stack-apply-backup" \
    "$HOME/mcp-eval/.latest-final-rollout-backup" \
    "$HOME/mcp-eval/.latest-stack-rollout-backup" \
    "$HOME/mcp-eval/.latest-backup-path"; do
    if [ -f "$f" ]; then
      cat "$f"
      return 0
    fi
  done
  return 1
}

if [ -z "$BACKUP_PATH" ]; then
  BACKUP_PATH="$(pick_latest_backup || true)"
fi

if [ -z "$BACKUP_PATH" ] || [ ! -d "$BACKUP_PATH" ]; then
  echo "Backup path missing or invalid. Provide: $0 <backup_dir>" >&2
  exit 1
fi

echo "Restoring from: $BACKUP_PATH"
mkdir -p "$HOME/.codex" "$HOME/.codex-mcp-eval" "$HOME/.config/opencode" "$STACK_ROOT/logs"

restore_if_exists() {
  local src="$1"
  local dst="$2"
  if [ -f "$src" ]; then
    cp -a "$src" "$dst"
    echo "Restored $dst"
  fi
}

restore_if_exists "$BACKUP_PATH/codex.config.toml" "$HOME/.codex/config.toml"
restore_if_exists "$BACKUP_PATH/codex-eval.config.toml" "$HOME/.codex-mcp-eval/config.toml"
restore_if_exists "$BACKUP_PATH/claude.json" "$HOME/.claude.json"
restore_if_exists "$BACKUP_PATH/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

restore_if_exists "$BACKUP_PATH/config.toml" "$HOME/.codex/config.toml"
restore_if_exists "$BACKUP_PATH/config.json" "$HOME/.codex/config.json"
restore_if_exists "$BACKUP_PATH/auth.json" "$HOME/.codex/auth.json"
restore_if_exists "$BACKUP_PATH/version.json" "$HOME/.codex/version.json"
restore_if_exists "$BACKUP_PATH/AGENTS.md" "$HOME/.codex/AGENTS.md"

if [ -x "$STACK_ROOT/scripts/stack_infra.sh" ]; then
  "$STACK_ROOT/scripts/stack_infra.sh" down full || true
fi

if [ -f "$STACK_ROOT/infra/docker-compose.yml" ]; then
  (cd "$STACK_ROOT/infra" && docker compose down || true)
fi

if [ -f "$STACK_ROOT/servers/coleam00-Archon/docker-compose.yml" ]; then
  if [ -f "$STACK_ROOT/tmp/ai-mcp-archon.env" ]; then
    (cd "$STACK_ROOT/servers/coleam00-Archon" && docker compose --env-file "$STACK_ROOT/tmp/ai-mcp-archon.env" down || true)
  elif [ -f "$STACK_ROOT/tmp/archon.runtime.env" ]; then
    (cd "$STACK_ROOT/servers/coleam00-Archon" && docker compose --env-file "$STACK_ROOT/tmp/archon.runtime.env" down || true)
  else
    (cd "$STACK_ROOT/servers/coleam00-Archon" && docker compose down || true)
  fi
fi

rm -f \
  "$STACK_ROOT/tmp/ai-mcp-archon.env" \
  "$STACK_ROOT/tmp/ai-mcp-infra.env" \
  "$STACK_ROOT/tmp/surrealist-instance.json" \
  "$STACK_ROOT/tmp/archon.runtime.env" \
  >/dev/null 2>&1 || true

for c in \
  ai-mcp-qdrant \
  ai-mcp-chroma \
  ai-mcp-postgres \
  ai-mcp-redis \
  ai-mcp-surreal-mcp \
  ai-mcp-surrealdb \
  ai-mcp-surrealist \
  ai-mcp-docs-mcp \
  ai-mcp-archon-server \
  ai-mcp-archon-mcp \
  ai-mcp-archon-ui \
  mcp-eval-qdrant \
  mcp-eval-ollama \
  mcp-eval-surrealmcp \
  letta-local \
  memcp-eval-postgres \
  postgres \
  rabbitmq \
  redis \
  archon-server \
  archon-mcp \
  memory-mcp-server \
  memory-mcp-postgres \
  memory-mcp-qdrant \
  memory-mcp-rabbitmq \
  memory-mcp-redis \
  memory-mcp-celery-worker \
  memory-mcp-frontend; do
  docker rm -f "$c" >/dev/null 2>&1 || true
done

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_CODEX="$STACK_ROOT/logs/restore_codex_mcp_list_${STAMP}.txt"
OUT_CODEX_EVAL="$STACK_ROOT/logs/restore_codex_eval_mcp_list_${STAMP}.txt"
OUT_CLAUDE="$STACK_ROOT/logs/restore_claude_mcp_list_${STAMP}.txt"
OUT_OPENCODE="$STACK_ROOT/logs/restore_opencode_mcp_list_${STAMP}.txt"

codex mcp list >"$OUT_CODEX" || true
CODEX_HOME="$HOME/.codex-mcp-eval" codex mcp list >"$OUT_CODEX_EVAL" || true
claude mcp list >"$OUT_CLAUDE" || true
opencode mcp list >"$OUT_OPENCODE" || true

echo "Restore completed."
echo "Snapshots:"
echo "- $OUT_CODEX"
echo "- $OUT_CODEX_EVAL"
echo "- $OUT_CLAUDE"
echo "- $OUT_OPENCODE"
