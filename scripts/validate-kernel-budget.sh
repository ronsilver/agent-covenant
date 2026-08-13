#!/usr/bin/env bash
# validate-kernel-budget.sh — Enforce the 6000-byte budget for agent kernel files.
# Run: bash scripts/validate-kernel-budget.sh
# Exit 0 = all kernels within budget, exit 1 = at least one kernel exceeds.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"
AGENTS_DIR="${REPO_ROOT}/content/rules/agents"
KERNEL_LIMIT=6000

failures=0

for kernel_file in "${AGENTS_DIR}"/*-global.md; do
    [[ -f "${kernel_file}" ]] || continue
    size=$(wc -c <"${kernel_file}" | tr -d ' ')
    name=$(basename "${kernel_file}")
    if [[ "${size}" -gt "${KERNEL_LIMIT}" ]]; then
        echo "[FAIL] ${name}: ${size} bytes (limit ${KERNEL_LIMIT})"
        failures=$((failures + 1))
    else
        echo "[PASS] ${name}: ${size} bytes (limit ${KERNEL_LIMIT})"
    fi
done

if [[ "${failures}" -gt 0 ]]; then
    echo "[FAIL] ${failures} kernel file(s) exceed the ${KERNEL_LIMIT}-byte budget."
    exit 1
fi

echo "[PASS] All kernel files are within the ${KERNEL_LIMIT}-byte budget."
exit 0
