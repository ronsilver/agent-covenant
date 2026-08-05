#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# validate.sh - Validate agent-covenant configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"
[[ ! -f "${MANIFEST_FILE}" ]] && MANIFEST_FILE="${REPO_ROOT}/manifest.example.yaml"

# Load common functions
source "${SCRIPT_DIR}/lib/common.sh"

# Variables
CONTENT_DIR=""
ERRORS=0
WARNINGS=0

# =============================================================================
# Validation functions
# =============================================================================

validate_manifest() {
    log_section "Validating manifest"

    # Check that it exists
    if [[ ! -f "$MANIFEST_FILE" ]]; then
        log_error "manifest file not found: $MANIFEST_FILE"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Check YAML syntax
    if ! yq '.' "$MANIFEST_FILE" >/dev/null 2>&1; then
        log_error "manifest.yaml has invalid YAML syntax"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Check version
    local version
    version=$(yq '.version // ""' "$MANIFEST_FILE")
    if [[ -z "$version" || "$version" == "null" ]]; then
        log_warn "manifest.yaml has no version defined"
        WARNINGS=$((WARNINGS + 1))
    else
        # Validate it is a supported version
        case "${version}" in
            2.0)
                log_debug "Manifest version: $version"
                ;;
            *)
                log_warn "Unsupported manifest version: ${version} (supported: 2.0)"
                WARNINGS=$((WARNINGS + 1))
                ;;
        esac
    fi

    log_success "manifest.yaml is valid"
    return 0
}

validate_content_dir() {
    log_section "Validating content directory"

    local manifest_json
    manifest_json=$(yq -o=json '.' "${MANIFEST_FILE}")
    CONTENT_DIR=$(resolve_content_dir "${REPO_ROOT}" "${manifest_json}")

    if [[ ! -d "$CONTENT_DIR" ]]; then
        log_error "Content directory not found: $CONTENT_DIR"
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    log_success "Content directory: $CONTENT_DIR"
    return 0
}

# Validate files of a specific type (generic)
validate_file_list() {
    local type="$1"
    local errors=0

    log_info "Validating ${type}..."
    local source_dir
    source_dir=$(yq ".${type}.source_dir // \"${type}\"" "$MANIFEST_FILE")

    # Get file count to iterate
    local file_count
    file_count=$(yq ".${type}.files | length" "$MANIFEST_FILE" 2>/dev/null || echo 0)

    for ((i = 0; i < file_count; i++)); do
        # Check if entry is a string or object
        local entry_type
        entry_type=$(yq ".${type}.files[${i}] | type" "$MANIFEST_FILE")

        local file_path
        local agent_list

        if [[ "${entry_type}" == "!!str" ]]; then
            # Simple string format (no agent filter)
            file_path=$(yq ".${type}.files[${i}]" "$MANIFEST_FILE")
            agent_list=""
        else
            # Object format with optional agent filter
            file_path=$(yq ".${type}.files[${i}].path // .${type}.files[${i}]" "$MANIFEST_FILE")
            agent_list=$(yq ".${type}.files[${i}].agents[]?" "$MANIFEST_FILE" 2>/dev/null | tr '\n' ',' || echo "")
        fi

        [[ -z "${file_path}" || "${file_path}" == "null" ]] && continue

        local full_path="${CONTENT_DIR}/${source_dir}/${file_path}"
        if [[ ! -f "$full_path" ]]; then
            log_error "  File not found: ${source_dir}/${file_path}"
            errors=$((errors + 1))
        else
            if [[ -n "${agent_list}" ]]; then
                log_debug "  ✓ ${source_dir}/${file_path} (agents: ${agent_list})"
            else
                log_debug "  ✓ ${source_dir}/${file_path}"
            fi
        fi
    done

    echo "${errors}"
}

validate_files() {
    log_section "Validating referenced files"

    local file_errors=0
    local type_errors

    for type in rules workflows prompts; do
        type_errors=$(validate_file_list "${type}")
        file_errors=$((file_errors + type_errors))
    done

    if [[ $file_errors -gt 0 ]]; then
        log_error "Found $file_errors missing files"
        ERRORS=$((ERRORS + file_errors))
        return 1
    fi

    log_success "All files exist"
    return 0
}

# Validate frontmatter of files in a directory with required fields
validate_frontmatter_dir() {
    local dir_path="$1"
    local label="$2"
    shift 2
    local required_fields=("$@")
    local warnings=0

    if [[ ! -d "${dir_path}" ]]; then
        echo "0"
        return
    fi

    log_info "Validating ${label} frontmatter..."
    while IFS= read -r file; do
        local rel_path="${file#"${CONTENT_DIR}"/}"
        if ! has_frontmatter "$file"; then
            log_warn "  No frontmatter: ${rel_path}"
            warnings=$((warnings + 1))
        else
            local fm_content
            fm_content=$(awk '/^---$/{if(n++)exit}n' "$file")
            for field in "${required_fields[@]}"; do
                if ! printf '%s\n' "$fm_content" | grep -q "^${field}:"; then
                    log_warn "  Missing '${field}' in frontmatter: ${rel_path}"
                    warnings=$((warnings + 1))
                fi
            done
        fi
    done < <(find "${dir_path}" -name "*.md" -type f 2>/dev/null)

    echo "${warnings}"
}

validate_frontmatter() {
    log_section "Validating file frontmatter"

    local fm_warnings=0
    local type_warnings

    # Required fields schema per type
    local rules_dir
    rules_dir=$(yq '.rules.source_dir // "rules"' "$MANIFEST_FILE")
    type_warnings=$(validate_frontmatter_dir "${CONTENT_DIR}/${rules_dir}" "rules" "trigger")
    fm_warnings=$((fm_warnings + type_warnings))

    local workflows_dir
    workflows_dir=$(yq '.workflows.source_dir // "workflows"' "$MANIFEST_FILE")
    type_warnings=$(validate_frontmatter_dir "${CONTENT_DIR}/${workflows_dir}" "workflows" "description")
    fm_warnings=$((fm_warnings + type_warnings))

    local prompts_dir
    prompts_dir=$(yq '.prompts.source_dir // "prompts"' "$MANIFEST_FILE")
    type_warnings=$(validate_frontmatter_dir "${CONTENT_DIR}/${prompts_dir}" "prompts" "name" "description")
    fm_warnings=$((fm_warnings + type_warnings))

    if [[ $fm_warnings -gt 0 ]]; then
        log_warn "Found $fm_warnings frontmatter issues"
        WARNINGS=$((WARNINGS + fm_warnings))
    else
        log_success "All files have valid frontmatter"
    fi

    return 0
}

validate_skills() {
    log_section "Validating skills"

    local skills_source_dir
    skills_source_dir=$(yq '.skills.source_dir // "skills"' "$MANIFEST_FILE")
    local skills_base="${CONTENT_DIR}/${skills_source_dir}"

    # Check that the skills directory exists
    if [[ ! -d "${skills_base}" ]]; then
        log_warn "Skills directory not found: ${skills_base}"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi

    local skill_errors=0
    local skill_warnings=0

    while IFS= read -r dir_name; do
        [[ -z "${dir_name}" || "${dir_name}" == "null" ]] && continue
        local skill_path="${skills_base}/${dir_name}"

        # Check that the directory exists
        if [[ ! -d "${skill_path}" ]]; then
            log_error "  Skill directory not found: ${skills_source_dir}/${dir_name}"
            skill_errors=$((skill_errors + 1))
            continue
        fi

        # Check that SKILL.md exists
        if [[ ! -f "${skill_path}/SKILL.md" ]]; then
            log_error "  SKILL.md not found in: ${skills_source_dir}/${dir_name}/"
            skill_errors=$((skill_errors + 1))
            continue
        fi

        # Validate SKILL.md frontmatter (name and description required)
        local skill_md="${skill_path}/SKILL.md"
        if ! has_frontmatter "${skill_md}"; then
            log_error "  No frontmatter in SKILL.md: ${skills_source_dir}/${dir_name}/"
            skill_errors=$((skill_errors + 1))
            continue
        fi

        # Extract YAML frontmatter block into a temp file and parse with yq
        # (strict YAML parser — catches invalid YAML that grep would miss)
        local fm_tmpfile
        fm_tmpfile=$(mktemp)
        awk '/^---$/{if(n++)exit}n' "${skill_md}" >"${fm_tmpfile}"

        if ! yq '.' "${fm_tmpfile}" >/dev/null 2>&1; then
            log_error "  Invalid YAML in frontmatter of SKILL.md: ${skills_source_dir}/${dir_name}/"
            skill_errors=$((skill_errors + 1))
            rm -f "${fm_tmpfile}"
            continue
        fi

        # NOTE: 'metadata:' (author, version, category, etc.) is an optional field per the official
        # skill spec and MUST NOT be validated or warned about here. Version is also tracked in
        # manifest.yaml but that does not make it invalid inside SKILL.md frontmatter.
        # DO NOT add a check for metadata: presence or any of its subfields.

        for field in name description license; do
            local val
            val=$(yq ".${field} // \"\"" "${fm_tmpfile}" 2>/dev/null)
            if [[ -z "${val}" || "${val}" == "null" ]]; then
                log_error "  Missing '${field}' in SKILL.md: ${skills_source_dir}/${dir_name}/"
                skill_errors=$((skill_errors + 1))
            fi
        done

        # Validate that name matches the directory name
        local skill_name
        skill_name=$(yq '.name // ""' "${fm_tmpfile}" 2>/dev/null)
        rm -f "${fm_tmpfile}"

        if [[ -n "${skill_name}" && "${skill_name}" != "${dir_name}" ]]; then
            log_warn "  Skill name '${skill_name}' does not match directory '${dir_name}'"
            skill_warnings=$((skill_warnings + 1))
        fi

        # Validate name format (lowercase, hyphens, no consecutive hyphens)
        if [[ -n "${skill_name}" ]] && ! [[ "${skill_name}" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]]; then
            log_warn "  Skill name does not follow convention (lowercase, hyphens): '${skill_name}'"
            skill_warnings=$((skill_warnings + 1))
        fi

        log_debug "  ✓ ${skills_source_dir}/${dir_name}/"
    done < <(yq '.skills.directories[]' "$MANIFEST_FILE" 2>/dev/null)

    if [[ ${skill_errors} -gt 0 ]]; then
        log_error "Found ${skill_errors} errors in skills"
        ERRORS=$((ERRORS + skill_errors))
    fi

    if [[ ${skill_warnings} -gt 0 ]]; then
        log_warn "Found ${skill_warnings} warnings in skills"
        WARNINGS=$((WARNINGS + skill_warnings))
    fi

    if [[ ${skill_errors} -eq 0 && ${skill_warnings} -eq 0 ]]; then
        log_success "All skills are valid"
    fi

    return 0
}

validate_skill_coherence() {
    log_section "Validating source/manifest coherence"

    local skills_source_dir
    skills_source_dir=$(yq '.skills.source_dir // "skills"' "$MANIFEST_FILE")
    local skills_base="${CONTENT_DIR}/${skills_source_dir}"

    if [[ ! -d "${skills_base}" ]]; then
        return 0
    fi

    # Build sorted lists: dirs on disk vs dirs in manifest
    local on_disk_tmp manifest_tmp retired_tmp
    on_disk_tmp=$(mktemp)
    manifest_tmp=$(mktemp)
    retired_tmp=$(mktemp)

    find "${skills_base}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort >"${on_disk_tmp}"
    yq '.skills.directories[]' "$MANIFEST_FILE" 2>/dev/null | sort >"${manifest_tmp}"
    # Retired skills: suppress "untracked on disk" warnings (source dirs may be deleted)
    yq '.skills.retired[].name // ""' "$MANIFEST_FILE" 2>/dev/null | grep -v '^$' | sort >"${retired_tmp}"

    # Always-excluded helper/template directories — not deployable skills
    local excluded_tmp
    excluded_tmp=$(mktemp)
    printf '_TEMPLATE\nnew-skill\n' | sort >"${excluded_tmp}"

    # Skills on disk but not in manifest active list (and not retired or excluded) → untracked
    local untracked
    untracked=$(comm -23 "${on_disk_tmp}" "${manifest_tmp}" | comm -23 - "${retired_tmp}" | comm -23 - "${excluded_tmp}")
    # Skills in manifest but not on disk (already caught by validate_skills — debug only)
    local missing_from_disk
    missing_from_disk=$(comm -13 "${on_disk_tmp}" "${manifest_tmp}")

    rm -f "${on_disk_tmp}" "${manifest_tmp}" "${retired_tmp}" "${excluded_tmp}"

    local coherence_warnings=0

    if [[ -n "${untracked}" ]]; then
        log_warn "  Skills on disk not listed in manifest (will never be synced):"
        while IFS= read -r s; do
            log_warn "    - ${skills_source_dir}/${s}/"
            coherence_warnings=$((coherence_warnings + 1))
        done <<<"${untracked}"
    fi

    if [[ -n "${missing_from_disk}" ]]; then
        while IFS= read -r s; do
            log_debug "  In manifest but missing on disk (caught by validate_skills): ${s}"
        done <<<"${missing_from_disk}"
    fi

    if [[ ${coherence_warnings} -gt 0 ]]; then
        log_warn "Found ${coherence_warnings} untracked skill(s) — add to manifest or remove from disk"
        WARNINGS=$((WARNINGS + coherence_warnings))
    else
        log_success "Source and manifest are coherent"
    fi

    return 0
}

validate_agents() {
    log_section "Validating agent configuration"

    local agents
    agents=$(yq '.agents | keys | .[]' "$MANIFEST_FILE" 2>/dev/null || true)

    if [[ -z "$agents" ]]; then
        log_warn "No agents configured"
        WARNINGS=$((WARNINGS + 1))
        return 0
    fi

    local enabled_count=0
    local path_errors=0

    while IFS= read -r agent; do
        [[ -z "$agent" ]] && continue

        local enabled
        enabled=$(yq ".agents.${agent}.enabled // false" "$MANIFEST_FILE")
        local description
        description=$(yq ".agents.${agent}.description // \"\"" "$MANIFEST_FILE")

        if [[ "$enabled" == "true" ]]; then
            log_info "  ✓ ${agent}: ${description} (enabled)"
            enabled_count=$((enabled_count + 1))

            # Validate target paths for enabled agents
            local target_types
            target_types=$(yq ".agents.${agent}.targets | keys | .[]" "$MANIFEST_FILE" 2>/dev/null || true)

            while IFS= read -r target_type; do
                [[ -z "${target_type}" ]] && continue

                local target_path
                target_path=$(yq ".agents.${agent}.targets.${target_type}.path // \"\"" "$MANIFEST_FILE")

                if [[ -n "${target_path}" && "${target_path}" != "null" ]]; then
                    # Expand variables for validation
                    local expanded_path="${target_path}"
                    expanded_path="${expanded_path//\$\{HOME\}/${HOME}}"
                    expanded_path="${expanded_path//\$\{REPO_ROOT\}/${REPO_ROOT}}"
                    expanded_path="${expanded_path//\$\{DETECTED_BASE\}/${HOME}/.claude}"

                    # Check parent directory exists or can be created
                    local parent_dir
                    if [[ "${expanded_path}" == *".md" ]] || [[ "${expanded_path}" == *".json" ]]; then
                        parent_dir=$(dirname "${expanded_path}")
                    else
                        parent_dir="${expanded_path}"
                    fi

                    if [[ "${CI:-}" == "true" ]]; then
                        log_debug "    ${target_type}: ${target_path} (skipped in CI)"
                    elif [[ ! -d "${parent_dir}" ]]; then
                        # Check if we can create it (parent of parent must exist and be writable)
                        local parent_parent
                        parent_parent=$(dirname "${parent_dir}")
                        if [[ -d "${parent_parent}" ]] && [[ -w "${parent_parent}" ]]; then
                            log_debug "    ${target_type}: ${target_path} (will create)"
                        else
                            log_error "    ${target_type}: ${target_path} (parent not writable)"
                            path_errors=$((path_errors + 1))
                        fi
                    elif [[ ! -w "${parent_dir}" ]]; then
                        log_error "    ${target_type}: ${target_path} (not writable)"
                        path_errors=$((path_errors + 1))
                    else
                        log_debug "    ${target_type}: ${target_path} (ok)"
                    fi
                fi
            done <<<"${target_types}"
        else
            log_debug "  ○ ${agent}: ${description} (disabled)"
        fi
    done <<<"$agents"

    if [[ $enabled_count -eq 0 ]]; then
        log_warn "No agents enabled"
        WARNINGS=$((WARNINGS + 1))
    else
        if [[ ${path_errors} -gt 0 ]]; then
            log_error "Found ${path_errors} invalid target paths"
            ERRORS=$((ERRORS + path_errors))
        else
            log_success "$enabled_count agent(s) enabled with valid paths"
        fi
    fi

    return 0
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --debug | -d)
                export DEBUG=true
                shift
                ;;
            --help | -h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --debug, -d    Show debug information"
                echo "  --help, -h     Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    log_section "Agent Covenant - Validation"

    # Check dependencies
    check_dependency "yq" "brew install yq" || exit 1
    check_dependency "jq" "brew install jq" || exit 1

    # Fatal validations — cannot continue without these
    if ! validate_manifest; then
        log_fail "Invalid manifest, aborting"
        exit 1
    fi
    if ! validate_content_dir; then
        log_fail "Invalid content dir, aborting"
        exit 1
    fi

    # Non-fatal validations — only if fatal ones passed
    if [[ $ERRORS -eq 0 ]]; then
        validate_files || true
        validate_frontmatter || true
        validate_skills || true
        validate_skill_coherence || true
        validate_agents || true

        # Validate paths against canonical documentation
        if [[ -x "${SCRIPT_DIR}/validate-canonical-paths.sh" ]]; then
            log_info "Running canonical path validation..."
            if "${SCRIPT_DIR}/validate-canonical-paths.sh" 2>&1 | grep -v "^━" | grep -v "^$"; then
                :
            fi
        fi

        # Validate kernel skill invocation clauses and memory declarations
        if [[ -x "${SCRIPT_DIR}/validate-kernel-skill-coherence.sh" ]]; then
            log_section "Validating kernel skill invocation and memory coherence"
            if ! "${SCRIPT_DIR}/validate-kernel-skill-coherence.sh" >/dev/null 2>&1; then
                "${SCRIPT_DIR}/validate-kernel-skill-coherence.sh" >&2 || true
                ERRORS=$((ERRORS + 1))
            else
                log_success "Kernel skill invocation and memory declarations are coherent"
            fi
        fi
    fi

    # Summary
    echo "" >&2
    log_section "Summary"

    if [[ $ERRORS -gt 0 ]]; then
        log_error "Errors: $ERRORS"
    else
        log_success "Errors: 0"
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        log_warn "Warnings: $WARNINGS"
    else
        log_success "Warnings: 0"
    fi

    echo "" >&2

    if [[ $ERRORS -gt 0 ]]; then
        log_fail "Validation failed"
        exit 1
    else
        log_success "Validation completed"
        exit 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
