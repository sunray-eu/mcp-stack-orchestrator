#!/usr/bin/env bash
set -euo pipefail

ROOT="${MCP_CODE_GRAPH_PROJECT_ROOT:-${PWD:-.}}"
if [ -d "$ROOT/.git" ]; then
  ROOT="$(cd "$ROOT" && pwd)"
elif command -v git >/dev/null 2>&1; then
  if GIT_TOP="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
    ROOT="$GIT_TOP"
  fi
fi

exec uvx --from code-graph-mcp code-graph-mcp --project-root "$ROOT"
