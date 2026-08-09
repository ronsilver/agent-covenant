# Skill Quality Standard — 7 Pillars

> Version: 1.0 | Effective: 2026-05-25
> Applies to all skills under `content/skills/`

Every skill in this repository must meet the **7-pillar standard** to be considered
"world-class." This document defines each pillar, how it is measured, and provides
before/after examples.

---

## The 7 Pillars

| # | Pillar | Weight | Definition |
|---|--------|--------|------------|
| 1 | **Autosuficiencia** | 20pt | Skill is usable without chasing `references/` files for the 80% common case |
| 2 | **Árbol de decisiones** | 15pt | Contains a decision table or branching workflow with ≥3 routes |
| 3 | **Anti-patrones** | 15pt | ≥3 `❌ WRONG` / `✅ CORRECT` pairs with concrete code examples |
| 4 | **Verificación** | 15pt | Workflow ends with a verification checklist or confirm steps |
| 5 | **Profundidad** | 10pt | Documents known bugs, platform quirks, or edge cases |
| 6 | **Triggers precisos** | 15pt | `description` has ≥3 trigger keywords + ≥1 anti-trigger ("Do NOT use for...") |
| 7 | **Referencias vivas** | 10pt | ≥2 external URLs with `last_verified: YYYY-MM-DD` dates |

**Total:** 100pt. Minimum passing: 70pt. World-class target: 80pt+

---

## How Scoring Works

Run `scripts/validate-skill-quality.py` to score all skills:

```bash
python3 scripts/validate-skill-quality.py           # summary
python3 scripts/validate-skill-quality.py --report  # detailed per-skill
python3 scripts/validate-skill-quality.py --ci      # CI mode (exit 1 if below threshold)
python3 scripts/validate-skill-quality.py --json    # machine-readable
```

Set minimum via env var: `QUALITY_MIN_SCORE=80 make validate-quality`

---

## Pillar Details

### 1. Autosuficiencia (20pt)

**Goal:** Agent can complete the 80% scenario using only `SKILL.md` content.
Reference files are for the 20% edge cases.

**Measurement:**
```
inline_ratio = SKILL.md lines / (SKILL.md lines + references/ total lines)
score = 20 * inline_ratio
```

**Before (bad):** `references/implementation.md` contains 200 lines; `SKILL.md`
says "see refs" with 20 lines of stub content.

**After (good):** SKILL.md has 150 lines covering the main workflow, with 1-2
reference files for advanced topics only.

---

### 2. Árbol de decisiones (15pt)

**Goal:** Agent can route between scenarios without asking the user.

**Measurement:**
- Markdown table with ≥3 content rows, or
- ≥3 `If X: / When Y:` conditional branches in the workflow

**Example:**
```markdown
| If you need to         | Do this            |
|------------------------|--------------------|
| Create a new resource  | Follow path A      |
| Update an existing one | Follow path B      |
| Debug a failure        | Follow path C      |
```

---

### 3. Anti-patrones (15pt)

**Goal:** Teach the agent what NOT to do, not just what to do.

**Measurement:** Count of `❌`/`✅` pairs where both markers have adjacent code blocks.

**Example:**
```markdown
### ❌ Hardcoding credentials
```go
// WRONG
db := sql.Open("postgres", "user=admin password=secret")
```
```go
// CORRECT
db := sql.Open("postgres", os.Getenv("DATABASE_URL"))
```
**Why:** Hardcoded secrets leak in version control and violate security policy.
```

---

### 4. Verificación (15pt)

**Goal:** Every workflow has a "did it work?" gate before claiming done.

**Measurement:**
- `## Verification` section present (7pt)
- ≥3 checklist items `- [ ]` (5pt)
- ≥5 verify/confirm/validate keywords (3pt)

**Example:**
```markdown
## Verification Checklist

Before claiming done:
- [ ] Run `npm test` — all green
- [ ] Check `/health` endpoint returns 200
- [ ] Confirm logs show no errors
- [ ] Edge case: empty input handled gracefully
```

---

### 5. Profundidad (10pt)

**Goal:** Skill shows real expertise — not just API docs, but known quirks.

**Measurement:** Count of "gotcha"/"known bug"/"limitation"/"workaround" mentions
plus presence of a troubleshooting section.

**Example:**
```
⚠ Known issue: Library v2.3.1 throws on Unicode chars. Use v2.3.2+ or
apply this workaround in older versions: [code].
```

---

### 6. Triggers precisos (15pt)

**Goal:** `description` field lets the agent decide when to load the skill
and when to skip it.

**Measurement:**
- ≥3 trigger keywords (e.g., "Use when building X, debugging Y, implementing Z")
- ≥1 anti-trigger (e.g., "Do NOT trigger for pure configuration changes")

**Before (bad):**
```yaml
description: Security rules for the application.
```

**After (good):**
```yaml
description: Security audit rules for cloud-native services. Trigger: OWASP review, SAST scan,
  CVE check, threat model, IAM audit, secret scan. Do NOT trigger for: runtime patches,
  dependency updates without security context. Use when: reviewing PRs for security,
  running semgrep/checkov, or auditing infrastructure IaC.
```

---

### 7. Referencias vivas (10pt)

**Goal:** External references are verifiable and don't rot silently.

**Measurement:**
- ≥2 external URLs (not internal/proprietary repos)
- ≥1 `last_verified: YYYY-MM-DD` date

**Example:**
```markdown
## References

| Resource | URL | Last verified |
|---|---|---|
| Official OWASP Top 10 (2025) | https://owasp.org/Top10/ | 2026-08-08 |
| AWS IAM Best Practices | https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html | 2026-05-25 |
```

---

## CI Integration

The `make validate-quality` target runs the scoring script in CI mode.
A PR will be blocked if any skill scores below `QUALITY_MIN_SCORE` (default: 70).

```bash
make validate-quality              # runs with default threshold (70)
make validate-quality MIN=80       # stricter world-class threshold
```

---

## Skill Quality Lifecycle

```
[Draft]  → score < 50   → needs major work
[Good]   → score 50-69   → needs specific improvements
[Great]  → score 70-79   → passing, one or two weak pillars
[World-class] → score 80+ → all 7 pillars strong
```

New skills start as `status: draft`. They graduate to `status: stable` only
when scoring ≥70 on the 7-pillar standard.

---

## Related

- [SKILL.md Template](../content/skills/_TEMPLATE/SKILL.md) — canonical structure
- See `_TEMPLATE` in `content/skills/` for skill creation workflow
- [manifest.yaml](../manifest.yaml) — registration
- [AgentSkills.io specification](https://agentskills.io/specification) — industry standard
