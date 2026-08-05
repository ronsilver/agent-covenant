#!/usr/bin/env bash
# PreToolUse hook — block Edit/Write on files not read in the current session.
# Called by Claude Code before any Edit or Write tool call.
# Input: JSON object from stdin with keys: tool_name, tool_input.
# Exit 2 = block the tool call and show the error message.
# Override: set env CLAUDE_ALLOW_BLIND_EDIT=1 (e.g., for new files).
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // ""')

# Only guard Edit and Write
if [[ "$tool_name" != "Edit" && "$tool_name" != "Write" ]]; then
    exit 0
fi

# Allow override for new-file creation
if [[ "${CLAUDE_ALLOW_BLIND_EDIT:-0}" == "1" ]]; then
    exit 0
fi

# If the file doesn't exist yet, allow (Write creating new file)
if [[ -n "$file_path" && ! -f "$file_path" ]]; then
    exit 0
fi

# Find the current session JSONL (most recently modified) without /tmp mtime dependency
session_jsonl=$(ls -t "${HOME}/.claude/projects"/*/*.jsonl 2>/dev/null | head -1)

if [[ -z "$session_jsonl" ]]; then
    exit 0  # Cannot determine session — allow (fail open)
fi

# Single jq pass: check if file_path appears in any Read tool_use entry
if jq -e --arg fp "$file_path" \
    'select(.type == "tool_use" and .name == "Read" and .input.file_path == $fp)' \
    "$session_jsonl" >/dev/null 2>&1; then
    exit 0  # Read found — allow
fi

echo "BLOCKED: Read '${file_path}' before editing. Rule: Read BEFORE Edit/Write (tool-usage)." >&2
echo "  → Run: Read tool on '${file_path}' first, then retry the edit." >&2
echo "  → Override: export CLAUDE_ALLOW_BLIND_EDIT=1 (for new files only)" >&2
exit 2
