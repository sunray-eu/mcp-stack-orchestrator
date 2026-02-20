#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_SCRIPT="${STACK_ROOT}/scripts/stack_infra.sh"
VERSIONS_SCRIPT="${STACK_ROOT}/scripts/stack_versions.sh"
MANIFEST_FILE="${STACK_ROOT}/configs/mcp_stack_manifest.json"
SECRETS_FILE="${STACK_ROOT}/.secrets.env"
INFRA_RUNTIME_ENV="${STACK_ROOT}/tmp/ai-mcp-infra.env"
ARCHON_RUNTIME_ENV="${STACK_ROOT}/tmp/ai-mcp-archon.env"

PROFILE="${1:-full}"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

pass() {
  echo "PASS: $*"
  PASS_COUNT=$((PASS_COUNT + 1))
}
warn() {
  echo "WARN: $*"
  WARN_COUNT=$((WARN_COUNT + 1))
}
fail() {
  echo "FAIL: $*"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

require_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    pass "command available: $cmd"
  else
    fail "missing command: $cmd"
  fi
}

check_file() {
  local f="$1"
  if [ -f "$f" ]; then
    pass "file exists: $f"
  else
    fail "missing file: $f"
  fi
}

check_perm_600_or_warn() {
  local f="$1"
  [ -f "$f" ] || return 0
  local perm
  perm="$(stat -f '%Lp' "$f" 2>/dev/null || echo "")"
  if [ "$perm" = "600" ]; then
    pass "permissions 600: $f"
  else
    warn "permissions are $perm (expected 600): $f"
  fi
}

http_code() {
  local url="$1"
  curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$url" 2>/dev/null || echo "000"
}

check_endpoint() {
  local name="$1"
  local url="$2"
  local expected_csv="$3"
  local max_tries="${4:-1}"
  local attempt code
  local expected
  IFS=',' read -r -a expected <<<"$expected_csv"

  for attempt in $(seq 1 "$max_tries"); do
    code="$(http_code "$url")"
    for e in "${expected[@]}"; do
      if [ "$code" = "$e" ]; then
        pass "endpoint $name -> $code ($url)"
        return 0
      fi
    done
    if [ "$attempt" -lt "$max_tries" ]; then
      sleep 2
    fi
  done
  fail "endpoint $name unexpected status $code (expected: $expected_csv, url: $url)"
}

check_bash_syntax() {
  local f="$1"
  if bash -n "$f"; then
    pass "bash syntax ok: $f"
  else
    fail "bash syntax invalid: $f"
  fi
}

check_codex_profile_servers() {
  if ! command -v codex >/dev/null 2>&1; then
    warn "codex not found; skipping managed MCP registration check"
    return 0
  fi
  if [ ! -f "$MANIFEST_FILE" ]; then
    warn "manifest missing; skipping managed MCP registration check"
    return 0
  fi

  local required
  required="$(
    MANIFEST_FILE="$MANIFEST_FILE" PROFILE="$PROFILE" python3 - <<'PY'
import json
import os
from pathlib import Path
manifest = json.loads(Path(os.environ["MANIFEST_FILE"]).read_text())
profile = os.environ["PROFILE"]
for s in manifest["profiles"].get(profile, []):
    print(s)
PY
  )"
  if [ -z "${required:-}" ]; then
    pass "profile ${PROFILE} has no managed MCP servers"
    return 0
  fi

  local list_out
  list_out="$(CODEX_HOME="$HOME/.codex-mcp-eval" codex mcp list 2>/dev/null || true)"
  if [ -z "${list_out:-}" ]; then
    warn "could not read codex eval mcp list"
    return 0
  fi
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if echo "$list_out" | awk 'NR>1{print $1}' | grep -Fx "$name" >/dev/null; then
      pass "codex eval MCP present: $name"
    else
      warn "codex eval MCP missing for profile ${PROFILE}: $name"
    fi
  done <<<"$required"
}

case "$PROFILE" in
  core | surreal | archon | docs | full) ;;
  *)
    echo "Invalid profile: $PROFILE" >&2
    echo "Use one of: core|surreal|archon|docs|full" >&2
    exit 2
    ;;
esac

echo "== stack_doctor :: profile=${PROFILE} =="

require_cmd docker
require_cmd python3
require_cmd curl
require_cmd bash

check_file "$INFRA_SCRIPT"
check_file "$VERSIONS_SCRIPT"
check_file "$MANIFEST_FILE"
check_file "$STACK_ROOT/infra/docker-compose.yml"
check_file "$STACK_ROOT/infra/versions.env"
check_file "$STACK_ROOT/scripts/mcpx_qdrant_auto.sh"
check_file "$STACK_ROOT/scripts/mcpx_lsp_auto.sh"

check_bash_syntax "$INFRA_SCRIPT"
check_bash_syntax "$VERSIONS_SCRIPT"
check_bash_syntax "$STACK_ROOT/scripts/mcpx_qdrant_auto.sh"
check_bash_syntax "$STACK_ROOT/scripts/mcpx_lsp_auto.sh"

if [ -f "$SECRETS_FILE" ]; then
  pass "secrets file exists: $SECRETS_FILE"
  check_perm_600_or_warn "$SECRETS_FILE"
else
  warn "secrets file not present: $SECRETS_FILE (required for archon/docs profiles)"
fi

check_perm_600_or_warn "$INFRA_RUNTIME_ENV"
check_perm_600_or_warn "$ARCHON_RUNTIME_ENV"

if docker compose --env-file "$STACK_ROOT/infra/versions.env" -f "$STACK_ROOT/infra/docker-compose.yml" config >/dev/null; then
  pass "docker compose config resolves with versions.env"
else
  fail "docker compose config failed"
fi

if [ -f "$INFRA_RUNTIME_ENV" ]; then
  if docker compose --env-file "$STACK_ROOT/infra/versions.env" --env-file "$INFRA_RUNTIME_ENV" -f "$STACK_ROOT/infra/docker-compose.yml" config >/dev/null; then
    pass "docker compose config resolves with versions.env + runtime env"
  else
    fail "docker compose config failed with runtime env"
  fi
fi

check_codex_profile_servers

if [ "$PROFILE" = "core" ] || [ "$PROFILE" = "surreal" ] || [ "$PROFILE" = "archon" ] || [ "$PROFILE" = "docs" ] || [ "$PROFILE" = "full" ]; then
  check_endpoint "qdrant-api" "http://127.0.0.1:6333/healthz" "200"
  check_endpoint "qdrant-dashboard" "http://127.0.0.1:6333/dashboard/" "200"
fi

if [ "$PROFILE" = "surreal" ] || [ "$PROFILE" = "full" ]; then
  check_endpoint "surreal-mcp" "http://127.0.0.1:18080/mcp" "401,406"
  check_endpoint "surrealist-ui" "http://127.0.0.1:18082" "200"
  check_endpoint "surrealdb-rpc" "http://127.0.0.1:18083/rpc" "400,401,405"
fi

if [ "$PROFILE" = "archon" ] || [ "$PROFILE" = "full" ]; then
  check_endpoint "archon-api" "http://127.0.0.1:18081/health" "200"
  check_endpoint "archon-mcp-health" "http://127.0.0.1:18051/health" "200"
  check_endpoint "archon-ui" "http://127.0.0.1:13737" "200"
fi

if [ "$PROFILE" = "docs" ] || [ "$PROFILE" = "full" ]; then
  check_endpoint "docs-mcp-ui" "http://127.0.0.1:16280" "200" "8"
fi

echo
echo "== stack_doctor summary =="
echo "PASS=$PASS_COUNT WARN=$WARN_COUNT FAIL=$FAIL_COUNT"

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
