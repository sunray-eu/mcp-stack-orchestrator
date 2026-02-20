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
  stack_infra.sh <bootstrap|up|down|status> [core|surreal|archon|docs|full]

Profiles:
  core     -> qdrant backend + dashboard on 127.0.0.1:6333
  surreal  -> core + local SurrealDB + surrealdb MCP + Surrealist UI (127.0.0.1:18080/18082/18083)
  archon   -> core + archon server + mcp + web ui (127.0.0.1:18081/18051/13737)
  docs     -> core + docs-mcp-server web ui/http endpoint (127.0.0.1:16280)
              requires provider credentials in ${SECRETS_FILE}
              defaults DOCS_MCP_EMBEDDING_MODEL=text-embedding-3-small when OPENAI_API_KEY is present
  full     -> core + surreal + archon + docs

Filesystem access (MCP containers):
  - Host root is mounted read-only to /hostfs
  - /Users is mounted read-only to /Users (direct-path convenience)
  - Override mount sources with MCP_HOST_FS_ROOT and MCP_HOST_FS_USERS in ${SECRETS_FILE}

SurrealDB runtime overrides (optional in ${SECRETS_FILE}):
  - SURREALDB_ROOT_USER, SURREALDB_ROOT_PASS
  - SURREALDB_DEFAULT_NS, SURREALDB_DEFAULT_DB
  - SURREALDB_RPC_PORT, SURREALDB_WS_HOST, SURREALIST_CONNECTION_NAME

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
    echo "ARCHON_MCP_PORT=18051"
    echo "ARCHON_UI_PORT=13737"
    echo "AGENTS_ENABLED=false"
    echo "LOG_LEVEL=${log_level:-INFO}"
    echo "MCP_HOST_FS_ROOT=${mcp_host_fs_root:-/}"
    echo "MCP_HOST_FS_USERS=${mcp_host_fs_users:-/Users}"
    echo "GITHUB_PAT_TOKEN=${github_pat_token:-}"
    if [ -n "${openai_api_key:-}" ]; then
      echo "OPENAI_API_KEY=${openai_api_key}"
    fi
  } > "$ARCHON_RUNTIME_ENV"
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
  python3 - <<'PY' > "$SURREALIST_INSTANCE_RUNTIME"
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
  local google_api_key google_application_credentials
  local aws_access_key_id aws_secret_access_key aws_region
  local azure_openai_api_key azure_openai_api_instance_name
  local azure_openai_api_deployment_name azure_openai_api_version
  local mcp_host_fs_root mcp_host_fs_users
  local surrealdb_root_user surrealdb_root_pass surrealdb_default_ns surrealdb_default_db
  local surrealdb_rpc_port surrealdb_ws_host surrealist_connection_name
  local provider_credentials_found

  openai_api_key="$(read_env_var "OPENAI_API_KEY" "$SECRETS_FILE")"
  docs_embedding_model="$(read_env_var "DOCS_MCP_EMBEDDING_MODEL" "$SECRETS_FILE")"
  openai_api_base="$(read_env_var "OPENAI_API_BASE" "$SECRETS_FILE")"
  google_api_key="$(read_env_var "GOOGLE_API_KEY" "$SECRETS_FILE")"
  google_application_credentials="$(read_env_var "GOOGLE_APPLICATION_CREDENTIALS" "$SECRETS_FILE")"
  aws_access_key_id="$(read_env_var "AWS_ACCESS_KEY_ID" "$SECRETS_FILE")"
  aws_secret_access_key="$(read_env_var "AWS_SECRET_ACCESS_KEY" "$SECRETS_FILE")"
  aws_region="$(read_env_var "AWS_REGION" "$SECRETS_FILE")"
  azure_openai_api_key="$(read_env_var "AZURE_OPENAI_API_KEY" "$SECRETS_FILE")"
  azure_openai_api_instance_name="$(read_env_var "AZURE_OPENAI_API_INSTANCE_NAME" "$SECRETS_FILE")"
  azure_openai_api_deployment_name="$(read_env_var "AZURE_OPENAI_API_DEPLOYMENT_NAME" "$SECRETS_FILE")"
  azure_openai_api_version="$(read_env_var "AZURE_OPENAI_API_VERSION" "$SECRETS_FILE")"
  mcp_host_fs_root="$(read_env_var "MCP_HOST_FS_ROOT" "$SECRETS_FILE")"
  mcp_host_fs_users="$(read_env_var "MCP_HOST_FS_USERS" "$SECRETS_FILE")"
  surrealdb_root_user="$(read_env_var "SURREALDB_ROOT_USER" "$SECRETS_FILE")"
  surrealdb_root_pass="$(read_env_var "SURREALDB_ROOT_PASS" "$SECRETS_FILE")"
  surrealdb_default_ns="$(read_env_var "SURREALDB_DEFAULT_NS" "$SECRETS_FILE")"
  surrealdb_default_db="$(read_env_var "SURREALDB_DEFAULT_DB" "$SECRETS_FILE")"
  surrealdb_rpc_port="$(read_env_var "SURREALDB_RPC_PORT" "$SECRETS_FILE")"
  surrealdb_ws_host="$(read_env_var "SURREALDB_WS_HOST" "$SECRETS_FILE")"
  surrealist_connection_name="$(read_env_var "SURREALIST_CONNECTION_NAME" "$SECRETS_FILE")"

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

  write_surrealist_instance_config \
    "$surrealdb_root_user" \
    "$surrealdb_root_pass" \
    "$surrealdb_ws_host" \
    "$surrealdb_rpc_port" \
    "$surrealdb_default_ns" \
    "$surrealdb_default_db" \
    "$surrealist_connection_name"

  mkdir -p "$(dirname "$INFRA_RUNTIME_ENV")"
  {
    echo "OPENAI_API_KEY=${openai_api_key:-}"
    echo "DOCS_MCP_EMBEDDING_MODEL=${docs_embedding_model:-}"
    echo "OPENAI_API_BASE=${openai_api_base:-}"
    echo "GOOGLE_API_KEY=${google_api_key:-}"
    echo "GOOGLE_APPLICATION_CREDENTIALS=${google_application_credentials:-}"
    echo "AWS_ACCESS_KEY_ID=${aws_access_key_id:-}"
    echo "AWS_SECRET_ACCESS_KEY=${aws_secret_access_key:-}"
    echo "AWS_REGION=${aws_region:-}"
    echo "AZURE_OPENAI_API_KEY=${azure_openai_api_key:-}"
    echo "AZURE_OPENAI_API_INSTANCE_NAME=${azure_openai_api_instance_name:-}"
    echo "AZURE_OPENAI_API_DEPLOYMENT_NAME=${azure_openai_api_deployment_name:-}"
    echo "AZURE_OPENAI_API_VERSION=${azure_openai_api_version:-}"
    echo "MCP_HOST_FS_ROOT=${mcp_host_fs_root:-/}"
    echo "MCP_HOST_FS_USERS=${mcp_host_fs_users:-/Users}"
    echo "SURREALDB_ROOT_USER=${surrealdb_root_user}"
    echo "SURREALDB_ROOT_PASS=${surrealdb_root_pass}"
    echo "SURREALDB_DEFAULT_NS=${surrealdb_default_ns}"
    echo "SURREALDB_DEFAULT_DB=${surrealdb_default_db}"
    echo "SURREALDB_RPC_PORT=${surrealdb_rpc_port}"
    echo "SURREALIST_INSTANCE_FILE=${SURREALIST_INSTANCE_RUNTIME}"
  } > "$INFRA_RUNTIME_ENV"
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

surreal_up() {
  require_file "$INFRA_COMPOSE"
  write_infra_runtime_env false
  infra_compose up -d surrealmcp surrealdb surrealist
}

surreal_down() {
  require_file "$INFRA_COMPOSE"
  infra_compose rm -sf surrealmcp surrealdb surrealist >/dev/null 2>&1 || true
  docker rm -f ai-mcp-surreal-mcp ai-mcp-surrealdb ai-mcp-surrealist mcp-eval-surrealmcp >/dev/null 2>&1 || true
}

docs_up() {
  require_file "$INFRA_COMPOSE"
  write_infra_runtime_env true
  infra_compose up -d docs-mcp-web
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
  (cd "$ARCHON_DIR" && archon_compose --env-file "$ARCHON_RUNTIME_ENV" up -d archon-server archon-mcp archon-frontend)
}

archon_down() {
  if [ ! -d "$ARCHON_DIR" ]; then
    return 0
  fi
  require_file "$ARCHON_OVERRIDE_COMPOSE"
  if [ -f "$ARCHON_RUNTIME_ENV" ]; then
    (cd "$ARCHON_DIR" && archon_compose --env-file "$ARCHON_RUNTIME_ENV" stop archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true)
    (cd "$ARCHON_DIR" && archon_compose --env-file "$ARCHON_RUNTIME_ENV" rm -sf archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true)
  else
    (cd "$ARCHON_DIR" && archon_compose stop archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true)
    (cd "$ARCHON_DIR" && archon_compose rm -sf archon-mcp archon-server archon-frontend >/dev/null 2>&1 || true)
  fi
  docker rm -f ai-mcp-archon-server ai-mcp-archon-mcp ai-mcp-archon-ui archon-server archon-mcp archon-ui >/dev/null 2>&1 || true
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

show_endpoints() {
  local surrealdb_rpc_port
  surrealdb_rpc_port="$(read_env_var "SURREALDB_RPC_PORT" "$INFRA_RUNTIME_ENV")"
  if [ -z "${surrealdb_rpc_port:-}" ]; then
    surrealdb_rpc_port="18083"
  fi
  echo
  echo "== Endpoint checks =="
  printf "%-24s %-32s %s\n" "service" "url" "http"
  printf "%-24s %-32s %s\n" "qdrant-api" "http://127.0.0.1:6333/healthz" "$(http_code 'http://127.0.0.1:6333/healthz')"
  printf "%-24s %-32s %s\n" "qdrant-dashboard" "http://127.0.0.1:6333/dashboard/" "$(http_code 'http://127.0.0.1:6333/dashboard/')"
  printf "%-24s %-32s %s\n" "surrealdb-rpc" "http://127.0.0.1:${surrealdb_rpc_port}/rpc" "$(http_code "http://127.0.0.1:${surrealdb_rpc_port}/rpc")"
  printf "%-24s %-32s %s\n" "surreal-mcp" "http://127.0.0.1:18080/mcp" "$(http_code 'http://127.0.0.1:18080/mcp')"
  printf "%-24s %-32s %s\n" "surrealist-ui" "http://127.0.0.1:18082" "$(http_code 'http://127.0.0.1:18082')"
  printf "%-24s %-32s %s\n" "archon-api" "http://127.0.0.1:18081/health" "$(http_code 'http://127.0.0.1:18081/health')"
  printf "%-24s %-32s %s\n" "archon-mcp-health" "http://127.0.0.1:18051/health" "$(http_code 'http://127.0.0.1:18051/health')"
  printf "%-24s %-32s %s\n" "archon-ui" "http://127.0.0.1:13737" "$(http_code 'http://127.0.0.1:13737')"
  printf "%-24s %-32s %s\n" "docs-mcp-ui" "http://127.0.0.1:16280" "$(http_code 'http://127.0.0.1:16280')"
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
  core|surreal|archon|docs|full) ;;
  *)
    echo "Invalid profile: $profile" >&2
    usage
    exit 1
    ;;
esac

case "$action" in
  bootstrap)
    if [ "$profile" = "archon" ] || [ "$profile" = "full" ]; then
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
    esac
    show_status
    ;;
  down)
    case "$profile" in
      core)
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
