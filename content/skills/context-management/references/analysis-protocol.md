# Analysis Protocol & Source-of-Truth

## Analysis Protocol -- MANDATORY (before acting)

Order of reads before any change:
```
understand objective -> identify affected files -> read entry points -> read deps -> plan -> act
```

NEVER start implementing before reading relevant code.
Scope check: if understanding requires >3 files -> confirm objective with user before reading further.

## Source-of-Truth Hierarchy -- MANDATORY

```
Code > Tests > Inline comments > Docs > Memory > Assumptions
```

When sources conflict: trust the highest. State the conflict explicitly -- never silently pick one.
NEVER derive behavior from docs alone when code is available to read.

## Re-read vs Trust -- MANDATORY

Trust existing context: files read in current session that haven't been modified.

Re-read required when:
- File was modified since last read
- File was read >10 turns ago
- Conflicting signals found about its content

NEVER re-read a file already read in current session unless one of the above applies -- reference by filename.

## Just-in-Time Loading -- MANDATORY

Prefer references over pre-loading. Load dynamically.
NEVER pre-load entire corpora speculatively.
Progressive disclosure: read entry points -> follow imports -> expand as needed.

## Problem Decomposition -- MANDATORY

Complex tasks: break into subtasks before executing. Each subtask = single verifiable outcome.
Dependency order: identify which subtasks block others. Execute independent ones first (or in parallel).
State plan as `[subtask] -> verify: [check]` before starting multi-step work.

## Missing Information Heuristics

Stop and surface when:
- Contradictory tool outputs
- Behavior doesn't match expectation after 2 attempts
- Content of one file contradicts what another file implies

Response: name exactly what's missing -> ask targeted question. NEVER invent missing context.
NEVER proceed past a known unknown -- surface it explicitly.

## Missing-Information Signal Taxonomy (pointer)

The 3 heuristics above are the minimal stop-conditions. For the full signal-type catalog (silent failure, partial output, type mismatch, schema drift, stale cache, permission drift, contradictory files, behavior != expectation) + response per type: see [missing-info-signals.md](missing-info-signals.md).

## Boundary

- Anti-hallucination LABELS (V/I/U, STATIC/EXECUTED/INFERRED): -> `operating-protocol`.
- Signal-type CATALOG and per-type RESPONSE: owned HERE.
- Recovery PROCEDURE from contradictory outputs (triangulation, Reflexion): -> [context-failure-modes.md](context-failure-modes.md).
