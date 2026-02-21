#!/usr/bin/env bash
set -euo pipefail

ROOT="${MCP_CODE_GRAPH_PROJECT_ROOT:-${PWD:-.}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -d "$ROOT/.git" ]; then
  ROOT="$(cd "$ROOT" && pwd)"
elif command -v git >/dev/null 2>&1; then
  if GIT_TOP="$(git -C "$ROOT" rev-parse --show-toplevel 2>/dev/null)"; then
    ROOT="$GIT_TOP"
  fi
fi

# code-graph-mcp currently speaks newline-delimited JSON-RPC over stdio.
# Codex expects framed MCP stdio, so we bridge transports here.
exec python3 "$SCRIPT_DIR/mcp_stdio_line_bridge.py" -- \
  uvx --from code-graph-mcp code-graph-mcp --project-root "$ROOT"
