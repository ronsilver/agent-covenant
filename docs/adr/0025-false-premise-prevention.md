# ADR 0025: False Premise Prevention — Operating Protocol Enhancement

**Date:** 2026-08-04
**Status:** Proposed

## Context

Agent pipeline (ultraplan → ultrareview → ultrathinking → ultracode) iterated 50+
times on a ZAP server task because agents accepted a false user premise ("ZAP
daemon mode has a Web UI") without verification. Root cause: agents accept user
claims about third-party software capabilities by default. The operating-protocol
skill defines max_iter=2 but lacks a concrete enforcement mechanism. The planning-expert
skill has no step to verify feature existence before committing to a plan.

## Decision

Enhance 4 skill files with surgical safeguards:

1. **planning-expert**: Add conditional "Feature Existence Check" step (Step 0) that
   verifies third-party tool capabilities against official docs before planning.
   Add assumption classification (`verified | unverified | critical`). Add
   anti-pattern for accepting unverified claims.

2. **operating-protocol**: Add concrete enforcement mechanism for max_iter=2
   (retry/blocker emit tags). Add anti-pattern for 3+ fix attempts without
   premise reassessment. Add troubleshooting row.

3. **operating-protocol/references/done-criteria.md**: Add SKIPPED status to
   4-Status Handoff table. Add SKIPPED Rules section (verification tasks that
   are SKIPPED get INVALID verdict, not PASS).

4. **reasoning-expert**: Add "Premise Acceptance" fallacy to Fallacy Detection.
   Add user claims verification constraint.

These are operational improvements to existing skill content, not architectural
changes. The orchestration flow, skill structure, and manifest are unchanged.

## Alternatives Considered

1. **Add blanket fact-verification to every planning cycle**: Rejected — adds
   overhead to all plans including internal-code-only plans. Conditional trigger
   is more efficient.

2. **Add environment detection to planning-expert**: Rejected — belongs in
   execution layer (ultracode), not planning layer. Plans should be
   environment-agnostic where possible.

3. **Change orchestration flow to add research-before-plan**: Rejected — changes
   core pipeline architecture for an edge case. Skill-level conditional gate is
   less invasive.

4. **Add external fact verification to reviewer-expert**: Rejected — changes
   reviewer scope from code quality to external verification. Flagging unverified
   claims is sufficient; verification belongs in a research step.

## Consequences

- **Easier**: False premises about third-party software caught before planning
  (earliest possible point in the pipeline).
- **Easier**: max_iter enforcement becomes observable (RETRY/BLOCKED tags).
- **Easier**: Skipped verification tasks produce INVALID verdict instead of false PASS.
- **Harder**: planning-expert Step 0 adds conditional overhead (mitigated: only
  triggers when plan depends on external tool capabilities).
- **Risk**: Step 0 could over-trigger on internal code assumptions. Mitigated:
  scoped to third-party tool capability claims specifically.

## Evidence

Analysis based on two conversation histories (STATIC, read 2026-08-04):
- `/Users/silver/Desktop/reasong/new-session-2026-08-04t13-41-52-641z-2026-08-04.md` (2469 lines)
- `/Users/silver/Desktop/reasong/implementar-plan-zap-server-2026-08-04.md` (1236 lines)

Stress-tested by ultrathinking agent: 8 proposed fixes reduced to 4 after
identifying circular logic, confirmation bias, and premature convergence in
the initial analysis.
