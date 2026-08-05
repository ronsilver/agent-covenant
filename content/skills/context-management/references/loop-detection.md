# Loop Detection -- Session-Level Cycling Detection

## Scope

Detect when the agent is CYCLING across turns (re-reading same files, re-stating same plan, re-trying same approach). Distinct from `operating-protocol` per-operation max_iter=2 (error retry). This file owns SESSION-LEVEL loop detection.

## 5 Signals

| # | Signal | Detection |
|---|---|---|
| 1 | Read similarity | Re-reading the same file(s) already read this session without staleness trigger |
| 2 | Approach repetition | Same plan/approach stated across multiple turns |
| 3 | Velocity spike | Rapid context churn (many tool calls) without measurable progress |
| 4 | Error frequency | Repeated failures on the same operation (overlaps max_iter but session-wide) |
| 5 | Goal drift | Actions diverge from the stated objective |

Source: RyjoxTechnologies/Octopoda-OS 5-signal loop detection. [V: https://github.com/RyjoxTechnologies/Octopoda-OS, accessed 2026-06-30]

## Thresholds + Response

- **Amber** (1-2 signals): warn -> externalize state to progress.txt -> state blocker. Continue with caution.
- **Red** (3+ signals AND no progress): STOP -> escalate to human. NOT abandon -- escalate.

## Productive vs Unproductive (false-positive guard)

Distinguish PRODUCTIVE iteration from UNPRODUCTIVE looping BEFORE firing red:
- Productive: TDD red-green-refactor (re-reads test file, but tests pass/progress visible, files modified).
- Unproductive: same error, no files modified, no blockers resolved.

**MANDATORY progress check before red:** are blockers being resolved? are files being modified? If YES -> productive iteration, NEVER fire red.

## Auto-Snapshot on Detection

On amber/red: snapshot current state (progress.txt + files modified + blockers) so the loop point is diagnosable. See context-audit-trail.md.

## Boundary

- Per-operation ERROR RETRY (max_iter=2): -> `operating-protocol`.
- Session-level LOOP DETECTION (agent cycling across turns): owned HERE.
- Token cost of loops: -> `token-efficiency`.
