# Docker Runtime Audit and Cleanup

Date: 2026-02-20

## Scope
- Verify all Docker containers related to the AI MCP runtime.
- Keep only required runtime containers.
- Remove stale evaluation containers.
- Normalize naming to production convention.

## Naming Convention Applied
- Runtime containers: `ai-mcp-*`
- Supabase project: `ai-mcp-archon`
- Managed MCP server IDs: `mcpx-*`

## Required Runtime Containers (kept)
- `ai-mcp-qdrant`
- `ai-mcp-surreal-mcp`
- `ai-mcp-surrealist`
- `ai-mcp-archon-server`
- `ai-mcp-archon-mcp`
- `ai-mcp-archon-ui`
- `ai-mcp-docs-mcp`

## Host Filesystem Access Policy (Docker MCP)
- All MCP-serving containers use read-only host filesystem mounts for local indexing and retrieval:
  - Host `/` mounted to `/hostfs`
  - Host `/Users` mounted to `/Users`
- Scope: `ai-mcp-docs-mcp`, `ai-mcp-surreal-mcp`, `ai-mcp-archon-server`, `ai-mcp-archon-mcp`
- Rationale: maximize local retrieval capability while blocking host writes from containers.

## Removed Containers (stale eval/test)
- `memcp-eval-postgres`
- `mcp-eval-ollama`
- `mcp-eval-qdrant`
- `letta-local`
- `rabbitmq`
- `redis`
- Legacy names after migration: `mcp-eval-surrealmcp`, `archon-server`, `archon-mcp`

## Current Runtime Verification
- `docker ps -a` contains only the required `ai-mcp-*` runtime containers.
- Qdrant API and dashboard return `200`.
- Archon API/MCP/UI endpoints return `200`.
- Surreal MCP endpoint is reachable on `/mcp` (plain probe returns `406`, expected for MCP streamable protocol).
- Surrealist UI returns `200`.
- Docs MCP UI returns `200`; `/mcp` endpoint returns `405` on `GET` probe (method mismatch expected).
- Docs MCP embeddings now initialize successfully with OpenAI provider (`Embeddings: openai:text-embedding-3-small`) after runtime env wiring from `<STACK_ROOT>/.secrets.env`.

## Infra Naming/Script Updates
- Surreal container name updated in:
  - `<STACK_ROOT>/infra/docker-compose.yml`
- Archon naming override added:
  - `<STACK_ROOT>/infra/archon.compose.override.yml`
- Infra manager updated for project-scoped compose runs and safe env parsing:
  - `<STACK_ROOT>/scripts/stack_infra.sh`
- Restore logic updated for new names and env path fallback:
  - `<STACK_ROOT>/scripts/restore_original.sh`

## Supabase Naming Verification
- Project ref: `gydtkaqliotvwasgyubw`
- Project name: `ai-mcp-archon`
- Status: `ACTIVE_HEALTHY`

## Operational Commands
- Start full runtime:
```bash
<STACK_ROOT>/scripts/stack_activate.sh full
```
- Check runtime status:
```bash
<STACK_ROOT>/scripts/stack_infra.sh status
```
- Stop runtime:
```bash
<STACK_ROOT>/scripts/stack_infra.sh down full
```

Endpoint status artifact:
- `<STACK_ROOT>/report/ui_endpoint_status.tsv`
