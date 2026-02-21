# New-Wave Compatibility Retest (2026-02-21)

## Scope

Retested the three previously failing candidates from the new-wave batch:

1. `CodeGraphContext/CodeGraphContext`
2. `danyQe/codebase-mcp`
3. `NgoTaiCo/mcp-codebase-index`

Goal: verify whether failures were true runtime incompatibilities or transport/startup issues that can be remediated.

Probe dataset: `report/data/new_wave_compat_probes.tsv`

## Findings

### 1) CodeGraphContext

- Framed stdio MCP probe (`Content-Length` transport): failed.
- Root cause: server reads newline-delimited JSON-RPC from stdin (legacy transport), not framed stdio.
- Compatibility retest using newline JSON-RPC: passed initialize + tools/list + tool call.
- Decision: **conditionally viable** via adapter; keep out of default profile due compatibility overhead.

### 2) codebase-mcp

- Framed stdio MCP probe: failed.
- Root cause: server expects newline JSON-RPC transport in this implementation path.
- Compatibility retest using newline JSON-RPC: passed initialize + tools/list + tool call.
- Operational caveat: meaningful tool behavior depends on separate FastAPI backend at `localhost:6789`.
- Decision: **not recommended for default stack**; setup/ops friction remains high despite transport fix.

### 3) mcp-codebase-index

- Framed stdio MCP probe: failed under default startup path.
- Root cause: runtime `console.log` output on stdout pollutes protocol channel; strict clients cannot parse stream reliably.
- Compatibility retest:
  - redirected runtime logs to stderr,
  - kept MCP responses on stdout channel,
  - initialize + tools/list + `indexing_status` tool call succeeded.
- Operational caveat: stable indexing still requires valid `GEMINI_API_KEY` + Qdrant credentials/quota.
- Decision: **conditionally viable** via wrapper, but not default-profile material.

## Integration Recommendation Update

- Keep default production profile focused on native-compatible, low-friction servers.
- Treat these three candidates as **experimental compatibility entries**:
  - useful for targeted evaluation or niche workflows,
  - not suitable for always-on baseline due adapter/supervision/credential burden.

## Scoring Update (post-retest)

- `CodeGraphContext`: `5.4 -> 6.0`
- `danyQe/codebase-mcp`: `4.7 -> 5.3`
- `NgoTaiCo/mcp-codebase-index`: `4.6 -> 5.1`

The score uplift reflects successful technical remediation paths, not default-stack promotion.
