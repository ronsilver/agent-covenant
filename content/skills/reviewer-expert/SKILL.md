---
name: reviewer-expert
description: "Systematic code review execution: latent defect detection, test coverage validation, OWASP Top 10 compliance, evolvability analysis, PR review with GitHub CLI, and structured reports with verdict (APPROVE/COMMENT/REQUEST_CHANGES). Optimal speed: 200-400 LOC/hour. Use when reviewing pull requests, auditing code quality, checking for security vulnerabilities, reviewing architectural decisions in PRs, or producing structured review reports. Trigger: code review, PR review, pull request, security review, OWASP, CWE, audit. Do NOT trigger for: planning, architecture design, feature implementation."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: quality
  status: stable
---
# Reviewer Expert

**Code review: PR analysis, security checks, structured reports.**

## Review Workflow

1. **Fetch PR metadata** — `gh pr view <number> --json title,body,author,baseRefName,headRefName`
2. **Get diff** — `gh pr diff <number>`. Check CI: `gh pr checks <number>`
3. **Analyze changes**
   - Architecture: does it fit existing design?
   - Correctness: logic bugs, edge cases, error paths
   - Tests: coverage for new/changed behavior
   - Performance: N+1 queries, unbounded loops, missing indexes
4. **Security phase** (scope = diff only)
   - Secrets: grep for tokens, keys, passwords, connection strings
   - Input validation: new endpoints validated + sanitized?
   - Auth: new routes -> authentication enforced? authorization checked?
   - Injection: SQL/NoSQL/command -> parameterized queries, no `eval`
   - Dependencies: new packages added? check CVE status
   - Cryptography: hardcoded salts, weak algos (MD5/SHA1), insecure random
   - Data exposure: PII in logs, error messages leaking internals
5. **Write review** — structured report
6. **Submit** — `gh pr review <number> --approve | --comment | --request-changes`

## Severity Labels

| Label | Meaning | Action |
|---|---|---|
| `[BLOCKER]` | Must fix before merge | Cannot approve |
| `[MAJOR]` | Should fix; merge at your own risk | Approve with caveat |
| `[LOW]` | Style, minor; author's call | Mention, NEVER block |
| `[PRAISE]` | Highlight good work | ALWAYS include at least one |

## Report Structure

```
## PR Review: <title> (#<number>)
**Author**: @<author> | **Base**: <base> <- <head>
**CI**: PASS | FAIL | PENDING

### Summary
<2-3 sentence overview>

### Strengths
- <what was done well>

### Issues
- [BLOCKER] <file>:<line> — <description> (CWE-XXX if security)
- [MAJOR] <description>

### Security
CLEAN | N findings (CRITICAL/HIGH/MEDIUM)
<findings with CWE reference and concrete fix>

### Verdict
APPROVE | COMMENT | REQUEST CHANGES
<one-line rationale>
```

## Review Speed — Optimal 200-400 LOC/h

- >500 lines changed: flag for scope split
- >1000 lines: request split into 2+ PRs
- Multiple independent changes: request separate PRs per concern

## Plan/Design Review (Pre-implementation)

| Check | Question |
|---|---|
| Requirements | Problem clearly defined? Scope bounded? |
| Design | Architecture fits? Data flow clear? |
| Implementation | Testable? Secure? Handles errors? |
| Operational | Deployable? Observable? Rollback plan? |

**Red flags**:
- No rollback strategy for destructive operations
- No test strategy defined before coding
- Security deferred ("we'll add auth later")
- Over-engineered for stated scale

## Constraints

- NEVER output real secrets — `<REDACTED>` always
- NEVER approve if CI failing or [BLOCKER] issues exist
- NEVER comment on formatting (delegate to linters)
- ALWAYS read PR description before reviewing diff
- Feedback as questions: "What happens if X?" not "Fix this"
- Security findings ALWAYS include CWE reference + concrete fix
- NEVER review >500 LOC without flagging for scope split
- NEVER skip praise — find at least one thing done well

## Overview

Systematic code review methodology for pull requests. Covers PR diff analysis, severity-labeled feedback (BLOCKER/MAJOR/LOW/PRAISE), OWASP Top 10 security scanning, architectural evaluation, and structured report generation with GitHub CLI.

## Anti-patterns

FAIL: **Reviewing >500 LOC changes without flagging scope**
```text
"Found 800 lines changed, looks OK."  # BAD: beyond optimal 200-400 LOC/h
```
PASS: Flag scope split: "This PR exceeds 500 lines. Consider splitting into 2+ PRs per concern."

FAIL: **Approving with CI failing**
```text
"CI has a test failure but the logic looks right, LGTM"  # BAD
```
PASS: Request CI fix: "CI is failing. Please investigate and fix before merge."

FAIL: **Commenting on formatting/style instead of delegating to linters**
```text
"Can you add a space before the brace?"  # BAD: linter handles this
```
PASS: Focus feedback on logic, correctness, security, and architecture. Let `golangci-lint`/`ruff`/`eslint` handle formatting.

FAIL: **Blame-oriented feedback**
```text
"You forgot to handle the error case here."  # BAD: accusatory
```
PASS: Ask questions: "What happens if `processRecord` returns an error here?"

FAIL: **Approving without checking security for new endpoints**
```text
"New route looks clean, approved."  # BAD: skipped input validation, auth check
```
PASS: Security checklist: "Is this new route authenticated? Are inputs validated? Any SQL injection risk?"

## Adversarial Verification Pass

Before trusting your own review verdict, run an adversarial pass (fable-judge, master catalog #152):
1. Re-run every claimed check yourself; do not accept the diff at face value
2. Diff the claimed change against the actual file state
3. Hunt for weakened tests: skipped assertions, loosened bounds, removed coverage
4. Issue a verdict per claim: VERIFIED, CAVEATS, or REFUTED
A REFUTED claim invalidates the review verdict; stop and re-review.

## Receiving-Review Discipline

When your own work is reviewed (master catalog #20):
- Treat every comment as a question about the change, not an attack on the author
- Separate the person from the code; engage the substance, not the tone
- Ask for the reproduction or the failing case before pushing back
- Adopt the fix or explain why it does not apply, in writing

## Doubt-Driven Development

Apply the doubt loop to every non-trivial change (master catalog #17):
CLAIM -> EXTRACT -> DOUBT -> RECONCILE -> STOP
1. CLAIM: state the change's guarantees explicitly
2. EXTRACT: pull the evidence (tests, diffs, logs) that supports each claim
3. DOUBT: try to refute the claim with counter-examples and edge cases
4. RECONCILE: fix or weaken the claim until it survives the doubt
5. STOP: end when the claim cannot be refuted within scope

## References

| Resource | URL | Last verified |
|---|---|---|
| Google Code Review Guide | https://google.github.io/eng-practices/review/ | 2025-05 |
| OWASP Top 10 (2025) | https://owasp.org/Top10/ | 2026-08 |
| GitHub PR Review Docs | https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes | 2025-05 |
| CWE Common Weakness Enumeration | https://cwe.mitre.org/ | 2025-05 |

- [references/ieee-1028.md](references/ieee-1028.md)
- [references/review-metrics.md](references/review-metrics.md)
- [references/review-template.md](references/review-template.md)
- [references/security-checklist.md](references/security-checklist.md)

## Verification Checklist

- [ ] PR description read before reviewing the diff
- [ ] Security phase completed: secrets, input validation, auth, injection, dependencies, cryptography, data exposure
- [ ] At least one praise included in the review feedback
- [ ] Findings labeled with correct severity: `[BLOCKER]` / `[MAJOR]` / `[LOW]`
- [ ] Security findings include CWE reference + concrete fix suggestion
- [ ] Feedback framed as questions (not blame): "What happens if X?" not "Fix this"
- [ ] CI status checked before submitting verdict

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Author pushes back on review feedback | Feedback was prescriptive (commands) instead of curious (questions) | Reframe as questions: "What happens when this endpoint receives negative value?" |
| Critical bug slipped through review | Review pace exceeded optimal 200-400 LOC/h | Flag PRs >500 lines for scope split before starting review |
| Security finding accepted but reintroduced later | No CWE reference in finding to track it | Always include CWE ID; track via security issue in addition to PR comment |
| Reviewer misses bug in PR that touches both backend and frontend (known issue: single-language focus bias) | Reviewer specializes in one language and skims the other | Split review across two reviewers per language; use checklist that explicitly covers frontend + backend |
