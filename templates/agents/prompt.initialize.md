You are performing deep repository/platform initialization for "{{PROJECT_NAME}}" (company: {{COMPANY_NAME}}).

Goal:
- Build complete, evidence-based understanding of the repository and its platform role.
- Produce durable project knowledge artifacts and seed memory MCP stores with high-signal facts.
- Leave the repository ready for high-correctness implementation work with minimal future rediscovery cost.

Strict rules:
- Do not guess. Every architectural or behavioral claim must be traceable to code/docs/config.
- Prefer repository truth over assumptions.
- Never store secrets, tokens, or PII in artifacts or memory backends.
- Keep updates reversible and auditable.

Execution workflow:
1. Load instruction baseline:
   - `AGENTS.md`
   - `.ai/guidelines/project.md`
   - `.ai/context/platform_overview.md`
   - `.ai/context/repo_context.md`
2. If MCP stack orchestrator tooling is available, verify stack health from stack root:
   - `cd {{STACK_ROOT}}`
   - `task infra:status`
   - `task quality:doctor PROFILE={{DEFAULT_PROFILE}}`
   If orchestrator tooling is unavailable in this environment, skip this step.
3. Perform full repository/platform analysis:
   - repository purpose and bounded context
   - service/component topology
   - runtime architecture and entrypoints
   - business workflows and state transitions
   - integration boundaries (DB/queue/search/billing/auth/observability/external APIs)
   - API contracts/events and cross-service dependencies
   - operational workflows (dev/test/build/deploy/rollback)
   - quality/security/reliability posture and top risks
4. Update context artifacts (create if missing):
   - `.ai/context/platform_overview.md`
   - `.ai/context/repo_context.md`
   - `.ai/context/architecture_map.md`
   - `.ai/context/workflow_catalog.md`
   - `.ai/context/integration_matrix.md`
   - `.ai/context/operational_runbook.md`
   - `.ai/context/risk_register.md`
5. Persist durable knowledge to memory MCPs (all enabled project-scoped stores):
   - architecture decisions and invariants
   - stable commands and troubleshooting outcomes
   - integration assumptions and dependency constraints
   - known risks and mitigations
6. Produce a concise initialization report summarizing:
   - what was analyzed
   - artifacts updated
   - memory entries created
   - unresolved questions / follow-up tasks

Output requirements:
- Provide a component/service map with clear ownership boundaries.
- Provide business-workflow mapping with trigger -> action -> side effect.
- Provide integration matrix with directionality (upstream/downstream).
- Provide top risks ordered by impact and confidence.
- Include exact file references for key claims.
