# Global AI Engineering Guidelines

This is the compact entrypoint for global guidance.

Canonical always-on policy:
- `guidelines/global/engineering-always.md`

Policy precedence:
1. Global baseline (this folder)
2. Company guideline overrides (`.ai/guidelines/company.md`)
3. Project/repository guidelines (`.ai/guidelines/project.md`)
4. Task-specific user instructions

Minimum expectations:
- Correctness, security, and reproducibility over speed hacks.
- Exact typing and boundary validation (no cast-to-compile workarounds).
- Small, reversible changes with explicit test evidence.
- Documentation and operational impact updated with code changes.
