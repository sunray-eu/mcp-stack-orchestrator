# AGENTS.md

## Scope
- Project: `mcp-stack-orchestrator`
- Company context: `multi-company`
- Primary language: `polyglot`
- Default MCP profile: `full`
- Optional MCP profiles: `core-surreal, core-archon, full`
- Memory namespace: `mcp-stack-orchestrator`
- Qdrant collection: `proj-mcp-stack-orchestrator`

## Instruction Precedence
Apply instructions in this order:
1. Global baseline guidelines
2. Company guidelines/semantics
3. Project/repository guidelines
4. Task-specific user instructions

## MCP Tool Routing
- `mcpx-lsp`: symbol navigation, definitions/references, safe refactors, diagnostics.
- `mcpx-qdrant`: fast semantic recall of decisions/snippets and cross-session context lookup.
- `mcpx-basic-memory`: long-term project memory and notes.
- `mcpx-chroma`: local vector fallback/experiments.
- `mcpx-archon-http` (when enabled): project/task/doc workflows and RAG on ingested sources.
- `mcpx-surrealdb-http` (when enabled): structured graph/document operations and local DB-backed experiments.

## Standard Workflow
1. Confirm active profile and stack health:
   - `task infra:status`
   - `task quality:doctor PROFILE=full`
2. For net-new repo understanding, run the bootstrap prompt below.
3. Store stable decisions in memory (`mcpx-qdrant` and/or `mcpx-basic-memory`).
4. For company-sensitive tasks, apply company guideline overrides before coding.

## Bootstrap Prompt
```text
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
```

## Memory Update Prompt
```text
You are updating persistent project memory for "mcp-stack-orchestrator".

Goal:
- Capture durable, high-signal information only.
- Keep memory concise, factual, and reusable.

Workflow:
1. Collect final implementation decisions:
   - APIs changed
   - migration/infra changes
   - operational commands added/updated
   - known limitations and TODOs
2. Save short, searchable records using:
   - `mcpx-qdrant` for semantic snippets/decisions
   - `mcpx-basic-memory` for structured notes
3. Include references to source files and commands.
4. Exclude transient details (timestamps, temporary errors, secrets).

Required memory tags:
- company: `multi-company`
- project: `mcp-stack-orchestrator`
- namespace: `mcp-stack-orchestrator`

Output:
- bullet list of memory entries created/updated
- one-paragraph summary of current project state
```

## Global Guidelines
Source: `${STACK_ROOT}/guidelines/global/default.md`
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

## Company Guidelines
Source: `.ai/guidelines/company.md`
# Company Guidelines (multi-company)

## Sensitive Data
- Never include secrets, production credentials, internal endpoints, customer data, or NDA-protected details in commits or logs.
- Redact company-specific names when generating public reports or examples.

## Governance
- Follow company-approved security/compliance controls before shipping infra or automation changes.
- Prefer reversible changes with clear rollback instructions.

## Review Expectations
- Require concise change summaries with impacted paths and validation evidence.
- Escalate when instructions conflict with compliance or security policy.

## Overrides
- Add company-specific coding standards, legal constraints, and deployment rules below this line.

## Project Guidelines
Source: `.ai/guidelines/project.md`
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
