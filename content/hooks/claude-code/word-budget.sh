#!/usr/bin/env bash
# PostToolUse hook — warn when inter-tool assistant text exceeds word budget.
# Non-blocking (exit 0 always) — observability only.
# Input: JSON from stdin. Relevant fields: transcript_path (session jsonl).
# Claude Code PostToolUse payload does NOT include assistant_message;
# we read the last assistant turn directly from transcript_path.
set -euo pipefail

input=$(cat)
transcript_path=$(echo "$input" | jq -r '.transcript_path // ""')

if [[ -z "$transcript_path" || ! -f "$transcript_path" ]]; then
    exit 0
fi

# Extract text of the most recent assistant message in the transcript
assistant_msg=$(jq -r 'select(.role == "assistant") | .content' "$transcript_path" 2>/dev/null | tail -1)

if [[ -z "$assistant_msg" ]]; then
    exit 0
fi

word_count=$(echo "$assistant_msg" | wc -w | tr -d ' ')

# Inter-tool limit: 25 words; done limit: 50 words
if [[ "$word_count" -gt 50 ]]; then
    echo "WARN [word-budget]: last assistant message was ${word_count}w (limit <=50w done, <=25w inter-tool). Compress per token-efficiency." >&2
elif [[ "$word_count" -gt 25 ]]; then
    echo "WARN [word-budget]: last assistant message was ${word_count}w (limit <=25w inter-tool). Compress per token-efficiency." >&2
fi

exit 0
