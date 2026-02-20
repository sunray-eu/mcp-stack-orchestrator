# Contributing

## Workflow

1. Create a branch from `main` using:
   - `feat/<short-topic>`
   - `fix/<short-topic>`
   - `chore/<short-topic>`
2. Keep commits focused and small.
3. Run validation before opening PR:
   - `make doctor PROFILE=core`
   - `python3 -m py_compile scripts/stack_apply.py`
   - `bash -n scripts/*.sh`

## Commit Convention

Use Conventional Commits:

- `feat: ...`
- `fix: ...`
- `docs: ...`
- `chore: ...`
- `refactor: ...`
- `test: ...`
- `ci: ...`

Examples:

- `feat: add archon bootstrap with pinned ref`
- `fix: resolve stack-root token expansion in manifest`
- `docs: expand quickstart for secrets and profiles`

## Pull Requests

- Include summary, risk, and rollback notes.
- Include evidence (doctor output or report links) for runtime-impacting changes.
- Do not commit secrets or generated runtime env files.
