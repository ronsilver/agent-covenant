# Deterministic Compliance Audit

## Scope

Defines the deterministic, CI-enforceable compliance audit for the skills
ecosystem. Replaces advisory checks with exit-code gates. Audits by reference
against the 8 engineering-standards evaluation domains -- does NOT duplicate
criteria.

Patterns adopted from affaan-m/ECC (`ecc status --exit-code`) and
anthropics/financial-services (`scripts/check.py` drift detection).

Source: https://github.com/affaan-m/ECC (accessed 2026-07-02, [unverified] adoption; pattern from README).
Source: https://github.com/anthropics/financial-services (accessed 2026-07-02) -- check.py lints manifests, verifies cross-file refs, fails on skill drift.

## 8-Domain Audit

| Domain | Check | Pass criterion | Tool |
|--------|-------|----------------|------|
| 1. Manifest | Every content file registered | make validate exits 0 | scripts/validate.sh |
| 2. Schema | frontmatter valid (schema v2) | make validate exits 0 | scripts/validate.sh |
| 3. Quality | 7-pillar score >= 70 | make validate-quality exits 0 | scripts/validate-skill-quality.py |
| 4. References | No orphan refs | make validate-skill-refs exits 0 | scripts/validate-skill-refs.sh |
| 5. Version drift | manifest version == frontmatter version | grep comparison exits 0 | manual / CI script |
| 6. Discoverability | No hidden: true in content/subagents/ | grep "hidden: true" exits 1 | grep |
| 7. Language | content/ + docs/ English-only | grep non-English pattern exits 1 | quarterly_review.py |
| 8. ATLAS canonicalization | No stale ATLAS names in F9 scope (content/skills/, content/rules/core/, docs/reference/skills-catalog.md, docs/SKILL_QUALITY_STANDARD.md) | grep stale names exits 1 | grep |

## PASS / WARN / FAIL Gate

Every audit run produces a `## Core Skills Compliance` block:

```
## Core Skills Compliance
- operating-protocol: [PASS] / [WARN] / [FAIL]
- engineering-standards: [PASS] / [WARN] / [FAIL]
- context-management: [PASS] / [WARN] / [FAIL]
- token-efficiency: [PASS] / [WARN] / [FAIL]
- tool-usage: [PASS] / [WARN] / [FAIL]
- governance: [PASS] / [WARN] / [FAIL]
```

- PASS: all 8 domains pass. CI proceeds.
- WARN: 1-2 domains fail non-blockingly. CI proceeds with warning.
- FAIL: any domain fails blockingly (version drift, hidden subagent, schema
  invalid). CI BLOCKS merge. Each FAIL requires documented justification +
  exception ADR.

## Exit-Code Gate (CI-enforceable)

```bash
# Run full audit; exit non-zero if any blocking domain fails
make validate || exit 1
make validate-quality || exit 1
make validate-skill-refs || exit 1
grep -r "hidden: true" content/subagents/ && exit 1 || true
# ATLAS canonicalization check (domain 8, F9 scope; exclude this gate file from self-match)
grep -rnE "ML Model Access|ML Supply Chain Compromise|LLM Plugin Compromise" content/skills/ content/rules/core/ docs/reference/skills-catalog.md docs/SKILL_QUALITY_STANDARD.md --exclude="compliance-audit.md" && exit 1 || true
# version drift check
for skill in $(grep -E "^\s+- \w" manifest.example.yaml | sed 's/.*- //'); do
  mv=$(grep "version:" manifest.example.yaml | head -1 | sed 's/.*: //')
  fv=$(grep "^version:" content/skills/$skill/SKILL.md | head -1 | sed 's/.*: //')
  [ "$mv" != "$fv" ] && echo "DRIFT: $skill" && exit 1
done
exit 0
```

Exit code != 0 = CI BLOCKS merge. No advisory mode.

## Drift Detection (financial-services check.py pattern)

anthropics/financial-services `scripts/check.py` lints every manifest, verifies
all cross-file references resolve, and fails if any bundled skill has drifted
from its vertical source. Governance binding:

- Quarterly: run scripts/quarterly_review.py for staleness + schema v2 audit.
- Per-PR: manifest version MUST equal frontmatter version (domain 5).
- Per-merge: cross-file refs resolve (domain 4).

## Boundary

- Detailed vulnerability hunting: security-expert
- PCI DSS audit: security-expert
- MCP review CRITERIA: engineering-standards/references/mcp-review-criteria.md
- This file = DETERMINISTIC COMPLIANCE GATE + drift detection only.
