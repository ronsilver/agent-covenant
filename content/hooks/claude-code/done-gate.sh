#!/usr/bin/env bash
# Stop hook — verify evidence labels before session ends.
# Warns when the last assistant turn lacks evidence labels on factual claims.
# Non-blocking (exit 0 always) — observability only.
# Input: JSON from stdin with field: transcript_path (session JSONL).
set -euo pipefail

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    exit 0
fi

# Extract the most recent assistant turn text
last_text=$(jq -r '
  select(.type == "assistant") |
  .message.content // [] |
  map(select(.type == "text") | .text) |
  join(" ")
' "$transcript_path" 2>/dev/null | tail -1)

if [[ -z "$last_text" ]]; then
    exit 0
fi

# Check for task-completion signals without evidence labels
has_completion=$(echo "$last_text" | grep -iE "(task complete|done|finished|implemented|fixed|added|updated|created)" || true)
has_evidence=$(echo "$last_text" | grep -E "(EXECUTED|STATIC|INFERRED|BLOCKED)" || true)

if [[ -n "$has_completion" && -z "$has_evidence" ]]; then
    echo "WARN [done-gate]: task-completion language detected but no evidence labels (EXECUTED/STATIC/INFERRED/BLOCKED) found." >&2
    echo "  → Per operating-protocol: label factual claims before declaring done." >&2
fi

exit 0
