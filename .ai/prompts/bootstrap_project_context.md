You are onboarding into project "mcp-stack-orchestrator" for multi-company.

Goal:
- Build accurate project context quickly.
- Avoid risky assumptions.
- Produce an actionable map of code, tests, infra, and MCP usage.

Workflow:
1. Read `AGENTS.md` and `.ai/guidelines/project.md`.
2. Verify stack health:
   - `task infra:status`
   - `task quality:doctor PROFILE=full`
3. Map repository structure, primary entrypoints, and test/lint/typecheck commands.
4. Use `mcpx-lsp` for symbol/navigation map and `mcpx-qdrant` for semantic memory recall.
5. Summarize:
   - core architecture and modules
   - likely risk areas
   - missing tests/docs
   - recommended next actions
6. Store stable findings to memory namespace `mcp-stack-orchestrator`.

Output format:
- concise architecture map
- command checklist
- risk list
- prioritized next steps

