#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2016,SC2034,SC2030,SC2031
# =============================================================================
# Tests for scripts/sync.sh functions
# =============================================================================
# Run: bats tests/test_sync.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    # Source real implementations (sync.sh sources common.sh internally)
    source "${SCRIPT_DIR}/sync.sh"

    TEST_FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
    mkdir -p "${TEST_FIXTURES}"

    # Override globals that sync.sh sets at source time
    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"
    DRY_RUN=false
    CREATE_BACKUP=false
    TIMESTAMP="2026-01-01 00:00:00"
    MANIFEST_JSON=""                        # populated after MANIFEST_FILE is written
    SYNC_CACHE_DIR="${TEST_FIXTURES}/cache" # isolated cache per test run

    # Create comprehensive test manifest
    cat >"${TEST_FIXTURES}/test-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - second-rule.md
workflows:
  source_dir: "workflows"
  files:
    - test-workflow.md
agents:
  enabled-agent:
    enabled: true
    description: "Enabled Test Agent"
    targets:
      rules:
        path: "${HOME}/.test-agent/rules.md"
        format: merged
        strip_frontmatter: true
        header: |
          # Rules - Generated {{timestamp}}
  disabled-agent:
    enabled: false
    description: "Disabled Test Agent"
    targets:
      rules:
        path: "${HOME}/.disabled-agent/rules.md"
        format: merged
  detected-agent:
    enabled: true
    description: "Detected Agent"
    detect:
      paths:
        - "/nonexistent/path/that/will/never/exist"
      commands:
        - "nonexistent_binary_xyz_12345"
    targets:
      rules:
        path: "${HOME}/.detected/rules.md"
        format: merged
  individual-agent:
    enabled: true
    description: "Individual Agent"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${HOME}/.individual-agent/rules"
        format: individual
        strip_frontmatter: true
        output_extension: ".md"
  transform-agent:
    enabled: true
    description: "Transform Agent"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${HOME}/.transform-agent/rules"
        format: individual
        strip_frontmatter: false
        transform_frontmatter: true
        output_extension: ".mdc"
        header: |
          ---
          name: {{name}}
          generated: {{timestamp}}
          ---
  multi-target-agent:
    enabled: true
    description: "Multi Target Agent"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${HOME}/.multi/rules.md"
        format: merged
        strip_frontmatter: true
        source_type: "rules"
      workflows:
        path: "${HOME}/.multi/workflows.md"
        format: merged
        strip_frontmatter: true
        source_type: "workflows"
YAML

    # Create test content — rules
    mkdir -p "${TEST_FIXTURES}/content/rules"
    cat >"${TEST_FIXTURES}/content/rules/test-rule.md" <<'MD'
---
trigger: always
---

# Test Rule

This is a test rule.
MD

    cat >"${TEST_FIXTURES}/content/rules/second-rule.md" <<'MD'
---
trigger: manual
---

# Second Rule

This is the second rule.
MD

    # Create test content — workflows
    mkdir -p "${TEST_FIXTURES}/content/workflows"
    cat >"${TEST_FIXTURES}/content/workflows/test-workflow.md" <<'MD'
---
description: Test workflow
---

# Test Workflow

Workflow content.
MD

    # Initialize MANIFEST_JSON from the base manifest so all tests have it
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
}

# Helper: extract a JSON object from MANIFEST_FILE at the given jq path.
# Used by tests that call _impl functions directly.
# Usage: _cfg ".agents.foo.targets.bar"
_cfg() {
    [[ -z "${MANIFEST_JSON}" ]] && MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    jq -r "${1}" <<<"${MANIFEST_JSON}"
}

teardown() {
    rm -rf "${TEST_FIXTURES}"
}

# =============================================================================
# parse_args tests
# =============================================================================

@test "parse_args rejects --agent without value" {
    run parse_args --agent
    [[ "$status" -ne 0 ]]
}

@test "parse_args sets SPECIFIC_AGENT" {
    SPECIFIC_AGENT=""
    parse_args --agent claude_code
    [[ "${SPECIFIC_AGENT}" == "claude_code" ]]
}

@test "parse_args sets DRY_RUN" {
    DRY_RUN=false
    parse_args --dry-run
    [[ "${DRY_RUN}" == "true" ]]
}

@test "parse_args sets CREATE_BACKUP" {
    CREATE_BACKUP=false
    parse_args --backup
    [[ "${CREATE_BACKUP}" == "true" ]]
}

@test "parse_args sets VALIDATE_FIRST" {
    VALIDATE_FIRST=false
    parse_args --validate
    [[ "${VALIDATE_FIRST}" == "true" ]]
}

@test "parse_args sets DEBUG" {
    parse_args --debug
    [[ "${DEBUG}" == "true" ]]
}

@test "parse_args rejects unknown option" {
    run parse_args --unknown-flag
    [[ "$status" -ne 0 ]]
}

# =============================================================================
# Agent name validation
# =============================================================================

@test "valid agent names are accepted" {
    for name in "claude_code" "test-123"; do
        [[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]
    done
}

@test "invalid agent names are rejected" {
    for name in "agent;rm" 'agent$(cmd)' "agent name" "agent/path"; do
        ! [[ "${name}" =~ ^[a-zA-Z0-9_-]+$ ]]
    done
}

# =============================================================================
# check_dependencies tests
# =============================================================================

@test "check_dependencies succeeds when yq is installed" {
    run check_dependencies
    [[ "$status" -eq 0 ]]
}

# =============================================================================
# is_agent_enabled tests
# =============================================================================

@test "is_agent_enabled returns true for enabled agent" {
    is_agent_enabled "enabled-agent"
}

@test "is_agent_enabled returns false for disabled agent" {
    run ! is_agent_enabled "disabled-agent"
    [[ "$status" -ne 0 ]]
}

@test "is_agent_enabled returns false for nonexistent agent" {
    run ! is_agent_enabled "nonexistent-agent"
    [[ "$status" -ne 0 ]]
}

# =============================================================================
# is_agent_installed tests
# =============================================================================

@test "is_agent_installed returns true when no detect config" {
    # enabled-agent has no detect section → assumed installed
    is_agent_installed "enabled-agent"
}

@test "is_agent_installed returns false when nothing detected" {
    # detected-agent has nonexistent paths and commands
    run ! is_agent_installed "detected-agent"
    [[ "$status" -ne 0 ]]
}

@test "is_agent_installed returns true when path exists" {
    # individual-agent detects /tmp which always exists
    is_agent_installed "individual-agent"
}

# =============================================================================
# get_source_files tests
# =============================================================================

@test "get_source_files resolves rules files from manifest" {
    result=$(get_source_files "rules")
    [[ "$result" == *"test-rule.md"* ]]
    [[ "$result" == *"second-rule.md"* ]]
}

@test "get_source_files resolves workflow files from manifest" {
    result=$(get_source_files "workflows")
    [[ "$result" == *"test-workflow.md"* ]]
}

@test "get_source_files warns about missing files" {
    # Add a nonexistent file to manifest
    cat >"${TEST_FIXTURES}/bad-manifest.yaml" <<'YAML'
rules:
  source_dir: "rules"
  files:
    - nonexistent.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    run get_source_files "rules"
    [[ "$output" == *"File not found"* ]]
}

# =============================================================================
# get_target_paths tests
# =============================================================================

@test "get_target_paths resolves single path" {
    local result
    result=$(get_target_paths "$(_cfg '.agents."enabled-agent".targets.rules')")
    [[ "$result" == "${HOME}/.test-agent/rules.md" ]]
}

@test "get_target_paths returns empty for nonexistent target" {
    local result
    result=$(get_target_paths "$(_cfg '.agents."enabled-agent".targets.nonexistent')" || true)
    [[ -z "$result" ]]
}

# =============================================================================
# Content change detection (using real write_sync_file)
# =============================================================================

@test "write_sync_file skips unchanged content" {
    local target="${TEST_FIXTURES}/output/unchanged.md"
    mkdir -p "$(dirname "${target}")"
    printf '%s\n' "same content" >"${target}"

    run write_sync_file "${target}" "same content"
    [[ "$status" -eq 0 ]]
    [[ "$(cat "${target}")" == "same content" ]]
}

@test "write_sync_file writes changed content" {
    local target="${TEST_FIXTURES}/output/changed.md"
    mkdir -p "$(dirname "${target}")"
    printf '%s\n' "old content" >"${target}"

    write_sync_file "${target}" "new content"
    [[ "$(cat "${target}")" == "new content" ]]
}

@test "write_sync_file creates new file" {
    local target="${TEST_FIXTURES}/output/new_file.md"

    write_sync_file "${target}" "brand new"
    [[ -f "${target}" ]]
    [[ "$(cat "${target}")" == "brand new" ]]
}

@test "write_sync_file dry-run does not write" {
    local target="${TEST_FIXTURES}/output/dry.md"
    DRY_RUN=true

    run write_sync_file "${target}" "dry content"
    [[ "$status" -eq 0 ]]
    [[ ! -f "${target}" ]]
    [[ "$output" == *"DRY-RUN"* ]]
}

@test "write_sync_file creates backup when enabled" {
    local target="${TEST_FIXTURES}/output/backup_test.md"
    mkdir -p "$(dirname "${target}")"
    printf '%s\n' "old" >"${target}"
    CREATE_BACKUP=true

    write_sync_file "${target}" "new"

    local backup_base="${XDG_STATE_HOME:-${HOME}/.local/state}/agent-covenant/backups"
    local backup_count
    backup_count=$(find "${backup_base}" -name "backup_test.md.*.bak" -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$backup_count" -ge 1 ]]
}

# =============================================================================
# transform_file_frontmatter tests
# =============================================================================

@test "transform_file_frontmatter replaces frontmatter with template" {
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    local result
    result=$(transform_file_frontmatter \
        "${TEST_FIXTURES}/content/rules/test-rule.md" \
        "transform-agent" \
        "$(_cfg '.agents."transform-agent".targets.rules')")

    # Should contain template-generated frontmatter
    [[ "$result" == *"name: test-rule"* ]]
    [[ "$result" == *"generated: ${TIMESTAMP}"* ]]
    # Should contain body content
    [[ "$result" == *"# Test Rule"* ]]
    [[ "$result" == *"This is a test rule."* ]]
    # Should NOT contain original frontmatter
    [[ "$result" != *"trigger: always"* ]]
}

# =============================================================================
# sync_merged_impl tests
# =============================================================================

@test "sync_merged_impl creates merged file with header" {
    local target_dir="${TEST_FIXTURES}/output/merged"
    mkdir -p "${target_dir}"

    # Override target path to writable fixture dir
    cat >"${TEST_FIXTURES}/merge-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - second-rule.md
agents:
  merge-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/merged-rules.md"
        format: merged
        strip_frontmatter: true
        header: "# Header {{timestamp}}"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/merge-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_merged_impl "merge-test" "rules" "rules" "$(_cfg '.agents."merge-test".targets.rules')"

    [[ -f "${target_dir}/merged-rules.md" ]]
    local content
    content=$(cat "${target_dir}/merged-rules.md")
    # Header with timestamp
    [[ "$content" == *"# Header ${TIMESTAMP}"* ]]
    # Both rules present
    [[ "$content" == *"# Test Rule"* ]]
    [[ "$content" == *"# Second Rule"* ]]
    # Frontmatter stripped
    [[ "$content" != *"trigger:"* ]]
    # Separator between files
    [[ "$content" == *"---"* ]]
}

@test "sync_merged_impl to directory creates default rules.md" {
    local target_dir="${TEST_FIXTURES}/output/dir-merge"
    mkdir -p "${target_dir}/dest"

    cat >"${TEST_FIXTURES}/dir-merge-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  dir-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/dest"
        format: merged
        strip_frontmatter: true
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/dir-merge-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_merged_impl "dir-test" "rules" "rules" "$(_cfg '.agents."dir-test".targets.rules')"

    [[ -f "${target_dir}/dest/rules.md" ]]
}

# =============================================================================
# sync_individual_impl tests
# =============================================================================

@test "sync_individual_impl creates individual files" {
    local target_dir="${TEST_FIXTURES}/output/individual"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/indiv-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - second-rule.md
agents:
  indiv-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}"
        format: individual
        strip_frontmatter: true
        output_extension: ".md"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/indiv-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_individual_impl "indiv-test" "rules" "rules" "$(_cfg '.agents."indiv-test".targets.rules')"

    [[ -f "${target_dir}/test-rule.md" ]]
    [[ -f "${target_dir}/second-rule.md" ]]
    # Frontmatter stripped
    local content
    content=$(cat "${target_dir}/test-rule.md")
    [[ "$content" != *"trigger:"* ]]
    [[ "$content" == *"# Test Rule"* ]]
}

@test "sync_individual_impl with transform creates transformed files" {
    local target_dir="${TEST_FIXTURES}/output/transform"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/transform-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  xform-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}"
        format: individual
        strip_frontmatter: false
        transform_frontmatter: true
        output_extension: ".mdc"
        header: |
          ---
          name: {{name}}
          ---
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/transform-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_individual_impl "xform-test" "rules" "rules" "$(_cfg '.agents."xform-test".targets.rules')"

    [[ -f "${target_dir}/test-rule.mdc" ]]
    local content
    content=$(cat "${target_dir}/test-rule.mdc")
    [[ "$content" == *"name: test-rule"* ]]
}

# =============================================================================
# sync_target tests
# =============================================================================

@test "sync_target dispatches merged format" {
    local target_dir="${TEST_FIXTURES}/output/sync-target"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/st-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  st-agent:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/rules.md"
        format: merged
        strip_frontmatter: true
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/st-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    sync_target "st-agent" "rules" "rules"
    [[ -f "${target_dir}/rules.md" ]]
}

@test "sync_target skips nonexistent target config" {
    run sync_target "enabled-agent" "nonexistent" "nonexistent"
    [[ "$status" -eq 0 ]]
}

@test "sync_target rejects unknown format" {
    cat >"${TEST_FIXTURES}/bad-format-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  bad-agent:
    enabled: true
    targets:
      rules:
        path: "/tmp/bad"
        format: unknown_format
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-format-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    run sync_target "bad-agent" "rules" "rules"
    [[ "$status" -ne 0 ]]
    [[ "$output" == *"Unknown format"* ]]
}

# =============================================================================
# sync_agent tests
# =============================================================================

@test "sync_agent skips disabled agent" {
    run sync_agent "disabled-agent"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"disabled"* ]]
}

@test "sync_agent skips uninstalled agent" {
    DEBUG=true
    run sync_agent "detected-agent"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"not installed"* ]]
}

@test "sync_agent syncs enabled and installed agent" {
    local target_dir="${TEST_FIXTURES}/output/sync-agent"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/sa-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  sa-test:
    enabled: true
    description: "Sync Agent Test"
    detect:
      paths:
        - "/tmp"
      commands: []
    targets:
      rules:
        path: "${target_dir}/rules.md"
        format: merged
        strip_frontmatter: true
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/sa-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run sync_agent "sa-test"
    [[ "$status" -eq 0 ]]
    [[ -f "${target_dir}/rules.md" ]]
}

@test "sync_agent warns when no targets configured" {
    cat >"${TEST_FIXTURES}/no-targets-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  empty-agent:
    enabled: true
    description: "Empty"
    detect:
      paths:
        - "/tmp"
      commands: []
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-targets-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run sync_agent "empty-agent"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"No targets"* ]]
}

# =============================================================================
# sync_directory_impl tests
# =============================================================================

@test "sync_directory_impl copies skill directories" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    local skill_src="${TEST_FIXTURES}/content/skills/test-skill"
    mkdir -p "${target_dir}" "${skill_src}/references"

    # Create SKILL.md and a reference file
    cat >"${skill_src}/SKILL.md" <<'MD'
---
name: test-skill
description: Skill de prueba
license: MIT
---

# Test Skill

Contenido del skill.
MD
    echo "ref content" >"${skill_src}/references/checklist.md"

    cat >"${TEST_FIXTURES}/skill-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  source_dir: "skills"
  directories:
    - test-skill
agents:
  skill-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/skill-manifest.yaml"
    init_sync_registry

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_directory_impl "skill-agent" "skills" "skills" "$(_cfg '.agents."skill-agent".targets.skills')"

    # Verify SKILL.md was copied
    [[ -f "${target_dir}/test-skill/SKILL.md" ]]
    # Verify subdirectories were copied
    [[ -f "${target_dir}/test-skill/references/checklist.md" ]]
    # Verify content
    [[ "$(cat "${target_dir}/test-skill/references/checklist.md")" == "ref content" ]]
}

@test "sync_directory_impl skips directory without SKILL.md" {
    local target_dir="${TEST_FIXTURES}/output/skills-no-md"
    local skill_src="${TEST_FIXTURES}/content/skills/bad-skill"
    mkdir -p "${target_dir}" "${skill_src}"

    # Directory without SKILL.md
    echo "no skill" >"${skill_src}/readme.txt"

    cat >"${TEST_FIXTURES}/no-skill-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - bad-skill
agents:
  ns-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-skill-manifest.yaml"
    init_sync_registry

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    run sync_directory_impl "ns-agent" "skills" "skills" "$(_cfg '.agents."ns-agent".targets.skills')"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"SKILL.md not found"* ]]
    # Must not create target directory
    [[ ! -d "${target_dir}/bad-skill" ]]
}

@test "sync_directory_impl detects unchanged content" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    local skill_src="${TEST_FIXTURES}/content/skills/unchanged-skill"
    mkdir -p "${target_dir}/unchanged-skill" "${skill_src}"

    cat >"${skill_src}/SKILL.md" <<'MD'
---
name: unchanged-skill
description: Sin cambios
license: MIT
---

# Unchanged
MD
    # Copy the same content to target
    cp "${skill_src}/SKILL.md" "${target_dir}/unchanged-skill/SKILL.md"

    cat >"${TEST_FIXTURES}/unchanged-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  source_dir: "skills"
  directories:
    - unchanged-skill
agents:
  uc-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/unchanged-manifest.yaml"
    init_sync_registry
    DEBUG=true

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    run sync_directory_impl "uc-agent" "skills" "skills" "$(_cfg '.agents."uc-agent".targets.skills')"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Unchanged"* ]]
}

# =============================================================================
# cleanup_stale_files y save_sync_registry tests
# =============================================================================

@test "cleanup_stale_files elimina archivos que ya no se sincronizan" {
    local stale_file="${TEST_FIXTURES}/output/stale.md"
    local kept_file="${TEST_FIXTURES}/output/kept.md"
    mkdir -p "$(dirname "${stale_file}")"
    echo "stale" >"${stale_file}"
    echo "kept" >"${kept_file}"

    # Simulate previous registry with both files
    mkdir -p "${SYNC_REGISTRY_DIR}"
    printf '%s\n' "${stale_file}" "${kept_file}" >"${SYNC_REGISTRY}"

    # Initialize new registry with only kept_file
    init_sync_registry
    register_managed_file "${kept_file}"

    cleanup_stale_files

    # stale_file must have been removed
    [[ ! -f "${stale_file}" ]]
    # kept_file must still exist
    [[ -f "${kept_file}" ]]
}

@test "cleanup_stale_files no elimina en dry-run" {
    local stale_file="${TEST_FIXTURES}/output/stale-dry.md"
    mkdir -p "$(dirname "${stale_file}")"
    echo "stale" >"${stale_file}"

    mkdir -p "${SYNC_REGISTRY_DIR}"
    printf '%s\n' "${stale_file}" >"${SYNC_REGISTRY}"

    init_sync_registry
    DRY_RUN=true

    run cleanup_stale_files
    [[ "$status" -eq 0 ]]
    # File must still exist in dry-run
    [[ -f "${stale_file}" ]]
    [[ "$output" == *"DRY-RUN"* ]]
}

@test "save_sync_registry guarda archivo ordenado y sin duplicados" {
    init_sync_registry
    register_managed_file "/z/file.md"
    register_managed_file "/a/file.md"
    register_managed_file "/z/file.md"

    save_sync_registry

    [[ -f "${SYNC_REGISTRY}" ]]
    local count
    count=$(wc -l <"${SYNC_REGISTRY}" | tr -d ' ')
    [[ "$count" -eq 2 ]]
    # Verify order
    local first_line
    first_line=$(head -1 "${SYNC_REGISTRY}")
    [[ "$first_line" == "/a/file.md" ]]
}

@test "save_sync_registry no guarda en dry-run" {
    DRY_RUN=true
    init_sync_registry
    register_managed_file "/tmp/test.md"

    save_sync_registry

    # Must not exist or must not contain new data
    if [[ -f "${SYNC_REGISTRY}" ]]; then
        ! grep -q "/tmp/test.md" "${SYNC_REGISTRY}"
    fi
}

@test "cleanup_stale_files no falla sin registry previo" {
    # Remove registry if it exists
    rm -f "${SYNC_REGISTRY}"
    init_sync_registry

    run cleanup_stale_files
    [[ "$status" -eq 0 ]]
}

# =============================================================================
# list_agents tests
# =============================================================================

@test "list_agents shows all agents with status" {
    run list_agents
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"enabled-agent"* ]]
    [[ "$output" == *"disabled-agent"* ]]
    [[ "$output" == *"enabled"* ]]
    [[ "$output" == *"disabled"* ]]
}

# =============================================================================
# register_managed_file edge cases
# =============================================================================

@test "register_managed_file does nothing when registry not initialized" {
    local old_reg="${_SYNC_REGISTRY_NEW}"
    _SYNC_REGISTRY_NEW=""
    register_managed_file "/some/file.md"
    # Should not fail
    _SYNC_REGISTRY_NEW="${old_reg}"
}

# =============================================================================
# save_sync_registry edge cases
# =============================================================================

@test "save_sync_registry does nothing when registry not initialized" {
    local old_reg="${_SYNC_REGISTRY_NEW}"
    _SYNC_REGISTRY_NEW=""
    save_sync_registry
    # Should not fail
    _SYNC_REGISTRY_NEW="${old_reg}"
}

# =============================================================================
# get_source_skill_dirs tests
# =============================================================================

@test "get_source_skill_dirs returns existing skill directories" {
    local skill_dir="${TEST_FIXTURES}/content/skills/my-skill"
    mkdir -p "${skill_dir}"

    cat >"${TEST_FIXTURES}/skill-dirs-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - my-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/skill-dirs-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    local result
    result=$(get_source_skill_dirs)
    [[ "$result" == *"my-skill"* ]]
}

@test "get_source_skill_dirs warns about missing directories" {
    cat >"${TEST_FIXTURES}/missing-skill-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - nonexistent-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-skill-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run get_source_skill_dirs
    [[ "$output" == *"Skill directory not found"* ]]
}

# =============================================================================
# get_target_paths additional tests
# =============================================================================

@test "get_target_paths resolves multiple paths" {
    cat >"${TEST_FIXTURES}/multi-path-manifest.yaml" <<YAML
agents:
  mp-agent:
    targets:
      rules:
        paths:
          - "/tmp/path-a"
          - "/tmp/path-b"
        format: merged
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/multi-path-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    local result
    result=$(get_target_paths "$(_cfg '.agents."mp-agent".targets.rules')")
    [[ "$result" == *"/tmp/path-a"* ]]
    [[ "$result" == *"/tmp/path-b"* ]]
}

@test "get_target_paths resolves glob paths" {
    local gdir="${TEST_FIXTURES}/glob-test"
    mkdir -p "${gdir}/dir-a" "${gdir}/dir-b"

    # Write manifest with printf to prevent shell glob expansion of *
    printf 'agents:\n  glob-agent:\n    targets:\n      rules:\n        glob_paths:\n          - "%s/dir-*"\n        format: merged\n' "${gdir}" >"${TEST_FIXTURES}/glob-manifest.yaml"
    MANIFEST_FILE="${TEST_FIXTURES}/glob-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    local result
    result=$(get_target_paths "$(_cfg '.agents."glob-agent".targets.rules')")
    [[ "$result" == *"dir-a"* ]]
    [[ "$result" == *"dir-b"* ]]
}

@test "get_target_paths handles non-matching glob" {
    printf 'agents:\n  ng-agent:\n    targets:\n      rules:\n        glob_paths:\n          - "/nonexistent/path-*"\n        format: merged\n' >"${TEST_FIXTURES}/noglob-manifest.yaml"
    MANIFEST_FILE="${TEST_FIXTURES}/noglob-manifest.yaml"

    local result
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    result=$(get_target_paths "$(_cfg '.agents."ng-agent".targets.rules')")
    [[ -z "$result" ]]
}

# =============================================================================
# sync_merged_impl additional tests
# =============================================================================

@test "sync_merged_impl preserves frontmatter when strip is false" {
    local target_dir="${TEST_FIXTURES}/output/merged-nostrip"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/nostrip-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  nostrip-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/rules.md"
        format: merged
        strip_frontmatter: false
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/nostrip-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_merged_impl "nostrip-test" "rules" "rules" "$(_cfg '.agents."nostrip-test".targets.rules')"

    local content
    content=$(cat "${target_dir}/rules.md")
    # Frontmatter should be preserved
    [[ "$content" == *"trigger: always"* ]]
    [[ "$content" == *"# Test Rule"* ]]
}

@test "sync_merged_impl uses output_filename when specified" {
    local target_dir="${TEST_FIXTURES}/output/merged-custom-name"
    mkdir -p "${target_dir}/dest"

    cat >"${TEST_FIXTURES}/custom-name-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  cn-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}/dest"
        format: merged
        strip_frontmatter: true
        output_filename: "custom-rules.md"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/custom-name-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_merged_impl "cn-test" "rules" "rules" "$(_cfg '.agents."cn-test".targets.rules')"

    [[ -f "${target_dir}/dest/custom-rules.md" ]]
    [[ ! -f "${target_dir}/dest/rules.md" ]]
}

@test "sync_merged_impl warns and skips when no source files resolved" {
    local target_dir="${TEST_FIXTURES}/output/merged-no-sources"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/no-src-manifest.yaml" <<YAML
version: "2.0"
agents:
  ns-test:
    enabled: true
    targets:
      unknown_target:
        path: "${target_dir}/out.md"
        format: merged
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-src-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run sync_merged_impl "ns-test" "unknown_target" "unknown_type" "$(_cfg '.agents."ns-test".targets.unknown_target')"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"No source files resolved"* ]]
}
@test "sync_individual_impl copies raw content when no strip or transform" {
    local target_dir="${TEST_FIXTURES}/output/individual-raw"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/raw-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  raw-test:
    enabled: true
    targets:
      rules:
        path: "${target_dir}"
        format: individual
        strip_frontmatter: false
        transform_frontmatter: false
        output_extension: ".md"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/raw-manifest.yaml"

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_individual_impl "raw-test" "rules" "rules" "$(_cfg '.agents."raw-test".targets.rules')"

    [[ -f "${target_dir}/test-rule.md" ]]
    local content
    content=$(cat "${target_dir}/test-rule.md")
    # Frontmatter should be preserved (raw copy)
    [[ "$content" == *"trigger: always"* ]]
    [[ "$content" == *"# Test Rule"* ]]
}

# =============================================================================
# sync_directory_impl additional tests
# =============================================================================

@test "sync_directory_impl dry-run does not copy files" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    local skill_src="${TEST_FIXTURES}/content/skills/dry-skill"
    mkdir -p "${target_dir}" "${skill_src}"
    cat >"${skill_src}/SKILL.md" <<'MD'
---
name: dry-skill
description: Dry run test
license: MIT
---
# Dry Skill
MD

    cat >"${TEST_FIXTURES}/dry-skill-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  source_dir: "skills"
  directories:
    - dry-skill
agents:
  dry-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/dry-skill-manifest.yaml"
    init_sync_registry
    DRY_RUN=true
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    run sync_directory_impl "dry-agent" "skills" "skills" "$(_cfg '.agents."dry-agent".targets.skills')"
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"DRY-RUN"* ]]
    # Directory should not be created
    [[ ! -d "${target_dir}/dry-skill" ]]
}

@test "sync_directory_impl creates backup when enabled" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    local skill_src="${TEST_FIXTURES}/content/skills/bk-skill"
    mkdir -p "${target_dir}/bk-skill" "${skill_src}"

    cat >"${skill_src}/SKILL.md" <<'MD'
---
name: bk-skill
description: Backup test
license: MIT
---
# New content
MD

    # Pre-populate target with different content
    echo "old content" >"${target_dir}/bk-skill/SKILL.md"

    cat >"${TEST_FIXTURES}/bk-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  source_dir: "skills"
  directories:
    - bk-skill
agents:
  bk-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bk-manifest.yaml"
    init_sync_registry
    CREATE_BACKUP=true
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    XDG_STATE_HOME="${TEST_FIXTURES}/state"
    sync_directory_impl "bk-agent" "skills" "skills" "$(_cfg '.agents."bk-agent".targets.skills')"

    # New content should be written
    [[ -f "${target_dir}/bk-skill/SKILL.md" ]]
    [[ "$(cat "${target_dir}/bk-skill/SKILL.md")" == *"New content"* ]]
    # Backup should exist
    local backup_count
    backup_count=$(find "${TEST_FIXTURES}/state/agent-covenant/backups" -name "SKILL.md.*.bak" -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$backup_count" -ge 1 ]]
}

# =============================================================================
# _prune_stale_skill_dirs tests
# =============================================================================

@test "_prune_stale_skill_dirs removes non-empty stale skill directory" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    mkdir -p "${target_dir}/active-skill" "${target_dir}/retired-skill/subdir"
    echo "active" >"${target_dir}/active-skill/SKILL.md"
    echo "retired" >"${target_dir}/retired-skill/SKILL.md"
    echo "extra" >"${target_dir}/retired-skill/subdir/file.md"

    cat >"${TEST_FIXTURES}/prune-stale-manifest.yaml" <<YAML
version: "2.0"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  directories:
    - active-skill
agents:
  ps-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/prune-stale-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    _prune_stale_skill_dirs

    [[ -d "${target_dir}/active-skill" ]]
    [[ ! -d "${target_dir}/retired-skill" ]]
}

@test "_prune_stale_skill_dirs keeps valid skill directories intact" {
    local target_dir="${TEST_FIXTURES}/output/skills-prune-valid"
    mkdir -p "${target_dir}/skill-a" "${target_dir}/skill-b"
    echo "a" >"${target_dir}/skill-a/SKILL.md"
    echo "b" >"${target_dir}/skill-b/SKILL.md"

    cat >"${TEST_FIXTURES}/prune-valid-manifest.yaml" <<YAML
version: "2.0"
skills:
  directories:
    - skill-a
    - skill-b
agents:
  pv-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/prune-valid-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    _prune_stale_skill_dirs

    [[ -d "${target_dir}/skill-a" ]]
    [[ -d "${target_dir}/skill-b" ]]
}

@test "_prune_stale_skill_dirs handles no stale dirs gracefully" {
    local target_dir="${TEST_FIXTURES}/output/skills-prune-none"
    mkdir -p "${target_dir}/my-skill"
    echo "ok" >"${target_dir}/my-skill/SKILL.md"

    cat >"${TEST_FIXTURES}/prune-none-manifest.yaml" <<YAML
version: "2.0"
skills:
  directories:
    - my-skill
agents:
  pn-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/prune-none-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run _prune_stale_skill_dirs
    [[ "$status" -eq 0 ]]
    [[ -d "${target_dir}/my-skill" ]]
}

@test "_prune_stale_skill_dirs dry-run does not delete" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    mkdir -p "${target_dir}/stale-skill"
    echo "stale" >"${target_dir}/stale-skill/SKILL.md"

    cat >"${TEST_FIXTURES}/prune-dry-manifest.yaml" <<YAML
version: "2.0"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  directories:
    - other-skill
agents:
  pd-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/prune-dry-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    DRY_RUN=true
    run _prune_stale_skill_dirs
    [[ "$status" -eq 0 ]]
    [[ -d "${target_dir}/stale-skill" ]]
    [[ "$output" == *"DRY-RUN"* ]]
    DRY_RUN=false
}

# =============================================================================
# sync_json_impl array command resolution tests (opencode format)
# =============================================================================

@test "sync_json_impl resolves first element of array command (opencode format)" {
    local target_path="${TEST_FIXTURES}/output/mcp-array.json"
    local mcp_src="${CONTENT_DIR}/mcp/mcp-test.json"
    mkdir -p "$(dirname "${target_path}")" "$(dirname "${mcp_src}")"
    rm -f "${target_path}"

    printf '{"mcp":{"test-srv":{"type":"local","command":["bash","-c","echo hi"],"enabled":true}}}' >"${mcp_src}"

    cat >"${TEST_FIXTURES}/mcp-array-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
mcp:
  file: "mcp-test.json"
  source_dir: "mcp"
agents:
  ma-test:
    enabled: true
    targets:
      mcp:
        path: "${target_path}"
        format: json
        merge_key: "mcp"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/mcp-array-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run sync_json_impl "ma-test" "mcp" "$(_cfg '.agents."ma-test".targets.mcp')"
    [[ "$status" -eq 0 ]]
    [[ -f "${target_path}" ]]

    local resolved_cmd
    resolved_cmd=$(jq -r '.mcp."test-srv".command[0] // ""' "${target_path}")
    echo "Resolved command[0]: ${resolved_cmd}" >&2
    [[ "${resolved_cmd}" == /bin/* ]] || [[ "${resolved_cmd}" == /usr/* ]] || [[ "${resolved_cmd}" == /opt/* ]] || [[ "${resolved_cmd}" == "bash" ]]
}

@test "sync_json_impl resolves array commands under mcp container key (opencode)" {
    local target_path="${TEST_FIXTURES}/output/mcp-opencode.json"
    local mcp_src="${CONTENT_DIR}/mcp/mcp-test.json"
    mkdir -p "$(dirname "${target_path}")" "$(dirname "${mcp_src}")"
    rm -f "${target_path}"

    printf '{"mcp":{"fetch":{"type":"local","command":["uvx","mcp-server-fetch"],"enabled":true},"time":{"type":"local","command":["uvx","mcp-server-time"],"enabled":true}}}' >"${mcp_src}"

    cat >"${TEST_FIXTURES}/mcp-opencode-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
mcp:
  file: "mcp-test.json"
  source_dir: "mcp"
agents:
  mo-test:
    enabled: true
    targets:
      mcp:
        path: "${target_path}"
        format: json
        merge_key: "mcp"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/mcp-opencode-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run sync_json_impl "mo-test" "mcp" "$(_cfg '.agents."mo-test".targets.mcp')"
    [[ "$status" -eq 0 ]]
    [[ -f "${target_path}" ]]

    jq -e '.mcp.fetch.command[0] | length > 0' "${target_path}" >/dev/null
    jq -e '.mcp.time.command[0] | length > 0' "${target_path}" >/dev/null
}

@test "sync_json_impl resolves both mcpServers and mcp container keys" {
    local target_path="${TEST_FIXTURES}/output/mcp-dual.json"
    local mcp_src="${CONTENT_DIR}/mcp/mcp-test.json"
    mkdir -p "$(dirname "${target_path}")" "$(dirname "${mcp_src}")"
    rm -f "${target_path}"

    # Create both formats in one source file
    printf '{"mcpServers":{"standard":{"command":"bash","args":[]}},"mcp":{"opencode":{"type":"local","command":["bash"],"enabled":true}}}' >"${mcp_src}"

    cat >"${TEST_FIXTURES}/mcp-dual-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
mcp:
  file: "mcp-test.json"
  source_dir: "mcp"
agents:
  md-test:
    enabled: true
    targets:
      mcp:
        path: "${target_path}"
        format: json
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/mcp-dual-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    run sync_json_impl "md-test" "mcp" "$(_cfg '.agents."md-test".targets.mcp')"
    [[ "$status" -eq 0 ]]

    jq -e '.mcpServers.standard.command == "bash"' "${target_path}" >/dev/null
    jq -e '.mcp.opencode.command[0] == "bash"' "${target_path}" >/dev/null
}

# =============================================================================
# sync_target additional dispatch tests
# =============================================================================

@test "sync_target dispatches individual format" {
    local target_dir="${TEST_FIXTURES}/output/st-individual"
    mkdir -p "${target_dir}"

    cat >"${TEST_FIXTURES}/st-indiv-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
agents:
  sti-agent:
    enabled: true
    targets:
      rules:
        path: "${target_dir}"
        format: individual
        strip_frontmatter: true
        output_extension: ".md"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/st-indiv-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    sync_target "sti-agent" "rules" "rules"
    [[ -f "${target_dir}/test-rule.md" ]]
}

@test "sync_target dispatches directory format" {
    local target_dir="${TEST_FIXTURES}/shared-base/skills"
    local skill_src="${TEST_FIXTURES}/content/skills/st-skill"
    mkdir -p "${target_dir}" "${skill_src}"
    cat >"${skill_src}/SKILL.md" <<'MD'
---
name: st-skill
description: Sync target test
license: MIT
---
# ST Skill
MD

    cat >"${TEST_FIXTURES}/st-dir-manifest.yaml" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "${TEST_FIXTURES}/shared-base"
skills:
  source_dir: "skills"
  directories:
    - st-skill
agents:
  std-agent:
    enabled: true
    targets:
      skills:
        path: "${target_dir}"
        format: directory
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/st-dir-manifest.yaml"
    init_sync_registry

    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    sync_target "std-agent" "skills" "skills"
    [[ -f "${target_dir}/st-skill/SKILL.md" ]]
}

# =============================================================================
# cleanup_stale_files with backup
# =============================================================================

@test "cleanup_stale_files skips when registry not initialized" {
    local old_reg="${_SYNC_REGISTRY_NEW}"
    _SYNC_REGISTRY_NEW=""

    # Create a registry file with entries
    mkdir -p "${SYNC_REGISTRY_DIR}"
    printf '%s\n' "/some/file.md" >"${SYNC_REGISTRY}"

    run cleanup_stale_files
    [[ "$status" -eq 0 ]]
    _SYNC_REGISTRY_NEW="${old_reg}"
}

@test "cleanup_stale_files skips already-deleted files in registry" {
    mkdir -p "${SYNC_REGISTRY_DIR}"
    # Registry references a file that no longer exists on disk
    printf '%s\n' "/nonexistent/already-gone.md" >"${SYNC_REGISTRY}"

    init_sync_registry

    run cleanup_stale_files
    [[ "$status" -eq 0 ]]
    # Should not error, just skip silently
}

@test "cleanup_stale_files creates backup before removing when enabled" {
    local stale_file="${TEST_FIXTURES}/output/stale-bk.md"
    mkdir -p "$(dirname "${stale_file}")"
    echo "stale with backup" >"${stale_file}"

    mkdir -p "${SYNC_REGISTRY_DIR}"
    printf '%s\n' "${stale_file}" >"${SYNC_REGISTRY}"

    init_sync_registry
    CREATE_BACKUP=true
    XDG_STATE_HOME="${TEST_FIXTURES}/state"

    cleanup_stale_files

    # File should be removed
    [[ ! -f "${stale_file}" ]]
    # Backup should exist
    local backup_count
    backup_count=$(find "${TEST_FIXTURES}/state/agent-covenant/backups" -name "stale-bk.md.*.bak" -type f 2>/dev/null | wc -l | tr -d ' ')
    [[ "$backup_count" -ge 1 ]]
}

# =============================================================================
# is_agent_installed command detection
# =============================================================================

@test "is_agent_installed detects agent via command" {
    cat >"${TEST_FIXTURES}/cmd-detect-manifest.yaml" <<YAML
agents:
  cmd-agent:
    enabled: true
    description: "Command detected"
    detect:
      paths: []
      commands:
        - "bash --version"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/cmd-detect-manifest.yaml"
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    is_agent_installed "cmd-agent"
}

# =============================================================================
# parse_args additional tests
# =============================================================================

@test "parse_args --help exits 0" {
    run parse_args --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
}

@test "parse_args --list exits 0" {
    run parse_args --list
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"enabled-agent"* ]]
}

@test "parse_args -n sets DRY_RUN (short flag)" {
    DRY_RUN=false
    parse_args -n
    [[ "${DRY_RUN}" == "true" ]]
}

@test "parse_args -b sets CREATE_BACKUP (short flag)" {
    CREATE_BACKUP=false
    parse_args -b
    [[ "${CREATE_BACKUP}" == "true" ]]
}

@test "parse_args -a sets SPECIFIC_AGENT (short flag)" {
    SPECIFIC_AGENT=""
    parse_args -a myagent
    [[ "${SPECIFIC_AGENT}" == "myagent" ]]
}

@test "parse_args --force sets FORCE" {
    FORCE=false
    parse_args --force
    [[ "${FORCE}" == "true" ]]
}

@test "parse_args -f sets FORCE (short flag)" {
    FORCE=false
    parse_args -f
    [[ "${FORCE}" == "true" ]]
}

# =============================================================================
# Sync cache tests
# =============================================================================

@test "compute_source_hash produces a non-empty hash" {
    local hash
    hash=$(compute_source_hash "${MANIFEST_FILE}" "${TEST_FIXTURES}/content")
    [[ -n "${hash}" ]]
    [[ "${#hash}" -eq 64 ]]
}

@test "compute_source_hash is deterministic" {
    local h1 h2
    h1=$(compute_source_hash "${MANIFEST_FILE}" "${TEST_FIXTURES}/content")
    h2=$(compute_source_hash "${MANIFEST_FILE}" "${TEST_FIXTURES}/content")
    [[ "${h1}" == "${h2}" ]]
}

@test "compute_source_hash changes when content changes" {
    local h1 h2
    h1=$(compute_source_hash "${MANIFEST_FILE}" "${TEST_FIXTURES}/content")
    echo "extra" >>"${TEST_FIXTURES}/content/rules/test-rule.md"
    h2=$(compute_source_hash "${MANIFEST_FILE}" "${TEST_FIXTURES}/content")
    [[ "${h1}" != "${h2}" ]]
}

@test "load_sync_cache returns empty when no cache file" {
    local tmp_cache="${TEST_FIXTURES}/.no-cache"
    SYNC_CACHE_FILE="${tmp_cache}"
    local result
    result=$(load_sync_cache)
    [[ -z "${result}" ]]
}

@test "save_sync_cache and load_sync_cache roundtrip" {
    local tmp_cache="${TEST_FIXTURES}/.test-cache"
    SYNC_CACHE_FILE="${tmp_cache}"
    save_sync_cache "abc123"
    local result
    result=$(load_sync_cache)
    [[ "${result}" == "abc123" ]]
    rm -f "${tmp_cache}"
}

@test "invalidate_sync_cache removes cache file" {
    local tmp_cache="${TEST_FIXTURES}/.inv-cache"
    SYNC_CACHE_FILE="${tmp_cache}"
    save_sync_cache "todelete"
    [[ -f "${tmp_cache}" ]]
    invalidate_sync_cache
    [[ ! -f "${tmp_cache}" ]]
}

# =============================================================================
# sync_hooks_impl
# =============================================================================

@test "sync_hooks_impl: copies script to scripts_path with chmod 755" {
    local hooks_dir="${TEST_FIXTURES}/hooks-out"
    local script_src="${CONTENT_DIR}/hooks/claude-code/test-hook.sh"
    mkdir -p "$(dirname "${script_src}")" "${hooks_dir}"
    printf '#!/bin/bash\necho hello\n' >"${script_src}"

    local target_config
    target_config=$(jq -n \
        --arg sp "${hooks_dir}" \
        --argjson scripts '["hooks/claude-code/test-hook.sh"]' \
        '{scripts_path: $sp, scripts: $scripts}')

    # sync_hooks_impl writes hook scripts to the shared base (not scripts_path).
    MANIFEST_JSON="{\"shared_base\":\"${TEST_FIXTURES}/shared-base\"}"
    run sync_hooks_impl "claude-code" "hooks" "${target_config}"
    [[ "$status" -eq 0 ]]
    [[ -f "${TEST_FIXTURES}/shared-base/hooks/test-hook.sh" ]]
    [[ -x "${TEST_FIXTURES}/shared-base/hooks/test-hook.sh" ]]
}

@test "sync_hooks_impl: merges fragment into empty settings.json" {
    local hooks_dir="${TEST_FIXTURES}/hooks-merge-empty"
    local settings_file="${TEST_FIXTURES}/settings-empty.json"
    local fragment_src="${CONTENT_DIR}/hooks/claude-code/settings.fragment.json"
    mkdir -p "$(dirname "${fragment_src}")" "${hooks_dir}"
    rm -f "${settings_file}"

    printf '{"hooks":{"PreToolUse":[{"matcher":"Edit","hooks":[]}]}}' >"${fragment_src}"

    local target_config
    target_config=$(jq -n \
        --arg sp "${hooks_dir}" \
        --arg stp "${settings_file}" \
        --arg sf "hooks/claude-code/settings.fragment.json" \
        '{scripts_path: $sp, settings_path: $stp, settings_fragment: $sf}')

    run sync_hooks_impl "claude-code" "hooks" "${target_config}"
    [[ "$status" -eq 0 ]]
    [[ -f "${settings_file}" ]]
    jq -e '.hooks.PreToolUse' "${settings_file}" >/dev/null
}

@test "sync_hooks_impl: merges fragment without overwriting existing keys" {
    local hooks_dir="${TEST_FIXTURES}/hooks-merge-existing"
    local settings_file="${TEST_FIXTURES}/settings-existing.json"
    local fragment_src="${CONTENT_DIR}/hooks/claude-code/settings.fragment.json"
    mkdir -p "$(dirname "${fragment_src}")" "${hooks_dir}"

    printf '{"permissions":{"allow":["Read"]},"hooks":{"PreToolUse":[]}}' >"${settings_file}"
    printf '{"hooks":{"PostToolUse":[{"matcher":".*","hooks":[]}]}}' >"${fragment_src}"

    local target_config
    target_config=$(jq -n \
        --arg sp "${hooks_dir}" \
        --arg stp "${settings_file}" \
        --arg sf "hooks/claude-code/settings.fragment.json" \
        '{scripts_path: $sp, settings_path: $stp, settings_fragment: $sf}')

    run sync_hooks_impl "claude-code" "hooks" "${target_config}"
    [[ "$status" -eq 0 ]]
    # Original permissions key must still exist
    jq -e '.permissions.allow' "${settings_file}" >/dev/null
    # Fragment's PostToolUse must be merged in
    jq -e '.hooks.PostToolUse' "${settings_file}" >/dev/null
}

@test "sync_hooks_impl: dry-run does not write settings.json" {
    local hooks_dir="${TEST_FIXTURES}/hooks-dryrun"
    local settings_file="${TEST_FIXTURES}/settings-dryrun.json"
    local fragment_src="${CONTENT_DIR}/hooks/claude-code/settings.fragment.json"
    mkdir -p "$(dirname "${fragment_src}")" "${hooks_dir}"
    rm -f "${settings_file}"

    printf '{"hooks":{}}' >"${fragment_src}"
    DRY_RUN=true

    local target_config
    target_config=$(jq -n \
        --arg sp "${hooks_dir}" \
        --arg stp "${settings_file}" \
        --arg sf "hooks/claude-code/settings.fragment.json" \
        '{scripts_path: $sp, settings_path: $stp, settings_fragment: $sf}')

    run sync_hooks_impl "claude-code" "hooks" "${target_config}"
    [[ "$status" -eq 0 ]]
    [[ ! -f "${settings_file}" ]]
    DRY_RUN=false
}

@test "claude-code shared:false skills write real per-workspace dirs; cleanup scans them (A3)" {
    # HOME isolation: never touch live ~/.claude dirs (pre-migration they are
    # symlinks into the shared base). Mirrors test_bootstrap_symlinks.bats.
    local FAKE_HOME
    FAKE_HOME="$(mktemp -d)"
    export HOME="${FAKE_HOME}"

    mkdir -p "${TEST_FIXTURES}/content/skills/test-skill"
    cat >"${TEST_FIXTURES}/content/skills/test-skill/SKILL.md" <<'MD'
---
name: test-skill
description: shared:false test
license: MIT
---
# Test Skill
MD

    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"
    DRY_RUN=false
    CREATE_BACKUP=false
    TIMESTAMP="2026-01-01 00:00:00"

    # detect.paths REQUIRED: cleanup_agent_stale_files resolves ${DETECTED_BASE}
    # per workspace via detect_all_agent_paths (DETECTED_BASE is unset by then).
    cat >"${MANIFEST_FILE}" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "\${HOME}/.config/agent-covenant"
skills:
  source_dir: "skills"
  directories:
    - test-skill
agents:
  claude-code:
    enabled: true
    detect:
      paths:
        - "\${HOME}/.claude"
        - "\${HOME}/.claude-silver"
      commands: []
    targets:
      skills:
        path: "\${DETECTED_BASE}/skills"
        format: directory
        shared: false
YAML
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    init_sync_registry

    local tcfg
    tcfg=$(jq -c '.agents."claude-code".targets.skills' <<<"${MANIFEST_JSON}")

    # Workspace 1
    DETECTED_BASE="${HOME}/.claude"
    sync_directory_impl "claude-code" "skills" "skills" "${tcfg}"
    # Workspace 2 — same agent:source cache key, must still be written
    DETECTED_BASE="${HOME}/.claude-silver"
    sync_directory_impl "claude-code" "skills" "skills" "${tcfg}"
    unset DETECTED_BASE

    [[ -f "${HOME}/.claude/skills/test-skill/SKILL.md" ]]
    [[ -f "${HOME}/.claude-silver/skills/test-skill/SKILL.md" ]]
    [[ ! -d "${HOME}/.config/agent-covenant/skills/test-skill" ]]

    # Sentinel at the WORKSPACE ROOT (unregistered — created after the sync
    # writes): proves cleanup is scoped to the RESOLVED TARGET SUBDIR
    # (${HOME}/.claude/skills), not the raw workspace base (${HOME}/.claude).
    # If T3 Edit 11 emitted the raw base, the find+comm-23+rm pass would scan
    # the entire workspace root and delete this file (user-state wipe).
    echo '{"user": true}' >"${HOME}/.claude/sentinel-user-state.json"

    # A3: cleanup_agent_stale_files scans the real per-workspace dirs even though
    # DETECTED_BASE is unset (per-workspace resolution via detect_all_agent_paths).
    echo "stale" >"${HOME}/.claude/skills/stale.md"
    cleanup_agent_stale_files "claude-code"
    [[ ! -f "${HOME}/.claude/skills/stale.md" ]]
    [[ -f "${HOME}/.claude/skills/test-skill/SKILL.md" ]]
    [[ -f "${HOME}/.claude-silver/skills/test-skill/SKILL.md" ]]
    [[ -f "${HOME}/.claude/sentinel-user-state.json" ]]

    unset DETECTED_BASE
    rm -rf "${FAKE_HOME}"
}

@test "sync_individual_impl cache-hit re-writes when dest is missing (A2)" {
    # HOME isolation (F3): never rm -rf a live ~/.claude/agents symlink.
    local FAKE_HOME
    FAKE_HOME="$(mktemp -d)"
    export HOME="${FAKE_HOME}"

    mkdir -p "${TEST_FIXTURES}/content/subagents"
    cat >"${TEST_FIXTURES}/content/subagents/ultraplan.md" <<'MD'
---
name: ultraplan
description: A2 test subagent
---
# Ultraplan
MD

    MANIFEST_FILE="${TEST_FIXTURES}/test-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"
    DRY_RUN=false
    CREATE_BACKUP=false
    TIMESTAMP="2026-01-01 00:00:00"

    cat >"${MANIFEST_FILE}" <<YAML
version: "2.0"
content_dir: "content"
shared_base: "\${HOME}/.config/agent-covenant"
subagents:
  source_dir: "subagents"
  files:
    - ultraplan.md
agents:
  claude-code:
    enabled: true
    targets:
      subagents:
        path: "\${DETECTED_BASE}/agents"
        format: individual
        shared: false
        transform: strip
YAML
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")
    init_sync_registry

    local tcfg
    tcfg=$(jq -c '.agents."claude-code".targets.subagents' <<<"${MANIFEST_JSON}")
    DETECTED_BASE="${HOME}/.claude"
    sync_individual_impl "claude-code" "subagents" "subagents" "${tcfg}"
    [[ -f "${HOME}/.claude/agents/ultraplan.md" ]]

    # Dest removed; second call hits the cache but must re-write (A2 guard).
    rm -rf "${HOME}/.claude/agents"
    sync_individual_impl "claude-code" "subagents" "subagents" "${tcfg}"
    [[ -f "${HOME}/.claude/agents/ultraplan.md" ]]
    unset DETECTED_BASE
    rm -rf "${FAKE_HOME}"
}
