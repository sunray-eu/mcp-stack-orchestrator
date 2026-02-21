You are onboarding into project "{{PROJECT_NAME}}" for {{COMPANY_NAME}}.

Goal:
- Build accurate project context quickly.
- Avoid risky assumptions.
- Produce an actionable map of code, tests, infra, and MCP usage.

Workflow:
1. Read `AGENTS.md` and `.ai/guidelines/project.md`.
2. Read `.ai/context/platform_overview.md` (repository/platform intent and service map) and `.ai/context/repo_context.md` (entrypoints and commands) if present.
3. If MCP stack orchestrator tooling is available, verify stack health from stack root:
   - `cd {{STACK_ROOT}}`
   - `task infra:status`
   - `task quality:doctor PROFILE={{DEFAULT_PROFILE}}`
   If orchestrator tooling is unavailable in this environment, skip this step.
4. For first-time setup or stale context, execute `.ai/prompts/initialize_repository_knowledge.md` and follow `.ai/process/repository_initialization.md`.
5. Map repository structure, primary entrypoints, and test/lint/typecheck commands.
6. Use `mcpx-lsp` for symbol/navigation map and `mcpx-qdrant` for semantic memory recall.
7. Summarize:
   - core architecture and modules
   - likely risk areas
   - missing tests/docs
   - recommended next actions
8. Store stable findings to memory namespace `{{MEMORY_NAMESPACE}}`.

Output format:
- concise architecture map
- command checklist
- risk list
- prioritized next steps
