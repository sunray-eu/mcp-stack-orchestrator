## Platform Overview

### Repository Identity
- Project: `{{PROJECT_NAME}}`
- Company: `{{COMPANY_NAME}}`
- Primary language: `{{PROJECT_LANGUAGE}}`

### What This Repository Owns
- Describe the repository purpose and bounded context.
- Clarify whether this repo is a runtime service, UI, orchestration/devenv, shared library, or tooling.

### Platform Topology & Related Services
- List upstream/downstream services this repository depends on.
- List sibling services/apps in the same platform and their roles.
- Include integration boundaries (DB, queue, search, billing, auth, analytics, messaging).

### Runtime & Operations
- Entrypoints used in development and production.
- Required infrastructure/services (datastores, queues, external APIs).
- Health checks, critical env vars, and operational commands.

### Engineering Workflow Notes
- Primary local commands (`install`, `dev`, `test`, `lint`, `typecheck`, `build`).
- Expected quality gates.
- Known high-risk areas and ownership hotspots.

### Maintenance Rule (Mandatory)
- Treat this file as a living source of truth.
- Update it in the same change whenever:
  - repository purpose changes,
  - service boundaries or integrations change,
  - runtime/ops workflow changes,
  - major architectural findings are learned.
