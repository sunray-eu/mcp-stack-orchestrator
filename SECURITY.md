# Security Policy

## Supported Scope

This project orchestrates MCP tooling and local/remote infra. Security-sensitive areas:

- Credential handling in `.secrets.env`
- Agent config mutation scripts
- Docker compose service definitions and host mounts

## Reporting a Vulnerability

Please report privately via GitHub security advisories for this repository.

Include:

- Impacted file(s)
- Reproduction steps
- Potential blast radius
- Proposed mitigation (if available)

## Operational Security Requirements

- Never commit `.secrets.env` or generated runtime env files.
- Keep host mounts read-only unless there is a justified exception.
- Treat third-party MCP services as untrusted until reviewed.
