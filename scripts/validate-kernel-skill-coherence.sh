#!/usr/bin/env bash
# validate-kernel-skill-coherence.sh
# Checks that agent kernels have coherent skill invocation and memory declarations.
# Exits non-zero if any error is found.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
AGENTS_DIR="${REPO_ROOT}/content/rules/agents"

ERRORS=0

error() {
    echo "ERROR: $*" >&2
    ERRORS=$((ERRORS + 1))
}
ok() { echo "OK:    $*" >&2; }

# Kernels that support a skill tool (must name it explicitly)
TOOL_AGENTS=(claude-code opencode)
# Kernels without a runtime skill tool (must name @file pattern)
FILE_AGENTS=(antigravity codex-cli pi omp)

check_no_windsurf_leak() {
    local file="$1" agent="$2"
    # mcp11_* and create_memory are Windsurf-only — must not appear in non-Windsurf kernels.
    # Gemini legitimately mentions "no `create_memory`" as a negation — exclude that pattern.
    if [[ "$agent" == "windsurf" ]]; then
        return 0
    fi
    if grep -qE "mcp11_" "$file"; then
        error "${agent}: contains Windsurf-only token (mcp11_*)"
    fi
    # Detect positive use of create_memory (not the "no create_memory" negation)
    if grep -E "create_memory" "$file" | grep -qvE "(no .create_memory|no create_memory)"; then
        error "${agent}: contains Windsurf-only token (create_memory) outside negation"
    fi
}

check_invocation_clause() {
    local file="$1" agent="$2"
    # Tool-capable agents: canonical marker is "Mentioning in prose is NOT invocation"
    # (set by the new <SKILLS> template; works regardless of markdown bold syntax around tool name)
    for a in "${TOOL_AGENTS[@]}"; do
        if [[ "$agent" == "$a" ]]; then
            if ! grep -q "Mentioning in prose is NOT invocation" "$file"; then
                error "${agent}: missing canonical invocation clause ('Mentioning in prose is NOT invocation') in <SKILLS>"
            fi
            if grep -q "Invoke by name. Never guess." "$file"; then
                error "${agent}: contains regressive text 'Invoke by name. Never guess.' — replace with tool-explicit clause"
            fi
            return 0
        fi
    done
    # @file agents: must reference SKILL.md and a file-open mechanism
    for a in "${FILE_AGENTS[@]}"; do
        if [[ "$agent" == "$a" ]]; then
            if ! grep -qE "SKILL\.md" "$file"; then
                error "${agent}: missing 'SKILL.md' reference in <SKILLS>"
            fi
            return 0
        fi
    done
}

check_baseline_skills() {
    local file="$1" agent="$2"
    for skill in operating-protocol governance engineering-standards context-management tool-usage token-efficiency skill-router; do
        if ! grep -q "\`${skill}\`" "$file"; then
            error "${agent}: baseline skill '\`${skill}\`' missing from <SKILLS>"
        fi
    done
}

check_memory_block() {
    local file="$1" agent="$2"
    if ! grep -q "<MEMORY>" "$file"; then
        error "${agent}: missing <MEMORY> block"
        return
    fi
    # The memory block must have concrete content beyond just the pointer to operating-protocol
    local memory_content
    memory_content=$(awk '/<MEMORY>/,/<\/MEMORY>/' "$file")
    if ! echo "$memory_content" | grep -qE "(persist|write|create_entities|add_observations|\.md|\.cursor|\.gemini|mcp__memory__)"; then
        error "${agent}: <MEMORY> block has no concrete persistence target (filesystem path or MCP call)"
    fi
}

check_claude_code_mcp() {
    local file="$1"
    if ! grep -q "mcp__memory__" "$file"; then
        error "claude-code: missing mcp__memory__ reference in kernel (expected in <MEMORY> and <REINFORCE>)"
    fi
}

check_reinforce_step3() {
    local file="$1" agent="$2"
    if grep -qE "Non-trivial task.*invoke.*operating-protocol" "$file"; then
        error "${agent}: REINFORCE step 3 still uses old 'Non-trivial task' pattern — update to mode-mapping"
    fi
}

# ---------- main ----------

if [[ ! -d "$AGENTS_DIR" ]]; then
    echo "ERROR: agents directory not found: $AGENTS_DIR" >&2
    exit 1
fi

for kernel_file in "${AGENTS_DIR}"/*-global.md; do
    [[ -f "$kernel_file" ]] || continue
    basename_file=$(basename "$kernel_file")
    agent="${basename_file%-global.md}"

    check_no_windsurf_leak "$kernel_file" "$agent"
    check_invocation_clause "$kernel_file" "$agent"
    check_baseline_skills "$kernel_file" "$agent"
    check_memory_block "$kernel_file" "$agent"
    check_reinforce_step3 "$kernel_file" "$agent"

    if [[ "$agent" == "claude-code" ]]; then
        check_claude_code_mcp "$kernel_file"
    fi

    if [[ $ERRORS -eq 0 ]]; then
        ok "${agent}-global.md"
    fi
done

if [[ $ERRORS -gt 0 ]]; then
    echo "" >&2
    echo "FAIL: $ERRORS kernel coherence error(s) found." >&2
    exit 1
fi

echo "PASS: all kernels are coherent." >&2
exit 0
