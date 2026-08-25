#!/usr/bin/env bats
# shellcheck disable=SC2034,SC2016
# SC2016: single-quoted patterns are intentional (literal grep strings with backticks)
# =============================================================================
# Regression gates: boot-skill Step-Zero enforcement (ADR-0036).
# Fails on resurrected prohibition wording, blanket auto-injection claims,
# and stale boot-count literals anywhere under content/ or in AGENTS.md.
# Run: bats tests/test_boot_skill_step_zero.bats
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
CONTENT_DIR="${REPO_ROOT}/content"
AGENTS_MD="${REPO_ROOT}/AGENTS.md"
COHERENCE="${REPO_ROOT}/scripts/validate-kernel-skill-coherence.sh"
BUDGET="${REPO_ROOT}/scripts/validate-kernel-budget.sh"

bats_require_minimum_version 1.5.0

@test "gate: no boot-skill prohibition wording in content/" {
    run grep -rniE 'NEVER invoke via|never invoked via' "${CONTENT_DIR}"
    [ "$status" -eq 1 ]
}

@test "gate: legacy blanket auto-load sentences banned" {
    run grep -rnE 'are auto-loaded at session start|Auto-loaded at Session Start|auto-injected by agent harness|Boot skills are auto-loaded|auto-loaded via instructions' "${CONTENT_DIR}" "${AGENTS_MD}"
    [ "$status" -eq 1 ]
}

@test "gate: stale boot-count literals banned" {
    run grep -rnE 'load all 6 Skills Core|load all 6 Core skills|loading all 6 Core skills|loading 6 Core skills|MUST load 6 Core skills|invoke these 4 skills' "${CONTENT_DIR}" "${AGENTS_MD}"
    [ "$status" -eq 1 ]
}

@test "gate: skill-router mandates Step-Zero invocation of all 7" {
    grep -qF 'Boot Skills (MUST load ALL 7 at session start — mechanism per host kernel: native skill tool where available, otherwise read each SKILL.md)' "${CONTENT_DIR}/skills/skill-router/SKILL.md"
    grep -qF 'All 7 boot skills loaded at session start via host kernel mechanism, OR each body verified verbatim in context' "${CONTENT_DIR}/skills/skill-router/SKILL.md"
}

@test "gate: kernels carry the anti-waiver clause" {
    grep -qF 'absent body = invoke now' "${CONTENT_DIR}/rules/agents/opencode-global.md"
    grep -qF 'absent body = invoke now' "${CONTENT_DIR}/rules/agents/claude-code-global.md"
}

@test "gate: kernel GOVERN pre-flight requires all 7 boot skills" {
    local f
    for f in "${CONTENT_DIR}"/rules/agents/*-global.md; do
        grep -q 'Pre-flight (T2+): verify all 7 boot skills loaded' "$f" || {
            echo "MISSING in $f" >&2
            return 1
        }
    done
}

@test "gate: opencode hook lists all 7 boot skills" {
    local f="${CONTENT_DIR}/hooks/opencode/baseline-skills.sh"
    grep -q 'invoke ALL 7 boot skills RIGHT NOW' "$f"
    local s
    for s in operating-protocol governance engineering-standards context-management tool-usage token-efficiency skill-router; do
        grep -q "skill({name:\"${s}\"})" "$f" || {
            echo "MISSING ${s}" >&2
            return 1
        }
    done
}

@test "gate: coherence validator baseline list covers all 7 names" {
    local s
    for s in operating-protocol governance engineering-standards context-management tool-usage token-efficiency skill-router; do
        grep -qE "^    for skill in .*${s}" "${COHERENCE}" || {
            echo "MISSING ${s}" >&2
            return 1
        }
    done
}

@test "gate: coherence validator passes with extended list" {
    run bash "${COHERENCE}"
    [ "$status" -eq 0 ]
}

@test "gate: governance declares transitive boot-skill binding" {
    grep -qF 'Core-skill loading is TRANSITIVE' "${CONTENT_DIR}/skills/governance/SKILL.md"
}

@test "gate: kernel files stay within the 6000-byte budget" {
    run bash "${BUDGET}"
    [ "$status" -eq 0 ]
}
