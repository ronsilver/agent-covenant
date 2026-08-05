#!/usr/bin/env bash
# UserPromptSubmit hook — detect and block prompt injection attempts.
# Blocks (exit 2) on high-confidence injection patterns.
# Warns (exit 0 with stderr) on suspicious but ambiguous patterns.
# Input: JSON from stdin with field: prompt (string).
set -euo pipefail

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // ""')

if [[ -z "$prompt" ]]; then
    exit 0
fi

# High-confidence injection patterns — BLOCK
HIGH_CONFIDENCE=(
    'ignore (previous|all) instructions'
    'disregard (your|the) (rules|constraints|guidelines|instructions)'
    'you are now (a |an )?[a-z]'
    'forget (everything|what you know|your (rules|instructions))'
    'new (system|override) (prompt|instruction)'
    'act as if you (have no|do not have) (restrictions|rules|guidelines)'
    '<\|.*\|>'
)

for pattern in "${HIGH_CONFIDENCE[@]}"; do
    if echo "$prompt" | grep -qiE "$pattern"; then
        echo "BLOCKED [injection-scan]: prompt matches injection pattern: ${pattern}" >&2
        echo "  → If this is a legitimate request, rephrase without the flagged language." >&2
        exit 2
    fi
done

# Medium-confidence patterns — WARN only (observability)
MEDIUM_CONFIDENCE=(
    'override (your|the) (instructions|rules|constraints)'
    'system prompt'
    'your (instructions|guidelines) say'
    'pretend (you are|to be)'
    'role ?play.*you are'
)

for pattern in "${MEDIUM_CONFIDENCE[@]}"; do
    if echo "$prompt" | grep -qiE "$pattern"; then
        echo "WARN [injection-scan]: prompt contains suspicious pattern: ${pattern}" >&2
        break
    fi
done

exit 0
