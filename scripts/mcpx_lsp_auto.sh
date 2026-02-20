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
    echo "mcpx-lsp: workspace does not exist: $workspace" >&2
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
      ''|'#'*) continue ;;
      *=*) ;;
      *) continue ;;
    esac

    local key="${line%%=*}"
    local val="${line#*=}"
    key="$(echo "$key" | tr -d '[:space:]')"

    case "$val" in
      \"*\") val="${val#\"}"; val="${val%\"}" ;;
      \'*\') val="${val#\'}"; val="${val%\'}" ;;
    esac

    case "$key" in
      MCP_LSP_MODE|MCP_LSP_PREFERENCE|MCP_LSP_FALLBACK|MCP_LANGUAGE_SERVER_BIN|MCP_TS_LSP|MCP_PY_LSP)
        export "$key=$val"
        ;;
      *) ;;
    esac
  done < "$file"
}

has_ts_markers() {
  local ws="$1"
  [ -f "$ws/tsconfig.json" ] || [ -f "$ws/package.json" ] || find "$ws" -maxdepth 3 -type f \( -name '*.ts' -o -name '*.tsx' \) | head -n 1 | grep -q .
}

has_py_markers() {
  local ws="$1"
  [ -f "$ws/pyproject.toml" ] || [ -f "$ws/requirements.txt" ] || [ -f "$ws/setup.py" ] || find "$ws" -maxdepth 3 -type f -name '*.py' | head -n 1 | grep -q .
}

pick_mode() {
  local ws="$1"
  local mode="${MCP_LSP_MODE:-auto}"
  local prefer="${MCP_LSP_PREFERENCE:-typescript}"

  if [ "$mode" = "python" ] || [ "$mode" = "typescript" ]; then
    echo "$mode"
    return 0
  fi

  local has_ts=false
  local has_py=false
  if has_ts_markers "$ws"; then has_ts=true; fi
  if has_py_markers "$ws"; then has_py=true; fi

  if [ "$has_ts" = true ] && [ "$has_py" = false ]; then
    echo "typescript"
    return 0
  fi
  if [ "$has_py" = true ] && [ "$has_ts" = false ]; then
    echo "python"
    return 0
  fi
  if [ "$has_py" = true ] && [ "$has_ts" = true ]; then
    echo "$prefer"
    return 0
  fi

  echo "${MCP_LSP_FALLBACK:-typescript}"
}

resolve_mcp_server_bin() {
  if [ -n "${MCP_LANGUAGE_SERVER_BIN:-}" ]; then
    echo "$MCP_LANGUAGE_SERVER_BIN"
    return 0
  fi
  if command -v mcp-language-server >/dev/null 2>&1; then
    command -v mcp-language-server
    return 0
  fi
  if [ -x "$HOME/go/bin/mcp-language-server" ]; then
    echo "$HOME/go/bin/mcp-language-server"
    return 0
  fi
  return 1
}

resolve_lsp_cmd() {
  local preferred="$1"
  if command -v "$preferred" >/dev/null 2>&1; then
    command -v "$preferred"
    return 0
  fi
  if command -v "${preferred##*/}" >/dev/null 2>&1; then
    command -v "${preferred##*/}"
    return 0
  fi
  return 1
}

workspace="$(resolve_workspace)"
load_workspace_overrides "$workspace/.mcp-stack.env"
mode="$(pick_mode "$workspace")"

mcp_bin="$(resolve_mcp_server_bin || true)"
if [ -z "${mcp_bin:-}" ] || [ ! -x "$mcp_bin" ]; then
  echo "mcpx-lsp: mcp-language-server not found; set MCP_LANGUAGE_SERVER_BIN or install it in PATH" >&2
  exit 3
fi

if [ "$mode" = "python" ]; then
  lsp_pref="${MCP_PY_LSP:-pyright-langserver}"
  lsp_cmd="$(resolve_lsp_cmd "$lsp_pref" || true)"
  lsp_args=(--stdio)
elif [ "$mode" = "typescript" ]; then
  lsp_pref="${MCP_TS_LSP:-typescript-language-server}"
  lsp_cmd="$(resolve_lsp_cmd "$lsp_pref" || true)"
  lsp_args=(--stdio)
else
  echo "mcpx-lsp: unsupported MCP_LSP_MODE resolved to '$mode'" >&2
  exit 4
fi

if [ -z "${lsp_cmd:-}" ]; then
  echo "mcpx-lsp: LSP command not found: $lsp_pref" >&2
  exit 5
fi

exec "$mcp_bin" --workspace "$workspace" --lsp "$lsp_cmd" -- "${lsp_args[@]}"
