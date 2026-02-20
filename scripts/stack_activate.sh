#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-full}"

case "$PROFILE" in
  none)
    "$SCRIPT_DIR/stack_apply.sh" none --agents codex,claude,opencode --codex-target both
    "$SCRIPT_DIR/stack_infra.sh" down full
    ;;
  core)
    "$SCRIPT_DIR/stack_infra.sh" up core
    "$SCRIPT_DIR/stack_apply.sh" core --agents codex,claude,opencode --codex-target both
    ;;
  core-surreal)
    "$SCRIPT_DIR/stack_infra.sh" up surreal
    "$SCRIPT_DIR/stack_apply.sh" core-surreal --agents codex,claude,opencode --codex-target both
    ;;
  core-archon)
    "$SCRIPT_DIR/stack_infra.sh" up archon
    "$SCRIPT_DIR/stack_apply.sh" core-archon --agents codex,claude,opencode --codex-target both
    ;;
  core-docs)
    "$SCRIPT_DIR/stack_infra.sh" up docs
    "$SCRIPT_DIR/stack_apply.sh" core --agents codex,claude,opencode --codex-target both
    ;;
  full)
    "$SCRIPT_DIR/stack_infra.sh" up full
    "$SCRIPT_DIR/stack_apply.sh" full --agents codex,claude,opencode --codex-target both
    ;;
  *)
    echo "Unknown profile: $PROFILE" >&2
    echo "Use one of: none, core, core-surreal, core-archon, core-docs, full" >&2
    exit 1
    ;;
esac
