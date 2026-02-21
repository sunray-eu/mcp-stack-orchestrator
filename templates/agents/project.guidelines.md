# Project Guidelines ({{PROJECT_NAME}})

## Scope
- Keep changes inside the requested scope.
- Prefer minimal diffs over broad refactors unless explicitly requested.
- Follow global and company precedence; do not bypass baseline safeguards.

## Engineering Defaults
- Validate behavior with project-native checks (tests/lint/typecheck/doctor scripts).
- Keep operational commands reproducible and documented.
- Use stable naming for services, environments, and generated artifacts.
- Keep `.ai/context/repo_context.md` current after notable architecture/tooling changes.

## MCP Usage Defaults
- Default profile: `{{DEFAULT_PROFILE}}`
- Use LSP for symbol-safe edits, Qdrant for semantic recall, and Basic Memory for persistent notes.
- Use Surreal/Archon only when task requires workflow graph or structured data operations.

## Repository-Specific Notes
- Document architecture assumptions, entrypoints, and local constraints here.
- Add any per-repo approval or deployment steps here.
