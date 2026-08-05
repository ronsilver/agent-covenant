#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# validate-canonical-paths.sh - Validate agent paths against canonical docs
# =============================================================================
# Compares paths in manifest.yaml against documented canonical paths from
# official agent documentation.
#
# Usage:
#   ./scripts/validate-canonical-paths.sh [--strict]
#
# Exit codes:
#   0 - All paths are canonical or warnings only
#   1 - Found non-canonical paths (in strict mode)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
MANIFEST_FILE="${REPO_ROOT}/manifest.yaml"
[[ ! -f "${MANIFEST_FILE}" ]] && MANIFEST_FILE="${REPO_ROOT}/manifest.example.yaml"
CANONICAL_FILE="${REPO_ROOT}/docs/canonical-paths.yaml"

# Load common functions
source "${SCRIPT_DIR}/lib/common.sh"

# Variables
STRICT_MODE=false
WARNINGS=0
ERRORS=0

# =============================================================================
# Parse arguments
# =============================================================================

parse_args() {
	while [[ $# -gt 0 ]]; do
		case $1 in
		--strict)
			STRICT_MODE=true
			shift
			;;
		--debug | -d)
			export DEBUG=true
			shift
			;;
		--help | -h)
			echo "Usage: $0 [options]"
			echo ""
			echo "Validate agent paths against canonical documentation."
			echo ""
			echo "Options:"
			echo "  --strict    Treat warnings as errors"
			echo "  --debug     Show debug information"
			echo "  --help      Show this help"
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
# Validation functions
# =============================================================================

# Get canonical paths for an agent and target type
get_canonical_paths() {
	local agent="$1"
	local target_type="$2"

	yq ".agents.${agent}.canonical_paths.${target_type}[].path" "${CANONICAL_FILE}" 2>/dev/null || echo ""
}

# Get source documentation for a canonical path
get_path_source() {
	local agent="$1"
	local target_type="$2"
	local path="$3"

	local count
	count=$(yq ".agents.${agent}.canonical_paths.${target_type} | length" "${CANONICAL_FILE}" 2>/dev/null || echo 0)

	for ((i = 0; i < count; i++)); do
		local canonical_path
		canonical_path=$(yq ".agents.${agent}.canonical_paths.${target_type}[${i}].path" "${CANONICAL_FILE}")

		if [[ "${canonical_path}" == "${path}" ]]; then
			yq ".agents.${agent}.canonical_paths.${target_type}[${i}].source // \"\"" "${CANONICAL_FILE}"
			return 0
		fi
	done

	echo ""
}

# Check if a path is canonical for an agent
is_canonical_path() {
	local agent="$1"
	local target_type="$2"
	local configured_path="$3"

	# Get all canonical paths for this agent/target
	local canonical_paths
	canonical_paths=$(get_canonical_paths "${agent}" "${target_type}")

	if [[ -z "${canonical_paths}" ]]; then
		# No canonical paths defined, cannot validate
		return 2
	fi

	# Check if configured path matches any canonical path
	while IFS= read -r canonical_path; do
		[[ -z "${canonical_path}" ]] && continue

		if [[ "${configured_path}" == "${canonical_path}" ]]; then
			return 0
		fi
	done <<<"${canonical_paths}"

	return 1
}

# Validate paths for a specific agent
validate_agent_paths() {
	local agent="$1"
	local agent_warnings=0

	local enabled
	enabled=$(yq ".agents.${agent}.enabled // false" "${MANIFEST_FILE}")

	if [[ "${enabled}" != "true" ]]; then
		log_debug "Skipping disabled agent: ${agent}"
		return 0
	fi

	local description
	description=$(yq ".agents.${agent}.description // \"${agent}\"" "${MANIFEST_FILE}")

	log_info "Validating: ${description}"

	# Get all target types configured for this agent
	local target_types
	target_types=$(yq ".agents.${agent}.targets | keys | .[]" "${MANIFEST_FILE}" 2>/dev/null || true)

	while IFS= read -r target_type; do
		[[ -z "${target_type}" ]] && continue

		local configured_path
		configured_path=$(yq ".agents.${agent}.targets.${target_type}.path // \"\"" "${MANIFEST_FILE}")

		if [[ -z "${configured_path}" || "${configured_path}" == "null" ]]; then
			log_debug "  ${target_type}: (no path configured)"
			continue
		fi

		# Check if path is canonical
		if is_canonical_path "${agent}" "${target_type}" "${configured_path}"; then
			log_debug "  ✓ ${target_type}: ${configured_path}"
		else
			local exit_code=$?

			if [[ ${exit_code} -eq 2 ]]; then
				# No canonical paths defined for this agent/target
				log_debug "  ? ${target_type}: ${configured_path} (no canonical reference)"
			else
				# Path is not canonical
				log_warn "  ⚠ ${target_type}: ${configured_path}"
				log_warn "    Not in canonical documentation"

				# Show alternatives
				local canonical_paths
				canonical_paths=$(get_canonical_paths "${agent}" "${target_type}")

				if [[ -n "${canonical_paths}" ]]; then
					log_warn "    Canonical options:"
					while IFS= read -r canonical_path; do
						[[ -z "${canonical_path}" ]] && continue
						local source
						source=$(get_path_source "${agent}" "${target_type}" "${canonical_path}")
						if [[ -n "${source}" && "${source}" != "null" ]]; then
							log_warn "      - ${canonical_path} (${source})"
						else
							log_warn "      - ${canonical_path}"
						fi
					done <<<"${canonical_paths}"
				fi

				agent_warnings=$((agent_warnings + 1))
			fi
		fi
	done <<<"${target_types}"

	if [[ ${agent_warnings} -gt 0 ]]; then
		WARNINGS=$((WARNINGS + agent_warnings))
	fi

	return 0
}

# =============================================================================
# Main
# =============================================================================

main() {
	parse_args "$@"

	log_section "Canonical Path Validation"

	# Check dependencies
	check_dependency "yq" "brew install yq" || exit 1

	# Check that files exist
	if [[ ! -f "${MANIFEST_FILE}" ]]; then
		log_error "Manifest not found: ${MANIFEST_FILE}"
		exit 1
	fi

	if [[ ! -f "${CANONICAL_FILE}" ]]; then
		log_error "Canonical paths reference not found: ${CANONICAL_FILE}"
		exit 1
	fi

	log_info "Manifest: ${MANIFEST_FILE}"
	log_info "Reference: ${CANONICAL_FILE}"
	echo "" >&2

	# Get all enabled agents
	local agents
	agents=$(yq '.agents | keys | .[]' "${MANIFEST_FILE}")

	while IFS= read -r agent; do
		[[ -z "${agent}" ]] && continue
		validate_agent_paths "${agent}"
	done <<<"${agents}"

	# Summary
	echo "" >&2
	log_section "Summary"

	if [[ ${ERRORS} -gt 0 ]]; then
		log_error "Errors: ${ERRORS}"
	else
		log_success "Errors: 0"
	fi

	if [[ ${WARNINGS} -gt 0 ]]; then
		log_warn "Non-canonical paths: ${WARNINGS}"
		log_info "These paths may work but differ from official documentation"
	else
		log_success "Warnings: 0"
	fi

	echo "" >&2

	# Exit based on strict mode
	if [[ "${STRICT_MODE}" == "true" && ${WARNINGS} -gt 0 ]]; then
		log_fail "Validation failed (strict mode)"
		exit 1
	elif [[ ${ERRORS} -gt 0 ]]; then
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
