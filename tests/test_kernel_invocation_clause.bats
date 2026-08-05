#!/usr/bin/env bats
# shellcheck disable=SC2034,SC2016
# SC2016: single-quoted backtick patterns are intentional (literal grep for `skill-name`)
# =============================================================================
# Tests for kernel skill invocation clauses and memory declarations.
# Runs the standalone validator and spot-checks specific assertions per kernel.
# Run: bats tests/test_kernel_invocation_clause.bats
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
AGENTS_DIR="${REPO_ROOT}/content/rules/agents"
VALIDATOR="${SCRIPT_DIR}/validate-kernel-skill-coherence.sh"

bats_require_minimum_version 1.5.0

# ---------------------------------------------------------------------------
# Validator binary
# ---------------------------------------------------------------------------

@test "validate-kernel-skill-coherence.sh exists and is executable" {
    [[ -x "$VALIDATOR" ]]
}

@test "all kernels pass the coherence validator" {
    run bash "$VALIDATOR"
    [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# claude-code-global.md
# ---------------------------------------------------------------------------

@test "claude-code: has canonical tool invocation clause" {
    grep -q "Mentioning in prose is NOT invocation" "${AGENTS_DIR}/claude-code-global.md"
}

@test "claude-code: references mcp__memory__ in MEMORY block" {
    grep -q "mcp__memory__" "${AGENTS_DIR}/claude-code-global.md"
}

@test "claude-code: REINFORCE step 4 uses mcp__memory__read_graph" {
    grep -q "mcp__memory__read_graph" "${AGENTS_DIR}/claude-code-global.md"
}

@test "claude-code: REINFORCE step 6 uses mcp__memory__ for persistence" {
    grep -qE "mcp__memory__(create_entities|add_observations)" "${AGENTS_DIR}/claude-code-global.md"
}

@test "claude-code: does not contain regressive 'Invoke by name' text" {
    run ! grep -q "Invoke by name. Never guess." "${AGENTS_DIR}/claude-code-global.md"
}

@test "claude-code: does not contain Windsurf-only mcp11_ tokens" {
    run ! grep -q "mcp11_" "${AGENTS_DIR}/claude-code-global.md"
}

# ---------------------------------------------------------------------------
# copilot-global.md
# ---------------------------------------------------------------------------

@test "copilot: references SKILL.md as invocation mechanism" {
    grep -q "SKILL.md" "${AGENTS_DIR}/copilot-global.md"
}

@test "copilot: does not contain mcp11_ tokens" {
    run ! grep -q "mcp11_" "${AGENTS_DIR}/copilot-global.md"
}

# ---------------------------------------------------------------------------
# antigravity-global.md
# ---------------------------------------------------------------------------

@test "antigravity: references SKILL.md as invocation mechanism" {
    grep -q "SKILL.md" "${AGENTS_DIR}/antigravity-global.md"
}

@test "antigravity: does not contain mcp11_ tokens" {
    run ! grep -q "mcp11_" "${AGENTS_DIR}/antigravity-global.md"
}

# ---------------------------------------------------------------------------
# opencode-global.md
# ---------------------------------------------------------------------------

@test "opencode: has canonical tool invocation clause" {
    grep -q "Mentioning in prose is NOT invocation" "${AGENTS_DIR}/opencode-global.md"
}

@test "opencode: does not contain mcp11_ tokens" {
    run ! grep -q "mcp11_" "${AGENTS_DIR}/opencode-global.md"
}

# ---------------------------------------------------------------------------
# Universal baseline in all kernels
# ---------------------------------------------------------------------------

@test "all kernels have baseline skill: operating-protocol" {
    for f in "${AGENTS_DIR}"/*-global.md; do
        grep -q '`operating-protocol`' "$f" || {
            echo "MISSING in $f" >&2
            return 1
        }
    done
}

@test "all kernels have baseline skill: tool-usage" {
    for f in "${AGENTS_DIR}"/*-global.md; do
        grep -q '`tool-usage`' "$f" || {
            echo "MISSING in $f" >&2
            return 1
        }
    done
}

@test "all kernels have baseline skill: token-efficiency" {
    for f in "${AGENTS_DIR}"/*-global.md; do
        grep -q '`token-efficiency`' "$f" || {
            echo "MISSING in $f" >&2
            return 1
        }
    done
}

@test "all kernels have baseline skill: skill-router" {
    for f in "${AGENTS_DIR}"/*-global.md; do
        grep -q '`skill-router`' "$f" || {
            echo "MISSING in $f" >&2
            return 1
        }
    done
}

@test "all kernels have a MEMORY block" {
    for f in "${AGENTS_DIR}"/*-global.md; do
        grep -q "<MEMORY>" "$f" || {
            echo "MISSING in $f" >&2
            return 1
        }
    done
}

@test "no kernel uses old 'Non-trivial task → invoke operating-protocol' pattern" {
    for f in "${AGENTS_DIR}"/*-global.md; do
        if grep -qE "Non-trivial task.*invoke.*operating-protocol" "$f"; then
            echo "FOUND regressive text in $f" >&2
            return 1
        fi
    done
}

# ---------------------------------------------------------------------------
# operating-protocol SKILL.md
# ---------------------------------------------------------------------------

@test "operating-protocol SKILL.md does not reference mcp11_read_graph" {
    run ! grep -q "mcp11_read_graph" "${REPO_ROOT}/content/skills/operating-protocol/SKILL.md"
}

@test "operating-protocol SKILL.md does not reference create_memory" {
    run ! grep -q "Save to .create_memory" "${REPO_ROOT}/content/skills/operating-protocol/SKILL.md"
}

@test "operating-protocol SKILL.md memory section is agent-agnostic" {
    grep -q "kernel.*MEMORY" "${REPO_ROOT}/content/skills/operating-protocol/SKILL.md"
}
