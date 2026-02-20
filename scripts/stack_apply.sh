#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -lt 1 ]; then
  cat <<'USAGE'
Usage:
  stack_apply.sh <profile> [--agents codex,claude,opencode] [--codex-target user|eval|both]

Examples:
  stack_apply.sh core
  stack_apply.sh full --codex-target both
  stack_apply.sh none --agents codex,claude,opencode
USAGE
  exit 1
fi

"${SCRIPT_DIR}/stack_apply.py" "$@"
