# TODO: Re-enable `mcpx-code-graph`

Status: **paused intentionally** (2026-02-21)

Reason:
- Current interactive Codex thread still shows intermittent/stale transport closure for `mcpx-code-graph`.
- Wrapper compatibility exists (`scripts/mcp_stdio_line_bridge.py`), but server is parked from active agent configs until a clean re-enable window.

What was changed:
- Removed `mcpx-code-graph` from:
  - `~/.codex/config.toml`
  - `~/.codex-mcp-eval/config.toml`
  - Claude user MCP config (`claude mcp remove mcpx-code-graph -s user`)
- Disabled in OpenCode:
  - `~/.config/opencode/opencode.jsonc` (`"enabled": false`)

Re-enable checklist:
1. Re-add MCP to Codex/Claude/OpenCode from orchestrator profile tooling.
2. Restart agent sessions to avoid stale MCP transport cache.
3. Verify framed MCP flow end-to-end:
   - initialize
   - tools/list
   - tools/call `get_usage_guide`
   - tools/call `analyze_codebase` (quick)
4. Run short smoke on TS + PY repos and record latency.
5. If stable across Codex/Claude/OpenCode, remove this TODO and set OpenCode `"enabled": true`.

