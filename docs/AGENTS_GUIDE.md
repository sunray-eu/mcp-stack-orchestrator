# AGENTS Guide

This repository includes a layered `AGENTS.md` scaffolding workflow so each project can have:
- global baseline behavior
- company-level semantics/constraints
- project-specific overrides

Canonical always-on policy lives in:
- `guidelines/global/engineering-always.md`

## Layering Model

Instruction precedence:
1. Global: `guidelines/global/engineering-always.md` (entrypoint: `guidelines/global/default.md`)
2. Company: repo-local `.ai/guidelines/company.md` (or custom path in `.ai/agents.toml`)
3. Project: repo-local `.ai/guidelines/project.md` (or custom path in `.ai/agents.toml`)
4. Task-specific user instruction

## Quickstart

Initialize a repository:

```bash
task agents:init REPO=/path/to/repo COMPANY=example-co PROJECT=example-api LANGUAGE=typescript PROFILE=core
```

Initialize + generate context map (`.ai/context/repo_context.md`):

```bash
task agents:onboard REPO=/path/to/repo COMPANY=example-co PROJECT=example-api LANGUAGE=typescript PROFILE=core
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
- `.ai/context/repo_context.md`
- `.mcp-stack.env` (if missing)

## Notes

- The generator is intentionally deterministic so `AGENTS.md` can be regenerated safely.
- Keep company/project guideline files concise and policy-focused.
- Do not put credentials or private identifiers in generated files.

## Suggested Memory Initialization

After `agents:onboard`, seed durable memory for the repo:

1. Read `.ai/context/repo_context.md` and key analysis docs.
2. Store concise architectural/operational decisions in `mcpx-basic-memory`.
3. Store high-signal semantic snippets in `mcpx-qdrant` for fast retrieval.
4. Optionally create an Archon project and add curated documents for team-visible RAG.
