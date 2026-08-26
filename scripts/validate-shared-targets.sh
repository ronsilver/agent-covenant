#!/usr/bin/env bash
# shellcheck disable=SC2016  # SHARED_BASE_LITERAL holds an unexpanded ${HOME} placeholder
# validate-shared-targets.sh — Enforce the shared-dir sync invariant (AGENTS.md #11):
#   - top-level `shared_base` must be ${HOME}/.config/agent-covenant
#   - directory-format targets (skills/subagents/hooks) keep their agent's REAL
#     dir in `path`/`scripts_path` (NOT the shared base). shared:true targets
#     write ONCE to <shared_base>/<type>[-<transform>] (agent dir symlinked in
#     by scripts/bootstrap-symlinks.sh); shared:false targets (claude-code)
#     write to the agent's real per-workspace dir.
#   - `shared` must be a boolean (default true when absent)
#   - `shared: false` requires a non-empty path/scripts_path
#   - `transform` (optional) ∈ {none, strip, opencode, header}
#   - residual legacy keys (strip_frontmatter/transform_frontmatter/shared_dir)
#     are rejected
# Usage: scripts/validate-shared-targets.sh [manifest-file ...]
#   No args = manifest.yaml + manifest.example.yaml (whichever exist).
#   Exit 0 = clean; exit 1 = violation.
set -euo pipefail

SHARED_BASE_LITERAL='${HOME}/.config/agent-covenant'
DIRECTORY_TARGET_TYPES=(skills subagents hooks)
TRANSFORM_VALUES=(none strip opencode header)
RESIDUAL_KEYS=(strip_frontmatter transform_frontmatter shared_dir)

manifests=("$@")
if [[ ${#manifests[@]} -eq 0 ]]; then
    for f in manifest.yaml manifest.example.yaml; do
        [[ -f "${f}" ]] && manifests+=("${f}")
    done
fi

main() {
    local errors=0
    local manifest shared_base agent ttype path_field p sv tv k key

    for manifest in "${manifests[@]}"; do
        [[ -f "${manifest}" ]] || {
            echo "FAIL: manifest not found: ${manifest}"
            errors=$((errors + 1))
            continue
        }

        # 1. shared_base must be present and canonical.
        shared_base=$(yq -r '.shared_base // ""' "${manifest}" 2>/dev/null || true)
        if [[ -z "${shared_base}" || "${shared_base}" == "null" ]]; then
            echo "FAIL: ${manifest}: missing top-level shared_base (must be ${SHARED_BASE_LITERAL})"
            errors=$((errors + 1))
        elif [[ "${shared_base}" != "${SHARED_BASE_LITERAL}" ]]; then
            echo "FAIL: ${manifest}: shared_base '${shared_base}' != ${SHARED_BASE_LITERAL}"
            errors=$((errors + 1))
        fi

        while IFS= read -r agent; do
            [[ -z "${agent}" ]] && continue
            for ttype in "${DIRECTORY_TARGET_TYPES[@]}"; do
                path_field="path"
                [[ "${ttype}" == "hooks" ]] && path_field="scripts_path"
                p=$(yq -r ".agents.\"${agent}\".targets.\"${ttype}\".${path_field} // \"\"" "${manifest}" 2>/dev/null || true)

                # 2. shared must be a boolean when present (default: true).
                # NOTE: yq's `// ""` returns empty for a boolean `false` (falsy
                # alternative), so read RAW and null-normalize. Never `// ""` on
                # shared — it silently blanks shared:false.
                sv=$(yq -r ".agents.\"${agent}\".targets.\"${ttype}\".shared" "${manifest}" 2>/dev/null || true)
                [[ "${sv}" == "null" || -z "${sv}" ]] && sv=""
                if [[ -n "${sv}" && "${sv}" != "true" && "${sv}" != "false" ]]; then
                    echo "FAIL: ${manifest}: ${agent}.targets.${ttype}.shared '${sv}' must be a boolean (true|false)"
                    errors=$((errors + 1))
                fi

                # 3. shared:false requires a non-empty path/scripts_path.
                if [[ "${sv}" == "false" ]] && [[ -z "${p}" || "${p}" == "null" ]]; then
                    echo "FAIL: ${manifest}: ${agent}.targets.${ttype}: shared:false requires a non-empty ${path_field}"
                    errors=$((errors + 1))
                fi

                # 4. Directory targets must keep the agent's real dir.
                if [[ -n "${p}" && "${p}" != "null" ]]; then
                    if [[ "${p}" == *"agent-covenant"* ]]; then
                        echo "FAIL: ${manifest}: ${agent}.targets.${ttype}.${path_field} '${p}' points at the shared base — must be the agent's real dir (content is written to <shared_base>/<dir> and symlinked here by bootstrap-symlinks.sh)"
                        errors=$((errors + 1))
                    fi
                fi

                # 5. transform must be a kebab-case enum value when present.
                tv=$(yq -r ".agents.\"${agent}\".targets.\"${ttype}\".transform // \"\"" "${manifest}" 2>/dev/null || true)
                if [[ -n "${tv}" && "${tv}" != "null" ]]; then
                    case " ${TRANSFORM_VALUES[*]} " in
                        *" ${tv} "*) ;;
                        *)
                            echo "FAIL: ${manifest}: ${agent}.targets.${ttype}.transform '${tv}' not in {${TRANSFORM_VALUES[*]}}"
                            errors=$((errors + 1))
                            ;;
                    esac
                fi

                # 6. Residual legacy keys are rejected.
                for key in "${RESIDUAL_KEYS[@]}"; do
                    k=$(yq -r ".agents.\"${agent}\".targets.\"${ttype}\".\"${key}\" // \"\"" "${manifest}" 2>/dev/null || true)
                    if [[ -n "${k}" && "${k}" != "null" ]]; then
                        echo "FAIL: ${manifest}: ${agent}.targets.${ttype}.${key} is a residual legacy key — use 'shared' + 'transform' instead"
                        errors=$((errors + 1))
                    fi
                done
            done
        done < <(yq -r '.agents | keys | .[]' "${manifest}" 2>/dev/null || true)
    done

    if [[ ${errors} -gt 0 ]]; then
        echo "FAILED shared-target validation: ${errors} violation(s)"
        exit 1
    fi

    echo "PASS: shared_base canonical; shared/transform valid; directory targets keep agent real dirs"
}

main
