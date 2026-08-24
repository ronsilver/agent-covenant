#!/usr/bin/env bats
# shellcheck disable=SC1091,SC2034,SC2317
# =============================================================================
# Tests for scripts/validate.sh functions
# =============================================================================
# Run: bats tests/test_validate.bats

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../scripts" && pwd)"
REPO_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

bats_require_minimum_version 1.5.0

setup() {
    # Source real implementations (validate.sh is now sourceable)
    source "${SCRIPT_DIR}/validate.sh"

    TEST_FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
    mkdir -p "${TEST_FIXTURES}"

    # Reset counters
    ERRORS=0
    WARNINGS=0

    # Create valid test manifest
    cat >"${TEST_FIXTURES}/valid-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
rules:
  source_dir: "rules"
  files:
    - test-rule.md
workflows:
  source_dir: "workflows"
  files:
    - test-workflow.md
prompts:
  source_dir: "prompts"
  files:
    - test-prompt.md
agents:
  test-agent:
    enabled: true
    description: "Test Agent"
    targets:
      rules:
        path: "${HOME}/.test/rules.md"
        format: merged
  disabled-agent:
    enabled: false
    description: "Disabled Agent"
YAML

    # Override globals — REPO_ROOT must point to fixtures so resolve_content_dir works
    REPO_ROOT="${TEST_FIXTURES}"
    MANIFEST_FILE="${TEST_FIXTURES}/valid-manifest.yaml"
    CONTENT_DIR="${TEST_FIXTURES}/content"

    # Create content directories and files
    mkdir -p "${TEST_FIXTURES}/content/rules"
    mkdir -p "${TEST_FIXTURES}/content/workflows"
    mkdir -p "${TEST_FIXTURES}/content/prompts"

    cat >"${TEST_FIXTURES}/content/rules/test-rule.md" <<'MD'
---
trigger: always
---

# Test Rule
MD

    cat >"${TEST_FIXTURES}/content/workflows/test-workflow.md" <<'MD'
---
description: Test workflow
---

# Test Workflow
MD

    cat >"${TEST_FIXTURES}/content/prompts/test-prompt.md" <<'MD'
---
name: test
description: Test prompt
---

# Test Prompt
MD
}

teardown() {
    rm -rf "${TEST_FIXTURES}"
}

# =============================================================================
# validate_manifest tests
# =============================================================================

@test "validate_manifest succeeds with valid manifest" {
    run validate_manifest
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"manifest.yaml is valid"* ]]
}

@test "validate_manifest fails when manifest does not exist" {
    MANIFEST_FILE="${TEST_FIXTURES}/nonexistent.yaml"

    run validate_manifest
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"not found"* ]]
}

@test "validate_manifest fails with invalid YAML" {
    cat >"${TEST_FIXTURES}/invalid.yaml" <<'YAML'
invalid: [yaml: broken
  - not: valid
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/invalid.yaml"

    run validate_manifest
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"invalid YAML syntax"* ]]
}

@test "validate_manifest warns when version is missing" {
    cat >"${TEST_FIXTURES}/no-version.yaml" <<'YAML'
content_dir: "content"
rules:
  files:
    - test.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-version.yaml"

    validate_manifest
    # Function succeeds but increments WARNINGS
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# validate_content_dir tests
# =============================================================================

@test "validate_content_dir succeeds with valid directory" {
    run validate_content_dir
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Content directory"* ]]
}

@test "validate_content_dir fails when directory missing" {
    cat >"${TEST_FIXTURES}/bad-content-manifest.yaml" <<'YAML'
content_dir: "nonexistent_dir"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-content-manifest.yaml"

    run validate_content_dir
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"not found"* ]]
}

# =============================================================================
# validate_file_list tests
# =============================================================================

@test "validate_file_list returns 0 errors for existing files" {
    local result
    result=$(validate_file_list "rules")
    [[ "$result" -eq 0 ]]
}

@test "validate_file_list returns error count for missing files" {
    cat >"${TEST_FIXTURES}/missing-files-manifest.yaml" <<'YAML'
rules:
  source_dir: "rules"
  files:
    - test-rule.md
    - missing-file.md
    - another-missing.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-files-manifest.yaml"

    local result
    result=$(validate_file_list "rules")
    [[ "$result" -eq 2 ]]
}

# =============================================================================
# validate_files tests
# =============================================================================

@test "validate_files succeeds with all files present" {
    run validate_files
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"All files exist"* ]]
}

@test "validate_files fails with missing files" {
    cat >"${TEST_FIXTURES}/missing-manifest.yaml" <<'YAML'
rules:
  source_dir: "rules"
  files:
    - nonexistent.md
workflows:
  source_dir: "workflows"
  files:
    - test-workflow.md
prompts:
  source_dir: "prompts"
  files:
    - test-prompt.md
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-manifest.yaml"

    run validate_files
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"missing files"* ]]
}

# =============================================================================
# validate_frontmatter_dir tests
# =============================================================================

@test "validate_frontmatter_dir returns 0 for valid frontmatter" {
    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/rules" "rules" "trigger")
    [[ "$result" -eq 0 ]]
}

@test "validate_frontmatter_dir returns warnings for missing fields" {
    # Create a file without the required 'trigger' field
    cat >"${TEST_FIXTURES}/content/rules/bad-fm.md" <<'MD'
---
description: no trigger field
---

# Bad Frontmatter
MD

    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/rules" "rules" "trigger")
    [[ "$result" -gt 0 ]]
}

@test "validate_frontmatter_dir returns warnings for files without frontmatter" {
    cat >"${TEST_FIXTURES}/content/rules/no-fm.md" <<'MD'
# No Frontmatter At All
MD

    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/rules" "rules" "trigger")
    [[ "$result" -gt 0 ]]
}

@test "validate_frontmatter_dir returns 0 for nonexistent directory" {
    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/nonexistent" "nope" "trigger")
    [[ "$result" -eq 0 ]]
}

@test "validate_frontmatter_dir checks multiple required fields" {
    local result
    result=$(validate_frontmatter_dir "${TEST_FIXTURES}/content/prompts" "prompts" "name" "description")
    [[ "$result" -eq 0 ]]
}

# =============================================================================
# validate_frontmatter tests
# =============================================================================

@test "validate_frontmatter succeeds with valid frontmatter" {
    run validate_frontmatter
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"valid frontmatter"* ]]
}

@test "validate_frontmatter reports warnings for bad frontmatter" {
    # Add a file without required frontmatter field
    cat >"${TEST_FIXTURES}/content/rules/missing-trigger.md" <<'MD'
---
description: no trigger
---

# Missing Trigger
MD

    validate_frontmatter
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# validate_agents tests
# =============================================================================

@test "validate_agents succeeds with configured agents" {
    run validate_agents
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"agent(s) enabled"* ]]
}

@test "validate_agents shows enabled and disabled agents" {
    DEBUG=true
    run validate_agents
    [[ "$output" == *"test-agent"* ]]
    [[ "$output" == *"enabled"* ]]
}

@test "validate_agents warns when no agents configured" {
    cat >"${TEST_FIXTURES}/no-agents-manifest.yaml" <<'YAML'
version: "2.0"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-agents-manifest.yaml"

    validate_agents
    [[ $WARNINGS -gt 0 ]]
}

@test "validate_agents warns when no agents enabled" {
    cat >"${TEST_FIXTURES}/all-disabled-manifest.yaml" <<'YAML'
version: "2.0"
agents:
  agent-a:
    enabled: false
    description: "Disabled A"
  agent-b:
    enabled: false
    description: "Disabled B"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/all-disabled-manifest.yaml"

    validate_agents
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# main integration tests (via run to capture exit)
# =============================================================================

@test "main succeeds with valid configuration" {
    run main
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Validation completed"* ]]
}

@test "main fails with missing manifest" {
    MANIFEST_FILE="${TEST_FIXTURES}/nonexistent.yaml"

    run main
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Invalid manifest"* ]]
}

@test "main accepts --debug flag" {
    run main --debug
    [[ "$status" -eq 0 ]]
}

@test "main rejects unknown flags" {
    run main --unknown
    [[ "$status" -eq 1 ]]
}

@test "main --help exits 0" {
    run main --help
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"Usage"* ]]
}

@test "main fails when content dir is invalid" {
    cat >"${TEST_FIXTURES}/bad-dir-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "nonexistent_content"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/bad-dir-manifest.yaml"

    run main
    [[ "$status" -eq 1 ]]
    [[ "$output" == *"Invalid content dir"* ]]
}

# =============================================================================
# validate_manifest additional tests
# =============================================================================

@test "validate_manifest warns on unsupported version" {
    cat >"${TEST_FIXTURES}/unsupported-version.yaml" <<'YAML'
version: "99.0"
content_dir: "content"
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/unsupported-version.yaml"

    validate_manifest
    [[ $WARNINGS -gt 0 ]]
}

# =============================================================================
# validate_skills tests
# =============================================================================

@test "validate_skills succeeds with valid skills" {
    local skills_dir="${TEST_FIXTURES}/content/skills/valid-skill"
    mkdir -p "${skills_dir}"
    cat >"${skills_dir}/SKILL.md" <<'MD'
---
name: valid-skill
description: A valid skill
license: MIT
---

# Valid Skill
MD

    cat >"${TEST_FIXTURES}/skills-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - valid-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/skills-manifest.yaml"

    run validate_skills
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"All skills are valid"* ]]
}

@test "validate_skills warns when skills directory does not exist" {
    cat >"${TEST_FIXTURES}/no-skills-dir-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "nonexistent_skills"
  directories:
    - some-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-skills-dir-manifest.yaml"

    validate_skills
    [[ $WARNINGS -gt 0 ]]
}

@test "validate_skills errors when skill directory is missing" {
    mkdir -p "${TEST_FIXTURES}/content/skills"

    cat >"${TEST_FIXTURES}/missing-skill-dir-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - missing-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-skill-dir-manifest.yaml"

    validate_skills
    [[ $ERRORS -gt 0 ]]
}

@test "validate_skills errors when SKILL.md is missing" {
    local skill_dir="${TEST_FIXTURES}/content/skills/no-md-skill"
    mkdir -p "${skill_dir}"
    echo "readme" >"${skill_dir}/README.md"

    cat >"${TEST_FIXTURES}/no-md-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - no-md-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-md-manifest.yaml"

    validate_skills
    [[ $ERRORS -gt 0 ]]
}

@test "validate_skills errors when SKILL.md has no frontmatter" {
    local skill_dir="${TEST_FIXTURES}/content/skills/no-fm-skill"
    mkdir -p "${skill_dir}"
    cat >"${skill_dir}/SKILL.md" <<'MD'
# No Frontmatter Skill
MD

    cat >"${TEST_FIXTURES}/no-fm-skill-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - no-fm-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/no-fm-skill-manifest.yaml"

    validate_skills
    [[ $ERRORS -gt 0 ]]
}

@test "validate_skills errors when required fields are missing" {
    local skill_dir="${TEST_FIXTURES}/content/skills/missing-fields"
    mkdir -p "${skill_dir}"
    cat >"${skill_dir}/SKILL.md" <<'MD'
---
name: missing-fields
---

# Missing Description and License
MD

    cat >"${TEST_FIXTURES}/missing-fields-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - missing-fields
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/missing-fields-manifest.yaml"

    validate_skills
    [[ $ERRORS -gt 0 ]]
}

@test "validate_skills warns when name does not match directory" {
    local skill_dir="${TEST_FIXTURES}/content/skills/dir-name"
    mkdir -p "${skill_dir}"
    cat >"${skill_dir}/SKILL.md" <<'MD'
---
name: different-name
description: Name mismatch
license: MIT
---

# Mismatch
MD

    cat >"${TEST_FIXTURES}/mismatch-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - dir-name
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/mismatch-manifest.yaml"

    validate_skills
    [[ $WARNINGS -gt 0 ]]
}

@test "validate_skills warns on invalid name format" {
    local skill_dir="${TEST_FIXTURES}/content/skills/BadName"
    mkdir -p "${skill_dir}"
    cat >"${skill_dir}/SKILL.md" <<'MD'
---
name: BadName
description: Invalid format
license: MIT
---

# Bad Name
MD

    cat >"${TEST_FIXTURES}/badname-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - BadName
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/badname-manifest.yaml"

    validate_skills
    [[ $WARNINGS -gt 0 ]]
}

@test "validate_skills succeeds when SKILL.md has optional metadata field" {
    local skill_dir="${TEST_FIXTURES}/content/skills/meta-skill"
    mkdir -p "${skill_dir}"
    cat >"${skill_dir}/SKILL.md" <<'MD'
---
name: meta-skill
description: Has metadata
license: MIT
metadata:
  version: "1.0"
---

# Meta Skill
MD

    cat >"${TEST_FIXTURES}/meta-manifest.yaml" <<'YAML'
version: "2.0"
content_dir: "content"
skills:
  source_dir: "skills"
  directories:
    - meta-skill
YAML
    MANIFEST_FILE="${TEST_FIXTURES}/meta-manifest.yaml"

    run validate_skills
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"All skills are valid"* ]]
}

# =============================================================================
# opencode-agents-config.json coverage tests (ADR-0020)
# Verifies that all 17 subagent .md files have a corresponding entry in the
# opencode config source file, so `make sync` registers them as invocable
# via the runtime task tool. These tests resolve the real repo root from
# BATS_TEST_DIRNAME rather than ${REPO_ROOT}, because setup() in other tests
# of this file may override REPO_ROOT to point at fixtures.
# =============================================================================

REAL_REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"

@test "opencode-agents-config.json contains all 17 subagents" {
    local config_file="${REAL_REPO_ROOT}/content/mcp/opencode-agents-config.json"
    local subagents_dir="${REAL_REPO_ROOT}/content/subagents"

    local expected_count
    expected_count=$(find "${subagents_dir}" -maxdepth 1 -name "*.md" ! -name "README.md" | wc -l | tr -d ' ')

    local actual_count
    actual_count=$(jq -r '.agent | keys | length' "${config_file}")

    [[ "${actual_count}" -eq "${expected_count}" ]]
}

@test "opencode-agents-config.json registers git-requests, ultracode, test-writer (ADR-0020)" {
    local config_file="${REAL_REPO_ROOT}/content/mcp/opencode-agents-config.json"

    for agent in git-requests ultracode test-writer; do
        local mode
        mode=$(jq -r ".agent.\"${agent}\".mode // \"MISSING\"" "${config_file}")
        [[ "${mode}" != "MISSING" ]] || {
            echo "agent ${agent} not registered"
            return 1
        }
        [[ "${mode}" == "subagent" ]] || {
            echo "agent ${agent} mode is ${mode}, expected subagent"
            return 1
        }
    done
}

@test "opencode-agents-config.json contains all 17 agents registered" {
    local config_file="${REAL_REPO_ROOT}/content/mcp/opencode-agents-config.json"

    local subagent_count
    subagent_count=$(jq -r '.agent | keys | length' "${config_file}")

    [[ "${subagent_count}" -eq 17 ]]
}

@test "no subagent uses hidden: true (ADR-0021 discoverability invariant)" {
    local subagents_dir="${REAL_REPO_ROOT}/content/subagents"

    # No file in content/subagents/ may have hidden: true in frontmatter.
    # The README.md is not a subagent and may have hidden in prose; exclude it.
    local offenders
    offenders=$(grep -l "^hidden: true" "${subagents_dir}"/*.md 2>/dev/null | grep -v "README.md" || true)

    if [[ -n "${offenders}" ]]; then
        echo "Subagents with hidden: true (forbidden by ADR-0021):"
        echo "${offenders}"
        return 1
    fi
}

# ADR-0022: git workflow permanent invariants
@test "git-requests.md frontmatter gates git push as ask (ADR-0022)" {
    run grep '"git push \*": ask' "${REAL_REPO_ROOT}/content/subagents/git-requests.md"
    [ "$status" -eq 0 ]
    run grep '"git push \*": allow' "${REAL_REPO_ROOT}/content/subagents/git-requests.md"
    [ "$status" -ne 0 ]
}

@test "git-requests.md step 4 forbids protected branch names (ADR-0022)" {
    local file="${REAL_REPO_ROOT}/content/subagents/git-requests.md"
    for name in main master develop development staging sandbox; do
        run grep -c "\b${name}\b" "$file"
        [ "$status" -eq 0 ]
    done
}

@test "git-requests.md step 6 asks confirmation before push (ADR-0022)" {
    run grep 'explicit user confirmation' "${REAL_REPO_ROOT}/content/subagents/git-requests.md"
    [ "$status" -eq 0 ]
}

@test "git-requests.md prefers max-segmentation commits (ADR-0022)" {
    run grep 'as many commits as possible' "${REAL_REPO_ROOT}/content/subagents/git-requests.md"
    [ "$status" -eq 0 ]
}

@test "git-expert SKILL.md documents protected branches (ADR-0022)" {
    run grep 'Protected branches' "${REAL_REPO_ROOT}/content/skills/git-expert/SKILL.md"
    [ "$status" -eq 0 ]
}

# ADR-0023: subagent model portability -- no hard-coded provider model
@test "no subagent hard-codes a model field (ADR-0023 provider portability)" {
    local subagents_dir="${REAL_REPO_ROOT}/content/subagents"
    local offenders
    offenders=$(grep -l '^model:' "${subagents_dir}"/*.md 2>/dev/null | grep -v "README.md" || true)
    if [[ -n "${offenders}" ]]; then
        echo "Subagents with hard-coded model: (forbidden by ADR-0023, not portable across providers):"
        echo "${offenders}"
        return 1
    fi
}

# ADR-0024: tool-block omission regression
@test "tools.task: true present in all 17 agents (ADR-0024 tools layer)" {
    local config_file="${REAL_REPO_ROOT}/content/mcp/opencode-agents-config.json"

    # Count agents with tools.task: true
    local task_enabled
    task_enabled=$(jq '.agent | to_entries | map(select(.value.tools.task == true)) | length' "${config_file}")

    # Count total agents
    local agent_count
    agent_count=$(jq '.agent | keys | length' "${config_file}")

    [[ "${task_enabled}" -eq "${agent_count}" ]] || {
        echo "tools.task missing in some agents: ${task_enabled}/${agent_count} enabled, expected ${agent_count}/${agent_count}"
        return 1
    }
}

@test "permission.task blocks absent except ultraorchestrator (ADR-0024 + ratified router allowlist)" {
    local config_file="${REAL_REPO_ROOT}/content/mcp/opencode-agents-config.json"

    # permission.task is reserved for ultraorchestrator (ratified task allowlist);
    # all other agents must not carry a permission.task block (ADR-0024 cleanup).
    local permission_task_agents
    permission_task_agents=$(jq -r '[.agent | to_entries[] | select((.value.permission // {}) | has("task")) | .key] | join(",")' "${config_file}")

    if [[ "${permission_task_agents}" == "ultraorchestrator" ]]; then
        return 0
    fi
    echo "permission.task blocks present outside ultraorchestrator (ADR-0024): ${permission_task_agents}"
    return 1
}

# =============================================================================
# validate_subagent_descriptions tests
# =============================================================================

@test "validate_subagent_descriptions returns 0 when subagents dir absent" {
    # setup() fixtures have no content/subagents directory; manifest has no
    # subagents: section so source_dir defaults to "subagents".
    run validate_subagent_descriptions
    [[ "$status" -eq 0 ]]
}

@test "validate_subagent_descriptions passes a valid description" {
    mkdir -p "${TEST_FIXTURES}/content/subagents"
    cat >"${TEST_FIXTURES}/content/subagents/good-agent.md" <<'MD'
---
name: good-agent
description: Audits dependency CVEs and delivers an upgrade plan.
permissionMode: read
---
MD

    run validate_subagent_descriptions
    [[ "$status" -eq 0 ]]
    [[ "$output" == *"All subagent descriptions are valid"* ]]
    [[ "$ERRORS" -eq 0 ]]
}

@test "validate_subagent_descriptions rejects Use when prefix" {
    mkdir -p "${TEST_FIXTURES}/content/subagents"
    cat >"${TEST_FIXTURES}/content/subagents/bad-agent.md" <<'MD'
---
name: bad-agent
description: Use when a failure must be root-caused.
permissionMode: read
---
MD

    validate_subagent_descriptions
    [[ "$ERRORS" -gt 0 ]]
}

@test "validate_subagent_descriptions rejects Use BEFORE case-insensitive" {
    mkdir -p "${TEST_FIXTURES}/content/subagents"
    cat >"${TEST_FIXTURES}/content/subagents/bad-agent.md" <<'MD'
---
name: bad-agent
description: Use BEFORE ultraplan when a decision is complex.
permissionMode: read
---
MD

    validate_subagent_descriptions
    [[ "$ERRORS" -gt 0 ]]
}

@test "validate_subagent_descriptions rejects quoted Use when prefix" {
    mkdir -p "${TEST_FIXTURES}/content/subagents"
    cat >"${TEST_FIXTURES}/content/subagents/bad-agent.md" <<'MD'
---
name: bad-agent
description: "Use when a code change needs review."
permissionMode: read
---
MD

    validate_subagent_descriptions
    [[ "$ERRORS" -gt 0 ]]
}

@test "validate_subagent_descriptions ignores README.md" {
    mkdir -p "${TEST_FIXTURES}/content/subagents"
    cat >"${TEST_FIXTURES}/content/subagents/README.md" <<'MD'
---
description: Use when this is only an illustration, not a subagent.
---
# Catalog
MD

    run validate_subagent_descriptions
    [[ "$status" -eq 0 ]]
    [[ "$ERRORS" -eq 0 ]]
}

# =============================================================================
# ultraorchestrator dispatch regression (router DISPATCHES, never self-executes)
# =============================================================================

@test "ultraorchestrator.md has REFUSAL PROTOCOL" {
    local file="${REAL_REPO_ROOT}/content/subagents/ultraorchestrator.md"
    run grep '^## REFUSAL PROTOCOL' "${file}"
    [ "$status" -eq 0 ]
}

@test "ultraorchestrator.md pipeline state machine mandates task dispatch" {
    local file="${REAL_REPO_ROOT}/content/subagents/ultraorchestrator.md"
    run grep '^## Pipeline state machine' "${file}"
    [ "$status" -eq 0 ]
    run grep 'task()' "${file}"
    [ "$status" -eq 0 ]
}

@test "ultraorchestrator.md forbids self-execution" {
    local file="${REAL_REPO_ROOT}/content/subagents/ultraorchestrator.md"
    run grep 'MUST NOT self-execute' "${file}"
    [ "$status" -eq 0 ]
}

@test "ultraorchestrator.md pipeline routing ask-gates executors" {
    local file="${REAL_REPO_ROOT}/content/subagents/ultraorchestrator.md"
    run grep 'ultracode: ask' "${file}"
    [ "$status" -eq 0 ]
    run grep 'git-requests: ask' "${file}"
    [ "$status" -eq 0 ]
    run grep 'test-writer: ask' "${file}"
    [ "$status" -eq 0 ]
}
