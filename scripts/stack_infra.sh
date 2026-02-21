#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_COMPOSE="${STACK_ROOT}/infra/docker-compose.yml"
INFRA_VERSIONS_ENV="${STACK_ROOT}/infra/versions.env"
INFRA_PROJECT="ai-mcp-infra"
ARCHON_DIR="${STACK_ROOT}/servers/coleam00-Archon"
ARCHON_BASE_COMPOSE="${ARCHON_DIR}/docker-compose.yml"
ARCHON_OVERRIDE_COMPOSE="${STACK_ROOT}/infra/archon.compose.override.yml"
ARCHON_PROJECT="ai-mcp-archon"
SECRETS_FILE="${STACK_ROOT}/.secrets.env"
ARCHON_RUNTIME_ENV="${STACK_ROOT}/tmp/ai-mcp-archon.env"
INFRA_RUNTIME_ENV="${STACK_ROOT}/tmp/ai-mcp-infra.env"
SURREALIST_INSTANCE_RUNTIME="${STACK_ROOT}/tmp/surrealist-instance.json"
ARCHON_REPO_URL="${ARCHON_REPO_URL:-https://github.com/coleam00/Archon.git}"
ARCHON_DEFAULT_REF="ecaece460c1924e9a81a409aebee692146f8a301"

usage() {
  cat <<USAGE
Usage:
  stack_infra.sh <bootstrap|up|down|status> [core|core-code-graph|core-neo4j|surreal|archon|docs|full|full-code-graph|full-neo4j|full-graph]

Profiles:
  core     -> qdrant backend + dashboard on 127.0.0.1:6333
  surreal  -> core + local SurrealDB + surrealdb MCP + Surrealist UI (127.0.0.1:18080/18082/18083)
  archon   -> core + archon server + mcp + web ui (127.0.0.1:18081/18051/13737)
  docs     -> core + docs-mcp-server web ui/http endpoint (127.0.0.1:16280)
              requires provider credentials in ${SECRETS_FILE}
              defaults DOCS_MCP_EMBEDDING_MODEL=text-embedding-3-small when OPENAI_API_KEY is present
              supports private GitHub indexing via GITHUB_TOKEN / GH_TOKEN
              runs in standalone server mode (embedded worker included upstream)
  core-neo4j -> core + local Neo4j+APOC (127.0.0.1:17474/17687)
  full     -> core + surreal + archon + docs
  core-code-graph -> core infra + optional code-graph MCP profile
  full-code-graph -> full infra + optional code-graph MCP profile
  full-neo4j -> full + local Neo4j+APOC
  full-graph -> full + local Neo4j+APOC (for Neo4j + code-graph MCP profile)

Filesystem access (MCP containers):
  - Host root is mounted read-only to /hostfs
  - /Users is mounted read-only to /Users (direct-path convenience)
  - Override mount sources with MCP_HOST_FS_ROOT and MCP_HOST_FS_USERS in ${SECRETS_FILE}

SurrealDB runtime overrides (optional in ${SECRETS_FILE}):
  - SURREALDB_ROOT_USER, SURREALDB_ROOT_PASS
  - SURREALDB_DEFAULT_NS, SURREALDB_DEFAULT_DB
  - SURREALDB_RPC_PORT, SURREALDB_WS_HOST, SURREALIST_CONNECTION_NAME
  - SURREAL_MCP_SERVER_URL
  - SURREAL_MCP_RATE_LIMIT_RPS, SURREAL_MCP_RATE_LIMIT_BURST

Neo4j runtime overrides (optional in ${SECRETS_FILE}):
  - NEO4J_HOST (default: 127.0.0.1)
  - NEO4J_HTTP_PORT (default: 17474)
  - NEO4J_BOLT_PORT (default: 17687)
  - NEO4J_USERNAME, NEO4J_PASSWORD
  - NEO4J_DATABASE (default: neo4j)
  - NEO4J_READ_ONLY (default: true)
  - NEO4J_TELEMETRY (default: false)
  - NEO4J_SCHEMA_SAMPLE_SIZE (default: 100)
  - MCP_NEO4J_VERSION (default: v1.4.1)

Docs MCP runtime overrides (optional in ${SECRETS_FILE}):
  - Provider keys: OPENAI_API_KEY, OPENAI_ORG_ID, OPENAI_API_BASE, GOOGLE_API_KEY,
    GOOGLE_APPLICATION_CREDENTIALS, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY,
    AWS_REGION, BEDROCK_AWS_REGION, AZURE_OPENAI_API_*
  - Source auth: GITHUB_TOKEN or GH_TOKEN
  - Advanced config: DOCS_MCP_* (for app/server/auth/scraper/splitter/embeddings/db/assembly)

Archon settings sync (optional in ${SECRETS_FILE}):
  - ARCHON_LLM_PROVIDER (default: openai)
  - ARCHON_MODEL_CHOICE (default: gpt-5.2)
  - ARCHON_EMBEDDING_PROVIDER (default: openai)
  - ARCHON_EMBEDDING_MODEL (default: text-embedding-3-large)
  - ARCHON_USE_AGENTIC_RAG (default: true)
  - ARCHON_USE_HYBRID_SEARCH (default: true)
  - ARCHON_USE_RERANKING (default: true)
  - ARCHON_USE_CONTEXTUAL_EMBEDDINGS (default: true)

Archon bootstrap:
  - repo URL: ${ARCHON_REPO_URL}
  - pinned ref key: ARCHON_REPO_REF in ${INFRA_VERSIONS_ENV} (fallback ${ARCHON_DEFAULT_REF})

Image versions:
  - Managed image refs are in ${INFRA_VERSIONS_ENV}
  - Use ${STACK_ROOT}/scripts/stack_versions.sh to view/refresh pinned digests
USAGE
}

require_file() {
  local f="$1"
  if [ ! -f "$f" ]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
}

read_env_var() {
  local key="$1"
  local file="$2"
  if [ ! -f "$file" ]; then
    echo ""
    return 0
  fi
  awk -F= -v k="$key" '$1==k{print substr($0, index($0,"=")+1); exit}' "$file"
}

infra_compose() {
  local args
  args=(-p "$INFRA_PROJECT")
  if [ -f "$INFRA_VERSIONS_ENV" ]; then
    args+=(--env-file "$INFRA_VERSIONS_ENV")
  fi
  if [ -f "$INFRA_RUNTIME_ENV" ]; then
    args+=(--env-file "$INFRA_RUNTIME_ENV")
  fi
  args+=(-f "$INFRA_COMPOSE")
  docker compose "${args[@]}" "$@"
}

archon_compose() {
  docker compose -p "$ARCHON_PROJECT" -f "$ARCHON_BASE_COMPOSE" -f "$ARCHON_OVERRIDE_COMPOSE" "$@"
}

archon_wait_ready() {
  local tries="${1:-90}"
  local i code
  for i in $(seq 1 "$tries"); do
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 "http://127.0.0.1:18081/api/health" 2>/dev/null || true)"
    if [ "$code" = "200" ]; then
      return 0
    fi
    sleep 1
  done
  echo "Archon API did not become healthy in time." >&2
  return 1
}

archon_sync_setting() {
  local key="$1"
  local value="$2"
  local category="${3:-rag_strategy}"
  local payload_file code
  payload_file="$(mktemp)"
  python3 - "$key" "$value" "$category" >"$payload_file" <<'PY'
import json
import sys
key, value, category = sys.argv[1], sys.argv[2], sys.argv[3]
print(json.dumps({
    "key": key,
    "value": value,
    "is_encrypted": False,
    "category": category,
    "description": "Managed by stack_infra.sh",
}))
PY
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 10 \
    -X PUT "http://127.0.0.1:18081/api/credentials/${key}" \
    -H 'Content-Type: application/json' \
    --data @"$payload_file" || true)"
  rm -f "$payload_file"
  if [ "$code" != "200" ]; then
    echo "Archon setting sync failed for ${key} (HTTP ${code})." >&2
    return 1
  fi
  return 0
}

archon_sync_settings() {
  require_file "$SECRETS_FILE"
  local llm_provider model_choice embedding_provider embedding_model
  local use_agentic_rag use_hybrid_search use_reranking use_contextual_embeddings

  llm_provider="$(read_env_var "ARCHON_LLM_PROVIDER" "$SECRETS_FILE")"
  model_choice="$(read_env_var "ARCHON_MODEL_CHOICE" "$SECRETS_FILE")"
  embedding_provider="$(read_env_var "ARCHON_EMBEDDING_PROVIDER" "$SECRETS_FILE")"
  embedding_model="$(read_env_var "ARCHON_EMBEDDING_MODEL" "$SECRETS_FILE")"
  use_agentic_rag="$(read_env_var "ARCHON_USE_AGENTIC_RAG" "$SECRETS_FILE")"
  use_hybrid_search="$(read_env_var "ARCHON_USE_HYBRID_SEARCH" "$SECRETS_FILE")"
  use_reranking="$(read_env_var "ARCHON_USE_RERANKING" "$SECRETS_FILE")"
  use_contextual_embeddings="$(read_env_var "ARCHON_USE_CONTEXTUAL_EMBEDDINGS" "$SECRETS_FILE")"

  if [ -z "${llm_provider:-}" ]; then llm_provider="openai"; fi
  if [ -z "${model_choice:-}" ]; then model_choice="gpt-5.2"; fi
  if [ -z "${embedding_provider:-}" ]; then embedding_provider="openai"; fi
  if [ -z "${embedding_model:-}" ]; then embedding_model="text-embedding-3-large"; fi
  if [ -z "${use_agentic_rag:-}" ]; then use_agentic_rag="true"; fi
  if [ -z "${use_hybrid_search:-}" ]; then use_hybrid_search="true"; fi
  if [ -z "${use_reranking:-}" ]; then use_reranking="true"; fi
  if [ -z "${use_contextual_embeddings:-}" ]; then use_contextual_embeddings="true"; fi

  archon_wait_ready
  archon_sync_setting "LLM_PROVIDER" "$llm_provider"
  archon_sync_setting "MODEL_CHOICE" "$model_choice"
  archon_sync_setting "EMBEDDING_PROVIDER" "$embedding_provider"
  archon_sync_setting "EMBEDDING_MODEL" "$embedding_model"
  archon_sync_setting "USE_AGENTIC_RAG" "$use_agentic_rag"
  archon_sync_setting "USE_HYBRID_SEARCH" "$use_hybrid_search"
  archon_sync_setting "USE_RERANKING" "$use_reranking"
  archon_sync_setting "USE_CONTEXTUAL_EMBEDDINGS" "$use_contextual_embeddings"
}

ensure_archon_repo() {
  local repo_ref
  repo_ref="$(read_env_var "ARCHON_REPO_REF" "$INFRA_VERSIONS_ENV")"
  if [ -z "${repo_ref:-}" ]; then
    repo_ref="$ARCHON_DEFAULT_REF"
  fi

  if [ ! -d "$ARCHON_DIR/.git" ]; then
    mkdir -p "$(dirname "$ARCHON_DIR")"
    git clone "$ARCHON_REPO_URL" "$ARCHON_DIR"
  fi

  if [ -n "${repo_ref:-}" ]; then
    local current_ref
    current_ref="$(git -C "$ARCHON_DIR" rev-parse HEAD 2>/dev/null || true)"
    if [ "$current_ref" != "$repo_ref" ]; then
      git -C "$ARCHON_DIR" fetch --depth 1 origin "$repo_ref" || git -C "$ARCHON_DIR" fetch origin "$repo_ref"
      git -C "$ARCHON_DIR" checkout "$repo_ref"
    fi
  fi

  require_file "$ARCHON_BASE_COMPOSE"
}

write_archon_runtime_env() {
  require_file "$SECRETS_FILE"
  local supabase_url supabase_service_key host_value log_level openai_api_key github_pat_token
  local mcp_host_fs_root mcp_host_fs_users
  supabase_url="$(read_env_var "SUPABASE_URL" "$SECRETS_FILE")"
  supabase_service_key="$(read_env_var "SUPABASE_SERVICE_KEY" "$SECRETS_FILE")"
  host_value="$(read_env_var "HOST" "$SECRETS_FILE")"
  log_level="$(read_env_var "LOG_LEVEL" "$SECRETS_FILE")"
  openai_api_key="$(read_env_var "OPENAI_API_KEY" "$SECRETS_FILE")"
  github_pat_token="$(read_env_var "GITHUB_PAT_TOKEN" "$SECRETS_FILE")"
  if [ -z "${github_pat_token:-}" ]; then
    github_pat_token="$(read_env_var "GITHUB_PERSONAL_ACCESS_TOKEN" "$SECRETS_FILE")"
  fi
  mcp_host_fs_root="$(read_env_var "MCP_HOST_FS_ROOT" "$SECRETS_FILE")"
  mcp_host_fs_users="$(read_env_var "MCP_HOST_FS_USERS" "$SECRETS_FILE")"

  if [ -z "${supabase_url:-}" ] || [ -z "${supabase_service_key:-}" ]; then
    echo "SUPABASE_URL and SUPABASE_SERVICE_KEY must be set in ${SECRETS_FILE}" >&2
    exit 2
  fi

  mkdir -p "$(dirname "$ARCHON_RUNTIME_ENV")"
  {
    echo "SUPABASE_URL=${supabase_url}"
    echo "SUPABASE_SERVICE_KEY=${supabase_service_key}"
    echo "HOST=${host_value:-localhost}"
    echo "ARCHON_SERVER_PORT=18081"
    echo "ARCHON_MCP_PORT=18052"
    echo "ARCHON_UI_PORT=13737"
    echo "AGENTS_ENABLED=false"
    echo "LOG_LEVEL=${log_level:-INFO}"
    echo "MCP_HOST_FS_ROOT=${mcp_host_fs_root:-/}"
    echo "MCP_HOST_FS_USERS=${mcp_host_fs_users:-/Users}"
    echo "GITHUB_PAT_TOKEN=${github_pat_token:-}"
    if [ -n "${openai_api_key:-}" ]; then
      echo "OPENAI_API_KEY=${openai_api_key}"
    fi
  } >"$ARCHON_RUNTIME_ENV"
  chmod 600 "$ARCHON_RUNTIME_ENV"
}

write_surrealist_instance_config() {
  local surrealdb_user="$1"
  local surrealdb_pass="$2"
  local surrealdb_host="$3"
  local surrealdb_rpc_port="$4"
  local surrealdb_ns="$5"
  local surrealdb_db="$6"
  local surrealist_connection_name="$7"

  mkdir -p "$(dirname "$SURREALIST_INSTANCE_RUNTIME")"
  SURREALDB_USER="$surrealdb_user" \
    SURREALDB_PASS="$surrealdb_pass" \
    SURREALDB_HOST="$surrealdb_host" \
    SURREALDB_RPC_PORT="$surrealdb_rpc_port" \
    SURREALDB_NS="$surrealdb_ns" \
    SURREALDB_DB="$surrealdb_db" \
    SURREALIST_CONNECTION_NAME="$surrealist_connection_name" \
    python3 - <<'PY' >"$SURREALIST_INSTANCE_RUNTIME"
import json
import os

payload = {
  "telemetry": False,
  "connections": [
    {
      "id": "local-surrealdb",
      "name": os.environ["SURREALIST_CONNECTION_NAME"],
      "defaultNamespace": os.environ["SURREALDB_NS"],
      "defaultDatabase": os.environ["SURREALDB_DB"],
      "authentication": {
        "protocol": "ws",
        "hostname": f"{os.environ['SURREALDB_HOST']}:{os.environ['SURREALDB_RPC_PORT']}",
        "mode": "root",
        "username": os.environ["SURREALDB_USER"],
        "password": os.environ["SURREALDB_PASS"],
      },
    }
  ],
  "cloud": {"enabled": False},
}
print(json.dumps(payload, indent=2))
PY
  chmod 600 "$SURREALIST_INSTANCE_RUNTIME"
}

write_infra_runtime_env() {
  local docs_provider_required="${1:-false}"

  local openai_api_key docs_embedding_model openai_api_base
  local openai_org_id github_token gh_token
  local google_api_key google_application_credentials
  local aws_access_key_id aws_secret_access_key aws_region bedrock_aws_region
  local azure_openai_api_key azure_openai_api_instance_name
  local azure_openai_api_deployment_name azure_openai_api_version
  local docs_mcp_public_port docs_mcp_config docs_mcp_store_path docs_mcp_app_store_path docs_mcp_app_telemetry_enabled docs_mcp_app_read_only
  local docs_mcp_server_protocol docs_mcp_server_host docs_mcp_server_heartbeat_ms
  local docs_mcp_server_ports_default docs_mcp_server_ports_worker docs_mcp_server_ports_mcp docs_mcp_server_ports_web
  local docs_mcp_auth_enabled docs_mcp_auth_issuer_url docs_mcp_auth_audience
  local docs_mcp_scraper_max_pages docs_mcp_scraper_max_depth docs_mcp_scraper_max_concurrency
  local docs_mcp_scraper_page_timeout_ms docs_mcp_scraper_browser_timeout_ms docs_mcp_scraper_fetcher_max_retries
  local docs_mcp_scraper_fetcher_base_delay_ms docs_mcp_scraper_document_max_size
  local docs_mcp_splitter_min_chunk_size docs_mcp_splitter_preferred_chunk_size docs_mcp_splitter_max_chunk_size
  local docs_mcp_embeddings_batch_size docs_mcp_embeddings_vector_dimension docs_mcp_db_migration_max_retries
  local docs_mcp_assembly_max_chunk_distance docs_mcp_assembly_max_parent_chain_depth docs_mcp_assembly_child_limit
  local docs_mcp_assembly_preceding_siblings_limit docs_mcp_assembly_subsequent_siblings_limit
  local mcp_host_fs_root mcp_host_fs_users
  local surrealdb_root_user surrealdb_root_pass surrealdb_default_ns surrealdb_default_db
  local surrealdb_rpc_port surrealdb_ws_host surrealist_connection_name
  local surreal_mcp_server_url surreal_mcp_rate_limit_rps surreal_mcp_rate_limit_burst
  local neo4j_host neo4j_http_port neo4j_bolt_port neo4j_username neo4j_password
  local neo4j_database neo4j_read_only neo4j_telemetry neo4j_schema_sample_size mcp_neo4j_version
  local provider_credentials_found

  openai_api_key="$(read_env_var "OPENAI_API_KEY" "$SECRETS_FILE")"
  docs_embedding_model="$(read_env_var "DOCS_MCP_EMBEDDING_MODEL" "$SECRETS_FILE")"
  openai_api_base="$(read_env_var "OPENAI_API_BASE" "$SECRETS_FILE")"
  openai_org_id="$(read_env_var "OPENAI_ORG_ID" "$SECRETS_FILE")"
  github_token="$(read_env_var "GITHUB_TOKEN" "$SECRETS_FILE")"
  gh_token="$(read_env_var "GH_TOKEN" "$SECRETS_FILE")"
  if [ -z "${github_token:-}" ]; then
    github_token="$(read_env_var "GITHUB_PAT_TOKEN" "$SECRETS_FILE")"
  fi
  if [ -z "${gh_token:-}" ]; then
    gh_token="$github_token"
  fi
  google_api_key="$(read_env_var "GOOGLE_API_KEY" "$SECRETS_FILE")"
  google_application_credentials="$(read_env_var "GOOGLE_APPLICATION_CREDENTIALS" "$SECRETS_FILE")"
  aws_access_key_id="$(read_env_var "AWS_ACCESS_KEY_ID" "$SECRETS_FILE")"
  aws_secret_access_key="$(read_env_var "AWS_SECRET_ACCESS_KEY" "$SECRETS_FILE")"
  aws_region="$(read_env_var "AWS_REGION" "$SECRETS_FILE")"
  bedrock_aws_region="$(read_env_var "BEDROCK_AWS_REGION" "$SECRETS_FILE")"
  azure_openai_api_key="$(read_env_var "AZURE_OPENAI_API_KEY" "$SECRETS_FILE")"
  azure_openai_api_instance_name="$(read_env_var "AZURE_OPENAI_API_INSTANCE_NAME" "$SECRETS_FILE")"
  azure_openai_api_deployment_name="$(read_env_var "AZURE_OPENAI_API_DEPLOYMENT_NAME" "$SECRETS_FILE")"
  azure_openai_api_version="$(read_env_var "AZURE_OPENAI_API_VERSION" "$SECRETS_FILE")"
  docs_mcp_public_port="$(read_env_var "DOCS_MCP_PUBLIC_PORT" "$SECRETS_FILE")"
  docs_mcp_config="$(read_env_var "DOCS_MCP_CONFIG" "$SECRETS_FILE")"
  docs_mcp_store_path="$(read_env_var "DOCS_MCP_STORE_PATH" "$SECRETS_FILE")"
  docs_mcp_app_store_path="$(read_env_var "DOCS_MCP_APP_STORE_PATH" "$SECRETS_FILE")"
  docs_mcp_app_telemetry_enabled="$(read_env_var "DOCS_MCP_APP_TELEMETRY_ENABLED" "$SECRETS_FILE")"
  docs_mcp_app_read_only="$(read_env_var "DOCS_MCP_APP_READ_ONLY" "$SECRETS_FILE")"
  docs_mcp_server_protocol="$(read_env_var "DOCS_MCP_SERVER_PROTOCOL" "$SECRETS_FILE")"
  docs_mcp_server_host="$(read_env_var "DOCS_MCP_SERVER_HOST" "$SECRETS_FILE")"
  docs_mcp_server_heartbeat_ms="$(read_env_var "DOCS_MCP_SERVER_HEARTBEAT_MS" "$SECRETS_FILE")"
  docs_mcp_server_ports_default="$(read_env_var "DOCS_MCP_SERVER_PORTS_DEFAULT" "$SECRETS_FILE")"
  docs_mcp_server_ports_worker="$(read_env_var "DOCS_MCP_SERVER_PORTS_WORKER" "$SECRETS_FILE")"
  docs_mcp_server_ports_mcp="$(read_env_var "DOCS_MCP_SERVER_PORTS_MCP" "$SECRETS_FILE")"
  docs_mcp_server_ports_web="$(read_env_var "DOCS_MCP_SERVER_PORTS_WEB" "$SECRETS_FILE")"
  docs_mcp_auth_enabled="$(read_env_var "DOCS_MCP_AUTH_ENABLED" "$SECRETS_FILE")"
  docs_mcp_auth_issuer_url="$(read_env_var "DOCS_MCP_AUTH_ISSUER_URL" "$SECRETS_FILE")"
  docs_mcp_auth_audience="$(read_env_var "DOCS_MCP_AUTH_AUDIENCE" "$SECRETS_FILE")"
  docs_mcp_scraper_max_pages="$(read_env_var "DOCS_MCP_SCRAPER_MAX_PAGES" "$SECRETS_FILE")"
  docs_mcp_scraper_max_depth="$(read_env_var "DOCS_MCP_SCRAPER_MAX_DEPTH" "$SECRETS_FILE")"
  docs_mcp_scraper_max_concurrency="$(read_env_var "DOCS_MCP_SCRAPER_MAX_CONCURRENCY" "$SECRETS_FILE")"
  docs_mcp_scraper_page_timeout_ms="$(read_env_var "DOCS_MCP_SCRAPER_PAGE_TIMEOUT_MS" "$SECRETS_FILE")"
  docs_mcp_scraper_browser_timeout_ms="$(read_env_var "DOCS_MCP_SCRAPER_BROWSER_TIMEOUT_MS" "$SECRETS_FILE")"
  docs_mcp_scraper_fetcher_max_retries="$(read_env_var "DOCS_MCP_SCRAPER_FETCHER_MAX_RETRIES" "$SECRETS_FILE")"
  docs_mcp_scraper_fetcher_base_delay_ms="$(read_env_var "DOCS_MCP_SCRAPER_FETCHER_BASE_DELAY_MS" "$SECRETS_FILE")"
  docs_mcp_scraper_document_max_size="$(read_env_var "DOCS_MCP_SCRAPER_DOCUMENT_MAX_SIZE" "$SECRETS_FILE")"
  docs_mcp_splitter_min_chunk_size="$(read_env_var "DOCS_MCP_SPLITTER_MIN_CHUNK_SIZE" "$SECRETS_FILE")"
  docs_mcp_splitter_preferred_chunk_size="$(read_env_var "DOCS_MCP_SPLITTER_PREFERRED_CHUNK_SIZE" "$SECRETS_FILE")"
  docs_mcp_splitter_max_chunk_size="$(read_env_var "DOCS_MCP_SPLITTER_MAX_CHUNK_SIZE" "$SECRETS_FILE")"
  docs_mcp_embeddings_batch_size="$(read_env_var "DOCS_MCP_EMBEDDINGS_BATCH_SIZE" "$SECRETS_FILE")"
  docs_mcp_embeddings_vector_dimension="$(read_env_var "DOCS_MCP_EMBEDDINGS_VECTOR_DIMENSION" "$SECRETS_FILE")"
  docs_mcp_db_migration_max_retries="$(read_env_var "DOCS_MCP_DB_MIGRATION_MAX_RETRIES" "$SECRETS_FILE")"
  docs_mcp_assembly_max_chunk_distance="$(read_env_var "DOCS_MCP_ASSEMBLY_MAX_CHUNK_DISTANCE" "$SECRETS_FILE")"
  docs_mcp_assembly_max_parent_chain_depth="$(read_env_var "DOCS_MCP_ASSEMBLY_MAX_PARENT_CHAIN_DEPTH" "$SECRETS_FILE")"
  docs_mcp_assembly_child_limit="$(read_env_var "DOCS_MCP_ASSEMBLY_CHILD_LIMIT" "$SECRETS_FILE")"
  docs_mcp_assembly_preceding_siblings_limit="$(read_env_var "DOCS_MCP_ASSEMBLY_PRECEDING_SIBLINGS_LIMIT" "$SECRETS_FILE")"
  docs_mcp_assembly_subsequent_siblings_limit="$(read_env_var "DOCS_MCP_ASSEMBLY_SUBSEQUENT_SIBLINGS_LIMIT" "$SECRETS_FILE")"
  mcp_host_fs_root="$(read_env_var "MCP_HOST_FS_ROOT" "$SECRETS_FILE")"
  mcp_host_fs_users="$(read_env_var "MCP_HOST_FS_USERS" "$SECRETS_FILE")"
  surrealdb_root_user="$(read_env_var "SURREALDB_ROOT_USER" "$SECRETS_FILE")"
  surrealdb_root_pass="$(read_env_var "SURREALDB_ROOT_PASS" "$SECRETS_FILE")"
  surrealdb_default_ns="$(read_env_var "SURREALDB_DEFAULT_NS" "$SECRETS_FILE")"
  surrealdb_default_db="$(read_env_var "SURREALDB_DEFAULT_DB" "$SECRETS_FILE")"
  surrealdb_rpc_port="$(read_env_var "SURREALDB_RPC_PORT" "$SECRETS_FILE")"
  surrealdb_ws_host="$(read_env_var "SURREALDB_WS_HOST" "$SECRETS_FILE")"
  surrealist_connection_name="$(read_env_var "SURREALIST_CONNECTION_NAME" "$SECRETS_FILE")"
  surreal_mcp_server_url="$(read_env_var "SURREAL_MCP_SERVER_URL" "$SECRETS_FILE")"
  surreal_mcp_rate_limit_rps="$(read_env_var "SURREAL_MCP_RATE_LIMIT_RPS" "$SECRETS_FILE")"
  surreal_mcp_rate_limit_burst="$(read_env_var "SURREAL_MCP_RATE_LIMIT_BURST" "$SECRETS_FILE")"
  neo4j_host="$(read_env_var "NEO4J_HOST" "$SECRETS_FILE")"
  neo4j_http_port="$(read_env_var "NEO4J_HTTP_PORT" "$SECRETS_FILE")"
  neo4j_bolt_port="$(read_env_var "NEO4J_BOLT_PORT" "$SECRETS_FILE")"
  neo4j_username="$(read_env_var "NEO4J_USERNAME" "$SECRETS_FILE")"
  neo4j_password="$(read_env_var "NEO4J_PASSWORD" "$SECRETS_FILE")"
  neo4j_database="$(read_env_var "NEO4J_DATABASE" "$SECRETS_FILE")"
  neo4j_read_only="$(read_env_var "NEO4J_READ_ONLY" "$SECRETS_FILE")"
  neo4j_telemetry="$(read_env_var "NEO4J_TELEMETRY" "$SECRETS_FILE")"
  neo4j_schema_sample_size="$(read_env_var "NEO4J_SCHEMA_SAMPLE_SIZE" "$SECRETS_FILE")"
  mcp_neo4j_version="$(read_env_var "MCP_NEO4J_VERSION" "$SECRETS_FILE")"

  if [ -z "${docs_embedding_model:-}" ] && [ -n "${openai_api_key:-}" ]; then
    docs_embedding_model="text-embedding-3-small"
  fi

  provider_credentials_found=0
  if [ -n "${openai_api_key:-}" ] || [ -n "${google_api_key:-}" ] || [ -n "${azure_openai_api_key:-}" ]; then
    provider_credentials_found=1
  fi
  if [ -n "${aws_access_key_id:-}" ] && [ -n "${aws_secret_access_key:-}" ]; then
    provider_credentials_found=1
  fi
  if [ "${docs_provider_required}" = "true" ] && [ "$provider_credentials_found" -eq 0 ]; then
    echo "No embedding provider credentials found in ${SECRETS_FILE}. Add OPENAI_API_KEY (recommended) or another provider key before starting docs profile." >&2
    exit 2
  fi

  if [ -z "${surrealdb_root_user:-}" ]; then surrealdb_root_user="root"; fi
  if [ -z "${surrealdb_root_pass:-}" ]; then surrealdb_root_pass="root"; fi
  if [ -z "${surrealdb_default_ns:-}" ]; then surrealdb_default_ns="mcp"; fi
  if [ -z "${surrealdb_default_db:-}" ]; then surrealdb_default_db="workspace"; fi
  if [ -z "${surrealdb_rpc_port:-}" ]; then surrealdb_rpc_port="18083"; fi
  if [ -z "${surrealdb_ws_host:-}" ]; then surrealdb_ws_host="127.0.0.1"; fi
  if [ -z "${surrealist_connection_name:-}" ]; then surrealist_connection_name="Local SurrealDB (Docker)"; fi
  if [ -z "${surreal_mcp_server_url:-}" ]; then surreal_mcp_server_url="http://127.0.0.1:18080"; fi
  if [ -z "${surreal_mcp_rate_limit_rps:-}" ]; then surreal_mcp_rate_limit_rps="2000"; fi
  if [ -z "${surreal_mcp_rate_limit_burst:-}" ]; then surreal_mcp_rate_limit_burst="4000"; fi
  if [ -z "${neo4j_host:-}" ]; then neo4j_host="127.0.0.1"; fi
  if [ -z "${neo4j_http_port:-}" ]; then neo4j_http_port="17474"; fi
  if [ -z "${neo4j_bolt_port:-}" ]; then neo4j_bolt_port="17687"; fi
  if [ -z "${neo4j_username:-}" ]; then neo4j_username="neo4j"; fi
  if [ -z "${neo4j_password:-}" ]; then neo4j_password="testpass"; fi
  if [ -z "${neo4j_database:-}" ]; then neo4j_database="neo4j"; fi
  if [ -z "${neo4j_read_only:-}" ]; then neo4j_read_only="true"; fi
  if [ -z "${neo4j_telemetry:-}" ]; then neo4j_telemetry="false"; fi
  if [ -z "${neo4j_schema_sample_size:-}" ]; then neo4j_schema_sample_size="100"; fi
  if [ -z "${mcp_neo4j_version:-}" ]; then mcp_neo4j_version="v1.4.1"; fi

  write_surrealist_instance_config \
    "$surrealdb_root_user" \
    "$surrealdb_root_pass" \
    "$surrealdb_ws_host" \
    "$surrealdb_rpc_port" \
    "$surrealdb_default_ns" \
    "$surrealdb_default_db" \
    "$surrealist_connection_name"

  mkdir -p "$(dirname "$INFRA_RUNTIME_ENV")"
  : >"$INFRA_RUNTIME_ENV"
  append_env() {
    printf '%s=%s\n' "$1" "$2" >>"$INFRA_RUNTIME_ENV"
  }
  append_if_set() {
    if [ -n "${2:-}" ]; then
      append_env "$1" "$2"
    fi
  }

  append_env "INFRA_RUNTIME_ENV_FILE" "$INFRA_RUNTIME_ENV"
  append_env "DOCS_MCP_PUBLIC_PORT" "${docs_mcp_public_port:-16280}"
  append_env "MCP_HOST_FS_ROOT" "${mcp_host_fs_root:-/}"
  append_env "MCP_HOST_FS_USERS" "${mcp_host_fs_users:-/Users}"
  append_env "SURREALDB_ROOT_USER" "$surrealdb_root_user"
  append_env "SURREALDB_ROOT_PASS" "$surrealdb_root_pass"
  append_env "SURREALDB_DEFAULT_NS" "$surrealdb_default_ns"
  append_env "SURREALDB_DEFAULT_DB" "$surrealdb_default_db"
  append_env "SURREALDB_RPC_PORT" "$surrealdb_rpc_port"
  append_env "SURREAL_MCP_SERVER_URL" "$surreal_mcp_server_url"
  append_env "SURREAL_MCP_RATE_LIMIT_RPS" "$surreal_mcp_rate_limit_rps"
  append_env "SURREAL_MCP_RATE_LIMIT_BURST" "$surreal_mcp_rate_limit_burst"
  append_env "SURREALIST_INSTANCE_FILE" "$SURREALIST_INSTANCE_RUNTIME"
  append_env "NEO4J_HOST" "$neo4j_host"
  append_env "NEO4J_HTTP_PORT" "$neo4j_http_port"
  append_env "NEO4J_BOLT_PORT" "$neo4j_bolt_port"
  append_env "NEO4J_USERNAME" "$neo4j_username"
  append_env "NEO4J_PASSWORD" "$neo4j_password"
  append_env "NEO4J_DATABASE" "$neo4j_database"
  append_env "NEO4J_READ_ONLY" "$neo4j_read_only"
  append_env "NEO4J_TELEMETRY" "$neo4j_telemetry"
  append_env "NEO4J_SCHEMA_SAMPLE_SIZE" "$neo4j_schema_sample_size"
  append_env "MCP_NEO4J_VERSION" "$mcp_neo4j_version"
  append_env "NEO4J_URI" "bolt://${neo4j_host}:${neo4j_bolt_port}"
  append_env "NEO4J_DOCKER_AUTH" "${neo4j_username}/${neo4j_password}"

  append_if_set "OPENAI_API_KEY" "$openai_api_key"
  append_if_set "OPENAI_ORG_ID" "$openai_org_id"
  append_if_set "DOCS_MCP_EMBEDDING_MODEL" "$docs_embedding_model"
  append_if_set "OPENAI_API_BASE" "$openai_api_base"
  append_if_set "GITHUB_TOKEN" "$github_token"
  append_if_set "GH_TOKEN" "$gh_token"
  append_if_set "GOOGLE_API_KEY" "$google_api_key"
  append_if_set "GOOGLE_APPLICATION_CREDENTIALS" "$google_application_credentials"
  append_if_set "AWS_ACCESS_KEY_ID" "$aws_access_key_id"
  append_if_set "AWS_SECRET_ACCESS_KEY" "$aws_secret_access_key"
  append_if_set "AWS_REGION" "$aws_region"
  append_if_set "BEDROCK_AWS_REGION" "$bedrock_aws_region"
  append_if_set "AZURE_OPENAI_API_KEY" "$azure_openai_api_key"
  append_if_set "AZURE_OPENAI_API_INSTANCE_NAME" "$azure_openai_api_instance_name"
  append_if_set "AZURE_OPENAI_API_DEPLOYMENT_NAME" "$azure_openai_api_deployment_name"
  append_if_set "AZURE_OPENAI_API_VERSION" "$azure_openai_api_version"
  append_if_set "DOCS_MCP_CONFIG" "$docs_mcp_config"
  append_if_set "DOCS_MCP_STORE_PATH" "$docs_mcp_store_path"
  append_if_set "DOCS_MCP_APP_STORE_PATH" "$docs_mcp_app_store_path"
  append_if_set "DOCS_MCP_APP_TELEMETRY_ENABLED" "$docs_mcp_app_telemetry_enabled"
  append_if_set "DOCS_MCP_APP_READ_ONLY" "$docs_mcp_app_read_only"
  append_if_set "DOCS_MCP_SERVER_PROTOCOL" "$docs_mcp_server_protocol"
  append_if_set "DOCS_MCP_SERVER_HOST" "$docs_mcp_server_host"
  append_if_set "DOCS_MCP_SERVER_HEARTBEAT_MS" "$docs_mcp_server_heartbeat_ms"
  append_if_set "DOCS_MCP_SERVER_PORTS_DEFAULT" "$docs_mcp_server_ports_default"
  append_if_set "DOCS_MCP_SERVER_PORTS_WORKER" "$docs_mcp_server_ports_worker"
  append_if_set "DOCS_MCP_SERVER_PORTS_MCP" "$docs_mcp_server_ports_mcp"
  append_if_set "DOCS_MCP_SERVER_PORTS_WEB" "$docs_mcp_server_ports_web"
  append_if_set "DOCS_MCP_AUTH_ENABLED" "$docs_mcp_auth_enabled"
  append_if_set "DOCS_MCP_AUTH_ISSUER_URL" "$docs_mcp_auth_issuer_url"
  append_if_set "DOCS_MCP_AUTH_AUDIENCE" "$docs_mcp_auth_audience"
  append_if_set "DOCS_MCP_SCRAPER_MAX_PAGES" "$docs_mcp_scraper_max_pages"
  append_if_set "DOCS_MCP_SCRAPER_MAX_DEPTH" "$docs_mcp_scraper_max_depth"
  append_if_set "DOCS_MCP_SCRAPER_MAX_CONCURRENCY" "$docs_mcp_scraper_max_concurrency"
  append_if_set "DOCS_MCP_SCRAPER_PAGE_TIMEOUT_MS" "$docs_mcp_scraper_page_timeout_ms"
  append_if_set "DOCS_MCP_SCRAPER_BROWSER_TIMEOUT_MS" "$docs_mcp_scraper_browser_timeout_ms"
  append_if_set "DOCS_MCP_SCRAPER_FETCHER_MAX_RETRIES" "$docs_mcp_scraper_fetcher_max_retries"
  append_if_set "DOCS_MCP_SCRAPER_FETCHER_BASE_DELAY_MS" "$docs_mcp_scraper_fetcher_base_delay_ms"
  append_if_set "DOCS_MCP_SCRAPER_DOCUMENT_MAX_SIZE" "$docs_mcp_scraper_document_max_size"
  append_if_set "DOCS_MCP_SPLITTER_MIN_CHUNK_SIZE" "$docs_mcp_splitter_min_chunk_size"
  append_if_set "DOCS_MCP_SPLITTER_PREFERRED_CHUNK_SIZE" "$docs_mcp_splitter_preferred_chunk_size"
  append_if_set "DOCS_MCP_SPLITTER_MAX_CHUNK_SIZE" "$docs_mcp_splitter_max_chunk_size"
  append_if_set "DOCS_MCP_EMBEDDINGS_BATCH_SIZE" "$docs_mcp_embeddings_batch_size"
  append_if_set "DOCS_MCP_EMBEDDINGS_VECTOR_DIMENSION" "$docs_mcp_embeddings_vector_dimension"
  append_if_set "DOCS_MCP_DB_MIGRATION_MAX_RETRIES" "$docs_mcp_db_migration_max_retries"
  append_if_set "DOCS_MCP_ASSEMBLY_MAX_CHUNK_DISTANCE" "$docs_mcp_assembly_max_chunk_distance"
  append_if_set "DOCS_MCP_ASSEMBLY_MAX_PARENT_CHAIN_DEPTH" "$docs_mcp_assembly_max_parent_chain_depth"
  append_if_set "DOCS_MCP_ASSEMBLY_CHILD_LIMIT" "$docs_mcp_assembly_child_limit"
  append_if_set "DOCS_MCP_ASSEMBLY_PRECEDING_SIBLINGS_LIMIT" "$docs_mcp_assembly_preceding_siblings_limit"
  append_if_set "DOCS_MCP_ASSEMBLY_SUBSEQUENT_SIBLINGS_LIMIT" "$docs_mcp_assembly_subsequent_siblings_limit"
  chmod 600 "$INFRA_RUNTIME_ENV"
}

qdrant_up() {
  require_file "$INFRA_COMPOSE"
  write_infra_runtime_env false
  infra_compose up -d qdrant
}

qdrant_down() {
  require_file "$INFRA_COMPOSE"
  infra_compose rm -sf qdrant >/dev/null 2>&1 || true
  docker rm -f ai-mcp-qdrant mcp-eval-qdrant >/dev/null 2>&1 || true
}

neo4j_up() {
  require_file "$INFRA_COMPOSE"
  write_infra_runtime_env false
  infra_compose up -d neo4j
}

neo4j_down() {
  require_file "$INFRA_COMPOSE"
  infra_compose rm -sf neo4j >/dev/null 2>&1 || true
  docker rm -f ai-mcp-neo4j >/dev/null 2>&1 || true
}

surreal_up() {
  require_file "$INFRA_COMPOSE"
  write_infra_runtime_env false
  infra_compose up -d surrealmcp surrealmcp-compat surrealdb surrealist
}

surreal_down() {
  require_file "$INFRA_COMPOSE"
  infra_compose rm -sf surrealmcp-compat surrealmcp surrealdb surrealist >/dev/null 2>&1 || true
  docker rm -f ai-mcp-surreal-mcp-compat ai-mcp-surreal-mcp ai-mcp-surrealdb ai-mcp-surrealist mcp-eval-surrealmcp >/dev/null 2>&1 || true
}

docs_up() {
  require_file "$INFRA_COMPOSE"
  write_infra_runtime_env true
  infra_compose up -d docs-mcp-web
  infra_compose rm -sf docs-mcp-worker >/dev/null 2>&1 || true
  docker rm -f ai-mcp-docs-worker >/dev/null 2>&1 || true
}

docs_down() {
  require_file "$INFRA_COMPOSE"
  infra_compose rm -sf docs-mcp-web >/dev/null 2>&1 || true
  docker rm -f ai-mcp-docs-mcp >/dev/null 2>&1 || true
}

archon_up() {
  ensure_archon_repo
  require_file "$ARCHON_OVERRIDE_COMPOSE"
  write_archon_runtime_env
  (
    cd "$ARCHON_DIR" &&
      archon_compose --env-file "$ARCHON_RUNTIME_ENV" up -d \
        archon-server archon-mcp archon-mcp-compat archon-frontend
  )
  archon_sync_settings
}

archon_down() {
  if [ ! -d "$ARCHON_DIR" ]; then
    return 0
  fi
  require_file "$ARCHON_OVERRIDE_COMPOSE"
  if [ -f "$ARCHON_RUNTIME_ENV" ]; then
    (
      cd "$ARCHON_DIR" &&
        archon_compose --env-file "$ARCHON_RUNTIME_ENV" stop \
          archon-mcp-compat archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true
    )
    (
      cd "$ARCHON_DIR" &&
        archon_compose --env-file "$ARCHON_RUNTIME_ENV" rm -sf \
          archon-mcp-compat archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true
    )
  else
    (
      cd "$ARCHON_DIR" &&
        archon_compose stop archon-mcp-compat archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true
    )
    (
      cd "$ARCHON_DIR" &&
        archon_compose rm -sf archon-mcp-compat archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true
    )
  fi
  docker rm -f \
    ai-mcp-archon-server ai-mcp-archon-mcp ai-mcp-archon-mcp-compat ai-mcp-archon-ui \
    archon-server archon-mcp archon-mcp-compat archon-ui >/dev/null 2>&1 || true
}

http_code() {
  local url="$1"
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || true)"
  if [ -z "$code" ] || [ "$code" = "000" ]; then
    echo "ERR"
  else
    echo "$code"
  fi
}

tcp_probe() {
  local host="$1"
  local port="$2"
  if bash -c "</dev/tcp/${host}/${port}" >/dev/null 2>&1; then
    echo "OK"
  else
    echo "ERR"
  fi
}

show_endpoints() {
  local surrealdb_rpc_port
  local docs_mcp_public_port
  local neo4j_http_port
  local neo4j_bolt_port
  surrealdb_rpc_port="$(read_env_var "SURREALDB_RPC_PORT" "$INFRA_RUNTIME_ENV")"
  if [ -z "${surrealdb_rpc_port:-}" ]; then
    surrealdb_rpc_port="18083"
  fi
  neo4j_http_port="$(read_env_var "NEO4J_HTTP_PORT" "$INFRA_RUNTIME_ENV")"
  if [ -z "${neo4j_http_port:-}" ]; then
    neo4j_http_port="17474"
  fi
  neo4j_bolt_port="$(read_env_var "NEO4J_BOLT_PORT" "$INFRA_RUNTIME_ENV")"
  if [ -z "${neo4j_bolt_port:-}" ]; then
    neo4j_bolt_port="17687"
  fi
  docs_mcp_public_port="$(read_env_var "DOCS_MCP_PUBLIC_PORT" "$INFRA_RUNTIME_ENV")"
  if [ -z "${docs_mcp_public_port:-}" ]; then
    docs_mcp_public_port="16280"
  fi
  echo
  echo "== Endpoint checks =="
  printf "%-24s %-32s %s\n" "service" "url" "http"
  printf "%-24s %-32s %s\n" "qdrant-api" "http://127.0.0.1:6333/healthz" "$(http_code 'http://127.0.0.1:6333/healthz')"
  printf "%-24s %-32s %s\n" "qdrant-dashboard" "http://127.0.0.1:6333/dashboard/" "$(http_code 'http://127.0.0.1:6333/dashboard/')"
  if docker ps --format '{{.Names}}' | grep -Fx "ai-mcp-neo4j" >/dev/null 2>&1; then
    printf "%-24s %-32s %s\n" "neo4j-http" "http://127.0.0.1:${neo4j_http_port}" "$(http_code "http://127.0.0.1:${neo4j_http_port}")"
    printf "%-24s %-32s %s\n" "neo4j-bolt-probe" "tcp://127.0.0.1:${neo4j_bolt_port}" "$(tcp_probe "127.0.0.1" "${neo4j_bolt_port}")"
  fi
  printf "%-24s %-32s %s\n" "surrealdb-rpc" "http://127.0.0.1:${surrealdb_rpc_port}/rpc" "$(http_code "http://127.0.0.1:${surrealdb_rpc_port}/rpc")"
  printf "%-24s %-32s %s\n" "surreal-mcp" "http://127.0.0.1:18080/mcp" "$(http_code 'http://127.0.0.1:18080/mcp')"
  printf "%-24s %-32s %s\n" "surrealist-ui" "http://127.0.0.1:18082" "$(http_code 'http://127.0.0.1:18082')"
  printf "%-24s %-32s %s\n" "archon-api" "http://127.0.0.1:18081/health" "$(http_code 'http://127.0.0.1:18081/health')"
  printf "%-24s %-32s %s\n" "archon-mcp-health" "http://127.0.0.1:18051/health" "$(http_code 'http://127.0.0.1:18051/health')"
  printf "%-24s %-32s %s\n" "archon-ui" "http://127.0.0.1:13737" "$(http_code 'http://127.0.0.1:13737')"
  printf "%-24s %-32s %s\n" "docs-mcp-ui" "http://127.0.0.1:${docs_mcp_public_port}" "$(http_code "http://127.0.0.1:${docs_mcp_public_port}")"
}

show_status() {
  echo "== Docker containers =="
  docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' | sed -n '1p;/ai-mcp-/p;/mcp-eval-/p'
  echo
  echo "== Archon infra =="
  if [ -d "$ARCHON_DIR" ]; then
    if [ -f "$ARCHON_RUNTIME_ENV" ]; then
      (cd "$ARCHON_DIR" && archon_compose --env-file "$ARCHON_RUNTIME_ENV" ps) || true
    else
      (cd "$ARCHON_DIR" && archon_compose ps) || true
    fi
  else
    echo "Archon repository not bootstrapped yet. Run: $0 bootstrap archon"
  fi
  show_endpoints
}

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 1
fi

action="$1"
profile="${2:-full}"

case "$profile" in
  core | core-code-graph | core-neo4j | surreal | archon | docs | full | full-code-graph | full-neo4j | full-graph) ;;
  *)
    echo "Invalid profile: $profile" >&2
    usage
    exit 1
    ;;
esac

case "$action" in
  bootstrap)
    if [ "$profile" = "archon" ] || [ "$profile" = "full" ] || [ "$profile" = "full-neo4j" ] || [ "$profile" = "full-graph" ]; then
      ensure_archon_repo
      echo "Archon repository ready at: $ARCHON_DIR"
    else
      echo "No bootstrap required for profile: $profile"
    fi
    ;;
  up)
    case "$profile" in
      core)
        qdrant_up
        ;;
      core-code-graph)
        qdrant_up
        ;;
      core-neo4j)
        qdrant_up
        neo4j_up
        ;;
      surreal)
        qdrant_up
        surreal_up
        ;;
      archon)
        qdrant_up
        archon_up
        ;;
      docs)
        qdrant_up
        docs_up
        ;;
      full)
        qdrant_up
        surreal_up
        archon_up
        docs_up
        ;;
      full-code-graph)
        qdrant_up
        surreal_up
        archon_up
        docs_up
        ;;
      full-neo4j)
        qdrant_up
        neo4j_up
        surreal_up
        archon_up
        docs_up
        ;;
      full-graph)
        qdrant_up
        neo4j_up
        surreal_up
        archon_up
        docs_up
        ;;
    esac
    show_status
    ;;
  down)
    case "$profile" in
      core)
        qdrant_down
        ;;
      core-code-graph)
        qdrant_down
        ;;
      core-neo4j)
        neo4j_down
        qdrant_down
        ;;
      surreal)
        surreal_down
        qdrant_down
        ;;
      archon)
        archon_down
        qdrant_down
        ;;
      docs)
        docs_down
        qdrant_down
        ;;
      full)
        docs_down
        archon_down
        surreal_down
        qdrant_down
        ;;
      full-code-graph)
        docs_down
        archon_down
        surreal_down
        qdrant_down
        ;;
      full-neo4j)
        docs_down
        archon_down
        surreal_down
        neo4j_down
        qdrant_down
        ;;
      full-graph)
        docs_down
        archon_down
        surreal_down
        neo4j_down
        qdrant_down
        ;;
    esac
    show_status
    ;;
  status)
    show_status
    ;;
  *)
    echo "Invalid action: $action" >&2
    usage
    exit 1
    ;;
esac
