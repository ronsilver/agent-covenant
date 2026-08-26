#!/usr/bin/env bash
# =============================================================================
# sync.sh (library) - Sync functions for agent-covenant
# This file is meant to be sourced by scripts/sync.sh, not executed directly.
# =============================================================================
# Requires: common.sh sourced first, and the following globals:
#   MANIFEST_FILE, CONTENT_DIR, DRY_RUN, CREATE_BACKUP, TIMESTAMP
#
# Performance optimizations applied:
#   1. MANIFEST_JSON: manifest parsed once at startup (1 yq call); all subsequent reads use jq on that string.
#   2. Per-file checksum cache: only files changed since last sync are re-processed.
#   3. sync_individual_impl: cache-hit files skip content generation entirely.
# =============================================================================

# =============================================================================
# Sync Registry — tracks managed files to detect and remove stale remnants
# =============================================================================

SYNC_REGISTRY_DIR="${HOME}/.config/agent-covenant"
SYNC_REGISTRY="${SYNC_REGISTRY_DIR}/.sync-registry"
_SYNC_REGISTRY_NEW=""

init_sync_registry() {
    mkdir -p "${SYNC_REGISTRY_DIR}"
    _SYNC_REGISTRY_NEW=$(mktemp)
    log_debug "Registry initialized: ${_SYNC_REGISTRY_NEW}"

    # First-run bootstrap: if no persisted registry exists, seed it from all
    # files currently deployed in every skill target path so that orphaned files
    # from a previous (un-tracked) deployment are picked up by cleanup_stale_files.
    if [[ ! -f "${SYNC_REGISTRY}" ]]; then
        log_info "No registry found — bootstrapping from deployed skill directories..."
        bootstrap_sync_registry
    fi
}

# Scan every directory-format skill target configured in the manifest and
# register all files found there into the PERSISTED registry (not the new-run
# temp file).  This lets cleanup_stale_files detect orphaned files on the very
# next sync even when the registry was never previously written.
bootstrap_sync_registry() {
    # No skills config (or no manifest) → nothing to seed.
    has_skill_directories || return 0
    # Directory-format targets (skills) write ONCE to the shared base, so the
    # bootstrap scan uses the shared skills dir (not per-agent `path` values).
    local skill_target_paths
    skill_target_paths=$(get_shared_write_path "skills" '{}')

    [[ -z "${skill_target_paths}" ]] && return 0

    local bootstrap_tmp
    bootstrap_tmp=$(mktemp)

    local valid_skill_dirs
    valid_skill_dirs=$(jq -r '.skills.directories[] // empty' <<<"${MANIFEST_JSON}" | sort -u)

    while IFS= read -r raw_path; do
        [[ -z "${raw_path}" ]] && continue
        local expanded_path
        expanded_path=$(expand_path "${raw_path}")
        [[ ! -d "${expanded_path}" ]] && continue
        while IFS= read -r deployed_file; do
            [[ -z "${deployed_file}" ]] && continue
            local rel_path="${deployed_file#"${expanded_path}"/}"
            local skill_name="${rel_path%%/*}"
            if printf '%s\n' "${valid_skill_dirs}" | grep -qxF "${skill_name}"; then
                printf '%s\n' "${deployed_file}" >>"${bootstrap_tmp}"
            fi
        done < <(find "${expanded_path}" -type f 2>/dev/null)
    done <<<"${skill_target_paths}"

    if [[ -s "${bootstrap_tmp}" ]]; then
        sort -u "${bootstrap_tmp}" >"${SYNC_REGISTRY}"
        local count
        count=$(wc -l <"${SYNC_REGISTRY}")
        log_info "Registry bootstrapped: ${count} file(s) registered from deployed paths"
    fi
    rm -f "${bootstrap_tmp}"
}

register_managed_file() {
    local file_path="$1"
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0
    echo "${file_path}" >>"${_SYNC_REGISTRY_NEW}"
}

cleanup_stale_files() {
    [[ ! -f "${SYNC_REGISTRY}" ]] && return 0
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0

    # comm -23 on sorted inputs yields lines in old registry but not new (stale).
    # This replaces an O(N) grep-per-file loop with a single sort+comm pass.
    local stale_count=0
    while IFS= read -r old_file; do
        [[ -z "${old_file}" ]] && continue
        [[ ! -f "${old_file}" ]] && continue
        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[DRY-RUN] Would remove stale: ${old_file}"
        else
            [[ "${CREATE_BACKUP}" == "true" ]] && backup_file "${old_file}"
            rm -f "${old_file}"
            log_warn "  ✗ Stale removed: ${old_file}"
        fi
        stale_count=$((stale_count + 1))
    done < <(comm -23 <(sort "${SYNC_REGISTRY}") <(sort "${_SYNC_REGISTRY_NEW}"))

    if [[ ${stale_count} -gt 0 ]]; then
        log_info "Cleanup: ${stale_count} stale file(s) removed"
    else
        log_debug "Cleanup: no stale files"
    fi

    # Prune empty directories left behind under every directory-format target.
    # This handles orphaned skill dirs that never had files tracked by the registry
    # (e.g. dirs created by a previous sync run that predates the registry, or dirs
    # whose files were all removed in the stale-file pass above).
    _prune_empty_skill_dirs

    # Prune stale skill directories whose names are NOT listed in
    # manifest.yaml skills.directories[]. This catches skills retired from
    # the manifest but still deployed on disk (with files that survived
    # the stale-file pass because they were never in the registry).
    _prune_stale_skill_dirs

    # Migration: shared:false claude-code targets no longer write the default
    # subagents dir or the shared hooks dir. Remove those dirs once empty (files
    # are already gone via the stale-file pass above; rmdir is a no-op when
    # non-empty, so a future transform:none subagents target is unaffected).
    local legacy_dir
    for legacy_dir in "${SYNC_REGISTRY_DIR}/subagents" "${SYNC_REGISTRY_DIR}/hooks"; do
        if [[ -d "${legacy_dir}" ]] && [[ -z "$(find "${legacy_dir}" -mindepth 1 2>/dev/null)" ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] Would remove empty legacy shared dir: ${legacy_dir}"
            else
                rmdir "${legacy_dir}" && log_warn "  ✗ Empty legacy shared dir removed: ${legacy_dir}"
            fi
        fi
    done
}

# Remove empty directories under every directory-format target path.
# Uses find -depth so child dirs are evaluated before parents, allowing
# a single pass to clean nested empty trees.
_prune_empty_skill_dirs() {
    has_skill_directories || return 0
    local skill_target_paths
    skill_target_paths=$(get_shared_write_path "skills" '{}')

    [[ -z "${skill_target_paths}" ]] && return 0

    local pruned=0
    while IFS= read -r raw_path; do
        [[ -z "${raw_path}" ]] && continue
        local expanded_path
        expanded_path=$(expand_path "${raw_path}")
        [[ ! -d "${expanded_path}" ]] && continue

        # Repeat passes until no more empty dirs are found. Using -depth ensures
        # deepest children are processed first, but after removal parents may
        # become empty and require a second pass.
        local pass_count
        while true; do
            pass_count=0
            while IFS= read -r empty_dir; do
                [[ -z "${empty_dir}" ]] && continue
                # Never remove the target root itself
                [[ "${empty_dir}" == "${expanded_path}" ]] && continue
                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[DRY-RUN] Would remove empty dir: ${empty_dir}"
                else
                    rmdir "${empty_dir}" 2>/dev/null && log_warn "  ✗ Empty dir removed: ${empty_dir}" || true
                fi
                pruned=$((pruned + 1))
                pass_count=$((pass_count + 1))
            done < <(find "${expanded_path}" -mindepth 1 -depth -type d -empty 2>/dev/null)
            # Stop when a full pass found nothing to remove
            [[ ${pass_count} -eq 0 ]] && break
        done
    done <<<"${skill_target_paths}"

    if [[ ${pruned} -gt 0 ]]; then
        log_info "Cleanup: ${pruned} empty director(ies) removed"
    else
        log_debug "Cleanup: no empty directories"
    fi
}

# Remove skill directories NOT listed in manifest's skills.directories[],
# even if they still contain files (unlike _prune_empty_skill_dirs which
# only handles empty dirs). This catches skills retired from manifest but
# still deployed on disk.
_prune_stale_skill_dirs() {
    has_skill_directories || return 0
    local dir_paths
    dir_paths=$(get_shared_write_path "skills" '{}')

    [[ -z "${dir_paths}" ]] && return 0

    local valid_dirs
    valid_dirs=$(jq -r '.skills.directories[] // empty' <<<"${MANIFEST_JSON}" | sort -u)
    [[ -z "${valid_dirs}" ]] && return 0

    local pruned=0
    while IFS= read -r raw_path; do
        [[ -z "${raw_path}" ]] && continue
        local expanded_path
        expanded_path=$(expand_path "${raw_path}")
        [[ ! -d "${expanded_path}" ]] && continue

        while IFS= read -r dir_entry; do
            [[ -z "${dir_entry}" ]] && continue
            local dir_name="${dir_entry##*/}"
            if ! printf '%s\n' "${valid_dirs}" | grep -qxF "${dir_name}"; then
                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[DRY-RUN] Would remove stale skill dir: ${dir_entry}"
                else
                    rm -rf "${dir_entry}"
                    log_warn "  ✗ Stale skill dir removed: ${dir_entry}"
                fi
                pruned=$((pruned + 1))
            fi
        done < <(find "${expanded_path}" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
    done <<<"${dir_paths}"

    if [[ ${pruned} -gt 0 ]]; then
        log_info "Cleanup: ${pruned} stale skill director(ies) removed"
    else
        log_debug "Cleanup: no stale skill directories"
    fi
}

# Partial-sync cleanup: remove deployed files/dirs for a specific agent that
# are no longer produced by the current sync run.
# Unlike cleanup_stale_files (global registry), this scans the agent's target
# paths directly and removes anything not registered in _SYNC_REGISTRY_NEW.
cleanup_agent_stale_files() {
    local agent="$1"
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0

    # Collect all target paths for this agent. Directory-format targets
    # (skills/subagents/hooks) map to the shared base — their real dir is a
    # symlink and find(1) does not traverse a symlinked start path. File-level
    # targets keep their literal path.
    local target_paths=""
    local target_types ttype
    target_types=$(jq -r --arg a "${agent}" '.agents[$a].targets | keys[]' <<<"${MANIFEST_JSON}" 2>/dev/null || true)
    while IFS= read -r ttype; do
        [[ -z "${ttype}" ]] && continue
        local tcfg
        tcfg=$(jq -r --arg a "${agent}" --arg t "${ttype}" '.agents[$a].targets[$t]' <<<"${MANIFEST_JSON}")
        case "${ttype}" in
            skills | subagents | hooks)
                local shared_t
                shared_t=$(jq -r 'if .shared == null then true else .shared end' <<<"${tcfg}")
                if [[ "${shared_t}" == "true" ]]; then
                    target_paths+="$(get_shared_write_path "${ttype}" "${tcfg}")"$'\n'
                else
                    # shared:false: scan the agent's real dirs (path for
                    # skills/subagents, scripts_path for hooks). Paths using
                    # ${DETECTED_BASE} are resolved per detected workspace HERE
                    # because sync.sh unsets DETECTED_BASE after each workspace
                    # (expand_path would otherwise yield /skills, /agents, /hooks
                    # — a silent no-op). Each emitted path is the FULL RESOLVED
                    # TARGET SUBDIR (e.g. ~/.claude/skills), NEVER the raw
                    # workspace base — downstream find+comm-23+rm (lib/sync.sh
                    # 269/264) must stay scoped to the subdir, not the workspace
                    # root (a base-level scan would delete user state: sessions/,
                    # plugins/, cache/, settings.local.json, .claude.json).
                    # Mirrors bootstrap-symlinks.sh resolve_agent_dirs
                    # (detect_all_agent_paths).
                    local rawp wbase
                    rawp=$(jq -r '.path // .scripts_path // empty' <<<"${tcfg}" 2>/dev/null || true)
                    if [[ "${rawp}" == *"\${DETECTED_BASE}"* ]]; then
                        while IFS= read -r wbase; do
                            [[ -n "${wbase}" ]] && target_paths+="$(expand_path "${rawp//\$\{DETECTED_BASE\}/${wbase}}")"$'\n'
                        done < <(detect_all_agent_paths "${agent}")
                    else
                        while IFS= read -r p; do
                            [[ -n "${p}" ]] && target_paths+="${p}"$'\n'
                        done < <(jq -r '.path // .scripts_path // empty, .paths[]? // empty' <<<"${tcfg}" 2>/dev/null || true)
                    fi
                fi
                ;;
            *)
                while IFS= read -r p; do
                    [[ -n "${p}" ]] && target_paths+="${p}"$'\n'
                done < <(jq -r '.path // empty, .paths[]? // empty' <<<"${tcfg}" 2>/dev/null || true)
                ;;
        esac
    done <<<"${target_types}"

    [[ -z "${target_paths}" ]] && return 0

    local stale_count=0
    while IFS= read -r raw_path; do
        [[ -z "${raw_path}" ]] && continue
        local expanded_path
        expanded_path=$(expand_path "${raw_path}")
        [[ ! -e "${expanded_path}" ]] && continue

        # comm -23 finds deployed files absent from the new registry (stale).
        while IFS= read -r deployed_file; do
            [[ -z "${deployed_file}" ]] && continue
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] Would remove stale: ${deployed_file}"
            else
                [[ "${CREATE_BACKUP}" == "true" ]] && backup_file "${deployed_file}"
                rm -f "${deployed_file}"
                log_warn "  ✗ Stale removed: ${deployed_file}"
            fi
            stale_count=$((stale_count + 1))
        done < <(comm -23 \
            <(find "${expanded_path}" -type f 2>/dev/null | sort) \
            <(sort "${_SYNC_REGISTRY_NEW}"))
    done <<<"${target_paths}"

    if [[ ${stale_count} -gt 0 ]]; then
        log_info "Cleanup: ${stale_count} stale file(s) removed for agent '${agent}'"
    else
        log_debug "Cleanup: no stale files for agent '${agent}'"
    fi

    # Prune empty dirs left behind under this agent's directory targets.
    # Directory content lives in the shared base (skills dir), not per-agent.
    local dir_target_paths
    dir_target_paths=$(get_shared_write_path "skills" '{}')

    if [[ -n "${dir_target_paths}" ]]; then
        local pruned=0
        while IFS= read -r raw_path; do
            [[ -z "${raw_path}" ]] && continue
            local expanded_path
            expanded_path=$(expand_path "${raw_path}")
            [[ ! -d "${expanded_path}" ]] && continue
            local pass_count
            while true; do
                pass_count=0
                while IFS= read -r empty_dir; do
                    [[ -z "${empty_dir}" ]] && continue
                    [[ "${empty_dir}" == "${expanded_path}" ]] && continue
                    if [[ "${DRY_RUN}" == "true" ]]; then
                        log_info "[DRY-RUN] Would remove empty dir: ${empty_dir}"
                    else
                        rmdir "${empty_dir}" 2>/dev/null && log_warn "  ✗ Empty dir removed: ${empty_dir}" || true
                    fi
                    pruned=$((pruned + 1))
                    pass_count=$((pass_count + 1))
                done < <(find "${expanded_path}" -mindepth 1 -depth -type d -empty 2>/dev/null)
                [[ ${pass_count} -eq 0 ]] && break
            done
        done <<<"${dir_target_paths}"
        [[ ${pruned} -gt 0 ]] && log_info "Cleanup: ${pruned} empty director(ies) removed for agent '${agent}'"
    fi

    # Prune stale skill directories for this agent (same check: dir name not in manifest)
    _prune_stale_skill_dirs
}

save_sync_registry() {
    [[ -z "${_SYNC_REGISTRY_NEW}" ]] && return 0

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_debug "[DRY-RUN] Registry not saved"
        rm -f "${_SYNC_REGISTRY_NEW}"
        return 0
    fi

    sort -u "${_SYNC_REGISTRY_NEW}" >"${SYNC_REGISTRY}"
    rm -f "${_SYNC_REGISTRY_NEW}"
    log_debug "Registry saved: ${SYNC_REGISTRY} ($(wc -l <"${SYNC_REGISTRY}") files)"
}

# Get list of files for a type (rules, workflows, prompts)
# Usage: get_source_files "rules" [agent_name]
#
# Performance: 1 yq call at startup converts YAML→JSON (MANIFEST_JSON).
# All reads here use jq on that in-memory string — zero extra processes per entry.
get_source_files() {
    local type="$1"
    local filter_agent="${2:-}"
    local source_dir
    source_dir=$(jq -r ".${type}.source_dir // \"${type}\"" <<<"${MANIFEST_JSON}")

    # One jq call → one compact JSON line per entry:
    #   "path/to/file.md"                                  (string entry)
    #   {"path":"...","agents":["a","b"]}                  (object entry)
    while IFS= read -r entry; do
        [[ -z "${entry}" ]] && continue

        local file_path agent_list=""
        if [[ "${entry}" == \"* ]]; then
            # String entry — strip surrounding quotes
            file_path="${entry%\"}"
            file_path="${file_path#\"}"
        else
            # Object entry — extract path and agents with inline jq
            file_path=$(jq -r '.path // ""' <<<"${entry}")
            agent_list=$(jq -r '.agents // [] | join(",")' <<<"${entry}")
        fi

        [[ -z "${file_path}" ]] && continue

        # Apply agent filter if this entry is restricted to specific agents
        if [[ -n "${filter_agent}" ]] && [[ -n "${agent_list}" ]]; then
            if ! echo ",${agent_list}," | grep -q ",${filter_agent},"; then
                log_debug "  Skipped (agent filter): ${file_path} (not for ${filter_agent})"
                continue
            fi
        fi

        local full_path="${CONTENT_DIR}/${source_dir}/${file_path}"
        if [[ -f "${full_path}" ]]; then
            echo "${full_path}"
        else
            log_warn "File not found: ${full_path}"
        fi
    done < <(jq -c ".${type}.files[]? // empty" <<<"${MANIFEST_JSON}" 2>/dev/null)
}

# Get list of skill directories
get_source_skill_dirs() {
    local source_dir
    source_dir=$(jq -r '.skills.source_dir // "skills"' <<<"${MANIFEST_JSON}")

    while IFS= read -r dir_name; do
        [[ -z "${dir_name}" ]] && continue
        local full_path="${CONTENT_DIR}/${source_dir}/${dir_name}"
        if [[ -d "${full_path}" ]]; then
            echo "${full_path}"
        else
            log_warn "Skill directory not found: ${full_path}"
        fi
    done < <(jq -r '.skills.directories[]? // empty' <<<"${MANIFEST_JSON}" 2>/dev/null)
}

# Get source MCP file
get_source_mcp_file() {
    local source_dir
    source_dir=$(jq -r '.mcp.source_dir // "mcp"' <<<"${MANIFEST_JSON}")

    local mcp_file
    mcp_file=$(jq -r '.mcp.file // "mcp.json"' <<<"${MANIFEST_JSON}")

    local full_path="${CONTENT_DIR}/${source_dir}/${mcp_file}"
    if [[ -f "${full_path}" ]]; then
        echo "${full_path}"
    else
        log_warn "MCP file not found: ${full_path}"
    fi
}

# Setup required directories for MCP servers
# Extracts file paths from env variables and creates parent directories
setup_mcp_directories() {
    local source_file
    source_file=$(get_source_mcp_file)

    if [[ -z "${source_file}" || ! -f "${source_file}" ]]; then
        return 0
    fi

    log_debug "Setting up MCP directories..."

    # Extract all env values that look like file paths (contain .json, .db, etc.)
    local file_paths
    # shellcheck disable=SC2016  # single quotes intentional: searching for literal ${...} patterns
    file_paths=$(grep -o '\${[^}]*}[^"]*\.[a-z]*' "${source_file}" 2>/dev/null || true)

    while IFS= read -r path_template; do
        [[ -z "${path_template}" ]] && continue

        # Expand environment variables in the path
        local expanded_path
        expanded_path=$(expand_vars_in_string "${path_template}")

        # Skip if still contains unexpanded variables
        if [[ "${expanded_path}" =~ \$\{ ]]; then
            continue
        fi

        # Get directory path (remove filename)
        local dir_path
        dir_path=$(dirname "${expanded_path}")

        # Create directory if it doesn't exist
        if [[ ! -d "${dir_path}" ]]; then
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_info "[DRY-RUN] Would create directory: ${dir_path}"
            else
                mkdir -p "${dir_path}"
                log_info "  ✓ Created MCP directory: ${dir_path}"
            fi
        else
            log_debug "  Directory exists: ${dir_path}"
        fi
    done <<<"${file_paths}"
}

# =============================================================================
# Sync functions
# =============================================================================

# Get target paths for a target
# target_config is the pre-extracted JSON object for this target
get_target_paths() {
    local target_config="$1"
    local result_paths=()

    # Single path
    local single_path
    single_path=$(jq -r '.path // ""' <<<"${target_config}")
    if [[ -n "${single_path}" && "${single_path}" != "null" ]]; then
        result_paths+=("$(expand_path "${single_path}")")
    fi

    # Multiple paths
    local multi_paths
    multi_paths=$(jq -r '.paths[]? // empty' <<<"${target_config}" 2>/dev/null || true)
    if [[ -n "${multi_paths}" ]]; then
        while IFS= read -r p; do
            result_paths+=("$(expand_path "${p}")")
        done <<<"${multi_paths}"
    fi

    # Glob paths
    local glob_paths
    glob_paths=$(jq -r '.glob_paths[]? // empty' <<<"${target_config}" 2>/dev/null || true)
    if [[ -n "${glob_paths}" ]]; then
        while IFS= read -r pattern; do
            local expanded_pattern
            expanded_pattern=$(expand_path "${pattern}")
            # Isolated subshell with nullglob for safe glob expansion
            local matched
            matched=$(bash -c 'shopt -s nullglob; for d in '"${expanded_pattern}"'; do printf "%s\n" "$d"; done')
            if [[ -n "${matched}" ]]; then
                while IFS= read -r d; do
                    result_paths+=("${d}")
                done <<<"${matched}"
            fi
        done <<<"${glob_paths}"
    fi

    if [[ ${#result_paths[@]} -gt 0 ]]; then
        printf '%s\n' "${result_paths[@]}"
    fi
}

# Shared base root for directory-format targets (skills/subagents/hooks).
# Directory content is written ONCE here; each agent's real dir (target `path`)
# is a symlink into it (created by scripts/bootstrap-symlinks.sh after sync).
# Reads the manifest's top-level `shared_base` key, defaulting to the canonical
# ${HOME}/.config/agent-covenant when absent.
get_shared_base() {
    local sb=""
    if [[ -n "${MANIFEST_JSON}" ]]; then
        sb=$(jq -r '.shared_base // ""' <<<"${MANIFEST_JSON}" 2>/dev/null || true)
    fi
    if [[ -z "${sb}" || "${sb}" == "null" ]]; then
        sb="${HOME}/.config/agent-covenant"
    fi
    expand_path "${sb}"
}

# Shared write path for a directory-format target.
#   $1 target_type  (skills | subagents | hooks)
#   $2 target_config JSON object (may be "{}" for registry scans)
# Write dir = ${shared_base}/<target_type> when transform is none (default);
# ${shared_base}/<target_type>-<transform> otherwise (e.g. subagents-strip,
# subagents-opencode). The transform suffix keeps differently-transformed
# copies of the same content type apart.
get_shared_write_path() {
    local target_type="$1"
    local target_config="$2"
    local sb tr
    sb=$(get_shared_base)
    tr=$(jq -r '.transform // "none"' <<<"${target_config}" 2>/dev/null || true)
    if [[ -z "${tr}" || "${tr}" == "null" ]]; then
        tr="none"
    fi
    if [[ "${tr}" == "none" ]]; then
        printf '%s\n' "${sb}/${target_type}"
    else
        printf '%s\n' "${sb}/${target_type}-${tr}"
    fi
}

# True (exit 0) when the manifest defines at least one skill directory to deploy.
# Used by the registry/prune scans so they no-op when there is no skills config
# (or no manifest at all — e.g. unit tests calling cleanup directly).
has_skill_directories() {
    [[ -n "${MANIFEST_JSON}" ]] || return 1
    jq -e '.skills.directories | length > 0' <<<"${MANIFEST_JSON}" >/dev/null 2>&1
}

# Write file with backup and dry-run support
# Usage: write_sync_file <dest_path> <content> [source_file]
#   source_file: when provided, its checksum is saved to the per-file cache on write.
write_sync_file() {
    local final_path="$1"
    local content="$2"
    local source_file="${3:-}"
    local agent="${4:-}"

    # ALWAYS register the file in the sync registry (even if unchanged)
    register_managed_file "${final_path}"

    # Skip if content unchanged (compare by checksum for robustness)
    if [[ -f "${final_path}" ]]; then
        local existing_hash new_hash
        existing_hash=$(file_hash "${final_path}")
        new_hash=$(printf '%s\n' "${content}" | file_hash)
        if [[ "${existing_hash}" == "${new_hash}" ]]; then
            log_debug "  Unchanged: ${final_path}"
            # Still update source cache: file was processed, even if dest unchanged
            if [[ "${DRY_RUN}" != "true" && -n "${source_file}" && -n "${agent}" ]]; then
                save_file_cache "${agent}" "${source_file}"
            fi
            return 0
        fi
    fi

    # Backup ONLY if there is a real change
    if [[ "${CREATE_BACKUP}" == "true" ]]; then
        backup_file "${final_path}"
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        if [[ "${QUIET_SYNC:-false}" == "true" ]]; then
            log_debug "[DRY-RUN] Would write to: ${final_path}"
        else
            log_info "[DRY-RUN] Would write to: ${final_path}"
        fi
        show_diff "${final_path}" "${content}"
    else
        mkdir -p "$(dirname "${final_path}")"
        printf '%s\n' "${content}" >"${final_path}"
        if [[ "${QUIET_SYNC:-false}" == "true" ]]; then
            log_debug "  → ${final_path}"
        else
            log_info "  → ${final_path}"
        fi
        if [[ -n "${source_file}" && -n "${agent}" ]]; then save_file_cache "${agent}" "${source_file}"; fi
    fi
}

# Transform frontmatter for agents that require it (e.g. Claude Code .mdc-style headers)
transform_file_frontmatter() {
    local source_file="$1"
    local agent="$2"
    local target_config="$3"

    # Get the agent's header template
    local header_template
    header_template=$(jq -r '.header // ""' <<<"${target_config}")

    # Extract source file name (without extension or path)
    local file_name
    file_name=$(basename "${source_file}" .md)

    # Generate new frontmatter based on the agent's template
    local new_header
    new_header=$(awk -v name="${file_name}" -v ts="${TIMESTAMP}" '{
        gsub(/\{\{name\}\}/, name); gsub(/\{\{timestamp\}\}/, ts); print
    }' <<<"${header_template}")

    # Combine: new frontmatter + content without original frontmatter
    printf '%s\n' "${new_header}"
    extract_content "${source_file}"
}

# Transform subagent frontmatter to opencode-native format.
# Preserves v2 subagent metadata so that OpenCode can enforce mode/tools/model.
# Extracts `description`, `permissionMode`, `tools`, and `model` from source YAML
# frontmatter and emits:
#   ---
#   description: <extracted>
#   mode: subagent
#   permissionMode: <read|build|full>
#   mode: subagent (default for all subagents)
#   permission:
#     read: allow | ask | deny
#     edit: allow | ask | deny
#     ...
#   model: <model-id>
#   ---
#   <body without original frontmatter>
opencode_subagent_transform() {
    local source_file="$1"

    local body default_desc
    body=$(extract_content "${source_file}")
    default_desc=$(printf '%s\n' "${body}" | head -5 | grep -m1 "^# " | sed 's/^# //' || true)

    local content_desc=""
    local permission_mode=""
    local mode=""
    local permission=""
    local model=""
    local hidden=""
    if has_frontmatter "${source_file}"; then
        content_desc=$(awk '
            BEGIN { in_fm=0 }
            NR==1 && /^---$/ { in_fm=1; next }
            in_fm && /^---$/ { exit }
            in_fm && /^description:/ {
                sub(/^description:[[:space:]]*"?/, "")
                sub(/"?[[:space:]]*$/, "")
                print
                exit
            }
        ' "${source_file}")

        permission_mode=$(awk '
            BEGIN { in_fm=0 }
            NR==1 && /^---$/ { in_fm=1; next }
            in_fm && /^---$/ { exit }
            in_fm && /^permissionMode:/ {
                sub(/^permissionMode:[[:space:]]*/, "")
                print
                exit
            }
        ' "${source_file}")

        mode=$(awk '
            BEGIN { in_fm=0 }
            NR==1 && /^---$/ { in_fm=1; next }
            in_fm && /^---$/ { exit }
            in_fm && /^mode:/ {
                sub(/^mode:[[:space:]]*/, "")
                print
                exit
            }
        ' "${source_file}")

        permission=$(awk '
            BEGIN { in_fm=0; collect=0; buf="" }
            NR==1 && /^---$/ { in_fm=1; next }
            in_fm && /^---$/ { if (collect) print buf; exit }
            in_fm && /^permission:/ {
                collect=1
                buf=$0 "\n"
                next
            }
            collect {
                buf=buf $0 "\n"
            }
        ' "${source_file}")

        model=$(awk '
            BEGIN { in_fm=0 }
            NR==1 && /^---$/ { in_fm=1; next }
            in_fm && /^---$/ { exit }
            in_fm && /^model:/ {
                sub(/^model:[[:space:]]*/, "")
                print
                exit
            }
        ' "${source_file}")

        hidden=$(awk '
            BEGIN { in_fm=0 }
            NR==1 && /^---$/ { in_fm=1; next }
            in_fm && /^---$/ { exit }
            in_fm && /^hidden:/ {
                sub(/^hidden:[[:space:]]*/, "")
                print
                exit
            }
        ' "${source_file}")
    fi

    local desc="${content_desc:-${default_desc}}"

    {
        printf '%s\n' "---"
        [[ -n "${desc}" ]] && printf 'description: %s\n' "${desc}"
        printf 'mode: %s\n' "${mode:-subagent}"
        [[ -n "${permission_mode}" ]] && printf 'permissionMode: %s\n' "${permission_mode}"
        if [[ -n "${permission}" ]]; then
            printf '%s\n' "${permission}"
        fi
        [[ -n "${model}" ]] && printf 'model: %s\n' "${model}"
        [[ -n "${hidden}" ]] && printf 'hidden: %s\n' "${hidden}"
        printf '%s\n' "---"
        printf '%s\n' "${body}"
    }
}

# Resolve source files for a merged target.
# If target_config has source_files[], use those (kernel mode — bypass global rules.files).
# Otherwise fall back to get_source_files() (standard merge mode).
get_merged_source_files() {
    local agent="$1"
    local source_type="$2"
    local target_config="$3"

    local explicit_sources
    explicit_sources=$(jq -r '.source_files[]? // empty' <<<"${target_config}" 2>/dev/null || true)

    if [[ -n "${explicit_sources}" ]]; then
        local source_dir
        source_dir=$(jq -r ".${source_type}.source_dir // \"${source_type}\"" <<<"${MANIFEST_JSON}")
        while IFS= read -r sf; do
            [[ -z "${sf}" ]] && continue
            local full_path="${CONTENT_DIR}/${source_dir}/${sf}"
            if [[ -f "${full_path}" ]]; then
                echo "${full_path}"
            else
                log_warn "source_files entry not found: ${full_path}"
            fi
        done <<<"${explicit_sources}"
    else
        get_source_files "${source_type}" "${agent}"
    fi
}

# Sync in merged format (single file with all content)
sync_merged_impl() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"
    local target_config="$4" # JSON object of this target's config

    local strip_frontmatter
    strip_frontmatter=$(jq -r '.strip_frontmatter // false' <<<"${target_config}")

    local header
    header=$(jq -r '.header // ""' <<<"${target_config}" |
        awk -v ts="${TIMESTAMP}" '{ gsub(/\{\{timestamp\}\}/, ts); print }')

    local output_filename
    output_filename=$(jq -r '.output_filename // ""' <<<"${target_config}")

    # Generate content — collect source files and check per-file cache
    local content=""
    local source_files=()
    local any_changed=false

    if [[ -n "${header}" && "${header}" != "null" ]]; then
        content="${header}"
    fi

    local first=true
    while IFS= read -r source_file; do
        [[ -z "${source_file}" ]] && continue
        source_files+=("${source_file}")

        # Track whether any source changed since last sync
        if [[ "${FORCE}" == "true" ]] || file_cache_changed "${agent}" "${source_file}"; then
            any_changed=true
        fi

        if [[ "${first}" == "true" ]]; then
            first=false
        else
            content+=$'\n\n---\n\n'
        fi

        if [[ "${strip_frontmatter}" == "true" ]]; then
            content+=$(extract_content "${source_file}")
        else
            content+=$(cat "${source_file}")
        fi
    done < <(get_merged_source_files "${agent}" "${source_type}" "${target_config}")

    # Edge case: no source files resolved (e.g. unknown source_type, missing source_dir).
    # Exit early to avoid unbound variable errors with bash set -u (nounset).
    if [[ ${#source_files[@]} -eq 0 ]]; then
        log_warn "No source files resolved for ${agent}/${source_type} — skipping"
        return 0
    fi

    # Get target paths
    local target_paths
    target_paths=$(get_target_paths "${target_config}")

    # If no source changed, just register destination files and skip writing
    if [[ "${any_changed}" == "false" ]] && [[ ${#source_files[@]} -gt 0 ]]; then
        log_debug "  Cache hit (all sources unchanged): ${agent}/${target_type}"
        local dest_missing=false
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            local expanded_target
            expanded_target=$(expand_path "${target_path}")
            local cached_final="${expanded_target}"
            if [[ -d "${expanded_target}" || "${expanded_target}" != *".md" ]]; then
                if [[ -n "${output_filename}" && "${output_filename}" != "null" ]]; then
                    cached_final="${expanded_target}/${output_filename}"
                else
                    cached_final="${expanded_target}/rules.md"
                fi
            fi
            [[ ! -f "${cached_final}" ]] && dest_missing=true
            register_managed_file "${cached_final}"
        done <<<"${target_paths}"
        [[ "${dest_missing}" == "false" ]] && return 0
    fi

    while IFS= read -r target_path; do
        [[ -z "${target_path}" ]] && continue
        local final_path="${target_path}"

        if [[ -d "${target_path}" || "${target_path}" != *".md" ]]; then
            mkdir -p "${target_path}"
            if [[ -n "${output_filename}" && "${output_filename}" != "null" ]]; then
                final_path="${target_path}/${output_filename}"
            else
                final_path="${target_path}/rules.md"
            fi
        fi

        write_sync_file "${final_path}" "${content}"
    done <<<"${target_paths}"

    # Update per-file cache for all source files after writing
    if [[ "${DRY_RUN}" != "true" ]]; then
        for sf in "${source_files[@]}"; do
            save_file_cache "${agent}" "${sf}"
        done
    fi
}

# Sync in directory format (copy entire skill directories)
sync_directory_impl() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"
    local target_config="$4"

    # shared:true — content is written ONCE to the shared base and the agent's
    # real dir is symlinked into it by scripts/bootstrap-symlinks.sh. shared:false
    # (e.g. claude-code) — content is written to the agent's real dir (per
    # detected workspace when path uses ${DETECTED_BASE}).
    local shared
    shared=$(jq -r 'if .shared == null then true else .shared end' <<<"${target_config}")
    local target_paths
    if [[ "${shared}" == "true" ]]; then
        target_paths=$(get_shared_write_path "${target_type}" "${target_config}")
    else
        target_paths=$(get_target_paths "${target_config}")
    fi

    # Pre-collect all source skill files in ONE find call, grouped by skill dir.
    # Avoids 112 separate find forks (one per skill dir) — each fork adds ~10ms on macOS.
    local skills_source_root
    skills_source_root="${CONTENT_DIR}/$(jq -r '.skills.source_dir // "skills"' <<<"${MANIFEST_JSON}")"
    local _skill_file_cache=""
    _skill_file_cache=$(mktemp -d)
    while IFS= read -r f; do
        local _rel="${f#"${skills_source_root}/"}"
        local _skill="${_rel%%/*}"
        echo "${f}" >>"${_skill_file_cache}/${_skill}"
    done < <(find "${skills_source_root}" -mindepth 2 -type f -not -path '*/workspace/*' 2>/dev/null)

    while IFS= read -r source_dir; do
        [[ -z "${source_dir}" ]] && continue

        local skill_name="${source_dir##*/}"

        # Verify SKILL.md exists in the source directory
        if [[ ! -f "${source_dir}/SKILL.md" ]]; then
            log_warn "SKILL.md not found in: ${source_dir} — skipping"
            continue
        fi

        # Copy to each target directory
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            # Migration verb for shared:false: drop a stale symlink into the
            # shared base so the real per-agent dir is created (idempotent;
            # order-independent with bootstrap-symlinks.sh).
            if [[ "${shared}" != "true" ]] && [[ -L "${target_path}" ]]; then
                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[DRY-RUN] Would remove symlink: ${target_path}"
                else
                    rm -f "${target_path}"
                    log_warn "  ✗ Symlink removed (shared:false target): ${target_path}"
                fi
            fi
            # Handle broken symlinks: if target_path or any component is a
            # dangling symlink, remove it first so mkdir -p can create real dirs.
            local _check="${target_path}"
            while [[ -L "${_check}" ]]; do
                local _link_target
                _link_target=$(readlink "${_check}")
                if [[ ! -d "${_link_target}" ]] && [[ ! -e "${_link_target}" ]]; then
                    rm -f "${_check}"
                    break
                fi
                _check="${_link_target}"
            done
            mkdir -p "${target_path}"
            local dest_dir="${target_path}/${skill_name}"

            if [[ "${DRY_RUN}" == "true" ]]; then
                if [[ "${QUIET_SYNC:-false}" == "true" ]]; then
                    log_debug "[DRY-RUN] Would copy directory: ${source_dir} → ${dest_dir}"
                else
                    log_info "[DRY-RUN] Would copy directory: ${source_dir} → ${dest_dir}"
                fi
                continue
            fi

            # Create target and copy recursively
            mkdir -p "${dest_dir}"

            # Sync skill files preserving structure
            local changed=false
            while IFS= read -r src_file; do
                local rel_path="${src_file#"${source_dir}"/}"
                local dest_file="${dest_dir}/${rel_path}"

                # Fast path: if dest exists and source unchanged since last sync, skip both
                # sha256 forks entirely. Falls through when dest is missing or source changed.
                # dest_file_dir is intentionally deferred past this check — dirname() is an
                # expensive subprocess fork that we must avoid for the 99% unchanged-file case.
                if [[ -f "${dest_file}" ]] && ! file_cache_changed "${agent}" "${src_file}"; then
                    log_debug "  Unchanged: ${dest_file}"
                    register_managed_file "${dest_file}"
                    continue
                fi

                # Only compute dest dir here (slow path — file is new or changed)
                local dest_file_dir="${dest_file%/*}"

                # Slow path: source may have changed; compare dest checksum to avoid
                # unnecessary writes when only mtime changed but content is same.
                if [[ -f "${dest_file}" ]]; then
                    local src_hash dest_hash
                    src_hash=$(file_hash "${src_file}")
                    dest_hash=$(file_hash "${dest_file}")
                    if [[ "${src_hash}" == "${dest_hash}" ]]; then
                        log_debug "  Unchanged: ${dest_file}"
                        register_managed_file "${dest_file}"
                        [[ "${DRY_RUN}" != "true" ]] && save_file_cache "${agent}" "${src_file}"
                        continue
                    fi
                fi

                changed=true

                if [[ "${CREATE_BACKUP}" == "true" ]]; then
                    backup_file "${dest_file}"
                fi

                mkdir -p "${dest_file_dir}"
                cp "${src_file}" "${dest_file}"
                log_debug "  → ${dest_file}"
                register_managed_file "${dest_file}"
                save_file_cache "${agent}" "${src_file}"
            done <"${_skill_file_cache}/${skill_name}"

            if [[ "${changed}" != "true" ]]; then
                log_debug "  Unchanged: ${dest_dir}/"
            else
                if [[ "${QUIET_SYNC:-false}" == "true" ]]; then
                    log_debug "  → ${dest_dir}/"
                else
                    log_info "  → ${dest_dir}/"
                fi
            fi
        done <<<"${target_paths}"
    done < <(get_source_skill_dirs)
    rm -rf "${_skill_file_cache}"
}

# Sync MCP configuration file
sync_json_impl() {
    local agent="$1"
    local target_type="$2"
    local target_config="$3"

    # Check if agent specifies a custom source file
    local custom_source_file
    custom_source_file=$(jq -r '.source_file // ""' <<<"${target_config}")

    local source_file
    if [[ -n "${custom_source_file}" && "${custom_source_file}" != "null" ]]; then
        # Use custom source file for this agent
        local source_dir
        source_dir=$(jq -r '.mcp.source_dir // "mcp"' <<<"${MANIFEST_JSON}")
        source_file="${CONTENT_DIR}/${source_dir}/${custom_source_file}"
        log_debug "Using custom MCP source file: ${custom_source_file}"
    else
        # Use default MCP file
        source_file=$(get_source_mcp_file)
    fi

    if [[ -z "${source_file}" || ! -f "${source_file}" ]]; then
        log_debug "No MCP source file found"
        return 0
    fi

    # Setup required directories before syncing
    setup_mcp_directories

    # Get target paths
    local target_paths
    target_paths=$(get_target_paths "${target_config}")

    # Load MCP env file if present (repo-local .env or ~/.mcp.env)
    local mcp_source_dir
    mcp_source_dir=$(jq -r '.mcp.source_dir // "mcp"' <<<"${MANIFEST_JSON}")
    local env_file="${CONTENT_DIR}/${mcp_source_dir}/.env"
    if [[ -f "${env_file}" ]]; then
        set -a
        # shellcheck source=/dev/null
        source "${env_file}"
        set +a
        log_debug "Loaded MCP env: ${env_file}"
    elif [[ -f "${HOME}/.mcp.env" ]]; then
        set -a
        # shellcheck source=/dev/null
        source "${HOME}/.mcp.env"
        set +a
        log_debug "Loaded MCP env: ${HOME}/.mcp.env"
    fi

    # Read and process JSON content, expanding all ${VAR} placeholders
    local json_content
    json_content=$(expand_vars_in_string "$(cat "${source_file}")")
    log_debug "Expanded env vars in MCP config"

    # Portability policy: keep command names as declared in the canonical
    # source (bare binaries like "npx", "uvx", "go") so configs work on any
    # Mac/Linux regardless of install manager (homebrew, mise, asdf). Do NOT
    # resolve them to absolute paths here — that couples configs to the PATH
    # of the sync machine and breaks on other machines. Do NOT inject a
    # literal PATH into every server environment either; server processes
    # inherit the agent runtime's environment, and hardcoded PATH values go
    # stale when toolchains move.

    local merge_key
    merge_key=$(jq -r '.merge_key // ""' <<<"${target_config}")

    if [[ -n "${merge_key}" && "${merge_key}" != "null" ]]; then
        # Merge mode: update only the specified key, preserving existing config
        log_debug "Merge mode enabled for key: ${merge_key}"
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            local expanded_target
            expanded_target=$(expand_path "${target_path}")
            local final_content="${json_content}"
            if [[ -f "${expanded_target}" ]]; then
                local clean_json
                clean_json=$(yq -o json '.' "${expanded_target}" 2>/dev/null || cat "${expanded_target}")
                final_content=$(jq -s --arg k "${merge_key}" '.[0] + {($k): .[1][$k]}' <(printf '%s\n' "${clean_json}") <(printf '%s\n' "${json_content}"))
            fi

            local inject_json
            inject_json=$(jq -c '.inject_keys // {}' <<<"${target_config}")
            if [[ "${inject_json}" != "{}" ]]; then
                final_content=$(jq -s --argjson inj "${inject_json}" '.[0] + $inj' <(printf '%s\n' "${final_content}"))
            fi
            write_sync_file "${expanded_target}" "${final_content}" "${source_file}" "${agent}"
        done <<<"${target_paths}"
    else
        # Overwrite mode (default): write full content as-is
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            local expanded_target
            expanded_target=$(expand_path "${target_path}")
            write_sync_file "${expanded_target}" "${json_content}" "${source_file}" "${agent}"
        done <<<"${target_paths}"
    fi
}

# Sync in individual format (one file per rule/workflow)
sync_individual_impl() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"
    local target_config="$4" # JSON object of this target's config

    local output_extension
    output_extension=$(jq -r '.output_extension // ".md"' <<<"${target_config}")

    # Single transform enum (none|strip|opencode|header). Legacy keys
    # (strip_frontmatter/transform_frontmatter) map onto it for backward
    # compatibility — the gate rejects them in manifests, but old test
    # fixtures still exercise them.
    local transform
    transform=$(jq -r '.transform // ""' <<<"${target_config}")
    if [[ -z "${transform}" || "${transform}" == "null" ]]; then
        local tf_legacy sf_legacy
        tf_legacy=$(jq -r '.transform_frontmatter // false' <<<"${target_config}")
        sf_legacy=$(jq -r '.strip_frontmatter // false' <<<"${target_config}")
        if [[ "${tf_legacy}" == "opencode" ]]; then
            transform="opencode"
        elif [[ "${tf_legacy}" == "true" ]]; then
            transform="header"
        elif [[ "${sf_legacy}" == "true" ]]; then
            transform="strip"
        else
            transform="none"
        fi
    fi

    # Get target paths. subagents: shared:true writes ONCE to the shared base
    # (real dir symlinked in by bootstrap-symlinks.sh); shared:false (claude-code)
    # writes to the agent's real dir, per detected workspace. Other individual
    # targets (e.g. workflows) stay per-agent.
    local shared
    shared=$(jq -r 'if .shared == null then true else .shared end' <<<"${target_config}")
    local target_paths
    if [[ "${target_type}" == "subagents" && "${shared}" == "true" ]]; then
        target_paths=$(get_shared_write_path "${target_type}" "${target_config}")
    else
        target_paths=$(get_target_paths "${target_config}")
    fi

    while IFS= read -r source_file; do
        [[ -z "${source_file}" ]] && continue

        # Skip if file unchanged since last sync (per-file cache)
        if [[ "${FORCE}" == "false" ]] && ! file_cache_changed "${agent}" "${source_file}"; then
            log_debug "  Cache hit (unchanged): ${source_file}"
            local _bn="${source_file##*/}"
            local base_name_cached="${_bn%.md}"
            # A2 guard: the cache key is agent:source — identical for both
            # claude-code workspaces. Register the dest, but fall through to the
            # write path when the dest file is missing (e.g. 2nd workspace never
            # written, or dir deleted) so it gets (re)created.
            local dest_missing=false
            while IFS= read -r target_path; do
                [[ -z "${target_path}" ]] && continue
                local cached_final="${target_path}/${base_name_cached}${output_extension}"
                register_managed_file "${cached_final}"
                [[ ! -f "${cached_final}" ]] && dest_missing=true
            done <<<"${target_paths}"
            [[ "${dest_missing}" == "false" ]] && continue
        fi

        # Derive output file name from source
        local _bn="${source_file##*/}"
        local base_name="${_bn%.md}"
        local file_content

        if [[ "${transform}" == "header" ]]; then
            file_content=$(transform_file_frontmatter "${source_file}" "${agent}" "${target_config}")
        elif [[ "${transform}" == "opencode" ]]; then
            file_content=$(opencode_subagent_transform "${source_file}")
        elif [[ "${transform}" == "strip" ]]; then
            file_content=$(extract_content "${source_file}")
        else
            file_content=$(cat "${source_file}")
        fi

        # Write to each target directory
        while IFS= read -r target_path; do
            [[ -z "${target_path}" ]] && continue
            # Migration verb for shared:false subagents: drop a stale symlink
            # into the shared base so the real per-agent dir is created
            # (idempotent; order-independent with bootstrap-symlinks.sh).
            if [[ "${shared}" != "true" ]] && [[ -L "${target_path}" ]]; then
                if [[ "${DRY_RUN}" == "true" ]]; then
                    log_info "[DRY-RUN] Would remove symlink: ${target_path}"
                else
                    rm -f "${target_path}"
                    log_warn "  ✗ Symlink removed (shared:false target): ${target_path}"
                fi
            fi
            mkdir -p "${target_path}"
            local final_path="${target_path}/${base_name}${output_extension}"
            write_sync_file "${final_path}" "${file_content}" "${source_file}" "${agent}"
        done <<<"${target_paths}"
    done < <(get_source_files "${source_type}" "${agent}")
}

# Deploy hook scripts and merge settings fragment into the agent's settings.json.
# target_config fields:
#   scripts[]        — paths relative to CONTENT_DIR (e.g. "hooks/claude-code/foo.sh")
#   scripts_path     — destination dir (supports ${HOME})
#   settings_fragment — path relative to CONTENT_DIR to a JSON fragment
#   settings_path    — destination settings.json (supports ${HOME})
sync_hooks_impl() {
    local agent="$1"
    local target_type="$2"
    local target_config="$3"

    local shared
    shared=$(jq -r 'if .shared == null then true else .shared end' <<<"${target_config}")
    local scripts_path
    if [[ "${shared}" == "true" ]]; then
        # Hook scripts write ONCE to the shared hooks dir; the agent's
        # scripts_path is symlinked in by bootstrap-symlinks.sh.
        scripts_path=$(get_shared_write_path "${target_type}" "${target_config}")
    else
        # shared:false (claude-code): scripts go to the agent's real dir,
        # resolved per detected workspace (${DETECTED_BASE}).
        scripts_path=$(expand_path "$(jq -r '.scripts_path // ""' <<<"${target_config}")")
    fi

    if [[ -z "${scripts_path}" ]]; then
        log_error "hooks target missing scripts_path for ${agent}"
        return 1
    fi

    # Migration verb for shared:false: drop a stale symlink into the shared base.
    if [[ "${shared}" != "true" ]] && [[ -L "${scripts_path}" ]]; then
        if [[ "${DRY_RUN}" == "true" ]]; then
            log_info "[DRY-RUN] Would remove symlink: ${scripts_path}"
        else
            rm -f "${scripts_path}"
            log_warn "  ✗ Symlink removed (shared:false target): ${scripts_path}"
        fi
    fi

    # --- 1. Copy hook scripts ---
    local scripts_json
    scripts_json=$(jq -r '.scripts[]? // empty' <<<"${target_config}" 2>/dev/null || true)

    while IFS= read -r rel_path; do
        [[ -z "${rel_path}" ]] && continue
        local source_file="${CONTENT_DIR}/${rel_path}"

        if [[ ! -f "${source_file}" ]]; then
            log_warn "  Hook script not found: ${source_file}"
            continue
        fi

        local script_name dest_path content
        script_name=$(basename "${source_file}")
        dest_path="${scripts_path}/${script_name}"
        content=$(cat "${source_file}")

        write_sync_file "${dest_path}" "${content}" "${source_file}" "${agent}"

        if [[ "${DRY_RUN}" != "true" ]]; then
            chmod 755 "${dest_path}"
            log_debug "  chmod 755: ${dest_path}"
        fi
    done <<<"${scripts_json}"

    # --- 2. Merge settings fragment into settings.json ---
    local settings_fragment settings_path
    settings_fragment=$(jq -r '.settings_fragment // ""' <<<"${target_config}")
    settings_path=$(expand_path "$(jq -r '.settings_path // ""' <<<"${target_config}")")

    if [[ -z "${settings_fragment}" || -z "${settings_path}" ]]; then
        return 0
    fi

    local fragment_file="${CONTENT_DIR}/${settings_fragment}"
    if [[ ! -f "${fragment_file}" ]]; then
        log_warn "  Settings fragment not found: ${fragment_file}"
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would merge hooks into: ${settings_path}"
        return 0
    fi

    mkdir -p "$(dirname "${settings_path}")"

    if [[ "${CREATE_BACKUP}" == "true" && -f "${settings_path}" ]]; then
        backup_file "${settings_path}"
    fi

    # Expand ${DETECTED_BASE} (and any other ${VAR}) placeholders in the fragment
    # so hook commands point at THIS workspace's hooks dir (A4: the committed
    # fragment uses ${DETECTED_BASE}/hooks/... placeholders; absent vars stay
    # literal, so legacy fragments merge unchanged).
    local fragment_content
    fragment_content=$(expand_vars_in_string "$(cat "${fragment_file}")")

    if [[ -f "${settings_path}" ]]; then
        # Recursive merge: existing settings wins except for hooks key (fragment wins)
        local merged
        merged=$(jq -s '.[0] * .[1]' "${settings_path}" <(printf '%s' "${fragment_content}"))
        printf '%s\n' "${merged}" >"${settings_path}"
    else
        printf '%s' "${fragment_content}" >"${settings_path}"
    fi

    log_info "  → merged hooks into: ${settings_path}"
}

# Dispatcher: choose merged, individual, directory, json, or hooks based on configuration
# target_config is passed as a pre-extracted JSON object to avoid jq path issues
# with hyphenated agent/target names.
sync_target() {
    local agent="$1"
    local target_type="$2"
    local source_type="$3"

    # Extract the target sub-object once; all _impl functions receive this JSON
    local target_config
    target_config=$(jq -r --arg a "${agent}" --arg t "${target_type}" \
        '.agents[$a].targets[$t]' <<<"${MANIFEST_JSON}")

    # Check if configuration exists
    if [[ "${target_config}" == "null" || -z "${target_config}" ]]; then
        log_debug "No ${target_type} configuration for ${agent}"
        return 0
    fi

    local format
    format=$(jq -r '.format // "merged"' <<<"${target_config}")

    case "${format}" in
        merged)
            sync_merged_impl "${agent}" "${target_type}" "${source_type}" "${target_config}"
            ;;
        individual)
            sync_individual_impl "${agent}" "${target_type}" "${source_type}" "${target_config}"
            ;;
        directory)
            sync_directory_impl "${agent}" "${target_type}" "${source_type}" "${target_config}"
            ;;
        json)
            sync_json_impl "${agent}" "${target_type}" "${target_config}"
            ;;
        hooks)
            sync_hooks_impl "${agent}" "${target_type}" "${target_config}"
            ;;
        *)
            log_error "Unknown format '${format}' for ${agent}/${target_type}"
            return 1
            ;;
    esac
}
