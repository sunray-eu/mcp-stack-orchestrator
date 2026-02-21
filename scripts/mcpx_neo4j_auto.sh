#!/usr/bin/env bash
set -euo pipefail

resolve_workspace() {
  local workspace="${MCP_WORKSPACE:-}"
  if [ -z "$workspace" ]; then
    if git -C "$PWD" rev-parse --show-toplevel >/dev/null 2>&1; then
      workspace="$(git -C "$PWD" rev-parse --show-toplevel)"
    else
      workspace="$PWD"
    fi
  fi
  if [ ! -d "$workspace" ]; then
    echo "mcpx-neo4j: workspace does not exist: $workspace" >&2
    exit 2
  fi
  (
    cd "$workspace"
    pwd
  )
}

load_workspace_overrides() {
  local file="$1"
  [ -f "$file" ] || return 0

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '' | '#'*) continue ;;
      *=*) ;;
      *) continue ;;
    esac

    local key="${line%%=*}"
    local val="${line#*=}"
    key="$(echo "$key" | tr -d '[:space:]')"

    case "$val" in
      \"*\")
        val="${val#\"}"
        val="${val%\"}"
        ;;
      \'*\')
        val="${val#\'}"
        val="${val%\'}"
        ;;
    esac

    case "$key" in
      NEO4J_URI | NEO4J_USERNAME | NEO4J_PASSWORD | NEO4J_DATABASE | NEO4J_READ_ONLY | NEO4J_TELEMETRY | NEO4J_SCHEMA_SAMPLE_SIZE | MCP_NEO4J_VERSION | MCP_NEO4J_CMD | MCP_NEO4J_DRY_RUN)
        export "$key=$val"
        ;;
      *) ;;
    esac
  done <"$file"
}

workspace="$(resolve_workspace)"
load_workspace_overrides "$workspace/.mcp-stack.env"

export NEO4J_URI="${NEO4J_URI:-bolt://127.0.0.1:17687}"
export NEO4J_USERNAME="${NEO4J_USERNAME:-neo4j}"
export NEO4J_PASSWORD="${NEO4J_PASSWORD:-testpass}"
export NEO4J_DATABASE="${NEO4J_DATABASE:-neo4j}"
export NEO4J_READ_ONLY="${NEO4J_READ_ONLY:-true}"
export NEO4J_TELEMETRY="${NEO4J_TELEMETRY:-false}"
export NEO4J_SCHEMA_SAMPLE_SIZE="${NEO4J_SCHEMA_SAMPLE_SIZE:-100}"
MCP_NEO4J_VERSION="${MCP_NEO4J_VERSION:-v1.4.1}"

if [ "${MCP_NEO4J_DRY_RUN:-0}" = "1" ]; then
  echo "workspace=$workspace"
  echo "NEO4J_URI=$NEO4J_URI"
  echo "NEO4J_USERNAME=$NEO4J_USERNAME"
  echo "NEO4J_DATABASE=$NEO4J_DATABASE"
  echo "NEO4J_READ_ONLY=$NEO4J_READ_ONLY"
  echo "NEO4J_TELEMETRY=$NEO4J_TELEMETRY"
  echo "NEO4J_SCHEMA_SAMPLE_SIZE=$NEO4J_SCHEMA_SAMPLE_SIZE"
  echo "MCP_NEO4J_VERSION=$MCP_NEO4J_VERSION"
  exit 0
fi

if [ -n "${MCP_NEO4J_CMD:-}" ]; then
  exec "$MCP_NEO4J_CMD" "$@"
fi

if command -v neo4j-mcp >/dev/null 2>&1; then
  exec neo4j-mcp \
    --neo4j-uri "$NEO4J_URI" \
    --neo4j-username "$NEO4J_USERNAME" \
    --neo4j-password "$NEO4J_PASSWORD" \
    --neo4j-database "$NEO4J_DATABASE" \
    --neo4j-read-only "$NEO4J_READ_ONLY" \
    --neo4j-telemetry "$NEO4J_TELEMETRY" \
    --neo4j-schema-sample-size "$NEO4J_SCHEMA_SAMPLE_SIZE" \
    "$@"
fi

if ! command -v go >/dev/null 2>&1; then
  echo "mcpx-neo4j: neo4j-mcp not found and go is unavailable for fallback." >&2
  exit 3
fi

exec go run "github.com/neo4j/mcp/cmd/neo4j-mcp@${MCP_NEO4J_VERSION}" \
  --neo4j-uri "$NEO4J_URI" \
  --neo4j-username "$NEO4J_USERNAME" \
  --neo4j-password "$NEO4J_PASSWORD" \
  --neo4j-database "$NEO4J_DATABASE" \
  --neo4j-read-only "$NEO4J_READ_ONLY" \
  --neo4j-telemetry "$NEO4J_TELEMETRY" \
  --neo4j-schema-sample-size "$NEO4J_SCHEMA_SAMPLE_SIZE" \
  "$@"
