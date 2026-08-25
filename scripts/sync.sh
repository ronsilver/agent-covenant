#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# sync.sh - Unified script to sync rules to AI agents v2.0
# =============================================================================
# Reads configuration from manifest.yaml and syncs rules, workflows and prompts
# to the configured destinations for each agent.
#
# Usage:
#   ./scripts/sync.sh                    # Sync all enabled agents
#   ./scripts/sync.sh --agent opencode   # Sync a specific agent
#   ./scripts/sync.sh --dry-run          # Show what would be done without executing
#   ./scripts/sync.sh --list             # List available agents
#   ./scripts/sync.sh --backup           # Create backup before writing
#   ./scripts/sync.sh --validate         # Validate before syncing
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"
[[ ! -f "${MANIFEST_FILE}" ]] && MANIFEST_FILE="${REPO_ROOT}/manifest.example.yaml"

# Load common functions
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/sync.sh"

# Global variables
DRY_RUN=false
SPECIFIC_AGENT=""
CREATE_BACKUP=false
VALIDATE_FIRST=false
FORCE=false
BOOTSTRAP_REGISTRY=false
TIMESTAMP=$(get_timestamp)
CONTENT_DIR=""
MANIFEST_JSON=""

# =============================================================================
# Check dependencies
# =============================================================================

check_dependencies() {
    check_dependency "yq" "brew install yq" || exit 1
    check_dependency "jq" "brew install jq" || exit 1
}

# Check if an agent is enabled
is_agent_enabled() {
    local agent="$1"
    local enabled
    enabled=$(jq -r --arg a "${agent}" '.agents[$a].enabled // false' <<<"${MANIFEST_JSON}")
    [[ "${enabled}" == "true" ]]
}

# Run a detection command with timeout protection
# Commands come from our manifest.yaml, not user input
run_detect_command() {
    local cmd="$1"
    local timeout_secs="${2:-5}"

    # Fast path: if the base binary doesn't exist, skip
    local binary="${cmd%% *}"
    if ! command -v "${binary}" &>/dev/null; then
        return 1
    fi

    # Run the full command to verify installation
    if command -v gtimeout &>/dev/null; then
        gtimeout "${timeout_secs}" bash -c "${cmd}" &>/dev/null 2>&1
    elif command -v timeout &>/dev/null; then
        timeout "${timeout_secs}" bash -c "${cmd}" &>/dev/null 2>&1
    else
        bash -c "${cmd}" &>/dev/null 2>&1
    fi
}

# Check if an agent is installed
is_agent_installed() {
    local agent="$1"

    # If no detection configuration, assume installed
    if [[ $(jq -r --arg a "${agent}" '.agents[$a].detect' <<<"${MANIFEST_JSON}") == "null" ]]; then
        return 0
    fi

    # Use detect_agent_path for path-based detection
    local detected_path
    detected_path=$(detect_agent_path "${agent}")
    if [[ -n "${detected_path}" ]]; then
        log_debug "Detected ${agent} via path: ${detected_path}"
        return 0
    fi

    # Check commands (run full command to verify, not just binary existence)
    local commands
    commands=$(jq -r --arg a "${agent}" '.agents[$a].detect.commands[]? // empty' <<<"${MANIFEST_JSON}" 2>/dev/null || echo "")
    if [[ -n "${commands}" ]]; then
        while IFS= read -r cmd; do
            [[ -z "${cmd}" ]] && continue
            if run_detect_command "${cmd}"; then
                log_debug "Detected ${agent} via command: ${cmd}"
                return 0
            fi
        done <<<"${commands}"
    fi

    # Configuration exists but nothing was detected
    return 1
}

# Returns first matching detect path for an agent, or empty string if none found.
# Scans detect.paths in order; first match wins.
detect_agent_path() {
    local agent="$1"
    local paths
    paths=$(jq -r --arg a "${agent}" '.agents[$a].detect.paths[]? // empty' <<<"${MANIFEST_JSON}" 2>/dev/null || echo "")
    if [[ -z "${paths}" ]]; then
        echo ""
        return 0
    fi
    while IFS= read -r path; do
        [[ -z "${path}" ]] && continue
        local expanded_path
        expanded_path=$(expand_path "${path}")
        if compgen -G "${expanded_path}" >/dev/null 2>&1; then
            echo "${expanded_path}"
            return 0
        fi
    done <<<"${paths}"
    echo ""
    return 1
}

# Returns ALL matching detect paths for an agent, one per line.
# Scans detect.paths in order; all matches returned (not just first).
detect_all_agent_paths() {
    local agent="$1"
    local paths
    paths=$(jq -r --arg a "${agent}" '.agents[$a].detect.paths[]? // empty' <<<"${MANIFEST_JSON}" 2>/dev/null || echo "")
    if [[ -z "${paths}" ]]; then
        echo ""
        return 0
    fi
    while IFS= read -r path; do
        [[ -z "${path}" ]] && continue
        local expanded_path
        expanded_path=$(expand_path "${path}")
        if compgen -G "${expanded_path}" >/dev/null 2>&1; then
            echo "${expanded_path}"
        fi
    done <<<"${paths}"
}

# =============================================================================
# Sync a specific agent
# =============================================================================

sync_agent() {
    local agent="$1"

    if ! is_agent_enabled "${agent}"; then
        log_warn "Agent '${agent}' is disabled"
        return 0
    fi

    local description
    description=$(jq -r --arg a "${agent}" '.agents[$a].description // $a' <<<"${MANIFEST_JSON}")

    # Check if the agent is installed
    if ! is_agent_installed "${agent}"; then
        log_debug "Agent '${agent}' is not installed - skipping"
        return 0
    fi

    log_section "Syncing: ${description}"

    # Discover target types from manifest (same for all workspaces)
    local target_types
    target_types=$(jq -r --arg a "${agent}" '.agents[$a].targets | keys[]' <<<"${MANIFEST_JSON}" 2>/dev/null || echo "")

    if [[ -z "${target_types}" ]]; then
        log_warn "No targets configured for ${agent}"
        return 0
    fi

    # Resolve ALL DETECTED_BASE paths for agents with path_strategy: detect_as_base
    local path_strategy
    path_strategy=$(jq -r --arg a "${agent}" '.agents[$a].path_strategy // ""' <<<"${MANIFEST_JSON}")

    if [[ "${path_strategy}" == "detect_as_base" ]]; then
        local all_detected_bases=()
        while IFS= read -r detected_base; do
            [[ -z "${detected_base}" ]] && continue
            all_detected_bases+=("${detected_base}")
        done < <(detect_all_agent_paths "${agent}")

        if [[ ${#all_detected_bases[@]} -eq 0 ]]; then
            log_warn "path_strategy=detect_as_base but no detect path matched for ${agent}"
            return 0
        fi

        # Iterate over ALL detected workspaces
        for detected_base in "${all_detected_bases[@]}"; do
            export DETECTED_BASE="${detected_base}"
            log_info "DETECTED_BASE=${DETECTED_BASE}"

            while IFS= read -r target_type; do
                [[ -z "${target_type}" ]] && continue
                local source_type
                source_type=$(jq -r --arg a "${agent}" --arg t "${target_type}" '.agents[$a].targets[$t].source_type // $t' <<<"${MANIFEST_JSON}")
                log_info "Syncing ${target_type}..."
                sync_target "${agent}" "${target_type}" "${source_type}"
            done <<<"${target_types}"

            # Unset DETECTED_BASE to prevent cross-workspace leak
            unset DETECTED_BASE
        done
    else
        # No path_strategy — just sync targets (standard agents)
        while IFS= read -r target_type; do
            [[ -z "${target_type}" ]] && continue
            local source_type
            source_type=$(jq -r --arg a "${agent}" --arg t "${target_type}" '.agents[$a].targets[$t].source_type // $t' <<<"${MANIFEST_JSON}")
            log_info "Syncing ${target_type}..."
            sync_target "${agent}" "${target_type}" "${source_type}"
        done <<<"${target_types}"
    fi
}

# =============================================================================
# List available agents
# =============================================================================

list_agents() {
    log_section "Available Agents"

    local agents
    agents=$(jq -r '.agents | keys[]' <<<"${MANIFEST_JSON}")

    while IFS= read -r agent; do
        local enabled
        enabled=$(jq -r --arg a "${agent}" '.agents[$a].enabled' <<<"${MANIFEST_JSON}")
        local description
        description=$(jq -r --arg a "${agent}" '.agents[$a].description // ""' <<<"${MANIFEST_JSON}")

        local status_color="${RED}"
        local status_text="disabled"
        if [[ "${enabled}" == "true" ]]; then
            status_color="${GREEN}"
            status_text="enabled"
        fi

        # Check installation
        local install_color="${RED}"
        local install_text="not installed"
        if is_agent_installed "${agent}"; then
            install_color="${GREEN}"
            install_text="installed"
        fi

        echo -e "  ${CYAN}${agent}${NC} - ${description}" >&2
        echo -e "    Status: ${status_color}${status_text}${NC} | ${install_color}${install_text}${NC}" >&2
    done <<<"${agents}"
}

# =============================================================================
# Parse arguments
# =============================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --agent | -a)
                if [[ $# -lt 2 ]]; then
                    log_error "--agent requires an agent name"
                    exit 1
                fi
                SPECIFIC_AGENT="$2"
                shift 2
                ;;
            --dry-run | -n)
                DRY_RUN=true
                shift
                ;;
            --backup | -b)
                CREATE_BACKUP=true
                shift
                ;;
            --validate | -v)
                VALIDATE_FIRST=true
                shift
                ;;
            --list | -l)
                list_agents
                exit 0
                ;;
            --force | -f)
                # shellcheck disable=SC2034  # FORCE is consumed by lib/sync.sh (sourced)
                FORCE=true
                shift
                ;;
            --bootstrap-registry)
                BOOTSTRAP_REGISTRY=true
                shift
                ;;
            --debug | -d)
                export DEBUG=true
                shift
                ;;
            --help | -h)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --agent, -a <name>       Sync a specific agent only"
                echo "  --dry-run, -n             Show what would be done without executing"
                echo "  --backup, -b              Create backup before writing"
                echo "  --validate, -v            Validate configuration before syncing"
                echo "  --list, -l                List available agents"
                echo "  --force, -f               Bypass sync cache and force a full sync"
                echo "  --bootstrap-registry      Re-seed registry from deployed paths (clears existing)"
                echo "  --debug, -d               Show debug information"
                echo "  --help, -h                Show this help"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# =============================================================================
# Main
# =============================================================================

main() {
    # Check that manifest exists
    if [[ ! -f "${MANIFEST_FILE}" ]]; then
        log_error "Manifest not found: ${MANIFEST_FILE}"
        exit 1
    fi

    check_dependencies

    # Convert manifest YAML → JSON once; all subsequent reads use jq on this string
    # Must happen before parse_args so --list can call list_agents() with MANIFEST_JSON set
    MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

    parse_args "$@"

    # Get content directory from manifest (v2.0)
    CONTENT_DIR=$(resolve_content_dir "${REPO_ROOT}" "${MANIFEST_JSON}")

    # Initialize a fresh-run temp registry (used by both full and partial syncs).
    # For full syncs it seeds the persisted registry; for partial syncs it tracks
    # what the agent writes so cleanup_agent_stale_files can diff against it.
    if [[ -z "${SPECIFIC_AGENT}" ]]; then
        # --bootstrap-registry: discard existing registry so init_sync_registry
        # re-seeds it from the currently deployed paths (useful for recovery).
        if [[ "${BOOTSTRAP_REGISTRY}" == "true" ]]; then
            rm -f "${SYNC_REGISTRY}"
            log_info "Registry cleared — will bootstrap from deployed paths"
        fi
        init_sync_registry
    else
        # Partial sync: just create the temp tracking file (no global registry ops).
        mkdir -p "${SYNC_REGISTRY_DIR}"
        _SYNC_REGISTRY_NEW=$(mktemp)
    fi
    # Clean up temp file on error or interruption
    trap 'rm -f "${_SYNC_REGISTRY_NEW}"' EXIT INT TERM

    log_section "Agent Covenant - Sync v2.0"
    log_info "Manifest: ${MANIFEST_FILE}"
    log_info "Content: ${CONTENT_DIR}"
    log_info "Timestamp: ${TIMESTAMP}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "DRY-RUN mode enabled - no changes will be made"
    fi

    if [[ "${CREATE_BACKUP}" == "true" ]]; then
        log_info "Backups enabled"
    fi

    # Validate if requested
    if [[ "${VALIDATE_FIRST}" == "true" ]]; then
        log_info "Running validation..."
        if [[ -x "${SCRIPT_DIR}/validate.sh" ]]; then
            "${SCRIPT_DIR}/validate.sh" || exit 1
        else
            log_warn "validate.sh not found, skipping validation"
        fi
    fi

    if [[ -n "${SPECIFIC_AGENT}" ]]; then
        # Validate agent name format
        if ! [[ "${SPECIFIC_AGENT}" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            log_error "Invalid agent name: '${SPECIFIC_AGENT}' (only alphanumeric, hyphens and underscores)"
            exit 1
        fi
        # Sync specific agent
        sync_agent "${SPECIFIC_AGENT}"
    else
        # Sync all enabled agents
        local agents
        agents=$(jq -r '.agents | keys[]' <<<"${MANIFEST_JSON}")

        while IFS= read -r agent; do
            if is_agent_enabled "${agent}"; then
                sync_agent "${agent}"
            else
                log_debug "Skipping disabled agent: ${agent}"
            fi
        done <<<"${agents}"
    fi

    # Clean up stale files from previous syncs
    if [[ -z "${SPECIFIC_AGENT}" ]]; then
        log_section "Cleanup"
        cleanup_stale_files
        save_sync_registry
    else
        # Partial sync: clean stale files and empty dirs for this agent's targets only.
        # The global registry is not used/modified — we only prune what this agent owns.
        log_section "Cleanup (agent: ${SPECIFIC_AGENT})"
        cleanup_agent_stale_files "${SPECIFIC_AGENT}"
    fi

    echo "" >&2
    log_info "✓ Sync completed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
