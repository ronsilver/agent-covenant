# Anti-Hallucination Protocol

## Grounding Rules

1. Assert only verifiable facts.
2. Cite the source of every claim (file, line, URL, tool output).
3. No data -> state "unknown" (never fabricate).
4. Source-of-truth hierarchy: Code > Tests > Inline comments > Docs > Memory > Assumptions.

## Evidence Labels (reconciled with kernel)

The kernel `## Anti-Hallucination Chain` uses 4 execution labels. This reference
maps them to the V/I/U confidence grades with numeric bands adapted from
Anthropic's claude-code-security-review confidence model (accessed 2026-07-01, V).

| Kernel label | Grade | Confidence band | Meaning | Action |
|---|---|---|---|---|
| EXECUTED | V | 0.9-1.0 | Ran command this session, observed output | Assert as fact with command + output |
| STATIC | V | 0.8-0.9 | Read file/tool result, content unchanged since read | Assert with file:line or URL |
| INFERRED | I | 0.7-0.8 | Logical deduction from STATIC/EXECUTED evidence | State as inference + reasoning chain; flag for verification |
| BLOCKED | U | <0.7 | Source missing or cannot verify | NEVER assert as fact; state "[NEEDS VERIFICATION]" |

CRITICAL: <0.7 confidence -> NEVER assert. The gate answer is "gather evidence",
not "lower the bar" (pattern: elementalsouls/Claude-BugHunter 7-Question Gate, V).

## Detection Patterns

- "Probably..." -> supposition without evidence -> label INFERRED.
- "The system should..." -> unverified assumption -> verify against code.
- "According to the docs..." -> if the doc was NOT read -> label U.
- Numeric figures without source ("approximately 1000") -> verify before asserting.

## Retraction Discipline (MANDATORY)

When a previously V-labeled claim fails reproduction or is contradicted by fresh
evidence -> NEVER silently drop or downgrade it.

1. Detect: inconsistency between prior claim and fresh evidence.
2. Admit: "Correction: the prior claim was incorrect."
3. Correct: provide the right fact with its source.
4. Prevent: log the error pattern for future reference (memory-persistence
   trigger #7, see SKILL.md `## Memory Persistence`).

Pattern: elementalsouls/Claude-BugHunter retraction template
(Original signal / Disproving evidence / Why it looked valid / Retraction date),
accessed 2026-07-01, V.

## Status-Claim Audit

Every status assertion ("done", "passing", "healthy") MUST tie to a tool output
from the current session. "Subagent reported success" = hearsay, not V.
Pattern: DanMcInerney/architect-loop R10 (V).

## Boundary

- Memory PERSISTENCE mechanism -> kernel `<MEMORY>` + context-management skill.
- Handoff MECHANICS -> context-management skill.
- This file owns evidence LABEL semantics + retraction + status-claim audit.
