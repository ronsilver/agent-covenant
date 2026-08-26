#!/usr/bin/env bash
# bootstrap-symlinks.sh — Create per-agent symlinks, DERIVED from the manifest.
#
# Every directory-format target (skills/subagents/hooks) writes ONCE into the
# shared base (<shared_base>/<shared_dir|target_type>, via scripts/sync.sh).
# This script links each agent's real dir (target `path` / `scripts_path`) into
# that shared dir so the agent sees the shared content. Symlinks are read from
# the manifest — no hardcoded link map — so adding an agent needs no edit here.
# Idempotent: already-linked dirs are skipped; real dirs are backed up to
# <dir>.bak.YYYYMMDD (never deleted) before linking.
#
# Usage: bash scripts/bootstrap-symlinks.sh [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reuse sync.sh's libraries and helpers (detect_all_agent_paths,
# get_shared_base/get_shared_write_path, expand_path, logging). sync.sh's main()
# is guarded, so sourcing only defines functions/globals and resolves
# MANIFEST_FILE.
# shellcheck source=sync.sh
source "${SCRIPT_DIR}/sync.sh"

DRY_RUN=false
if [[ $# -gt 1 ]]; then
    echo "Usage: bootstrap-symlinks.sh [--dry-run]" >&2
    exit 2
fi
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Parse manifest once (matches sync.sh's MANIFEST_JSON contract).
MANIFEST_JSON=$(yq -o=json '.' "${MANIFEST_FILE}")

SHARED=$(get_shared_base)

# Display paths with ~ instead of the full $HOME prefix — absolute paths wrap
# awkwardly in the terminal and make the output hard to read.
compact_path() {
    local p="$1"
    if [[ "${p}" == "${HOME}"/* ]]; then
        p="~${p#"${HOME}"}"
    fi
    printf '%s\n' "${p}"
}

echo "==> Bootstrapping shared agent-covenant at $(compact_path "${SHARED}")"

# ensure_link <agent_dir> <write_dir>
#   Backup-then-link, idempotent, never deletes. A symlink already pointing at
#   the write dir is a no-op; a real dir is moved to <dir>.bak.<date> first.
ensure_link() {
    local agent_dir="$1"
    local target="$2"

    if [[ -L "${agent_dir}" ]]; then
        local current
        current=$(readlink "${agent_dir}")
        if [[ "${current}" == "${target}" ]]; then
            echo "  OK       $(compact_path "${agent_dir}")"
            return 0
        fi
        echo "  RELINK   $(compact_path "${agent_dir}") (was -> $(compact_path "${current}"))"
        [[ "${DRY_RUN}" == "true" ]] && return 0
        ln -sfn "${target}" "${agent_dir}"
        return 0
    fi

    if [[ -d "${agent_dir}" ]]; then
        local backup
        backup="${agent_dir}.bak.$(date +%Y%m%d)"
        local n=0
        while [[ -e "${backup}" ]]; do
            n=$((n + 1))
            backup="${agent_dir}.bak.$(date +%Y%m%d).${n}"
        done
        echo "  BACKUP   $(compact_path "${agent_dir}") -> $(compact_path "${backup}")"
        if [[ "${DRY_RUN}" != "true" ]]; then
            mv "${agent_dir}" "${backup}"
        fi
    elif [[ -e "${agent_dir}" ]]; then
        echo "  SKIP     $(compact_path "${agent_dir}") (not a directory)"
        return 0
    fi

    if [[ ! -e "${agent_dir}" ]]; then
        echo "  LINK     $(compact_path "${agent_dir}") -> $(compact_path "${target}")"
        if [[ "${DRY_RUN}" != "true" ]]; then
            mkdir -p "$(dirname "${agent_dir}")"
            ln -sfn "${target}" "${agent_dir}"
        fi
    fi
}

# resolve_agent_dirs <agent> <target_type> <target_config>
#   Emit the resolved absolute agent dir(s). For detect_as_base agents the
#   ${DETECTED_BASE} placeholder is expanded to each detected workspace base.
resolve_agent_dirs() {
    local agent="$1"
    local ttype="$2"
    local tcfg="$3"
    local rawp
    rawp=$(jq -r '.path // ""' <<<"${tcfg}")
    [[ "${ttype}" == "hooks" ]] && rawp=$(jq -r '.scripts_path // ""' <<<"${tcfg}")
    [[ -z "${rawp}" || "${rawp}" == "null" ]] && return 0

    if [[ "${rawp}" == *"\${DETECTED_BASE}"* ]]; then
        while IFS= read -r base; do
            [[ -z "${base}" ]] && continue
            expand_path "${rawp//\$\{DETECTED_BASE\}/${base}}"
        done < <(detect_all_agent_paths "${agent}")
    else
        expand_path "${rawp}"
    fi
}

main() {
    while IFS= read -r agent; do
        [[ -z "${agent}" ]] && continue
        local target_types
        target_types=$(jq -r --arg a "${agent}" '.agents[$a].targets | keys[]' <<<"${MANIFEST_JSON}" 2>/dev/null || true)
        while IFS= read -r ttype; do
            [[ -z "${ttype}" ]] && continue
            case "${ttype}" in
                skills | subagents | hooks) ;;
                *) continue ;;
            esac
            local tcfg
            tcfg=$(jq -r --arg a "${agent}" --arg t "${ttype}" '.agents[$a].targets[$t]' <<<"${MANIFEST_JSON}")

            # shared:false targets (claude-code) are REAL per-workspace dirs —
            # never symlinked. Migration verb (D7): unlink any existing symlink
            # that points into the shared base. Dry-run-aware, idempotent; only
            # touches symlinks (never backups, never real dirs).
            local shared
            shared=$(jq -r 'if .shared == null then true else .shared end' <<<"${tcfg}")
            if [[ "${shared}" != "true" ]]; then
                while IFS= read -r agent_dir; do
                    [[ -z "${agent_dir}" ]] && continue
                    if [[ -L "${agent_dir}" ]]; then
                        local current
                        current=$(readlink "${agent_dir}")
                        if [[ "${current}" == "${SHARED}"/* ]]; then
                            echo "  UNLINK   $(compact_path "${agent_dir}") (was -> $(compact_path "${current}"))"
                            if [[ "${DRY_RUN}" != "true" ]]; then
                                rm -f "${agent_dir}"
                            fi
                        fi
                    fi
                done < <(resolve_agent_dirs "${agent}" "${ttype}" "${tcfg}")
                continue
            fi

            local write_dir
            write_dir=$(get_shared_write_path "${ttype}" "${tcfg}")
            while IFS= read -r agent_dir; do
                [[ -z "${agent_dir}" ]] && continue
                ensure_link "${agent_dir}" "${write_dir}"
            done < <(resolve_agent_dirs "${agent}" "${ttype}" "${tcfg}")
        done <<<"${target_types}"
    done < <(jq -r '.agents | keys[]' <<<"${MANIFEST_JSON}")

    echo "==> Bootstrap complete."
}

main "$@"
