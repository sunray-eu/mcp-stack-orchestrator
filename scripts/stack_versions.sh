#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSIONS_ENV="${STACK_ROOT}/infra/versions.env"
INFRA_COMPOSE="${STACK_ROOT}/infra/docker-compose.yml"

usage() {
  cat <<USAGE
Usage:
  stack_versions.sh <show|pull|check|refresh>

Commands:
  show     Print configured image refs and local digest presence.
  pull     Pull all images defined by docker-compose + versions.env.
  check    Compare pinned digest refs against latest upstream channel refs.
  refresh  Pull upstream channel refs and rewrite pinned digest keys in versions.env.
USAGE
}

require_file() {
  local f="$1"
  if [ ! -f "$f" ]; then
    echo "Missing required file: $f" >&2
    exit 1
  fi
}

compose_cmd() {
  docker compose --env-file "$VERSIONS_ENV" -f "$INFRA_COMPOSE" "$@"
}

read_var() {
  local key="$1"
  awk -F= -v k="$key" '$1==k {print substr($0, index($0, "=")+1); exit}' "$VERSIONS_ENV"
}

upsert_var() {
  local key="$1"
  local val="$2"
  local tmp
  tmp="$(mktemp)"
  awk -F= -v k="$key" -v v="$val" '
    BEGIN { done = 0 }
    $1 == k { print k "=" v; done = 1; next }
    { print $0 }
    END { if (!done) print k "=" v }
  ' "$VERSIONS_ENV" >"$tmp"
  mv "$tmp" "$VERSIONS_ENV"
}

local_digest_or_na() {
  local image_ref="$1"
  local digest
  digest="$(docker image inspect "$image_ref" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)"
  if [ -z "${digest:-}" ]; then
    echo "not-pulled"
  else
    echo "$digest" | tr -d '\r\n'
  fi
}

print_table_row() {
  printf "%-22s %-78s %s\n" "$1" "$2" "$3"
}

floating_key_pairs() {
  cat <<'EOF'
SURREALMCP_IMAGE surrealdb/surrealmcp:latest
# Keep SurrealDB on 2.3.x channel for current SurrealMCP compatibility.
SURREALDB_IMAGE surrealdb/surrealdb:v2.3.10
SURREALIST_IMAGE surrealdb/surrealist:latest
DOCS_MCP_IMAGE ghcr.io/arabold/docs-mcp-server:latest
EOF
}

cmd_show() {
  require_file "$VERSIONS_ENV"
  require_file "$INFRA_COMPOSE"
  echo "== versions.env refs =="
  print_table_row "key" "configured_ref" "local_digest"
  while IFS='=' read -r key value; do
    [ -n "${key}" ] || continue
    case "$key" in
      \#* | "") continue ;;
    esac
    print_table_row "$key" "$value" "$(local_digest_or_na "$value")"
  done <"$VERSIONS_ENV"
  echo
  echo "== compose resolved images =="
  compose_cmd config --images | sort -u
}

cmd_pull() {
  require_file "$VERSIONS_ENV"
  require_file "$INFRA_COMPOSE"
  compose_cmd pull
}

cmd_check() {
  require_file "$VERSIONS_ENV"
  echo "== digest pin freshness check =="
  print_table_row "key" "pinned_ref" "status"
  while read -r key source_ref; do
    [ -n "${key:-}" ] || continue
    pinned_ref="$(read_var "$key")"
    if [ -z "${pinned_ref:-}" ]; then
      print_table_row "$key" "-" "missing"
      continue
    fi
    docker pull "$source_ref" >/dev/null
    latest_ref="$(docker image inspect "$source_ref" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)"
    if [ -z "${latest_ref:-}" ]; then
      print_table_row "$key" "$pinned_ref" "unable-to-resolve-latest"
      continue
    fi
    if [ "$pinned_ref" = "$latest_ref" ]; then
      print_table_row "$key" "$pinned_ref" "up-to-date"
    else
      print_table_row "$key" "$pinned_ref" "update-available -> $latest_ref"
    fi
  done < <(floating_key_pairs)
}

cmd_refresh() {
  require_file "$VERSIONS_ENV"
  echo "Refreshing digest-pinned refs in $VERSIONS_ENV"
  while read -r key source_ref; do
    [ -n "${key:-}" ] || continue
    echo "Pulling $source_ref ..."
    docker pull "$source_ref" >/dev/null
    latest_ref="$(docker image inspect "$source_ref" --format '{{index .RepoDigests 0}}' 2>/dev/null || true)"
    if [ -z "${latest_ref:-}" ]; then
      echo "WARN: could not resolve digest for $source_ref" >&2
      continue
    fi
    upsert_var "$key" "$latest_ref"
    echo "Updated $key=$latest_ref"
  done < <(floating_key_pairs)
}

if [ "$#" -ne 1 ]; then
  usage
  exit 1
fi

case "$1" in
  show) cmd_show ;;
  pull) cmd_pull ;;
  check) cmd_check ;;
  refresh) cmd_refresh ;;
  *)
    usage
    exit 1
    ;;
esac
