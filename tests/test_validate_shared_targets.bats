#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2016,SC2034
# =============================================================================
# Tests for scripts/validate-shared-targets.sh (shared-dir invariant #11)
# =============================================================================
# Run: bats tests/test_validate_shared_targets.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    TEST_FIXTURES="${BATS_TEST_TMPDIR}/fixtures"
    mkdir -p "${TEST_FIXTURES}"
}

@test "gate passes on real manifests (shared_base + agent real dirs)" {
    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${REPO_ROOT}/manifest.yaml" "${REPO_ROOT}/manifest.example.yaml"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"PASS:"* ]]
}

@test "gate fails when top-level shared_base is missing" {
    cat >"${TEST_FIXTURES}/no-shared-base.yaml" <<'YAML'
version: "2.0"
agents:
  bad-agent:
    enabled: true
    targets:
      skills:
        path: "${HOME}/.codex/skills"
        format: directory
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/no-shared-base.yaml"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"missing top-level shared_base"* ]]
}

@test "gate fails when a directory target path points at the shared base" {
    cat >"${TEST_FIXTURES}/dir-points-at-shared.yaml" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  bad-agent:
    enabled: true
    targets:
      skills:
        path: "${HOME}/.config/agent-covenant/skills"
        format: directory
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/dir-points-at-shared.yaml"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"points at the shared base"* ]]
    [[ "$output" == *"bad-agent.targets.skills"* ]]
}

@test "gate skips file-level targets (per-agent paths allowed)" {
    cat >"${TEST_FIXTURES}/file-targets.yaml" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  file-agent:
    enabled: true
    targets:
      rules:
        path: "${HOME}/.codex/AGENTS.md"
        format: merged
      mcp:
        path: "${HOME}/.codex/config.toml"
        format: json
      workflows:
        path: "${HOME}/.gemini/antigravity/global_workflows"
        format: individual
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/file-targets.yaml"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"PASS:"* ]]
}

@test "gate rejects residual legacy keys (shared_dir, strip_frontmatter, transform_frontmatter)" {
    cat >"${TEST_FIXTURES}/residual-keys.yaml" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  bad-agent:
    enabled: true
    targets:
      subagents:
        path: "${HOME}/.codex/agents"
        shared_dir: "subagents-codex"
        strip_frontmatter: true
        transform_frontmatter: "opencode"
        format: individual
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/residual-keys.yaml"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"residual legacy key"* ]]
    [[ "$output" == *"shared_dir"* ]]
    [[ "$output" == *"strip_frontmatter"* ]]
    [[ "$output" == *"transform_frontmatter"* ]]
}

@test "gate fails when shared is not a boolean and transform is not in enum" {
    cat >"${TEST_FIXTURES}/bad-shared-transform.yaml" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  bad-agent:
    enabled: true
    targets:
      skills:
        path: "${HOME}/.claude/skills"
        format: directory
        shared: "maybe"
        transform: "UPPER"
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/bad-shared-transform.yaml"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"shared 'maybe' must be a boolean"* ]]
    [[ "$output" == *"transform 'UPPER' not in"* ]]
}

@test "gate fails when shared:false target has no path" {
    cat >"${TEST_FIXTURES}/shared-false-no-path.yaml" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  bad-agent:
    enabled: true
    targets:
      subagents:
        format: individual
        shared: false
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/shared-false-no-path.yaml"
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"shared:false requires a non-empty path"* ]]
}

@test "gate passes on shared:false targets with path and transform" {
    cat >"${TEST_FIXTURES}/shared-false-ok.yaml" <<'YAML'
version: "2.0"
shared_base: "${HOME}/.config/agent-covenant"
agents:
  claude-agent:
    enabled: true
    targets:
      skills:
        path: "${DETECTED_BASE}/skills"
        format: directory
        shared: false
      subagents:
        path: "${DETECTED_BASE}/agents"
        format: individual
        shared: false
        transform: strip
YAML

    run bash "${SCRIPT_DIR}/validate-shared-targets.sh" "${TEST_FIXTURES}/shared-false-ok.yaml"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"PASS:"* ]]
}
