#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2016,SC2034,SC2030,SC2031,SC2012
# =============================================================================
# Tests for shared-dir sync (write-once to shared base + manifest-derived symlinks)
# =============================================================================
# Run: bats tests/test_bootstrap_symlinks.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    FAKE_HOME="$(mktemp -d)"
    export HOME="${FAKE_HOME}"
    TEST_FIXTURES="${BATS_TEST_TMPDIR}/fixtures"
    mkdir -p "${TEST_FIXTURES}"

    # Source sync.sh (functions only; main is guarded). Uses fake HOME for ${HOME}.
    source "${SCRIPT_DIR}/sync.sh"
    SYNC_CACHE_DIR="${TEST_FIXTURES}/cache"
}

teardown() {
    rm -rf "${FAKE_HOME}"
}

@test "get_shared_write_path defaults shared_dir to target type" {
    MANIFEST_FILE="${TEST_FIXTURES}/m.yaml"
    cat >"${MANIFEST_FILE}" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  a:
    enabled: true
    targets:
      skills:
        path: "${HOME}/.codex/skills"
        format: directory
YAML
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run get_shared_write_path "skills" '{}'
    [[ "$status" -eq 0 ]]
    [[ "$output" == "${HOME}/.config/agent-covenant/skills" ]]
}

@test "get_shared_write_path appends transform suffix" {
    MANIFEST_FILE="${TEST_FIXTURES}/m.yaml"
    cat >"${MANIFEST_FILE}" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  a:
    enabled: true
    targets:
      subagents:
        path: "${HOME}/.config/opencode/agents"
        format: individual
        transform: opencode
YAML
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    local tcfg
    tcfg=$(jq -c '.agents.a.targets.subagents' <<<"${MANIFEST_JSON}")

    run get_shared_write_path "subagents" "${tcfg}"
    [[ "$status" -eq 0 ]]
    [[ "$output" == "${HOME}/.config/agent-covenant/subagents-opencode" ]]
}

@test "sync_directory_impl writes to the shared base, not the agent dir" {
    mkdir -p "${TEST_FIXTURES}/content/skills/test-skill/references"
    cat >"${TEST_FIXTURES}/content/skills/test-skill/SKILL.md" <<'MD'
---
name: test-skill
description: Shared write test
license: MIT
---
# Test Skill
MD
    echo "ref content" >"${TEST_FIXTURES}/content/skills/test-skill/references/checklist.md"

    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"
    DRY_RUN=false
    CREATE_BACKUP=false
    TIMESTAMP="2026-01-01 00:00:00"

    cat >"${MANIFEST_FILE}" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "\${HOME}/.config/agent-covenant"
skills:
  source_dir: "skills"
  directories:
    - test-skill
agents:
  codex-agent:
    enabled: true
    targets:
      skills:
        path: "\${HOME}/.codex/skills"
        format: directory
YAML
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    init_sync_registry
    sync_directory_impl "codex-agent" "skills" "skills" "$(jq -c '.agents."codex-agent".targets.skills' <<<"${MANIFEST_JSON}")"

    # Content lands in the shared base, not the per-agent dir.
    [[ -f "${HOME}/.config/agent-covenant/skills/test-skill/SKILL.md" ]]
    [[ -f "${HOME}/.config/agent-covenant/skills/test-skill/references/checklist.md" ]]
    [[ ! -d "${HOME}/.codex/skills" ]]
}

@test "bootstrap-symlinks.sh derives symlinks from the manifest" {
    mkdir -p "${HOME}/.codex/skills"
    echo "legacy" >"${HOME}/.codex/skills/legacy.md"

    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    cat >"${MANIFEST_FILE}" <<YAML
version: "2.0"
shared_base: "\${HOME}/.config/agent-covenant"
agents:
  codex-agent:
    enabled: true
    targets:
      skills:
        path: "\${HOME}/.codex/skills"
        format: directory
YAML

    run env MANIFEST_FILE="${MANIFEST_FILE}" bash "${SCRIPT_DIR}/bootstrap-symlinks.sh"
    [[ "$status" -eq 0 ]]

    [[ -L "${HOME}/.codex/skills" ]]
    [[ "$(readlink "${HOME}/.codex/skills")" == "${HOME}/.config/agent-covenant/skills" ]]

    # The legacy real dir was backed up, never deleted.
    local backup
    backup=$(ls -d "${HOME}"/.codex/skills.bak.* 2>/dev/null | head -1)
    [[ -n "${backup}" ]]
    [[ -f "${backup}/legacy.md" ]]
}

@test "bootstrap skips shared:false targets (keeps real dir untouched)" {
    mkdir -p "${HOME}/.claude/skills"
    echo "real" >"${HOME}/.claude/skills/keep.md"

    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    cat >"${MANIFEST_FILE}" <<YAML
version: "2.0"
shared_base: "\${HOME}/.config/agent-covenant"
agents:
  claude-agent:
    enabled: true
    targets:
      skills:
        path: "\${HOME}/.claude/skills"
        format: directory
        shared: false
YAML

    run env MANIFEST_FILE="${MANIFEST_FILE}" bash "${SCRIPT_DIR}/bootstrap-symlinks.sh"
    [[ "$status" -eq 0 ]]
    [[ -d "${HOME}/.claude/skills" ]]
    [[ ! -L "${HOME}/.claude/skills" ]]
    [[ -f "${HOME}/.claude/skills/keep.md" ]]
    [[ -z "$(ls -d "${HOME}"/.claude/skills.bak.* 2>/dev/null || true)" ]]
}

@test "bootstrap unlinks stale shared-base symlink for shared:false target" {
    mkdir -p "${HOME}/.config/agent-covenant/skills" "${HOME}/.claude"
    ln -s "${HOME}/.config/agent-covenant/skills" "${HOME}/.claude/skills"

    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    cat >"${MANIFEST_FILE}" <<YAML
version: "2.0"
shared_base: "\${HOME}/.config/agent-covenant"
agents:
  claude-agent:
    enabled: true
    targets:
      skills:
        path: "\${HOME}/.claude/skills"
        format: directory
        shared: false
YAML

    run env MANIFEST_FILE="${MANIFEST_FILE}" bash "${SCRIPT_DIR}/bootstrap-symlinks.sh"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"UNLINK"* ]]
    [[ ! -e "${HOME}/.claude/skills" ]]

    # Idempotent: second run exits 0, no UNLINK line.
    run env MANIFEST_FILE="${MANIFEST_FILE}" bash "${SCRIPT_DIR}/bootstrap-symlinks.sh"
    [[ "$status" -eq 0 ]]
    [[ "$output" != *"UNLINK"* ]]

    # --dry-run does not remove the symlink.
    ln -s "${HOME}/.config/agent-covenant/skills" "${HOME}/.claude/skills"
    run env MANIFEST_FILE="${MANIFEST_FILE}" bash "${SCRIPT_DIR}/bootstrap-symlinks.sh" --dry-run
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"UNLINK"* ]]
    [[ -L "${HOME}/.claude/skills" ]]
}
