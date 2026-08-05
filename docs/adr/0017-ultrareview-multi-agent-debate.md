# ADR-0017 -- ultrareview Multi-Agent Debate for specialist conflicts

**Status**: Accepted · **Date**: 2026-06-24

## Context
`ultrareview` (read mode) Workflow step 6 resolves conflicts between the 6
parallel specialists using a **linear hierarchy** (Security > Performance >
Maintainability > Style). When two specialists disagree on the SAME finding
(e.g., security flags [BLOCKER] while performance flags [MINOR] on the same
hot path), the hierarchy imposes the higher tier without examining the
disagreement. Multi-Agent Debate (Du et al., 2023, arXiv:2305.14325 `[I]`)
adds one structured debate round that converges to a more calibrated verdict
than a naive hierarchy override.

## Decision
Add a Multi-Agent Debate step, triggered ONLY when two specialists produce
conflicting severities on the same anchored finding (same `file:line`). One
debate round: each side states its case + evidence, then the orchestrator
adjudicates with the joint evidence. Non-conflicting findings skip the debate
(token cost not justified).

## Alternatives rejected
- Debate on every finding: +cost, no benefit on non-conflicting findings. Rejected.
- Multiple debate rounds (k>1): diminishing returns; 1 round suffices. Rejected.
- Keep pure hierarchy: misses calibration on genuine disagreements. Rejected.

## Consequences
- (+) More calibrated verdicts on specialist disagreements.
- (+) Audit trail of WHY a conflict was resolved a given way.
- (-) +latency and +tokens only on conflicting findings (gate acutes).
- (-) Risk of debate never converging -- mitigated by 1-round cap + orchestrator adjudication.

## Edit spec
See Edit below: APPEND Multi-Agent Debate section to `content/subagents/ultrareview.md`
after Workflow step 6 / before Output format.

## Approval
- Human: Accepted (explicit user approval 2026-06-24, "trabajemos en estos 2" group).
