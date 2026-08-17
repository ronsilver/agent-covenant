#!/usr/bin/env bash
set -euo pipefail

ROUTER="content/subagents/ultraorchestrator.md"
MCP_CFG="content/mcp/opencode-mcp.json"
errors=0

if ! grep -q "^## REFUSAL PROTOCOL" "$ROUTER"; then
	echo "FAIL: $ROUTER missing '## REFUSAL PROTOCOL'"
	errors=$((errors + 1))
fi

if ! grep -q "^## Dispatch" "$ROUTER"; then
	echo "FAIL: $ROUTER missing '## Dispatch' section"
	errors=$((errors + 1))
fi

if ! grep -q 'task(' "$ROUTER"; then
	echo "FAIL: $ROUTER never instructs calling task(...) for dispatch"
	errors=$((errors + 1))
fi

if ! grep -q "MUST NOT self-execute" "$ROUTER"; then
	echo "FAIL: $ROUTER missing 'MUST NOT self-execute'"
	errors=$((errors + 1))
fi

mount_count=$(jq -r '.mcp.filesystem.command[]' "$MCP_CFG" 2>/dev/null | grep -c '^/$' || true)
if [[ "${mount_count}" -gt 0 ]]; then
	echo "FAIL: $MCP_CFG filesystem server mounted at '/' — read-only subagents could write via MCP"
	errors=$((errors + 1))
fi

if [[ $errors -gt 0 ]]; then
	echo "FAILED router delegation check: ${errors} error(s)"
	exit 1
fi
echo "PASS: router delegates via task; MCP write root narrowed"
