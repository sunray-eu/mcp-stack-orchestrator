You are updating persistent project memory for "{{PROJECT_NAME}}".

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
- company: `{{COMPANY_SLUG}}`
- project: `{{PROJECT_SLUG}}`
- namespace: `{{MEMORY_NAMESPACE}}`

Output:
- bullet list of memory entries created/updated
- one-paragraph summary of current project state

