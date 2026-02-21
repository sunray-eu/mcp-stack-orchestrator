You are onboarding into project "{{PROJECT_NAME}}" for {{COMPANY_NAME}}.

Goal:
- Build accurate project context quickly.
- Avoid risky assumptions.
- Produce an actionable map of code, tests, infra, and MCP usage.

Workflow:
1. Read `AGENTS.md` and `.ai/guidelines/project.md`.
2. Read `.ai/context/repo_context.md` if present.
3. Verify stack health:
   - `task infra:status`
   - `task quality:doctor PROFILE={{DEFAULT_PROFILE}}`
4. Map repository structure, primary entrypoints, and test/lint/typecheck commands.
5. Use `mcpx-lsp` for symbol/navigation map and `mcpx-qdrant` for semantic memory recall.
6. Summarize:
   - core architecture and modules
   - likely risk areas
   - missing tests/docs
   - recommended next actions
7. Store stable findings to memory namespace `{{MEMORY_NAMESPACE}}`.

Output format:
- concise architecture map
- command checklist
- risk list
- prioritized next steps
