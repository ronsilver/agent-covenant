# Done Criteria & Verdict Semantics

## Scope

This file owns the verdict set, handoff status semantics, checkpoint-resumability
policy, status-claim audit rule, and silent-compliance rule. It does NOT own
handoff format (context-management), planning methodology (planning-expert), or
memory persistence mechanism (kernel `<MEMORY>`).

## Verdict Set (PASS / FAIL / INVALID)

Per-gate verdicts for irreversible actions and task completion (pattern:
DanMcInerney/architect-loop R4, V, accessed 2026-07-01):

| Verdict | Meaning | Action |
|---------|---------|--------|
| PASS | Criteria met; proceed | Continue to next step |
| FAIL | Criteria not met; stop + report | Report blocker, NEVER proceed |
| INVALID | Criteria not measured as specified; cannot judge | Re-measure or re-specify criteria |

INVALID prevents "unmeasured = passed" false confidence. If a gate cannot be
measured the way it was specified, the verdict is INVALID, not PASS.

## 4-Status Handoff Semantics

When delegating to a subagent or receiving a handoff (pattern: obra/superpowers,
V, accessed 2026-07-01):

| Status | Meaning | Receiver action |
|--------|---------|-----------------|
| DONE | Task complete, spec + quality verified | Proceed to next task |
| DONE_WITH_CONCERNS | Complete but has open items | Review concerns before proceeding |
| NEEDS_CONTEXT | Missing information to proceed | Provide context, re-dispatch |
| BLOCKED | Cannot proceed, needs human decision | Escalate to user |
| SKIPPED | Task skipped because requirement is impossible. Reason documented. User notified. | Record skip reason; do not mark as DONE |

## Checkpoint Policy

For long multi-step tasks: persist state after each step. On crash or failure,
resume from the last durable checkpoint. Retry metadata (attempt count, last
error, next backoff) belongs in the persisted state record (pattern:
microsoft/pg_durable, V, accessed 2026-07-01).

Crash-recovery trigger: if step cost > reconstruction cost -> resume from
checkpoint; else discard+redispatch. On corrupted context -> always discard
(never resume into poison).

## Status-Claim Audit

Every status assertion ("done", "passing", "healthy") MUST tie to a tool output
from the current session. "Subagent reported success" = hearsay, not V.
Pattern: DanMcInerney/architect-loop R10 (V, accessed 2026-07-01).

## Silent Compliance = Defect

If the agent disagrees with a spec or instruction but proceeds silently, that is
a defect. Every disagreement MUST be raised with a citation to real files. The
response to a raised disagreement is ACCEPT / REJECT / MODIFY + one-line why.
No deferrals (pattern: DanMcInerney/architect-loop R5, V, accessed 2026-07-01).

## SKIPPED Rules

If a verification task is SKIPPED, task verdict = INVALID (not PASS). An unmeasured verification cannot be claimed as passing.

### SKIPPED Decision Tree
1. Can capability be verified by reading official docs? → YES → verify → if not found, BLOCK (not SKIPPED).
2. Can it be verified by running the tool? → YES → run tool → if fails, BLOCK.
3. Neither docs nor tool access available → SKIPPED with: "Cannot verify: <what is missing>. Need: <specific access or docs>."

SKIPPED requires ALL three: (1) docs not available OR tool not accessible, (2) user notified with specific reason, (3) specific unblocking action named.
SKIPPED without unblocking action = INVALID (treated as BLOCKED).
Cannot claim "done" until verification runs. Exception: only if user explicitly approves the skip with documented reason.

## Boundary

- Handoff MECHANICS (JSON schema, message format) -> context-management skill.
- Planning METHODOLOGY -> planning-expert skill.
- Memory PERSISTENCE mechanism -> kernel `<MEMORY>`.
- This file = verdict SET + handoff STATUS semantics + checkpoint + audit.
