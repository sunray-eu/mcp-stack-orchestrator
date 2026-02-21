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
    esac
    case "$line" in
      *=*) ;;
      *) continue ;;
    esac

    local key="${line%%=*}"
    local val="${line#*=}"
    key="$(echo "$key" | tr -d '[:space:]')"

    # Strip one pair of surrounding quotes if present.
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
      MCP_QDRANT_COLLECTION_MODE | MCP_QDRANT_COLLECTION | QDRANT_URL | QDRANT_API_KEY | QDRANT_LOCAL_PATH | EMBEDDING_PROVIDER | EMBEDDING_MODEL | TOOL_STORE_DESCRIPTION | TOOL_FIND_DESCRIPTION | FASTMCP_LOG_LEVEL | FASTMCP_DEBUG | MCP_QDRANT_DRY_RUN)
        export "$key=$val"
        ;;
      *) ;;
    esac
  done <"$file"
}

slugify() {
  local raw="$1"
  echo "$raw" |
    tr '[:upper:]' '[:lower:]' |
    sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

workspace="$(resolve_workspace)"
workspace_name="$(basename "$workspace")"
workspace_slug="$(slugify "$workspace_name")"
if [ -z "$workspace_slug" ]; then
  workspace_slug="workspace"
fi

load_workspace_overrides "$workspace/.mcp-stack.env"

collection_mode="${MCP_QDRANT_COLLECTION_MODE:-workspace}"
collection_name=""
case "$collection_mode" in
  workspace)
    collection_name="${MCP_QDRANT_COLLECTION:-proj-${workspace_slug}}"
    ;;
  global)
    collection_name="${MCP_QDRANT_COLLECTION:-global}"
    ;;
  manual)
    collection_name=""
    ;;
  *)
    echo "mcpx-qdrant: unsupported MCP_QDRANT_COLLECTION_MODE=$collection_mode" >&2
    exit 2
    ;;
esac

if [ -n "${QDRANT_LOCAL_PATH:-}" ]; then
  unset QDRANT_URL || true
else
  export QDRANT_URL="${QDRANT_URL:-http://127.0.0.1:6333}"
fi
export EMBEDDING_PROVIDER="${EMBEDDING_PROVIDER:-fastembed}"
export EMBEDDING_MODEL="${EMBEDDING_MODEL:-sentence-transformers/all-MiniLM-L6-v2}"
export TOOL_STORE_DESCRIPTION="${TOOL_STORE_DESCRIPTION:-Store important implementation decisions, snippets, and notes. Include metadata.project_path and metadata.project_name when available.}"
export TOOL_FIND_DESCRIPTION="${TOOL_FIND_DESCRIPTION:-Find relevant notes/snippets for the current coding task. Prefer records from current project metadata, then fallback to broader matches.}"

if [ -n "$collection_name" ]; then
  export COLLECTION_NAME="$collection_name"
else
  unset COLLECTION_NAME || true
fi

if [ "${MCP_QDRANT_DRY_RUN:-0}" = "1" ]; then
  echo "workspace=$workspace"
  echo "workspace_name=$workspace_name"
  echo "workspace_slug=$workspace_slug"
  echo "collection_mode=$collection_mode"
  echo "collection_name=${collection_name:-<manual>}"
  echo "QDRANT_URL=${QDRANT_URL:-<unset>}"
  echo "QDRANT_LOCAL_PATH=${QDRANT_LOCAL_PATH:-<unset>}"
  echo "EMBEDDING_PROVIDER=$EMBEDDING_PROVIDER"
  echo "EMBEDDING_MODEL=$EMBEDDING_MODEL"
  exit 0
fi

exec uvx mcp-server-qdrant "$@"
