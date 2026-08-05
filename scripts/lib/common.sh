#!/usr/bin/env bash
# =============================================================================
# common.sh - Common functions for agent-covenant
# This file is meant to be sourced, not executed directly.
# =============================================================================

# Colors (only if stderr is a terminal)
if [[ -t 2 ]]; then
    export RED='\033[0;31m'
    export GREEN='\033[0;32m'
    export YELLOW='\033[1;33m'
    export BLUE='\033[0;34m'
    export CYAN='\033[0;36m'
    export BOLD='\033[1m'
    export NC='\033[0m'
else
    export RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# =============================================================================
# Logging functions
# Convention: echo -e for terminal/stderr output (ANSI colors)
#             printf '%s\n' for file writes (avoids corruption)
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${CYAN}[DEBUG]${NC} $*" >&2
    fi
}

log_section() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
    echo -e "${BLUE}  $*${NC}" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✓${NC} $*" >&2
}

log_fail() {
    echo -e "${RED}✗${NC} $*" >&2
}

# =============================================================================
# Utility functions
# =============================================================================

# Expand environment variables in a string (no eval for security)
expand_path() {
    local path="$1"
    local user="${USER:-$(whoami)}"
    local repo_root="${REPO_ROOT:-$(pwd)}"
    # Safe expansion of braced ${VAR} forms only — avoids ambiguity
    # (e.g. $HOME would match $HOME_DIR, $USER would match $USERNAME)
    path="${path//\$\{HOME\}/${HOME}}"
    path="${path//\$\{USER\}/${user}}"
    path="${path//\$\{XDG_CONFIG_HOME\}/${XDG_CONFIG_HOME:-${HOME}/.config}}"
    path="${path//\$\{XDG_DATA_HOME\}/${XDG_DATA_HOME:-${HOME}/.local/share}}"
    path="${path//\$\{REPO_ROOT\}/${repo_root}}"
    path="${path//\$\{DETECTED_BASE\}/${DETECTED_BASE:-}}"
    echo "${path}"
}

# Extract content without YAML frontmatter
extract_content() {
    local file="$1"
    awk '
        NR==1 && /^---$/ { in_frontmatter=1; next }
        in_frontmatter && /^---$/ { in_frontmatter=0; found_end=1; next }
        !in_frontmatter && found_end { print; next }
        !in_frontmatter { print }
    ' "${file}"
}

# Check if a file has frontmatter
has_frontmatter() {
    local file="$1"
    head -1 "$file" 2>/dev/null | grep -q "^---$"
}

# Get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Keep only the last N backups for a given pattern in a directory
_rotate_backups() {
    local backup_dir="$1"
    local base_pattern="$2"
    local keep="${3:-5}"

    local old_backups
    old_backups=$(find "${backup_dir}" -name "${base_pattern}" -type f 2>/dev/null | sort -r | awk -v keep="${keep}" 'NR > keep')
    if [[ -n "${old_backups}" ]]; then
        while IFS= read -r old_file; do
            rm -f "${old_file}"
        done <<<"${old_backups}"
        log_debug "Old backups removed"
    fi
}

# Create backup of a file
backup_file() {
    local file="$1"
    local backup_dir="${2:-${XDG_STATE_HOME:-${HOME}/.local/state}/agent-covenant/backups}"

    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        local backup_name
        backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "${backup_dir}/${backup_name}"
        log_debug "Backup created: ${backup_dir}/${backup_name}"

        _rotate_backups "${backup_dir}" "$(basename "$file").*.bak"
    fi
}

# Expand ${HOME}, ${REPO_ROOT} and all uppercase ${VAR} placeholders in a string.
# Usage: result=$(expand_vars_in_string "${content}")
# Safe: uses parameter expansion and sed — no eval.
expand_vars_in_string() {
    local content="$1"

    # Expand well-known braced variables first
    content="${content//\$\{HOME\}/${HOME}}"
    content="${content//\$\{REPO_ROOT\}/${REPO_ROOT:-}}"

    # Dynamically expand remaining ${UPPER_CASE_VAR} placeholders
    local env_vars
    env_vars=$(grep -oE '\$\{[A-Z_][A-Z0-9_]*\}' <<<"${content}" | sort -u | sed 's/[${}]//g' || true)
    while IFS= read -r var; do
        [[ -z "${var}" ]] && continue
        local val="${!var:-}"
        if [[ -n "${val}" ]]; then
            # shellcheck disable=SC2001  # dynamic pattern s|${VAR}|val| cannot use ${//}
            content=$(sed "s|\${${var}}|${val}|g" <<<"${content}")
        fi
    done <<<"${env_vars}"

    printf '%s' "${content}"
}

# Check dependencies
check_dependency() {
    local cmd="$1"
    local install_hint="${2:-}"

    if ! command -v "$cmd" &>/dev/null; then
        log_error "Missing dependency: $cmd"
        if [[ -n "$install_hint" ]]; then
            log_info "Install with: $install_hint"
        fi
        return 1
    fi
    return 0
}

# Resolve content directory from manifest JSON string
# Usage: resolve_content_dir "<repo_root>" "<manifest_json_string>"
resolve_content_dir() {
    local repo_root="$1"
    local manifest_json="$2"
    local content_dir_name
    content_dir_name=$(jq -r '.content_dir // ""' <<<"${manifest_json}")
    if [[ -n "${content_dir_name}" && "${content_dir_name}" != "null" ]]; then
        echo "${repo_root}/${content_dir_name}"
    else
        echo "${repo_root}"
    fi
}

# =============================================================================
# Hash functions (Linux/macOS portability)
# =============================================================================

# Compute SHA-256 of a file or stdin portably
file_hash() {
    if [[ $# -gt 0 ]]; then
        sha256sum "$1" 2>/dev/null | cut -d' ' -f1 ||
            shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1
    else
        sha256sum 2>/dev/null | cut -d' ' -f1 ||
            shasum -a 256 2>/dev/null | cut -d' ' -f1
    fi
}

# =============================================================================
# Sync cache — per-file checksum store
# Each source file gets its own entry: "<sha256>  <path>" under SYNC_CACHE_DIR.
# This enables partial syncs — only files whose checksum changed are re-synced.
# =============================================================================

SYNC_CACHE_DIR="${HOME}/.config/agent-covenant/file-cache"

# Return the cache entry path for a given agent + source file combination.
# The agent name is included in the key so that multiple agents sharing the
# same source file each get their own cache entry and do not falsely skip writes.
# If the encoded key exceeds filesystem filename limits, it is hashed to a
# stable short filename with the agent prefix preserved for readability.
_cache_entry_path() {
    local agent="$1"
    local file_path="$2"
    # Encode agent:file_path as a flat filename under SYNC_CACHE_DIR (no subprocess)
    local key="${agent}:${file_path}"
    local encoded="${key//\//%2F}"
    # macOS APFS and most Linux filesystems limit a single filename to 255 bytes.
    # Leave margin for the SYNC_CACHE_DIR prefix and any suffix.
    if [[ ${#encoded} -gt 230 ]]; then
        encoded="${agent}:$(printf '%s' "${file_path}" | file_hash)"
    fi
    echo "${SYNC_CACHE_DIR}/${encoded}"
}

# Check if a file has changed since the last sync for a given agent.
# Returns 0 (true) if changed or not cached; 1 if unchanged.
# Inlines _cache_entry_path to avoid a subshell fork on every call (hot path).
file_cache_changed() {
    local agent="$1"
    local file_path="$2"
    local _key="${agent}:${file_path}"
    local encoded="${_key//\//%2F}"
    if [[ ${#encoded} -gt 230 ]]; then
        encoded="${agent}:$(printf '%s' "${file_path}" | file_hash)"
    fi
    local entry="${SYNC_CACHE_DIR}/${encoded}"
    [[ ! -f "${entry}" ]] && return 0

    # Fast path: if the source file has not been modified since the cache entry
    # was last written, content cannot have changed — skip sha256 entirely.
    [[ ! "${file_path}" -nt "${entry}" ]] && return 1

    # Slow path: file is newer than cache — compare hashes to confirm change.
    local cached_hash current_hash
    cached_hash=$(cat "${entry}")
    current_hash=$(file_hash "${file_path}")
    [[ "${cached_hash}" != "${current_hash}" ]]
}

# Save the current checksum of a file to the cache for a given agent.
# Inlines _cache_entry_path to avoid a subshell fork on every call (hot path).
save_file_cache() {
    local agent="$1"
    local file_path="$2"
    local _key="${agent}:${file_path}"
    local encoded="${_key//\//%2F}"
    if [[ ${#encoded} -gt 230 ]]; then
        encoded="${agent}:$(printf '%s' "${file_path}" | file_hash)"
    fi
    local entry="${SYNC_CACHE_DIR}/${encoded}"
    mkdir -p "${SYNC_CACHE_DIR}"
    file_hash "${file_path}" >"${entry}"
    log_debug "File cache saved: ${agent}:${file_path}"
}

# Invalidate the cache entry for a single agent+file (or all files if no args).
invalidate_file_cache() {
    local agent="${1:-}"
    local file_path="${2:-}"
    if [[ -n "${agent}" && -n "${file_path}" ]]; then
        rm -f "$(_cache_entry_path "${agent}" "${file_path}")"
        log_debug "File cache invalidated: ${agent}:${file_path}"
    else
        rm -rf "${SYNC_CACHE_DIR}"
        log_debug "File cache fully invalidated"
    fi
}

# Legacy aliases so callers that still use the old API keep working
compute_source_hash() {
    local manifest="$1"
    local content_dir="$2"
    {
        cat "${manifest}"
        find "${content_dir}" -type f | sort | xargs cat 2>/dev/null
    } | file_hash
}
load_sync_cache() { [[ -f "${SYNC_CACHE_FILE:-}" ]] && cat "${SYNC_CACHE_FILE}" || echo ""; }
save_sync_cache() { [[ -n "${SYNC_CACHE_FILE:-}" ]] && echo "${1:-}" >"${SYNC_CACHE_FILE}"; }
invalidate_sync_cache() {
    rm -f "${SYNC_CACHE_FILE:-}"
    invalidate_file_cache "$@"
}

# =============================================================================
# File functions
# =============================================================================

# Show diff between existing file and new content
show_diff() {
    local path="$1"
    local new_content="$2"

    if [[ -f "$path" ]]; then
        diff --color=auto "$path" <(printf '%s\n' "$new_content") || true
    else
        printf '%b\n' "${GREEN}+ [New file]${NC}"
    fi
}
