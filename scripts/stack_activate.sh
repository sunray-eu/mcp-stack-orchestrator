#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-full}"

case "$PROFILE" in
  none)
    "$SCRIPT_DIR/stack_apply.sh" none --agents codex,claude,opencode --codex-target both
    "$SCRIPT_DIR/stack_infra.sh" down full-graph
    ;;
  core)
    "$SCRIPT_DIR/stack_infra.sh" up core
    "$SCRIPT_DIR/stack_apply.sh" core --agents codex,claude,opencode --codex-target both
    ;;
  core-code-graph)
    "$SCRIPT_DIR/stack_infra.sh" up core-code-graph
    "$SCRIPT_DIR/stack_apply.sh" core-code-graph --agents codex,claude,opencode --codex-target both
    ;;
  core-neo4j)
    "$SCRIPT_DIR/stack_infra.sh" up core-neo4j
    "$SCRIPT_DIR/stack_apply.sh" core-neo4j --agents codex,claude,opencode --codex-target both
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
  full-code-graph)
    "$SCRIPT_DIR/stack_infra.sh" up full-code-graph
    "$SCRIPT_DIR/stack_apply.sh" full-code-graph --agents codex,claude,opencode --codex-target both
    ;;
  full-neo4j)
    "$SCRIPT_DIR/stack_infra.sh" up full-neo4j
    "$SCRIPT_DIR/stack_apply.sh" full-neo4j --agents codex,claude,opencode --codex-target both
    ;;
  full-graph)
    "$SCRIPT_DIR/stack_infra.sh" up full-graph
    "$SCRIPT_DIR/stack_apply.sh" full-graph --agents codex,claude,opencode --codex-target both
    ;;
  *)
    echo "Unknown profile: $PROFILE" >&2
    echo "Use one of: none, core, core-code-graph, core-neo4j, core-surreal, core-archon, core-docs, full, full-code-graph, full-neo4j, full-graph" >&2
    exit 1
    ;;
esac
