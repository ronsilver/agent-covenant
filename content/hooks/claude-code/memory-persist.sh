#!/usr/bin/env bash
# Stop hook — advisory reminder to persist memory when new context is detected.
# Detects user/assistant signals indicating a decision or preference emerged,
# warns if no mcp__memory__ write happened during the session.
# Non-blocking (exit 0 always).
# Input: JSON from stdin with field: transcript_path (session JSONL).
set -euo pipefail

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    exit 0
fi

full_text=$(jq -r '
  .message.content // [] |
  map(select(.type == "text") | .text) |
  join(" ")
' "$transcript_path" 2>/dev/null | tr '\n' ' ')

if [[ -z "$full_text" ]]; then
    exit 0
fi

# Signals that new cross-session context may have emerged
has_signal=$(echo "$full_text" | grep -iE \
    "(recuerda|remember|from now on|siempre|never again|prefer|prefiero|decision|convention|going forward|I will note|I'll remember|saving to memory|persistido)" \
    || true)

if [[ -z "$has_signal" ]]; then
    exit 0
fi

# Check if a memory write tool call was made
has_memory_write=$(jq -r '
  select(.type == "tool_use") |
  .name // ""
' "$transcript_path" 2>/dev/null | grep -E "mcp__memory__(create_entities|add_observations)" || true)

if [[ -z "$has_memory_write" ]]; then
    echo "INFO [memory-advisor]: New context detected but no mcp__memory__ write found." >&2
    echo "  → Call mcp__memory__create_entities or mcp__memory__add_observations before ending session." >&2
    echo "  → See kernel <MEMORY> block for persistence instructions." >&2
fi

exit 0
