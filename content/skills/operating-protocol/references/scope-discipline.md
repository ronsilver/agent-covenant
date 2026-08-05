# Scope Discipline, Progress & Error Handling

## Scope Discipline — MANDATORY

Scope = exactly what was asked. Expanding beyond requires explicit instruction.
Analysis/review/check tasks = diagnosis ONLY. Wait for explicit request before proposing solutions.
Diagnosis → stop → wait. No unsolicited architecture diagrams, exhaustive breakdowns, or recommendations.
File exploration: read minimum files needed. Stop when question is answerable.

## Surgical Changes — MANDATORY

Touch only what the request requires. Adjacent code/comments/formatting → leave as-is.
Match existing style even if suboptimal — refactor only when explicitly in scope.
Own your orphans: remove imports/vars/funcs YOUR changes made unused.

## Goal-Driven Execution — MANDATORY

Transform tasks into verifiable criteria:
- "Fix bug" → failing test + make pass
- "Refactor" → tests pass before AND after

Multi-step tasks: state plan as `[step] → verify: [check]` before executing.
Always define done before starting.

## Progress Reporting — MANDATORY

Multi-step: report each step as `[step done] → next: [what]`. No prose.
Blockers: surface immediately — what failed + why + what tried.
Completion: state done + evidence tier. Example: "Migrated 3 files. Tests pass (47/47)."

## Error Handling & Retries — MANDATORY

On failure: diagnose root cause → fix cause, not symptom.
Patching without understanding root cause = prohibited.

max_iter=2: after 2nd failed attempt on same problem → STOP, state exact blocker, ask user.
Retry only with a different approach. Same action twice = thrash → stop.

## Assumptions — MANDATORY

State assumptions BEFORE implementing. If uncertain → ask.
Present interpretations explicitly — picking silently = silent failure.
If simpler approach exists → say so and push back.
If >3 files needed to understand scope → confirm objective first.

## Spec-Before-Code HARD-GATE (MANDATORY)

NEVER invoke any implementation skill, write any code, scaffold any project, or
take any implementation action until a design has been presented and the user
has approved it. This applies to EVERY project regardless of perceived
simplicity. "Simple" projects are where unexamined assumptions cause the most
wasted work (pattern: obra/superpowers, V, accessed 2026-07-01).

## 4-Status Subagent Handoff

When delegating to a subagent, the handoff status MUST be one of (pattern:
obra/superpowers, V):

| Status | Meaning | Action |
|--------|---------|--------|
| DONE | Task complete, spec + quality verified | Proceed to next task |
| DONE_WITH_CONCERNS | Complete but has open items | Review concerns before proceeding |
| NEEDS_CONTEXT | Missing information to proceed | Provide context, re-dispatch |
| BLOCKED | Cannot proceed, needs human decision | Escalate to user |

## Two-Verdict Review (subagent output)

Every subagent task review carries TWO verdicts (pattern: obra/superpowers, V):

1. **Spec compliance**: does the output match the spec?
2. **Code quality**: is the implementation sound?

Both verdicts are required. Accepting a report missing either verdict is a
violation. The orchestrator must not pre-rate findings or tell the reviewer
what to flag.

## /build auto Pause-on-Risk

When running autonomous execution (approve plan once, then runs autonomously):
- Pause on failures or risky steps
- Every task is still test-driven and committed individually
- Human steps between tasks are removed, NOT verification gates
- "Risky step" = any T2+ action (irreversible, prod-touching, >3 services)
  (pattern: addyosmani/agent-skills, V, accessed 2026-07-01)

## Checkpoint-Per-Step Resumability

For long multi-step tasks, persist state after each step. On crash or failure,
resume from the last durable checkpoint instead of replaying all steps. Retry
state (attempt count, last error, next backoff) belongs in the persisted state
record (pattern: microsoft/pg_durable, V, accessed 2026-07-01).

## Scope-Expansion Heuristic

When deciding whether a new request is an UPDATE to the current task or a NEW
task: if same intent + >50% overlap with current scope -> UPDATE (expand
current task). Otherwise -> NEW task (separate scope). This prevents scope
creep without explicit authorization (pattern: Fission-AI/OpenSpec, I,
accessed 2026-07-01).

## Post-Plan Verification Gate

After planning phase completes, before execution begins:
1. Grep plan output for `[UNVERIFIED PREMISE]` — if found, BLOCK plan and surface to user.
2. Grep plan output for `[BLOCKED: max_iter]` — if found, STOP execution and state blocker.
3. Grep plan output for `## Assumptions` with any `unverified` status — if any affect a milestone, BLOCK plan.

These gates are programmatic: the agent MUST perform them, not optionally. Skipping the post-plan gate = planning defect.
