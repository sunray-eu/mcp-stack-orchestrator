#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUT_FILE="${1:-$STACK_ROOT/report/data/final_runtime_perf.tsv}"
LABEL="${2:-refresh_$(date +%Y%m%d-%H%M%S)}"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ensure_header() {
  if [ ! -f "$OUT_FILE" ]; then
    mkdir -p "$(dirname "$OUT_FILE")"
    echo -e "target\ttest\truns\tok\tfail\tavg_ms\tp50_ms\tp95_ms" >"$OUT_FILE"
  fi
}

in_codes() {
  local code="$1"
  local allowed="$2"
  [[ ",$allowed," == *",$code,"* ]]
}

percentile_from_file() {
  local file="$1"
  local pct="$2"
  local n idx
  n="$(wc -l <"$file" | tr -d ' ')"
  if [ "$n" -eq 0 ]; then
    echo "NA"
    return 0
  fi
  idx=$(( (n * pct + 99) / 100 ))
  sort -n "$file" | sed -n "${idx}p"
}

append_stats() {
  local target="$1"
  local test="$2"
  local rows_file="$3"
  local runs ok fail avg p50 p95 times_file

  runs="$(wc -l <"$rows_file" | tr -d ' ')"
  ok="$(awk '$1==1{c++} END{print c+0}' "$rows_file")"
  fail=$((runs - ok))
  avg="$(awk '{s+=$2} END{if(NR>0) printf "%.3f", s/NR; else printf "NA"}' "$rows_file")"

  times_file="$TMP_DIR/times.$$"
  awk '{print $2}' "$rows_file" >"$times_file"
  p50="$(percentile_from_file "$times_file" 50)"
  p95="$(percentile_from_file "$times_file" 95)"

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$target" "$test" "$runs" "$ok" "$fail" "$avg" "$p50" "$p95" >>"$OUT_FILE"
}

collect_http_probe() {
  local target="$1"
  local test="$2"
  local runs="$3"
  local allowed_codes="$4"
  local url="$5"
  shift 5
  local out="$TMP_DIR/${target}_${test}.tsv"
  : >"$out"

  local i line code sec ms ok
  for i in $(seq 1 "$runs"); do
    line="$(curl -sS -o /dev/null -w '%{http_code} %{time_total}' "$@" "$url" 2>/dev/null || echo '000 0')"
    code="${line%% *}"
    sec="${line#* }"
    ms="$(awk -v t="$sec" 'BEGIN{printf "%.3f", t*1000}')"
    if in_codes "$code" "$allowed_codes"; then ok=1; else ok=0; fi
    printf "%s\t%s\t%s\n" "$ok" "$ms" "$code" >>"$out"
  done

  append_stats "$target" "${test}_${LABEL}" "$out"
}

collect_qdrant_vector_stress() {
  local collection="stress_${LABEL//[^a-zA-Z0-9_]/_}"
  local create_url="http://127.0.0.1:6333/collections/${collection}"
  local upsert_url="http://127.0.0.1:6333/collections/${collection}/points?wait=true"
  local search_url="http://127.0.0.1:6333/collections/${collection}/points/search"

  local create_payload="$TMP_DIR/qdrant_create.json"
  local upsert_payload="$TMP_DIR/qdrant_upsert.json"
  local search_payload="$TMP_DIR/qdrant_search.json"
  local upsert_rows="$TMP_DIR/qdrant_upsert_rows.tsv"
  local search_rows="$TMP_DIR/qdrant_search_rows.tsv"

  cat >"$create_payload" <<'JSON'
{"vectors":{"size":8,"distance":"Cosine"}}
JSON

  python3 - <<'PY' >"$upsert_payload"
import json
points = []
for i in range(1, 101):
    vec = [round(((i * j) % 17) / 17.0, 6) for j in range(1, 9)]
    points.append({"id": i, "vector": vec, "payload": {"label": f"p-{i}"}})
print(json.dumps({"points": points}))
PY

  cat >"$search_payload" <<'JSON'
{"vector":[0.11,0.22,0.33,0.44,0.55,0.66,0.77,0.88],"limit":5}
JSON

  curl -sS -o /dev/null -X PUT "$create_url" -H "Content-Type: application/json" --data @"$create_payload"

  : >"$upsert_rows"
  : >"$search_rows"

  local i line code sec ms ok
  for i in $(seq 1 10); do
    line="$(curl -sS -o /dev/null -w '%{http_code} %{time_total}' -X PUT "$upsert_url" -H "Content-Type: application/json" --data @"$upsert_payload" 2>/dev/null || echo '000 0')"
    code="${line%% *}"
    sec="${line#* }"
    ms="$(awk -v t="$sec" 'BEGIN{printf "%.3f", t*1000}')"
    if [ "$code" = "200" ]; then ok=1; else ok=0; fi
    printf "%s\t%s\t%s\n" "$ok" "$ms" "$code" >>"$upsert_rows"
  done

  for i in $(seq 1 200); do
    line="$(curl -sS -o /dev/null -w '%{http_code} %{time_total}' -X POST "$search_url" -H "Content-Type: application/json" --data @"$search_payload" 2>/dev/null || echo '000 0')"
    code="${line%% *}"
    sec="${line#* }"
    ms="$(awk -v t="$sec" 'BEGIN{printf "%.3f", t*1000}')"
    if [ "$code" = "200" ]; then ok=1; else ok=0; fi
    printf "%s\t%s\t%s\n" "$ok" "$ms" "$code" >>"$search_rows"
  done

  append_stats "qdrant_vector_stress" "upsert_batch_100x10_${LABEL}" "$upsert_rows"
  append_stats "qdrant_vector_stress" "search_200_${LABEL}" "$search_rows"

  curl -sS -o /dev/null -X DELETE "$create_url" || true
}

main() {
  ensure_header

  collect_http_probe "qdrant_api" "http_probe" 100 "200" "http://127.0.0.1:6333/healthz"
  collect_http_probe "archon_health" "http_probe" 100 "200" "http://127.0.0.1:18081/health"
  collect_http_probe "archon_mcp_health" "http_probe" 100 "200" "http://127.0.0.1:18051/health"
  collect_http_probe "docs_mcp_ui" "http_probe" 60 "200" "http://127.0.0.1:16280"
  collect_http_probe "surreal_mcp_health" "http_probe" 60 "200" "http://127.0.0.1:18080/health"
  collect_http_probe "surrealdb_rpc_probe" "http_probe" 60 "400" "http://127.0.0.1:18083/rpc"

  collect_http_probe "archon_mcp_toolcall" "health_check_post" 30 "200" "http://127.0.0.1:18051/mcp" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    --data '{"jsonrpc":"2.0","id":77,"method":"tools/call","params":{"name":"health_check","arguments":{}}}'

  collect_http_probe "surreal_mcp_initialize" "initialize_post" 30 "200" "http://127.0.0.1:18080/mcp" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    --data '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"stress","version":"1.0"}}}'

  collect_qdrant_vector_stress

  echo "Appended refresh results to: $OUT_FILE"
  echo "Label: $LABEL"
}

main "$@"
