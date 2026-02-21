# Engineering Operating Standard (Always-On)

This document is the canonical, always-on engineering policy for AI agents and developers using this stack.
Apply it by default in every repository unless a stricter policy is explicitly required.

## 0) North Star Principles (Non-Negotiables)

1. Correctness over cleverness. Prefer simple, provable behavior to smart code.
2. Readability is a feature. Code is primarily read and maintained, not written.
3. Make invalid states unrepresentable. Use types, invariants, schemas, and constraints.
4. Strong, exact typing with no shortcuts. Use precise types and type-safe designs; avoid casts and workarounds.
5. Avoid workarounds; implement exact fixes. Fix root causes, not symptoms.
6. Make changes with certainty. If anything is unclear, verify via docs/code/context instead of guessing.
7. Prefer native framework features. Use framework/library capabilities before reinventing.
8. Small, reversible changes beat big-bang rewrites.
9. Measure, do not guess. Use profiling, logs, metrics, and tests.
10. Security and privacy by default. Use least privilege, safe inputs, and safe outputs.
11. Automate quality. Enforce CI gates, formatting, linting, type checking, testing, and scanning.
12. Design for operation. Include observability, debuggability, and rollback plans.
13. Consistency beats preference. Conventions reduce cognitive load.
14. Document decisions, not trivia. Capture intent, constraints, and tradeoffs; keep docs exact where it matters.

## 1) Agent Semantics

### 1.1 Roles (Use One or Many)

- Product/Requirements Agent: clarifies goals, constraints, acceptance criteria, and edge cases.
- Architect Agent: proposes design, boundaries, data flows, failure modes, ADRs.
- Implementation Agent: writes code in small increments with tests.
- Test/QA Agent: expands coverage, integration/e2e tests, fuzzing, negative cases.
- Security Agent: threat model, input validation, authZ/authN review, secrets, SAST/DAST.
- Performance Agent: profiling plan, load testing, caching, algorithm choices.
- Docs/DevEx Agent: docs, examples, onboarding, tooling, CI, runbooks.

### 1.2 Standard Agent Output Format (Mandatory)

1. Goal: What user-visible/system goal the change achieves.
2. Assumptions and Constraints: Explicit list.
3. Plan: Small steps, each independently shippable.
4. Patch/Diff: Minimal, focused changes; no unrelated refactors.
5. Tests: Added/updated tests and exact commands.
6. Risk and Rollback: Risks, mitigations, flags, rollback plan.
7. Docs: Documentation updated/required.

### 1.3 No-Hallucination Rules

- If uncertain, say what is uncertain and provide verification steps.
- Never invent APIs, endpoints, config keys, library behavior, or framework semantics.
- Prefer referencing existing repository patterns.
- Never log or expose production data or secrets.
- Be 100 percent sure before implementing.
- For any library/framework used, verify latest syntax/docs or exact pinned-version docs first.

### 1.4 Change Size Semantics

- Default PR size: <= 300 lines changed (excluding generated files).
- Larger refactors: split into preparatory non-functional changes, behavior change behind a flag, then cleanup.

### 1.5 Stop Conditions

Stop and escalate when:

- Requirements are contradictory or missing critical acceptance criteria.
- Security boundaries are affected (auth, payments, PII) without review.
- Test strategy cannot validate correctness.
- Migration risks data integrity.
- Typed contracts are unclear or being forced; redesign types/contracts instead of casting.

### 1.6 Tooling, MCP, and Memory Orchestration (Mandatory)

- For best task completion, use any available and relevant capability: MCP servers, internal tools, skills, and web search.
- At task start, discover available tools and choose the best-fit path instead of defaulting to a single tool.
- Prefer local-first and low-risk execution paths, but use remote/provider tools when they materially improve correctness or speed.
- For framework/library behavior, verify against primary sources (official docs, upstream repos, version-accurate references) before implementation.
- Use specialized tools by intent:
  - Context/documentation tools for syntax and API semantics.
  - Repository/code graph/search tools for codebase navigation and impact analysis.
  - Runtime/infra tools for health checks, logs, and environment verification.
  - Security/scanning tools for sensitive or high-risk changes.
- Apply relevant skills whenever a matching skill exists for the task.

#### Memory Persistence Policy

- Persist durable, reusable project knowledge in all enabled memory-capable MCP backends when available (for example: qdrant, basic-memory, chroma, archon, surreal-backed memory tools).
- Store high-signal content only:
  - architecture decisions,
  - stable commands/workflows,
  - invariants and constraints,
  - known risks and mitigations,
  - validated troubleshooting outcomes.
- Keep memory entries structured and searchable with consistent tags/metadata (company, project, namespace).
- Never store secrets, tokens, personal data, or transient/debug noise in memory systems.
- When multiple memory stores are enabled, keep records semantically aligned (same facts, adapted format) to reduce retrieval drift.

## 2) End-to-End Developer Workflow

### Stage A: Discovery

Artifacts:

- Problem statement (1-5 sentences)
- Success metrics (business + technical)
- Constraints (latency, cost, regulation, deadlines, platform)
- Acceptance criteria (Given/When/Then)
- Tech context (frameworks/libraries, versions, ecosystem constraints)

Checklist:

- Who are the users?
- What does done look like?
- Edge cases: empty inputs, duplicates, concurrency, partial failure, retries.
- Backward compatibility expectations.
- What already exists internally and externally?

### Stage B: Design

Deliver:

- Architecture diagram (boxes/arrows)
- Interfaces/contracts (API schemas, events, DB schema)
- Failure modes/recovery (timeouts, retries, idempotency)
- ADR for meaningful decisions
- Type/contract design with invariants and validation strategy

Design rules:

- Clear boundaries with minimal coupling.
- One source of truth per domain entity.
- Avoid distributed transactions unless required; prefer saga/outbox patterns.
- Prefer native framework solutions when requirements are met.

### Stage C: Implementation

- Work in small increments; keep main branch releasable.
- Add tests for new behavior and bugs.
- Keep code idiomatic.
- Exact typing only; no cast-to-compile workarounds.
- Before building, deliberately scan for existing internal modules, framework-native features, or reputable libraries.

### Stage D: Verification

- Unit tests for logic/invariants
- Integration tests for IO
- Contract tests for APIs/events
- E2E tests for critical flows
- Load tests for performance-critical paths
- Security tests for auth/input validation/permissions

### Stage E: Release

- Feature flags for risky changes
- Canary/staged rollout
- Monitoring/alerts updated
- Migration plan validated (including rollback)

### Stage F: Operate

- Runbook ready
- SLO/error-budget awareness where applicable
- Post-incident reviews focus on systemic fixes

### Stage G: Improve

- Refactor hotspots measured by churn/bugs
- Budget tech debt paydown
- Routine dependency/security updates
- Keep docs and types current with behavior/contracts

## 3) Code Quality Core

### 3.1 Readability and Maintainability

- Prefer clear naming over comments.
- Functions should do one thing and stay easy to scan.
- Keep cyclomatic complexity low.
- Use guard clauses for invalid states.
- Avoid boolean parameters that hide intent.

Naming:

- Nouns for data: `invoice`, `userProfile`
- Verbs for actions: `calculateTotal`, `fetchOrders`
- `is/has/can/should` for booleans

### 3.2 Modularity and Boundaries

- Separate pure domain logic, side effects, and orchestration.
- Depend on interfaces, not concrete implementations.
- Avoid god modules and generic utils dumping grounds.
- Prefer domain/feature grouping with explicit public APIs.

### 3.3 DRY vs Duplication

- Duplicate knowledge is bad.
- Duplicate code can be acceptable if it avoids premature abstraction.
- Abstract when there are at least three meaningful repetitions and complexity is reduced.

### 3.4 Error Handling

- Errors must be actionable, structured, and contextual without leaking secrets.
- Do not swallow exceptions.
- Prefer typed error models at boundaries.

### 3.5 Logging

- Use structured logs with trace/request identifiers.
- Respect severity levels.
- Never log secrets or disallowed sensitive data.
- Log boundaries/state transitions, not every line.

### 3.6 Determinism and Purity

- Prefer pure functions.
- Isolate time, randomness, and network into adapters.
- Inject clock/UUID/external dependencies for testability.

### 3.7 Concurrency and Idempotency

- Retryable operations must be idempotent or guarded.
- Use idempotency keys for write APIs.
- Protect shared state with constraints/transactions/locking as needed.

### 3.8 Strong and Exact Typing (Mandatory)

- No unsafe assertions/workarounds except audited boundary adapters with tests.
- Model domains with discriminated unions, branded types (where appropriate), precise generics, and boundary validation.
- Convert untyped input to typed domain values via parsing/validation with explicit error paths.

## 4) Architecture and API Design Rules

### 4.1 API Contracts

- Version APIs intentionally.
- Validate input at boundaries.
- Use consistent error format (`code`, `message`, `details`, `request_id`).
- Keep types/interfaces and API docs aligned with behavior.

### 4.2 Data Modeling

- Define invariants (uniqueness, non-null, ranges).
- Enforce invariants at DB layer where possible.
- Avoid storing derived data without a consistency strategy.

### 4.3 Event-Driven Patterns

- Use outbox for reliable event publishing.
- Version event schemas.
- Consumers tolerate unknown fields.

### 4.4 Configuration

- Validate config at startup.
- Use safe defaults.
- Document all config keys.
- Never commit secrets.

## 5) Testing Gold Standard

### 5.1 Pyramid

- Many unit tests
- Some integration tests
- Few critical-flow E2E tests

### 5.2 Every New Feature Needs

- Happy-path test
- At least one negative/edge case
- One invariant assertion
- Regression test for bug fixes

### 5.3 Test Quality Rules

- Deterministic and isolated tests.
- Avoid sleep-based timing.
- Use factories/builders for test data.
- Assert behavior/outcomes, not internals.

### 5.4 Advanced Practices (When Valuable)

- Property-based testing
- Fuzzing
- Mutation testing for critical modules
- Contract tests

## 6) Security and Privacy by Default

### 6.1 Core Rules

- Least privilege everywhere.
- Validate/sanitize inputs.
- Output encode to prevent injection.
- Separate authentication from authorization.
- Never trust client-side checks.

### 6.2 Secrets

- Secrets only in managers/env injection.
- Rotate secrets, support key rollover.
- Prevent accidental secret logging.

### 6.3 Supply Chain Security

- Pin dependencies and keep lockfiles.
- Run vulnerability scanning.
- Verify provenance for critical artifacts where supported.
- Keep dependencies minimal.
- Evaluate candidate libraries (maintenance, CVEs, ownership reputation, API stability, license, transitive deps).

### 6.4 Lightweight Threat Modeling

For auth/payments/PII/admin-sensitive features:

- Identify assets, actors, entry points.
- Enumerate STRIDE-like threats.
- Document mitigations and tests.

## 7) Reliability and Observability

### 7.1 Operational Requirements

- Liveness/readiness checks
- Timeouts and retries (with backoff + jitter)
- Circuit breakers
- Bulkheads/concurrency limits

### 7.2 Observability

- Structured logs + trace IDs
- Metrics: latency, error rate, throughput, saturation
- End-to-end traces
- Dashboards aligned to UX + internals

### 7.3 SLO Mindset

Track availability, latency (p95/p99), correctness/error budget, and freshness where relevant.

## 8) Performance Engineering

### 8.1 Default Rules

- Make it correct first.
- Optimize only when needed and measured.
- Focus highest-impact paths first.

### 8.2 High-Leverage Practices

- Avoid N+1 queries; batch/paginate.
- Cache with TTL/invalidation/stampede strategy.
- Use async/concurrency only where it improves throughput and reasoning remains clear.
- Choose algorithms/data structures with explicit complexity tradeoffs.

## 9) Git, Branching, and Collaboration

### 9.1 Branching Strategy

- Trunk-based development.
- Small PRs to main.
- Feature flags for incomplete work.
- Short-lived branches.

### 9.2 Commit Messages

Use Conventional Commits (for example, `feat(scope): ...`, `fix(scope): ...`).

### 9.3 PR Discipline

Every PR should cover what changed, why, how to test, and risk/rollback.
Keep scope focused; split mixed concerns.
Update docs when behavior/contracts/usage changes.

### 9.4 Code Review Rubric

- Correctness and edge cases
- Simplicity and clarity
- Test quality
- Security impact
- Observability/operability
- Backward compatibility and migrations
- Performance impact
- Typing rigor
- Reuse of existing/native solutions

## 10) Tooling and Automation

### 10.1 Local DX

Provide one-command setup/test/lint/run where feasible.
Use pre-commit hooks for format/lint/type/security checks.

### 10.2 CI Gates (Minimum)

- Format check
- Lint
- Type check
- Unit tests
- Integration tests (when applicable)
- Dependency vulnerability scan
- License policy check (when relevant)

Optional for critical systems: SAST, container scanning, IaC scanning, DAST, mutation testing.

### 10.3 Reproducibility

- Lock dependencies and version toolchains.
- Favor deterministic builds.
- Ensure syntax/implementation matches latest or pinned-version docs.

## 11) Documentation That Helps

### 11.1 Must-Have Docs

- README (run/test/deploy basics)
- Architecture overview
- ADR log
- Incident runbooks
- API docs
- Changelog

### 11.2 Comment Rule

- Comment why, not what.
- Refactor first when code is hard to read.
- Document tricky invariants and non-obvious constraints.
- Keep inline docs precise and updated (TSDoc/JSDoc/docstrings/etc.).

## 12) Release Engineering and Deployment Safety

### 12.1 Versioning

Use semantic versioning for libraries; services should still tag and maintain changelogs.

### 12.2 Feature Flags

Each flag needs owner, expiry, default, and cleanup ticket.
Remove stale flags.

### 12.3 Migrations

Prefer backward-compatible sequence:

1. add new schema,
2. dual-write if needed,
3. backfill,
4. switch reads,
5. remove old schema.

Always define rollback strategy including data concerns.

### 12.4 Deployment Patterns

Use canary/blue-green/rolling/staged based on risk.
Use automatic rollback triggers for error/latency regressions.

## 13) Technical Debt, Refactoring, and Long-Term Health

### 13.1 Debt Policy

Track debt explicitly by impact (velocity, reliability, security).
Reserve recurring capacity for debt paydown.

### 13.2 Refactoring Practices

Refactor with tests in place.
Preserve behavior first, then change behavior.
Use strangler patterns for large subsystem replacement.

### 13.3 Deprecation Policy

Announce, provide migration path, measure usage, remove after grace period.

## 14) Definition of Ready and Done

### Definition of Ready

Task is ready when goal/scope, acceptance criteria, dependencies, risks, test approach, framework/library context, and existing-solution scan are complete.

### Definition of Done

Task is done when code is merged, tests/lint/typecheck pass, security/observability reviewed, docs updated, rollout/rollback defined, typing is exact, and inline docs are current.

## 15) Templates

### 15.1 ADR Template

```md
# ADR-XXXX: <Title>

## Status
Proposed | Accepted | Deprecated | Superseded

## Context
What problem are we solving? What constraints exist?

## Decision
What did we decide?

## Alternatives Considered
1) ...
2) ...

## Consequences
Pros, cons, risks, operational impact.

## Notes
Links, references, follow-ups.
```

### 15.2 PR Template

```md
## What
<summary of change>

## Why
<context / problem>

## How
<approach + key tradeoffs>

## Testing
- [ ] Unit:
- [ ] Integration:
- [ ] E2E:
Commands:
- `...`

## Risk
- Risk:
- Mitigation:
- Rollback:
- Feature flag:

## Typing and Docs (required)
- [ ] Exact types (no unsafe assertions/workarounds)
- [ ] Runtime validation aligns with types (at boundaries)
- [ ] Docs updated (README/ADR/API docs/runbooks)
- [ ] Inline docs updated/added (TSDoc/JSDoc/docstrings)
```

### 15.3 Code Review Checklist

```md
- [ ] Correctness + edge cases
- [ ] Readable naming and structure
- [ ] No unnecessary complexity
- [ ] Tests meaningful and cover failure modes
- [ ] Errors handled and observable
- [ ] No secrets/PII leaks
- [ ] Backward compatibility considered
- [ ] Performance impact understood
- [ ] Exact typing (no unsafe assertions/workarounds)
- [ ] Uses native framework features where appropriate
- [ ] Docs + inline docs updated with changes
```

## 16) Best-Default Enforced Rules (Short List)

1. Format automatically.
2. Type check where possible.
3. Strong, exact typing with no unsafe casts/workarounds.
4. Every change has tests or explicit justification.
5. No PR over 300 changed lines without a split plan.
6. No secrets in code or logs.
7. Validate inputs at boundaries.
8. Idempotency for retries.
9. Timeouts on network calls.
10. Structured logging with request IDs.
11. Document decisions with ADRs; keep docs in sync.
12. Main branch remains releasable (flags + staged rollout).

## 17) Practical Org Rollout

- Start with tooling + CI gates.
- Add PR template + review checklist (typing + docs gates).
- Add DoR/DoD into planning workflow.
- Establish observability baseline (request IDs, structured logging).
- Use feature flags + staged rollout for risk.
- Add security and secret scanning early.
- Add a library-adoption process (fit, security/maintenance, pinned versions, documented usage).
- Iterate using lead time, failure rate, and MTTR metrics.
