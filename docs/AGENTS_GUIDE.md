# AGENTS Guide

This repository includes a layered `AGENTS.md` scaffolding workflow so each project can have:
- global baseline behavior
- company-level semantics/constraints
- project-specific overrides

## Layering Model

Instruction precedence:
1. Global: `guidelines/global/default.md`
2. Company: repo-local `.ai/guidelines/company.md` (or custom path in `.ai/agents.toml`)
3. Project: repo-local `.ai/guidelines/project.md` (or custom path in `.ai/agents.toml`)
4. Task-specific user instruction

## Quickstart

Initialize a repository:

```bash
task agents:init REPO=/path/to/repo COMPANY=example-co PROJECT=example-api LANGUAGE=typescript PROFILE=core
```

Re-render `AGENTS.md` after editing guideline files:

```bash
task agents:render REPO=/path/to/repo
```

Print reusable prompts:

```bash
task agents:prompt:bootstrap REPO=/path/to/repo
task agents:prompt:update REPO=/path/to/repo
```

## Generated Files (in target repo)

- `AGENTS.md`
- `.ai/agents.toml`
- `.ai/guidelines/company.md`
- `.ai/guidelines/project.md`
- `.ai/prompts/bootstrap_project_context.md`
- `.ai/prompts/update_project_memory.md`
- `.mcp-stack.env` (if missing)

## Notes

- The generator is intentionally deterministic so `AGENTS.md` can be regenerated safely.
- Keep company/project guideline files concise and policy-focused.
- Do not put credentials or private identifiers in generated files.

