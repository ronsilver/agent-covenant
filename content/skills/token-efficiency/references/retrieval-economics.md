# Retrieval Economics -- Replace File Reads with Targeted Retrieval

Three retrieval mechanisms that reduce tokens WITHOUT losing quality. No specific tool mandated; implement via available code-graph MCP / observation store.

Index terms (case-insensitive):
- file-level dependency graph
- observation-timeline gate
- entity-level context window
- progressive disclosure ladder
- stale-index warning

## Mechanism 1: File-Level Dependency Graph

Build a graph of file dependencies. Query the graph for related files instead of reading blindly. Reads only the relevant subset. [unverified external benchmarks: up to ~76% fewer reads on retrieval-heavy tasks]

## Mechanism 2: Observation-Timeline Gate

Each tool observation compressed on write. Retrieval reads the compressed form. 4-level ladder: raw -> compressed -> summarized -> archived. Target ~95% savings per re-read vs full file. Small-file bypass: <1.5k bytes -> read directly (timeline costs more than the file).

## Mechanism 3: Entity-Level Context Window (G12)

Token-budgeted window: target entity + dependencies + dependents. NOT full file. 3-layer progressive disclosure: signature (~15t) -> signature+docstring (~60t) -> full body (~200t). Escalate layer on signal (explicit request, error, complexity).

### QUALITY CLAUSE (G12 -- MANDATORY)

Entity-level diff MUST include word-level inline highlights for modified entities. NEVER hide a 1-line fix inside a 50-line function block. If an entity is modified, the diff shows the changed line with +/- inline markers even in entity-level context. Hiding inline changes = the agent misses the actual change = quality failure.

## [BLOCKER] Stale-Index Warning (G4)

After ANY file edit, the graph index and observation timeline are STALE. Retrieval on a modified file returns pre-edit content -> silent wrong answer.

Rule: re-index immediately after edit. If re-index is async, mark file "dirty" and fall back to full read until index confirms update. NEVER serve retrieval results for a file modified since last index without verifying the index version.

## this project Implementation Note

This project implements semantic code-graph retrieval as an internal MCP service. No quantified benchmarks available yet (TBD). This skill describes the technique; the internal service is the implementation.

## Quality Mandate

Retrieval reduces tokens WITHOUT losing quality only when:
1. Index is fresh (no stale-after-edit)
2. Entity-level diffs show inline changes (G12 clause)
3. Progressive disclosure escalates correctly (signal-based, not arbitrary)
4. Retrieved content preserves errors, signatures, and types

## codegraph Benchmark (master catalog #29 codegraph -- README, re-measured 2026-08-05, Opus 4.8)

| Metric | Result |
|--------|--------|
| Fewer tool calls | 88% |
| Faster task completion | 53% |
| Fewer tokens | 62% |
| Cheaper | 44% |
| File reads | 0 |
| VS Code arm: tool calls | 2 vs 28 |
| VS Code arm: file reads | 0 vs 12 |
| VS Code arm: tokens | 77% fewer |
| VS Code arm: cost | 71% cheaper |

Residual-context caveat (both statements are true): retrieval leaves ~80% MORE context resident at session end (67k vs 18k tokens). Fewer tokens PROCESSED per turn plus a LARGER persistent footprint are not contradictory: retrieval rewrites the working set instead of reading files each turn.

Prior task-stated benchmark figures (~25% cheaper / ~62% fewer tool calls) were not found in this file on 2026-08-10; the README figures above are the verified replacement.
