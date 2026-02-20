#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="${1:-core}"

cat <<EOF
Applying standardized MCP stack profile: ${PROFILE}
- Agents: codex + claude + opencode
- Codex targets: ~/.codex and ~/.codex-mcp-eval
EOF

"${SCRIPT_DIR}/stack_apply.sh" "${PROFILE}" --agents codex,claude,opencode --codex-target both
