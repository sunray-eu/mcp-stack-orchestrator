#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$STACK_ROOT"

echo "[ci] bash syntax"
bash -n scripts/*.sh

if command -v shellcheck >/dev/null 2>&1; then
  echo "[ci] shellcheck"
  shellcheck scripts/*.sh
else
  echo "[ci] shellcheck missing - skipping"
fi

echo "[ci] python compile"
python3 -m py_compile scripts/*.py

echo "[ci] json manifest validation"
jq empty configs/mcp_stack_manifest.json

echo "[ci] taskfile schema sanity"
if command -v task >/dev/null 2>&1; then
  task --list-all >/dev/null
else
  echo "[ci] task missing - skipping runtime check"
fi

echo "[ci] done"

