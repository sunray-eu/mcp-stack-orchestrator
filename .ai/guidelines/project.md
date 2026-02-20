# Project Guidelines (mcp-stack-orchestrator)

## Scope
- Keep changes inside the requested scope.
- Prefer minimal diffs over broad refactors unless explicitly requested.

## Engineering Defaults
- Validate behavior with project-native checks (tests/lint/typecheck/doctor scripts).
- Keep operational commands reproducible and documented.
- Use stable naming for services, environments, and generated artifacts.

## MCP Usage Defaults
- Default profile: `full`
- Use LSP for symbol-safe edits, Qdrant for semantic recall, and Basic Memory for persistent notes.
- Use Surreal/Archon only when task requires workflow graph or structured data operations.

## Repository-Specific Notes
- Document architecture assumptions, entrypoints, and local constraints here.
- Add any per-repo approval or deployment steps here.

