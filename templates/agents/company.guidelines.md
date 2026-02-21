# Company Guidelines ({{COMPANY_NAME}})

## Baseline Policy
- Always apply global engineering policy first (`guidelines/global/engineering-always.md`).
- Company rules may add stricter constraints but should not weaken global safety/correctness rules.

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
