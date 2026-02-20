# SurrealDB MCP Compatibility

## Current State (2026-02-20)

- Production stack endpoint for Surreal MCP: `http://127.0.0.1:18080/mcp`
- Runtime topology:
  - `surrealmcp-compat` on `:18080` (frontend compatibility layer)
  - `surrealmcp` on `:18084` (backend server)
  - `surrealdb` on `:18083`
- SurrealDB is pinned to `2.3.10` for compatibility with current official `surrealdb/surrealmcp` build.

## Why Pin to 2.3.x

During runtime validation, SurrealDB `3.0.0` caused websocket subprotocol mismatch with current `surrealmcp` release lineage (built with `surrealdb 2.3.x`).

## Compatibility Layer Responsibilities

`infra/compat/surrealmcp-compat.mjs` currently handles:
- OAuth authorization-server probe path compatibility
- missing/ambiguous response content-type normalization
- stale MCP session recovery by bootstrap/replay

## Upgrade TODO (v3)

When official Surreal MCP supports SurrealDB v3 end-to-end:
1. Create a test branch and switch `SURREALDB_IMAGE` to a v3 tag/digest.
2. Re-run:
   - `task infra:up PROFILE=surreal`
   - `task quality:doctor PROFILE=surreal`
   - in-session MCP tool CRUD/query checks
   - Surrealist UI query verification
3. If stable, remove or simplify `surrealmcp-compat`.
4. Update:
   - `infra/versions.env`
   - `scripts/stack_versions.sh`
   - this document
   - recommendation/report files

