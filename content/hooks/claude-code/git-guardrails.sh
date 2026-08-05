#!/usr/bin/env bash
# PreToolUse hook — git safety guardrails.
# Blocks destructive git patterns and enforces signed commits.
# Input: JSON object from stdin with keys: tool_name, tool_input.
# Exit 2 = block the tool call. Exit 1 = warn but allow.
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
tool_input=$(echo "$input" | jq -r '.tool_input.command // ""')

# Only guard Bash(git *) calls
if [[ "$tool_name" != "Bash" ]]; then
    exit 0
fi

# Strip leading "git " for matching
git_cmd="${tool_input#git }"

# --- BLOCK: force push to main/master ---
if echo "$git_cmd" | grep -qE 'push.*(--force|-f).*(main|master)'; then
    echo "BLOCKED: git push --force to main/master is never allowed." >&2
    echo "  → Use a revert commit or a new PR instead." >&2
    exit 2
fi

# --- BLOCK: --no-verify ---
if echo "$git_cmd" | grep -qE '(-n|--no-verify|--no-gpg-sign)'; then
    echo "BLOCKED: git --no-verify / --no-gpg-sign not allowed. Hooks exist for a reason." >&2
    echo "  → Fix the underlying issue, don't skip hooks." >&2
    exit 2
fi

# --- BLOCK: amend after hook failure ---
# If the previous commit was created by a hook (indicated by recent amend),
# block another amend. This is a heuristic — it fires if amend is used at all.
if echo "$git_cmd" | grep -qE 'commit.*--amend'; then
    echo "BLOCKED: git commit --amend after hook failure creates silent data loss risk." >&2
    echo "  → Create a NEW commit instead of amending. git commit -m \"...\"" >&2
    exit 2
fi

# --- WARN: git add -A / git add . ---
if echo "$git_cmd" | grep -qE 'add\s+(-A|\.)'; then
    echo "WARNING: git add -A / git add . stages everything — secrets, binaries, noise." >&2
    echo "  → Prefer: git add <specific-files> or use -p for hunks." >&2
    # Warning only — allow with exit 0
fi

# --- WARN: unsigned commits ---
if echo "$git_cmd" | grep -qE 'commit'; then
    gpgsign=$(git config commit.gpgsign 2>/dev/null || echo "false")
    signingkey=$(git config user.signingkey 2>/dev/null || echo "")
    if [[ "$gpgsign" != "true" || -z "$signingkey" ]]; then
        echo "WARNING: Signed commits not configured." >&2
        echo "  → Run: git config --global commit.gpgsign true" >&2
        echo "  → Run: git config --global user.signingkey <KEY>" >&2
        # Warning only — allow
    fi
fi

exit 0
