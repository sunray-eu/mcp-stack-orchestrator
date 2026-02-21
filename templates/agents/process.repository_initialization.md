## Repository Initialization Process (Deep Analysis + Memory Seeding)

### Purpose
- Standardize first-time repository/platform initialization so AI agents can operate with high correctness and low rediscovery overhead.
- Build durable, maintainable context artifacts and memory records.

### When to Run
- New repository onboarding.
- Major architecture/platform changes.
- After large refactors, migrations, or integration rewrites.
- When context artifacts are stale or contradictory.

### Inputs
- `AGENTS.md`
- `.ai/guidelines/company.md`
- `.ai/guidelines/project.md`
- Existing `.ai/context/*` files
- Repository docs (README, architecture docs, runbooks, API specs)
- Source code, tests, config and infra manifests

### Step 1: Preflight
1. Confirm repository path and active branch.
2. Record current working-tree state (`git status`) and avoid reverting unrelated changes.
3. If orchestrator tooling exists, validate stack profile health from orchestrator root.

### Step 2: Structural Discovery
1. Enumerate repository structure and module/service boundaries.
2. Identify entrypoints, runtime bootstrap files, and key command surfaces.
3. Map dependencies:
   - internal module dependencies,
   - external services/providers,
   - data/queue/search/messaging dependencies.

### Step 3: Behavioral Analysis
1. Analyze core business workflows end-to-end:
   - trigger,
   - validation/guards,
   - processing path,
   - side effects,
   - failure modes and retries.
2. Analyze contract surfaces:
   - HTTP APIs,
   - async events/queues,
   - integration interfaces.
3. Identify non-functional controls:
   - security,
   - observability,
   - reliability,
   - performance constraints.

### Step 4: Context Artifact Updates
Update/create these files:
- `.ai/context/platform_overview.md` (repository purpose + platform role)
- `.ai/context/repo_context.md` (entrypoints, commands, topology snapshot)
- `.ai/context/architecture_map.md` (component/service architecture)
- `.ai/context/workflow_catalog.md` (business and system workflows)
- `.ai/context/integration_matrix.md` (upstream/downstream interfaces)
- `.ai/context/operational_runbook.md` (run/test/debug/recover commands)
- `.ai/context/risk_register.md` (ranked risks + mitigations)

Requirements:
- Keep claims evidence-based and path-referenced.
- Keep content precise, concise, and operationally useful.
- Redact/omit secrets and sensitive runtime values.

### Step 5: Memory Seeding
Persist only durable, high-signal records into enabled project-scoped memory MCPs:
- architecture decisions and invariants,
- stable commands and troubleshooting outcomes,
- integration constraints and compatibility notes,
- risk/mitigation facts.

Required tags/metadata:
- `company={{COMPANY_SLUG}}`
- `project={{PROJECT_SLUG}}`
- `namespace={{MEMORY_NAMESPACE}}`

### Step 6: Validation
1. Confirm artifact consistency:
   - platform overview aligns with repo context and guidelines,
   - workflow/integration/risk docs do not conflict.
2. Verify primary engineering commands are still accurate.
3. Confirm memory entries are non-sensitive and queryable.

### Step 7: Initialization Report
Produce a short report with:
- analysis coverage,
- artifacts created/updated,
- memory entries seeded,
- top unresolved questions and recommended next actions.

### Definition of Done
- All required context files are present and coherent.
- `AGENTS.md` references living knowledge artifacts and update obligations.
- Memory MCPs contain durable project-scoped initialization knowledge.
- No secrets or transient noise are persisted.
