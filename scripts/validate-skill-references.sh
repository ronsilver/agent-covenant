#!/usr/bin/env bash
set -euo pipefail

# Script to validate that all references mentioned in SKILL.md files actually exist
# and report any orphaned reference files not mentioned in SKILL.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions (colors, log_*)
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

SKILLS_DIR="${1:-content/skills}"
TOTAL_ERRORS=0
TOTAL_WARNINGS=0

log_info "Validating skill references in: ${SKILLS_DIR}"
echo "" >&2

# Process each SKILL.md using process substitution to keep variables in scope
while IFS= read -r skill_file; do
	skill_dir=$(dirname "${skill_file}")
	skill_name=$(basename "${skill_dir}")

	echo -e "${BLUE}=== Validating: ${skill_name} ===${NC}" >&2

	# Extract all references mentioned in SKILL.md.
	# Matches either local `references/file.md` or cross-skill
	# `<skill>/references/file.md` (the skill prefix is preserved for resolution).
	mentioned_refs=$(grep -oE '([a-z0-9_-]+/)?references/[a-z0-9_-]+\.md' "${skill_file}" 2>/dev/null | sort -u || true)

	# Get all actual reference files that exist
	actual_refs=""
	if [[ -d "${skill_dir}/references" ]]; then
		actual_refs=$(find "${skill_dir}/references" -name "*.md" -type f -exec basename {} \; | sort -u || true)
	fi

	# Check for missing reference files.
	# Cross-skill references (e.g. `governance/references/mcp-lifecycle.md` inside
	# engineering-standards/SKILL.md) resolve against the OTHER skill's directory.
	has_errors=false
	while IFS= read -r ref; do
		[[ -z "${ref}" ]] && continue
		case "${ref}" in
		*"/references/"*)
			# Cross-skill reference: "<skill>/references/<file>.md"
			ref_skill="${ref%%/*}"
			if [[ -f "${SKILLS_DIR}/${ref_skill}/references/$(basename "${ref}")" ]]; then
				log_warn "  Cross-skill reference: ${ref}"
				TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
			else
				log_error "  Missing: ${ref} (cross-skill reference target does not exist)"
				TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
				has_errors=true
			fi
			;;
		*)
			# Local reference: "references/<file>.md"
			if [[ ! -f "${skill_dir}/${ref}" ]]; then
				log_error "  Missing: ${ref} (referenced in SKILL.md but does not exist)"
				TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
				has_errors=true
			fi
			;;
		esac
	done <<<"${mentioned_refs}"

	# Check for orphaned reference files (exist but not mentioned)
	has_warnings=false
	if [[ -d "${skill_dir}/references" ]]; then
		while IFS= read -r ref_file; do
			[[ -z "${ref_file}" ]] && continue
			if ! grep -q "references/${ref_file}" <<<"${mentioned_refs}"; then
				log_warn "  Orphaned: references/${ref_file} (exists but not referenced in SKILL.md)"
				TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
				has_warnings=true
			fi
		done <<<"${actual_refs}"
	fi

	# Check for empty reference files (0 bytes or no alphabetic content)
	if [[ -d "${skill_dir}/references" ]]; then
		while IFS= read -r ref_file; do
			[[ -z "${ref_file}" ]] && continue
			filepath="${skill_dir}/references/${ref_file}"
			if [[ ! -s "${filepath}" ]]; then
				log_error "  Empty: references/${ref_file} (0 bytes)"
				TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
				has_errors=true
			elif ! grep -q '[[:alpha:]]' "${filepath}" 2>/dev/null; then
				log_error "  Empty: references/${ref_file} (no alphabetic content)"
				TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
				has_errors=true
			fi
		done <<<"${actual_refs}"
	fi

	# Check if references directory exists when references are mentioned
	if [[ -n "${mentioned_refs}" && ! -d "${skill_dir}/references" ]]; then
		log_error "  SKILL.md references files but directory references/ does not exist"
		TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
		has_errors=true
	fi

	# Check if SKILL.md mentions references but directory is empty
	if [[ -n "${mentioned_refs}" && -d "${skill_dir}/references" ]]; then
		ref_count=$(find "${skill_dir}/references" -name "*.md" -type f 2>/dev/null | wc -l | tr -dc '0-9')
		if [[ "${ref_count}" -eq 0 ]]; then
			log_error "  SKILL.md references files but the references/ directory is empty"
			TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
			has_errors=true
		fi
	fi

	# Summary per skill
	if [[ "${has_errors}" == false && "${has_warnings}" == false ]]; then
		ref_count=$(grep -c "references/" <<<"${mentioned_refs}" 2>/dev/null || true)
		ref_count="${ref_count%% *}"
		if [[ "${ref_count}" -gt 0 ]]; then
			log_success "  ${ref_count} reference(s) validated"
		else
			log_success "  No references (self-contained skill)"
		fi
	fi

	echo "" >&2
done < <(find "${SKILLS_DIR}" -name "SKILL.md" -type f | sort)

# Summary
echo "" >&2
log_section "Summary"

if [[ ${TOTAL_ERRORS} -eq 0 && ${TOTAL_WARNINGS} -eq 0 ]]; then
	log_success "Validation complete: no errors or warnings found"
	exit 0
fi

[[ ${TOTAL_ERRORS} -gt 0 ]] && log_error "Errors: ${TOTAL_ERRORS} (referenced files missing)"
[[ ${TOTAL_WARNINGS} -gt 0 ]] && log_warn "Warnings: ${TOTAL_WARNINGS} (orphaned reference files)"

if [[ ${TOTAL_ERRORS} -gt 0 ]]; then
	exit 1
fi
