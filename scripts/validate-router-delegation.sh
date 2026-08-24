#!/usr/bin/env bash
set -euo pipefail

ROUTER="content/subagents/ultraorchestrator.md"
THINKING="content/subagents/ultrathinking.md"
REVIEW="content/subagents/ultrareview.md"
MCP_CFG="content/mcp/opencode-mcp.json"
MIRROR="content/mcp/opencode-agents-config.json"
MANIFEST_EXAMPLE="manifest.example.yaml"
MANIFEST_LOCAL="manifest.yaml"
RUNTIME_OPENCODE="${HOME}/.config/opencode/opencode.json"
errors=0
warnings=0

fail() {
	echo "FAIL: $1"
	errors=$((errors + 1))
}
warn() {
	echo "WARN: $1"
	warnings=$((warnings + 1))
}

# Extract YAML frontmatter (between the first two '---' lines) and emit a JSON
# fragment for the given top-level key, or nothing on parse failure.
fm_key_json() {
	local file="$1" key="$2"
	awk 'NR==1 && $0=="---"{f=1;next} f && $0=="---"{exit} f{print}' "$file" |
		yq -o json ".${key}" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Existing structural checks
# ---------------------------------------------------------------------------
if ! grep -q "^## REFUSAL PROTOCOL" "$ROUTER"; then
	fail "$ROUTER missing '## REFUSAL PROTOCOL'"
fi

if ! grep -q "^## Pipeline state machine" "$ROUTER"; then
	fail "$ROUTER missing '## Pipeline state machine' section"
fi

if ! grep -q 'task(' "$ROUTER"; then
	fail "$ROUTER never instructs calling task(...) for dispatch"
fi

if ! grep -q "MUST NOT self-execute" "$ROUTER"; then
	fail "$ROUTER missing 'MUST NOT self-execute'"
fi

mount_count=$(jq -r '.mcp.filesystem.command[]' "$MCP_CFG" 2>/dev/null | grep -c '^/$' || true)
if [[ "${mount_count}" -gt 0 ]]; then
	fail "$MCP_CFG filesystem server mounted at '/' — read-only subagents could write via MCP"
fi

# ---------------------------------------------------------------------------
# Extract md permission + mirror permission once
# ---------------------------------------------------------------------------
perm=$(fm_key_json "$ROUTER" permission)
mirror_perm=$(jq -c '.agent.ultraorchestrator.permission' "$MIRROR" 2>/dev/null || true)

# ---------------------------------------------------------------------------
# (a) task map: executors ask-gated, docs-writer allow
# ---------------------------------------------------------------------------
if [[ -n "${perm}" ]]; then
	task_map=$(jq -c '.task' <<<"${perm}")
	for ex in ultracode git-requests test-writer; do
		val=$(jq -r --arg ex "$ex" '.[$ex] // "MISSING"' <<<"${task_map}")
		if [[ "$val" != "ask" ]]; then
			fail "(a) UO permission.task.${ex} must be 'ask' (got '${val}')"
		fi
	done
	dw=$(jq -r '.["docs-writer"] // "MISSING"' <<<"${task_map}")
	if [[ "$dw" != "allow" ]]; then
		fail "(a) UO permission.task.docs-writer must be 'allow' (got '${dw}')"
	fi
else
	fail "(a) could not parse UO frontmatter permission.task"
fi

# ---------------------------------------------------------------------------
# (b) per-file grep requirements
# ---------------------------------------------------------------------------
for pat in '[STAGE:S1|' '[STAGE:S3|' 'AUDIT: APPROVE' 'STRICT GATE' 'iteration == 2'; do
	if ! grep -qF "$pat" "$ROUTER"; then
		fail "(b) $ROUTER missing '${pat}'"
	fi
done

parallel_count=$(grep -cF 'parallel' "$ROUTER" || true)
if [[ "${parallel_count}" -lt 2 ]]; then
	fail "(b) $ROUTER requires >=2 occurrences of 'parallel' (got ${parallel_count})"
fi

if ! grep -qF 'max 4 concurrent workers' "$ROUTER"; then
	fail "(b) $ROUTER missing 'max 4 concurrent workers'"
fi

for f in 'Flow A' 'Flow B' 'Flow C' 'Flow D' 'Flow E'; do
	if ! grep -qF "$f" "$ROUTER"; then
		fail "(b) $ROUTER missing routing header '$f'"
	fi
done

for f in "$THINKING" "$REVIEW"; do
	if ! grep -qF 'AUDIT: APPROVE' "$f"; then
		fail "(b) $f missing 'AUDIT: APPROVE'"
	fi
done

# ---------------------------------------------------------------------------
# (b2) keep-strings guard (task( and MUST NOT self-execute already enforced above)
# ---------------------------------------------------------------------------
if ! grep -qF 'task(' "$ROUTER"; then
	fail "(b2) $ROUTER lost literal 'task('"
fi
if ! grep -qF 'MUST NOT self-execute' "$ROUTER"; then
	fail "(b2) $ROUTER lost literal 'MUST NOT self-execute'"
fi

# ---------------------------------------------------------------------------
# (c) real-key regression guard (blocking)
# ---------------------------------------------------------------------------
if [[ -n "${perm}" ]]; then
	for k in lsp plan_enter plan_exit external_directory todowrite; do
		val=$(jq -r --arg k "$k" '.[$k] // "MISSING"' <<<"${perm}")
		if [[ "$val" != "allow" ]]; then
			fail "(c) UO permission.${k} must be 'allow' (got '${val}')"
		fi
	done
	dl=$(jq -r '.doom_loop // "MISSING"' <<<"${perm}")
	if [[ "$dl" != "ask" ]]; then
		fail "(c) UO permission.doom_loop must be 'ask' (got '${dl}')"
	fi
	ap=$(jq -r '.apply_patch // "MISSING"' <<<"${perm}")
	if [[ "$ap" != "deny" ]]; then
		fail "(c) UO permission.apply_patch must be 'deny' (got '${ap}')"
	fi
else
	fail "(c) could not parse UO frontmatter permission for real-key guard"
fi

# ---------------------------------------------------------------------------
# (c2) inert-key check (warn-only, non-blocking)
# ---------------------------------------------------------------------------
if [[ -n "${perm}" ]]; then
	for k in codesearch todoread; do
		if jq -e --arg k "$k" 'has($k)' <<<"${perm}" >/dev/null 2>&1; then
			warn "(c2) inert key '${k}' present (UI/config-visible, not runtime-evaluated) — non-blocking"
		fi
	done
fi

# ---------------------------------------------------------------------------
# (d) mirror parity: full map deep-equals + full bash map pinned values
# ---------------------------------------------------------------------------
if [[ -n "${perm}" && -n "${mirror_perm}" ]]; then
	if ! diff <(jq -S . <<<"${perm}") <(jq -S . <<<"${mirror_perm}") >/dev/null 2>&1; then
		fail "(d) UO mirror permission map does not deep-equal md frontmatter permission"
	fi

	check_bash_pinned() {
		local jqstr="$1" scope="$2"
		for pat in "find *" "cat *" "jq *" "yq *" "ls *" "git status" "git log *" "git diff *" "git branch *" "git show *"; do
			local val
			val=$(jq -r --arg p "$pat" '.[$p] // "MISSING"' <<<"${jqstr}")
			if [[ "$val" != "allow" ]]; then
				fail "(d) UO ${scope} bash map '$pat' must be 'allow' (got '${val}')"
			fi
		done
		for pat in "rm -rf *" "git push *" "git commit *" "git add *" "git reset *" "kubectl delete *" "kubectl apply *" "terraform apply *"; do
			local val
			val=$(jq -r --arg p "$pat" '.[$p] // "MISSING"' <<<"${jqstr}")
			if [[ "$val" != "deny" ]]; then
				fail "(d) UO ${scope} bash map '$pat' must be 'deny' (got '${val}')"
			fi
		done
		local base
		base=$(jq -r '.["*"] // "MISSING"' <<<"${jqstr}")
		if [[ "$base" != "ask" ]]; then
			fail "(d) UO ${scope} bash map '*' must be 'ask' (got '${base}')"
		fi
	}
	md_bash=$(jq -c '.bash' <<<"${perm}")
	mirror_bash=$(jq -c '.bash' <<<"${mirror_perm}")
	check_bash_pinned "${md_bash}" "md"
	check_bash_pinned "${mirror_bash}" "mirror"
else
	fail "(d) could not extract md or mirror permission for parity check"
fi

# ---------------------------------------------------------------------------
# (d2) runtime bash-map assertion (warn-only when CI)
# ---------------------------------------------------------------------------
if [[ "${CI:-}" == "true" && -f "${RUNTIME_OPENCODE}" ]]; then
	rbash=$(jq -c '.agent.ultraorchestrator.permission.bash' "$RUNTIME_OPENCODE" 2>/dev/null || true)
	if [[ -n "${rbash}" ]]; then
		for cmd in "find *" "cat *" "jq *" "yq *" "ls *"; do
			val=$(jq -r --arg c "$cmd" '.[$c] // "MISSING"' <<<"${rbash}")
			if [[ "$val" != "allow" ]]; then
				warn "(d2) runtime bash map '$cmd' != allow (got '${val}') — possible sync-order regression"
			fi
		done
	fi
fi

# ---------------------------------------------------------------------------
# (e) manifest inject_keys.subagent_depth >= 2 (runtime warn-only)
# ---------------------------------------------------------------------------
for mf in "$MANIFEST_EXAMPLE" "$MANIFEST_LOCAL"; do
	d=$(yq -r '.agents.opencode.targets.config.inject_keys.subagent_depth // 0' "$mf" 2>/dev/null || echo 0)
	if [[ "$d" -lt 2 ]]; then
		fail "(e) $mf config inject_keys.subagent_depth must be >= 2 (got '${d}')"
	fi
done
if [[ -f "${RUNTIME_OPENCODE}" ]]; then
	rd=$(jq -r '.subagent_depth // 0' "$RUNTIME_OPENCODE" 2>/dev/null || echo 0)
	if [[ "$rd" -lt 2 ]]; then
		warn "(e) runtime subagent_depth < 2 (got '${rd}') — run make sync"
	fi
fi

# ---------------------------------------------------------------------------
# (f) glob parity: mirror edit/write globs match md
# ---------------------------------------------------------------------------
if [[ -n "${perm}" && -n "${mirror_perm}" ]]; then
	for g in edit write; do
		md_g=$(jq -c ".${g}" <<<"${perm}")
		mirror_g=$(jq -c ".${g}" <<<"${mirror_perm}")
		if ! diff <(jq -S . <<<"${md_g}") <(jq -S . <<<"${mirror_g}") >/dev/null 2>&1; then
			fail "(f) UO mirror ${g} globs do not match md frontmatter"
		fi
	done
fi

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------
if [[ $errors -gt 0 ]]; then
	echo "FAILED router delegation check: ${errors} error(s), ${warnings} warning(s)"
	exit 1
fi
echo "PASS: router delegates via task; pipeline state machine present; mirror/config parity enforced (${warnings} warning(s))"
