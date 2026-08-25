#!/usr/bin/env bash
# validate-no-fintech.sh — Ensure content/ is free of fintech-domain coupling.
# Run: bash scripts/validate-no-fintech.sh
# Exit 0 = clean, exit 1 = fintech terms found.
#
# Passes:
#   1. BANNED_TERMS (plain substring) — explicit fintech identifiers
#   2. BANNED_PATTERNS (regex / multiword / word-boundary) — fintech terms that
#      would false-positive as bare single words (authorize, approved, PSP, checkout)
#   3. Spanish-prose pass — accented Spanish outside code fences (proper nouns/data exempt)
#   4. Stale-skill-ref pass — backtick skill refs that do not match content/skills/ dirs

set -euo pipefail

CONTENT_DIR="content/"
DOCS_DIR="docs/reference/"

# Specific fintech terms that should NOT appear outside allowed contexts.
# NOTE: 'payments' is deliberately NOT included — it is a universally generic
# term used across many skills as an example domain (payments table, payments
# API, etc.). This script targets truly domain-specific coupling.
BANNED_TERMS=(
	"KillBill"
	"Spree"
	"4111111111111111"         # test credit card number
	"Stripe"                   # specific payment provider
	"payment_id"               # domain-specific identifier
	"credit card"              # fintech PII
	"redirect_url"             # payment redirect flow
	"railscommerce"            # dead e-commerce docs host
	"Data warehouse warehouse" # stale double-word artifact
	"pagar"                    # Spanish payment verb in test locators
	"fee_cents"                # fintech column
	"total_cents"              # fintech column
	"amount_cents"             # fintech column
	"fraud_flag"               # fintech flag
	"checkout page"            # e-commerce checkout UI (multiword to avoid git checkout)
	"checkout flow"            # e-commerce checkout flow
	"checkout API"             # e-commerce checkout API
	"checkout cart"            # e-commerce cart
	"checkout success"         # e-commerce conversion metric
	"checkout button"          # e-commerce UI element
	"checkout form"            # e-commerce UI element
)

# Regex patterns for terms that must not be flagged as bare substrings.
# - \bPSP\b            : payment service provider (word boundary; "PSPs" ok to catch)
# - \bmer_123\b        : merchant id example (boundary avoids customer_123 substring)
# - authorize\(        : fintech authorize() call (not "unauthorized"/IAM authorize)
# - "approved" or status...approved : fintech approval status value (not "plan is approved")
BANNED_PATTERNS=(
	'\bPSP\b'
	'\b[Pp][Ss][Pp]\b'
	'\bmer_123\b'
	'\bcurrency\b'
	'\bcents\b'
	'authorize\('
	'"approved"'
	'status[:=][[:space:]]*['"'"'"]?approved'
)

# Files to exempt entirely
is_exempt_file() {
	local filepath="$1"
	[[ "$filepath" == *"docs/plans/"* ]] && return 0
	[[ "$filepath" == *"CHANGELOG"* ]] && return 0
	[[ "$filepath" == *"scala-expert"* ]] && return 0
	# Historical/deprecated subagent references — fintech names preserved intentionally
	[[ "$filepath" == *"subagents/README.md" ]] && return 0
	# Reference docs that document historical context
	[[ "$filepath" == *"skill-router/references"* ]] && return 0
	# External/third-party references
	[[ "$filepath" == *"alternative-skill-creator/references"* ]] && return 0
	# DOMAIN-SPECIFIC reference files (not part of active skills)
	[[ "$filepath" == *"references/rails-conventions.md" ]] && return 0
	[[ "$filepath" == *"references/testing.md" ]] && return 0
	[[ "$filepath" == *"references/testing-patterns.md" ]] && return 0
	# Subagent reference catalog documents historical agents
	[[ "$filepath" == *"subagents-catalog.md" ]] && return 0
	# DOMAIN-SPECIFIC references (marked with [DOMAIN-SPECIFIC] in file)
	[[ "$filepath" == *"ruby-expert/references/spree-patterns.md" ]] && return 0
	[[ "$filepath" == *"java-expert/references/killbill.md" ]] && return 0
	# Tool-generated gitnexus skills (ADR-0037): examples from gitnexus docs corpus
	[[ "$filepath" == *"content/skills/gitnexus-"* ]] && return 0
	return 1
}

errors=0

# Pass 1: plain substring terms
for term in "${BANNED_TERMS[@]}"; do
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		filepath=$(echo "$line" | cut -d: -f1)
		if is_exempt_file "$filepath"; then
			continue
		fi
		if grep -q 'DOMAIN-SPECIFIC' "$filepath" 2>/dev/null; then
			continue
		fi
		echo "[FIN TECH] $term found: $line"
		errors=1
	done < <(grep -rn "$term" "$CONTENT_DIR" "$DOCS_DIR" 2>/dev/null || true)
done

# Pass 2: regex / multiword / word-boundary patterns
for pattern in "${BANNED_PATTERNS[@]}"; do
	while IFS= read -r line; do
		[ -z "$line" ] && continue
		filepath=$(echo "$line" | cut -d: -f1)
		if is_exempt_file "$filepath"; then
			continue
		fi
		if grep -q 'DOMAIN-SPECIFIC' "$filepath" 2>/dev/null; then
			continue
		fi
		echo "[FIN TECH] pattern $pattern found: $line"
		errors=1
	done < <(grep -rnE "$pattern" "$CONTENT_DIR" "$DOCS_DIR" 2>/dev/null || true)
done

# Pass 3: Spanish-prose pass — scan content/ .md/.json for accented Spanish
# outside fenced code blocks; exempt proper nouns/data (José, Nuevo León) and
# the existing exempt files (is_exempt_file).
PROPER_NOUN_EXEMPT="José|Nuevo León"
spanish_errors=0
while IFS= read -r filepath; do
	[ -z "$filepath" ] && continue
	if is_exempt_file "$filepath"; then
		continue
	fi
	if [[ "$filepath" == *.md ]]; then
		# Strip fenced code blocks before scanning prose
		content=$(awk 'BEGIN{infence=0} /^```/{infence=!infence; next} infence==0{print}' "$filepath" 2>/dev/null || true)
	else
		content=$(cat "$filepath" 2>/dev/null || true)
	fi
	while IFS= read -r hit; do
		[ -z "$hit" ] && continue
		linenum=$(echo "$hit" | cut -d: -f1)
		line=${hit#*:}
		cleaned=$(printf '%s\n' "$line" | sed -E "s/$PROPER_NOUN_EXEMPT//g")
		if printf '%s\n' "$cleaned" | grep -q '[áéíóúñÁÉÍÓÚ¿¡]'; then
			echo "[SPANISH] $filepath:$linenum: $line"
			spanish_errors=1
		fi
	done < <(printf '%s\n' "$content" | grep -n '[áéíóúñÁÉÍÓÚ¿¡]' || true)
done < <(find "$CONTENT_DIR" -type f \( -name '*.md' -o -name '*.json' \) 2>/dev/null || true)

if [ $spanish_errors -eq 1 ]; then
	errors=1
fi

# Pass 4: stale-skill-ref pass — backtick skill refs in "→ `name`" or "skill(name)"
# patterns that do not match a content/skills/ directory. Skips _TEMPLATE and
# references/ (documented historical names) plus a small allowlist of documented
# shorthand/non-skill tokens.
SKILL_DIRS_FILE=$(mktemp)
trap 'rm -f "$SKILL_DIRS_FILE"' EXIT
ls "$CONTENT_DIR/skills" 2>/dev/null | grep -v '^_TEMPLATE$' | grep -v '^README.md$' >"$SKILL_DIRS_FILE"
# Documented shorthand for aws-cloud-expert in skill-router's disambiguation table,
# plus tool names that legitimately appear backticked in "→ `tool`" chains.
STALE_ALLOWED="aws-cloud golangci-lint kube-linter"
stale_errors=0
while IFS= read -r filepath; do
	[ -z "$filepath" ] && continue
	if is_exempt_file "$filepath"; then
		continue
	fi
	case "$filepath" in
	*/references/* | */_TEMPLATE/*) continue ;;
	esac
	[[ "$filepath" == *.md ]] || continue
	while IFS= read -r hit; do
		[ -z "$hit" ] && continue
		linenum=$(echo "$hit" | cut -d: -f1)
		rest=${hit#*:}
		cand=$(printf '%s' "$rest" | grep -oE '[a-z0-9-]+$' || true)
		[ -z "$cand" ] && continue
		# Only skill-name-shaped refs (contain a hyphen) are cross-skill refs
		[[ "$cand" == *-* ]] || continue
		if grep -qxF "$cand" "$SKILL_DIRS_FILE" 2>/dev/null; then
			continue
		fi
		case " $STALE_ALLOWED " in
		*" $cand "*) continue ;;
		esac
		echo "[STALE REF] $filepath:$linenum: $cand"
		stale_errors=1
	done < <(grep -noE '(→[[:space:]]*`[a-z0-9-]+`|skill\([[:space:]]*`?[a-z0-9-]+`?\))' "$filepath" 2>/dev/null || true)
done < <(find "$CONTENT_DIR" -type f -name '*.md' 2>/dev/null || true)

if [ $stale_errors -eq 1 ]; then
	errors=1
fi

if [ $errors -eq 1 ]; then
	echo ""
	echo "[FAIL] Fintech-domain terms / Spanish prose / stale skill refs detected. See above for locations."
	exit 1
fi

echo "[PASS] No fintech-domain coupling, Spanish prose, or stale skill references detected."
exit 0
