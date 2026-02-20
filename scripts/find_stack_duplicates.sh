#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Canonical stack path:"
echo "  $STACK_ROOT"
echo

echo "Detected alternate/legacy stack roots:"
found=0

if [ -f "$HOME/mcp-eval/scripts/stack_infra.sh" ]; then
  echo "  $HOME/mcp-eval (legacy duplicate from evaluation harness)"
  found=1
fi

while IFS= read -r path; do
  dir="$(cd "$(dirname "$(dirname "$path")")" && pwd)"
  if [ "$dir" != "$STACK_ROOT" ] && [ "$dir" != "$HOME/mcp-eval" ]; then
    echo "  $dir"
    found=1
  fi
done < <(find "$HOME" -maxdepth 6 -type f -path "*/scripts/stack_infra.sh" 2>/dev/null || true)

if [ "$found" -eq 0 ]; then
  echo "  (none)"
fi
echo
echo "Recommendation:"
echo "  Run all infra/profile operations from the canonical stack path above."

