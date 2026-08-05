# Missing-Information Signals -- Type Catalog + Response

## Scope

Full signal-type catalog (the 3 heuristics in analysis-protocol.md are the minimal stop-conditions). Anti-hallucination LABELS are owned by `operating-protocol`. This file owns the signal-type CATALOG and per-type RESPONSE.

## 8 Signal Types

| # | Signal | Symptom | Response |
|---|---|---|---|
| 1 | Silent failure | Tool returns 200/0-exit but empty body | Re-run with verbose; check stderr; NEVER assume success |
| 2 | Partial output | Truncated response (pagination/limit) | Read next page; use grep on full output; never conclude from truncated |
| 3 | Type mismatch | Expected JSON, got text (or vice versa) | Re-fetch with explicit accept header; validate schema |
| 4 | Schema drift | API changed shape (field renamed/removed) | Re-read API spec; invalidate prior schema reads (see staleness-protocol.md) |
| 5 | Stale cache | Returns pre-edit content | Re-read (modified since last read); see staleness-protocol.md |
| 6 | Permission drift | Token expired mid-session | Re-auth; invalidate prior auth-dependent reads |
| 7 | Contradictory files | Two files imply different behavior | Triangulate (read third); trust source-of-truth hierarchy; see context-failure-modes.md |
| 8 | Behavior != expectation | Runtime differs from read/predicted | Re-run to confirm; re-read suspect file; label EXECUTED vs STATIC |

## Response Pattern (all signals)

1. STOP. NEVER proceed past a known unknown.
2. Name exactly what is missing (the signal type + the specific gap).
3. Ask a targeted question OR perform the verification read.
4. NEVER invent missing context.

## Boundary

- Anti-hallucination LABELS (V/I/U, STATIC/EXECUTED/INFERRED): -> `operating-protocol`.
- Signal-type CATALOG and per-type RESPONSE: owned HERE.
- Recovery PROCEDURE from contradictions: -> context-failure-modes.md.
