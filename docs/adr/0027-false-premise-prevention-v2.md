# ADR-0027: False Premise Prevention v2 — External Capability Verification

**Date:** 2026-08-05
**Status:** Proposed

## Context

Round 1 implemented 4 safeguards against false-premise acceptance (ADR-0025). Stress testing (ultraresearch + ultrathinking) found the conditional trigger in planning-expert Step 0 has 60-80% reliability. The core gap: operating-protocol (loaded by ALL agents and subagents) lacks an explicit "verify external tool capabilities before acting" rule. When agents receive claims like "Tool X has feature Y" during execution, they accept and propagate the premise without verification.

## Decision

Implement 7 fixes across 6 files:

1. **planning-expert Step 0**: Change from conditional to MANDATORY — scan ALL named third-party tools
2. **planning-expert Step 7**: Add Assumption Audit — review plan for unverified external claims
3. **operating-protocol Error Retries**: Add TRANSIENT vs PREMISE error classification before max_iter
4. **reasoning-expert Premise Acceptance**: Add CLAIM vs REQUIREMENT disambiguation
5. **done-criteria.md SKIPPED Rules**: Add decision tree requiring unblocking action
6. **scope-discipline.md**: Add Post-Plan Verification Gate (grep for tags)
7. **operating-protocol Verification Checklist**: Add External Capability Verification gate

## Scope Analysis (ultraresearch + ultrathinking)

| Component | Needed? | Why |
|-----------|---------|-----|
| operating-protocol (Core) | YES | Always-loaded, covers ALL agents/subagents |
| planning-expert | YES (already done in R1) | Planning phase verification |
| reasoning-expert | YES (already done in R1) | Reasoning phase detection |
| done-criteria.md | YES (already done in R1) | Handoff phase SKIPPED rules |
| scope-discipline.md | YES (already done in R1) | Post-plan tag enforcement |
| Subagent template | NO | Redundant with Core skill inheritance |
| All 50+ skills | NO | Wrong domain, high maintenance |
| governance | NO | Meta-process, not content validation |
| engineering-standards | NO | Code quality scope |
| Kernel | OPTIONAL | Pointer only, ~50 chars |

## Alternatives Considered

1. **Extend to all subagents individually**: Rejected — redundant with Core skill inheritance (invariant #4)
2. **Extend to all 50+ ordinary skills**: Rejected — high maintenance, low value, wrong domain
3. **Extend to governance/engineering-standards**: Rejected — scope creep, wrong domain
4. **Add to kernel as full rule**: Rejected — 6,000 char limit, pointer only feasible

## Consequences

- planning-expert: Step 0 always runs, cannot be skipped; Step 7 adds post-plan audit
- operating-protocol: Error classification adds ~2 lines per retry; External Capability Verification adds 1 checklist item
- reasoning-expert: Premise Acceptance fallacy now disambiguates CLAIM vs REQUIREMENT
- done-criteria.md: SKIPPED requires unblocking action or is treated as BLOCKED
- scope-discipline.md: Post-plan gate catches unverified premises before execution
- All agents/subagents: inherit External Capability Verification via boot skill loading

## Evidence

Scope analysis based on:
- ultraresearch dossier: architecture analysis, maintenance burden comparison, minimal effective scope
- ultrathinking stress test: 7 bypass scenarios, false positive analysis, difficulty ratings
- Both agents converged: ONE change to operating-protocol covers entire ecosystem
