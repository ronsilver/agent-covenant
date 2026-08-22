# Content Directory — Standard for Control Clauses

> Single source of truth for all control clauses, severity tags, obligation
> verbs, and violation labels used across `content/` (skills, rules, subagents,
> workflows, prompts). Any prompt authored in this repository MUST conform to
> this standard.

## Scope

This standard applies to every Markdown file under `content/`:
`skills/`, `rules/`, `subagents/`, `workflows/`, `prompts/`, `mcp/`, `hooks/`.

## Global Casing Rule

ALL control clauses, severity tags, and violation labels are **UPPERCASE**.
This makes them visually distinct from normal prose and easy to scan.

- CORRECT: `[BLOCKER]`, `BEFORE`, `MUST`, `NEVER`
- INCORRECT: `[blocker]`, `before`, `must`, `never` (as control clauses)

---

## 1. Temporal Clauses (Execution Order)

| Clause | Meaning | Syntax |
|---|---|---|
| `BEFORE` | Precondition: must hold prior to an action | Uppercase, inline or at bullet start |
| `AFTER` | Postcondition: must hold after an action | Uppercase, inline or at bullet start |

### Rules
- Use ONLY `BEFORE` / `AFTER`. Do NOT introduce `DURING`, `WHILE`, `UPON`, `ONCE` as control clauses.
- In bullet lists: place at the start in uppercase (`- BEFORE editing, read the file.`).
- In prose: inline uppercase (`Read BEFORE edit.`).
- SQL keywords (`BEFORE INSERT`, `AFTER UPDATE`) are NOT control clauses — exclude them.

### Examples
**Correct:**
- `Read file BEFORE editing.`
- `Run tests AFTER every change.`
- `Load 7 baseline skills BEFORE step 1 of the Workflow.`

**Incorrect:**
- `Read file before editing.` (lowercase — ambiguous with normal prose)
- `Upon completion, run tests.` (use `AFTER`, not `UPON`)

---

## 2. Severity Tags (Findings, Plans, Pre-mortems, PR Review)

Bracketed uppercase labels indicating the impact level of a finding, risk, or
plan warning. This hierarchy is UNIFIED — applies everywhere including PR review.

| Tag | Level | Use when | Blocks merge? |
|---|---|---|---|
| `[BLOCKER]` | 1 — Critical | Risk to regulatory compliance, SLO 99.9%, data loss, money loss, OR "must fix before merge" | Yes |
| `[CRITICAL]` | 2 — Critical vuln | Security finding (SAST/CVE) that does not necessarily break PCI/SLO | No (fix ASAP) |
| `[HIGH]` | 3 — High | High-severity defect or vulnerability | No |
| `[MAJOR]` | 4 — Major | Significant functional defect; "should fix, merge at your own risk" | No |
| `[MEDIUM]` | 5 — Medium | Moderate defect | No |
| `[MINOR]` | 6 — Minor | Minor defect | No |
| `[LOW]` | 7 — Low | Style / minor observation; "don't block" | No |
| `[WARN]` | — | Non-blocking warning in pre-mortems / plans | No |
| `[ASSUMPTION]` | — | Assumption that invalidates the plan if false | No |
| `[INFO]` | — | Neutral contextual note | No |
| `[PRAISE]` | — | Positive feedback (PR review ONLY — not a severity) | No |

### Hierarchy
`[BLOCKER]` > `[CRITICAL]` > `[HIGH]` > `[MAJOR]` > `[MEDIUM]` > `[MINOR]` > `[LOW]`

> **Note**: For deterministic ordinal anchoring in LLMs, consider using numeric prefixes
> (`[1-BLOCKER]`…`[7-LOW]`). The bare names are the canonical form; numeric prefixes
> are an optional alias for models that benefit from explicit rank ordering.

### Rules
- ALWAYS uppercase, ALWAYS bracketed: `[BLOCKER]`, never `[blocker]`.
- ONE tag per finding. Do NOT stack (`[BLOCKER][CRITICAL]` is forbidden).
- `[BLOCKER]` = critical risk (PCI/SLO/data/money loss) OR "must fix before merge" (PR review).
- `[PRAISE]` is the ONLY non-severity tag. Scoped to PR review. ALWAYS include ≥1 in PR reviews.

### Deprecated (refactor away)
- Lowercase `[blocking]` → use `[BLOCKER]`
- Bare `BLOCKING` (no bracket) → use `[BLOCKER]`
- Lowercase `[important]` → use `[MAJOR]`
- Lowercase `[nit]` → use `[LOW]`
- Lowercase `[praise]` → use `[PRAISE]`
- `[BLOCKED]` as a severity tag → use `[BLOCKER]`. (`[BLOCKED]` = action state, not finding tag.)

### PR-Review Tag Mapping (reviewer-expert refactor)
| Old (lowercase) | New (unified uppercase) |
|---|---|
| `[blocking]` | `[BLOCKER]` |
| `[important]` | `[MAJOR]` |
| `[nit]` | `[LOW]` |
| `[praise]` | `[PRAISE]` |

### Examples
**Correct:**
- `[BLOCKER] PAN in clear in logs — PCI Req 3.3.1 violation.`
- `[CRITICAL] SQL injection in auth.go:42 (CWE-89).`
- `[MAJOR] Error handling missing in payment path.`
- `[PRAISE] Good extraction of validation logic into reusable helper.`
- `[WARN] Redis hot key possible for high-volume merchants.`

**Incorrect:**
- `[blocking] must fix before merge.` → use `[BLOCKER]`
- `[important] refactor this.` → use `[MAJOR]`
- `[BLOCKER][CRITICAL] vuln found.` → pick ONE tag

---

## 3. Obligation Verbs (RFC 2119 Canonical)

| Verb | Level | Use for |
|---|---|---|
| `MUST` | Required | Non-negotiable requirement (formal/specs) |
| `MUST NOT` | Prohibited | Non-negotiable prohibition (formal/specs) |
| `SHOULD` | Recommended | Strong recommendation, justified exceptions allowed |
| `SHOULD NOT` | Discouraged | Discouraged, justified exceptions allowed |
| `MAY` | Optional | Optional permission |
| `NEVER` | Absolute prohibition | Emphatic alias of `MUST NOT` (golden rules, anti-patterns) |
| `ALWAYS` | Absolute mandate | Emphatic alias of `MUST` (golden rules, anti-patterns) |

### Rules
- `MUST` / `MUST NOT` = formal normative vocabulary (specs, compliance, governance).
- `NEVER` / `ALWAYS` = emphatic vocabulary (golden rules, anti-patterns, security).
- Do NOT mix within one document: normative doc → `MUST`/`MUST NOT`;
  practical-rules doc → `NEVER`/`ALWAYS`.
- `DO` / `DO NOT` → DEPRECATED. Replace with `MUST` / `MUST NOT` or `ALWAYS` / `NEVER`.
- `don't` / `do not` / `Do not` / `Do NOT` / `Don't` → DEPRECATED (lowercase/capitalized variants). Replace with `NEVER` / `MUST NOT` (prohibition) or `MUST` / `ALWAYS` (mandate). These lowercase forms are ambiguous with prose idioms and inconsistent with the UPPERCASE control-clause convention.

### Examples
**Correct (formal):**
- `Subagents MUST load all 7 boot skills before executing.`
- `PAN MUST NOT be stored in application databases.`

**Correct (emphatic):**
- `NEVER log raw PAN.`
- `ALWAYS mask PAN in logs.`

**Incorrect:**
- `DO not store CVV.` → use `MUST NOT` or `NEVER`
- `Don't hardcode secrets.` → use `NEVER hardcode secrets.`

---

## 4. Violation Tags (Governance — Immutable)

Defined by the `governance` Core skill and `rules/README.md`. IMMUTABLE — do
NOT modify via this standard. Listed for reference.

| Tag | Severity | Action |
|---|---|---|
| `[GOVERNANCE VIOLATION]` | Moderate+ | BLOCK + escalate |
| `[SCOPE VIOLATION]` | Moderate | Terminate subagent |
| `[CORE CONFLICT]` | Critical | Escalate human |
| `[CORE COMPLIANCE FAILURE]` | Critical | BLOCK |
| `[CI GATE VIOLATION]` | Critical | BLOCK merge |
| `[DISCOVERABILITY VIOLATION]` | Catastrophic | BLOCK |
| `[LANGUAGE POLICY VIOLATION]` | Moderate+ (BLOCK) | BLOCK |

### Rules
- These are the ONLY recognized governance violation tags.
- Do NOT invent new violation tags without an ADR.
- `[BLOCKED]` is an action state, NOT a violation tag.

---

## 5. Output Status Tags (Task / Claim State)

Bracketed uppercase labels indicating the state of a task, plan, or factual
claim in agent output. Distinct from severity (which classifies findings) and
violation tags (which classify governance breaches).

| Tag | Meaning | Action |
|---|---|---|
| `[NEEDS CLARIFICATION]` | Task/plan has ambiguity; agent proceeds on safest documented assumption | Surface in output; proceed cautiously |
| `[NEEDS VERIFICATION]` | Factual claim cannot be verified (source missing or blocked) | NEVER assert as fact; flag for human review |
| `[PASS]` | Compliance gate passed | Proceed |
| `[FAIL]` | Compliance gate failed | BLOCK; requires documented ADR exception |

### Rules
- ALWAYS uppercase, ALWAYS bracketed.
- `[NEEDS CLARIFICATION]` is for ambiguity in scope/requirements.
- `[NEEDS VERIFICATION]` is for unverified factual claims (anti-hallucination).
- Do NOT confuse with severity tags: `[NEEDS CLARIFICATION]` is not a finding,
  it is a state marker on the task itself.

### Examples
**Correct:**
- `Output: [NEEDS CLARIFICATION] merchant tier config ambiguous — proceeding with default tier.`
- `Claim: [NEEDS VERIFICATION] — could not read secrets manager source; do not assert token format.`

**Incorrect:**
- `[NEEDS CLARIFICATION] SQL injection found.` → use `[CRITICAL]` (this is a finding, not a state)

---

## Quick-Reference Cheat Sheet

```
TEMPORAL:    BEFORE | AFTER
SEVERITY:    [BLOCKER] [CRITICAL] [HIGH] [MAJOR] [MEDIUM] [MINOR] [LOW]
             [WARN] [ASSUMPTION] [INFO] [PRAISE]
OBLIGATION:  MUST | MUST NOT | SHOULD | SHOULD NOT | MAY | NEVER | ALWAYS
VIOLATION:   [GOVERNANCE VIOLATION] [SCOPE VIOLATION] [CORE CONFLICT]
             [CORE COMPLIANCE FAILURE] [CI GATE VIOLATION]
             [DISCOVERABILITY VIOLATION] [LANGUAGE POLICY VIOLATION]
STATUS:      [NEEDS CLARIFICATION] [NEEDS VERIFICATION] [PASS] [FAIL]
```

---

## Conformance

A file conforms to this standard when:
1. All temporal ordering uses `BEFORE` / `AFTER` (uppercase), not synonyms.
2. All severity findings use exactly one tag from the §2 table (uppercase,
   bracketed), with `[BLOCKER]` for critical risk or must-fix-before-merge.
3. All obligation verbs are `MUST`/`MUST NOT`/`SHOULD`/`SHOULD NOT`/`MAY`
   (formal) or `NEVER`/`ALWAYS` (emphatic). No `DO`/`DO NOT`.
4. No deprecated tags (`[blocking]`, `[important]`, `[nit]`, `[praise]` lowercase).
5. Governance violation tags remain untouched (§4 list).
6. `[PRAISE]` appears ONLY in PR-review context (reviewer-expert).
7. All control clauses are UPPERCASE.
8. No emoji icons or status dingbats — use text labels (`Correct:`/`Incorrect:`/`[BLOCKER]`/`[WARN]`/`[PASS]`/`[FAIL]`). Arrows (`→ ←`) and bullets (`•`) are permitted.
9. All prose (including `description:` frontmatter and body sections) is English. Proper nouns and data examples (e.g. `José → Jose`) are exempt.

## Validation

`make validate` (manifest + frontmatter) does NOT yet check clause conformance.
A future lint rule (`scripts/check-clauses.sh`) will enforce this standard.
Until then, manual review + the refactor plan in
`docs/plans/refactor-clausulas-prompts.md` govern adoption.
