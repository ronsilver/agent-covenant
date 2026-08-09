# ADR-0032: Compliance Audit Gate 7 -> 8 Domains

**Date:** 2026-08-08
**Status:** Approved

## Context

The deterministic compliance audit gate (compliance-audit.md) audits 7
domains. ADR-0029 introduces a gateable invariant — no stale ATLAS names in
content/skills/ + content/rules/core/ — requiring an 8th domain so the
canonicalization cannot silently regress. All "7-domain" references in
governance-owned files migrate to 8. Governance version 2.1 -> 2.2.

## Decision

Apply M1-M15. New domain 8 = ATLAS canonicalization (negative grep over F9
scope, exit 1 on stale names). Gate command excludes its own definition file
(`--exclude="compliance-audit.md"`).

## Migration decision — governance/SKILL.md:75/139/254

INCLUDE all three: phrasing "the 7 engineering-standards evaluation domains"
is byte-identical to compliance-audit.md:7 which defines the audit gate;
they name the gate, not engineering-standards' internal domain set.

## Residuals (documented, NOT edited)

1. docs/skills-core-definition.md Spanish legacy mirror (lines 224/290) —
   report-only, separate cleanup ADR.
2. compliance-audit.md "7-pillar" row (line 22) — a different 7
   (SKILL_QUALITY_STANDARD pillars), unchanged.
3. governance "6 Core skills" references — separate concept, unchanged.
4. skills-catalog.md version entries (eng-std v2.2, op v2.1, tool-usage v2.1)
   become stale after T2/T3 — report-only residual.

## Alternatives Considered

1. Keep 7 domains: rejected — gate would not cover the ADR-0029 invariant.
2. Advisory (non-blocking) 8th domain: rejected — gate is deterministic.
3. Governance 3.0 MAJOR bump: rejected — additive, MINOR.add (2.2) correct.

## Evidence

- Grep sweep 2026-08-08: 12 "7-domain" locations (governance/SKILL.md
  75/139/232/254/259, compliance-audit.md 7/16/42, overview.md:11,
  evals.json:37, tool-usage/SKILL.md:53, content/rules/core/governance.md:19,
  docs/reference/skills-catalog.md:20).
- governance SKILL.md:8 version "2.1".

## Appendix A — Applied Edits

| ID | File | oldText | newText |
|----|------|---------|---------|
| M1 | governance/SKILL.md:8 | `  version: "2.1"` | `  version: "2.2"` |
| M2 | governance/SKILL.md:75 | `Every step must be auditable against the 7 engineering-standards evaluation domains.` | `Every step must be auditable against the 8 engineering-standards evaluation domains.` |
| M3 | governance/SKILL.md:139 | `\| Workflow step \| Auditable against 7 engineering domains \| Minor violation \|` | `\| Workflow step \| Auditable against 8 engineering domains \| Minor violation \|` |
| M4 | governance/SKILL.md:232 | `- [references/compliance-audit.md](references/compliance-audit.md) - Deterministic 7-domain audit + drift detection + exit-code gate (audits by reference)` | `- [references/compliance-audit.md](references/compliance-audit.md) - Deterministic 8-domain audit + drift detection + exit-code gate (audits by reference)` |
| M5 | governance/SKILL.md:254 | `- [ ] Workflow steps are auditable against all 7 engineering-standards domains` | `- [ ] Workflow steps are auditable against all 8 engineering-standards domains` |
| M6 | governance/SKILL.md:259 | `- [ ] Compliance audit exit-code gate passed (7 domains, no FAIL on blocking)` | `- [ ] Compliance audit exit-code gate passed (8 domains, no FAIL on blocking)` |
| M7 | compliance-audit.md:7 | `against the 7 engineering-standards evaluation domains -- does NOT duplicate` | `against the 8 engineering-standards evaluation domains -- does NOT duplicate` |
| M8 | compliance-audit.md:16 | `## 7-Domain Audit` | `## 8-Domain Audit` |
| M9 | compliance-audit.md (after domain-7 row) | `\| 7. Language \| content/ + docs/ English-only \| grep non-English pattern exits 1 \| quarterly_review.py \|` | `\| 7. Language \| content/ + docs/ English-only \| grep non-English pattern exits 1 \| quarterly_review.py \|\n\| 8. ATLAS canonicalization \| No stale ATLAS names in F9 scope (content/skills/, content/rules/core/, docs/reference/skills-catalog.md, docs/SKILL_QUALITY_STANDARD.md) \| grep stale names exits 1 \| grep \|` |
| M10 | compliance-audit.md:42 | `- PASS: all 7 domains pass. CI proceeds.` | `- PASS: all 8 domains pass. CI proceeds.` |
| M11 | compliance-audit.md (exit-code block, after hidden:true line) | `grep -r "hidden: true" content/subagents/ && exit 1 || true\n# version drift check` | `grep -r "hidden: true" content/subagents/ && exit 1 || true\n# ATLAS canonicalization check (domain 8, F9 scope; exclude this gate file from self-match)\ngrep -rnE "ML Model Access|ML Supply Chain Compromise|LLM Plugin Compromise" content/skills/ content/rules/core/ docs/reference/skills-catalog.md docs/SKILL_QUALITY_STANDARD.md --exclude="compliance-audit.md" && exit 1 || true\n# version drift check` |
| M12 | governance/references/overview.md:11 | `\| [compliance-audit.md](compliance-audit.md) \| Deterministic 7-domain compliance audit + drift detection + exit-code gate (audits by reference) \|` | `\| [compliance-audit.md](compliance-audit.md) \| Deterministic 8-domain compliance audit + drift detection + exit-code gate (audits by reference) \|` |
| M13 | governance/evals/evals.json:37 | `"expected_output": "7 domains (compliance-audit.md): manifest, schema, quality (>=70), references, version drift, discoverability (no hidden:true), language (English-only).` | `"expected_output": "8 domains (compliance-audit.md): manifest, schema, quality (>=70), references, version drift, discoverability (no hidden:true), language (English-only), ATLAS canonicalization (no stale ATLAS names per ADR-0029).` |
| M14 | tool-usage/SKILL.md:53 | `- \`engineering-standards\`: Does it comply with the 7 evaluation domains?` | `- \`engineering-standards\`: Does it comply with the 8 evaluation domains?` |
| M15a | content/rules/core/governance.md:19 | `- Workflows: every step auditable against 7 engineering evaluation domains` | `- Workflows: every step auditable against 8 engineering evaluation domains` |
| M15b | docs/reference/skills-catalog.md:20 | `- **governance** (v2.1):` | `- **governance** (v2.2):` |
| M15c | docs/reference/skills-catalog.md:20 | `(deterministic 7-domain exit-code gate, audits by reference)` | `(deterministic 8-domain exit-code gate, audits by reference)` |
