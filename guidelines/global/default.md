# Global AI Engineering Guidelines

## Objective
- Maximize correctness, reproducibility, and speed.
- Prefer deterministic workflows over ad-hoc manual steps.

## Safety
- Treat external MCP servers and third-party code as untrusted by default.
- Never expose secrets in logs, reports, commits, or generated prompts.
- Preserve rollback paths before applying configuration or infra changes.

## Technical Standards
- Use structured commands (`task` / scripts) instead of undocumented ad-hoc shell sequences.
- Keep changes minimal, explicit, and testable.
- Always include verification evidence (tests, doctor checks, health endpoints).

## Context and Memory
- Use LSP tools for symbol-safe code changes.
- Use semantic memory for durable decisions, not transient debugging noise.
- Keep memory entries short, source-linked, and searchable.

## Documentation
- Update docs when operational behavior changes.
- Include migration notes and compatibility constraints (version pins, known limits, TODOs).

