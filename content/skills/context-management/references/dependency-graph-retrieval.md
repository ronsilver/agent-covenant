# Dependency-Graph Retrieval -- Loading-Order Strategy

## Scope

Which files to load, in what order, for CORRECTNESS (not token savings). Token savings from graph retrieval are owned by `token-efficiency` `retrieval-economics.md`. This file owns the loading-order decision.

## Call-Chain Traversal

Debugging function A: load callers of A (who invokes it) and callees of A (what it invokes) before reasoning about A. N-hop trace: follow the call chain N hops. Body-inlining trace: inline per-hop bodies for deep analysis.

Source: colbymchenry/codegraph trace tool (call-chain tracing, body-inlining). [V: https://github.com/colbymchenry/codegraph, accessed 2026-06-30]

## Impact-Radius Analysis

Editing symbol X: which files read X? Those readers are the impact radius. Re-load them (they are transitively stale -- see staleness-protocol.md). Use for cross-file refactoring: load the full impact radius before editing.

Source: codegraph value-reference edges (reader -> const/var it reads) + getImpactRadius. [V]

## Answer-Directly vs Delegate-to-Sub-Agent

When a graph exists, answering directly with graph tools keeps main-session context lean and scale-invariant (no blind reads). Delegate to a sub-agent with graph access when:
- The investigation is deep (many hops) and would flood main context.
- The subtask is independent (parallel exploration).

Answer directly when:
- Quick lookup (1-2 hops).
- Result feeds the active reasoning chain.

Source: codegraph answer-directly-vs-explore-agent (~50k main context, scale-invariant, 0 reads). [V]

## Node-Summary Schema (first-layer progressive disclosure)

Optional file-level summary for AI navigation: bounded sentence describing file responsibility + source file + label + generated_by + summary_version. Stored as sidecar `node-summaries.json` or inline in graph. First layer of progressive disclosure: load node summaries -> identify relevant files -> load full content only for matches.

Source: safishamsi/graphify node summaries RFC. [V: https://github.com/safishamsi/graphify, accessed 2026-06-30]

## Cross-File Refactoring as Atomic Retrieval

For cross-file refactors (rename, move, find references): use LSP-based semantic retrieval to load all affected symbols as one atomic call, not file-by-file blind reads.

Source: oraios/serena (LSP symbol-centric, cross-file refactoring as single atomic calls). [V: https://github.com/oraios/serena, accessed 2026-06-30]

## [BLOCKER] Stale-Index Warning

After ANY file edit, the graph index is STALE -> silent wrong answer. See [staleness-protocol.md](staleness-protocol.md) Dirty-Flag Fallback for the full rule (re-index, dirty-flag, fall back to full read).

## Boundary

- Token SAVINGS from graph retrieval: -> `token-efficiency` `retrieval-economics.md`. NEVER quote savings % here.
- LOADING ORDER for correctness (which files, what order): owned HERE.
- Tool selection (which graph tool to call): -> `tool-usage`.
- Staleness propagation: -> staleness-protocol.md.
