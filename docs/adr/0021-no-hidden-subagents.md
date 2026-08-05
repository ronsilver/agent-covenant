# ADR-0021 -- No `hidden: true` for subagents (discoverability invariant)

**Status**: Accepted · **Date**: 2026-06-24

## Context
10 of 17 subagents in `content/subagents/` had `hidden: true` in frontmatter,
making them invisible in the TUI/CLI agent picker of OpenCode (and any other
agent that respects the field). Orchestrators (`code-review`, `ultrareview`)
could still invoke them via `task`, but users could not. Asymmetric
discoverability: orchestrators knew the agents existed; users did not.

The original intent of `hidden: true` was to reduce clutter in the agent
menu, keeping only "primary" agents visible. This is a reasonable design
choice but it conflicts with the project's documented Orchestration Flow
(AGENTS.md L191-200), which treats all 17 subagents as first-class citizens.

## Decision
Remove `hidden: true` from all 10 affected subagents. All 17 subagents are
now visible in every agent's TUI/CLI picker. The `hidden` field remains
supported for system-internal agents but is forbidden in
`content/subagents/`.

This rule is encoded in two places in AGENTS.md for defense in depth:
- `Validation Rules > Subagents` (validation gate at sync time).
- `Architectural Invariants` (invariant #8: Subagent Discoverability).

Violations escalate as `[DISCOVERABILITY VIOLATION]` (parallel to existing
escalation tags: `[GOVERNANCE VIOLATION]`, `[CORE COMPLIANCE FAILURE]`,
`[LANGUAGE POLICY VIOLATION]`, `[CI GATE VIOLATION]`).

## Alternatives rejected
- Keep `hidden: true` for specialists only: preserves clutter-reduction but
  perpetuates the asymmetry. Rejected.
- Move hidden subagents to a separate `content/subagents-internal/` dir:
  would require sync logic changes; same effect achievable with frontmatter
  rule. Rejected.
- Document the asymmetry without fixing it: user can't find specialists
  they need. Rejected.

## Consequences
- (+) All 17 subagents visible in TUI: no discoverability gap.
- (+) Invariant encoded in AGENTS.md: enforced at sync time + governance gate.
- (+) Test added: `make validate` catches future violations of `hidden: true`
  in `content/subagents/*.md` (TBD; current fix removes existing ones but
  new additions could re-introduce).
- (-) TUI agent menu has 17 entries instead of 7; minor visual clutter.
- (-) `hidden` field becomes de-facto reserved for system-internal use only;
  any future use in repo subagents is a violation.

## Files changed

| File | Change |
|------|--------|
| `content/subagents/athia-agent.md` | removed `hidden: true` |
| `content/subagents/code-review.md` | removed `hidden: true` |
| `content/subagents/dependency-audit-agent.md` | removed `hidden: true` |
| `content/subagents/idempotency-agent.md` | removed `hidden: true` |
| `content/subagents/linting-agent.md` | removed `hidden: true` |
| `content/subagents/performance-profiler.md` | removed `hidden: true` |
| `content/subagents/prompt-engineer-agent.md` | removed `hidden: true` |
| `content/subagents/psp-integration-agent.md` | removed `hidden: true` |
| `content/subagents/security-auditor.md` | removed `hidden: true` |
| `AGENTS.md` | added Validation Rule + Architectural Invariant #8 |
| `CHANGELOG.md` | entry under `[Unreleased] / ### Changed` |
| `README.md` | ADR count 20 -> 21 |

## Approval
- Human: Accepted (explicit user instruction 2026-06-24, "no deben quedar como
  hidden nunca, corregelo por favor y agrega esa regla en @AGENTS.md").
