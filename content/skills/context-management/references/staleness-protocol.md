# Staleness Protocol -- Context Invalidation for Correctness

## Scope

When is loaded context INVALID (not just suboptimal)? How to propagate invalidation? This file owns the CORRECTNESS angle. The COST angle (re-reading stale index wastes tokens) is owned by `token-efficiency` `retrieval-economics.md`.

## Invalidation Triggers (beyond the base 3)

Base triggers (SKILL.md): file modified since last read | read >10 turns ago | conflicting signals.
Extended triggers:
- User correction of an assumption -> invalidate ALL downstream reasoning built on it.
- Tool error -> NEVER assume previous successful state holds; verify.
- Schema drift (API changed shape) -> invalidate prior schema reads.
- Permission drift (token expired mid-session) -> invalidate prior auth-dependent reads.
- Cache eviction (underlying store dropped the entry) -> invalidate.

## Hash / Mtime Verification

Before trusting cached context for a file, verify the file has not changed:
- Compare file mtime or content hash (SHA256) against the value recorded at load time.
- If mismatch -> context is STALE -> re-read before acting.
- If no recorded hash/mtime -> treat as unverified -> re-read on first critical use.

## Dirty-Flag Fallback (async re-index)

After a file edit, if the dependency-graph index re-indexes asynchronously:
1. Mark the edited file "dirty" immediately.
2. Fall back to FULL READ (not graph retrieval) until the index confirms update.
3. NEVER serve retrieval results for a file modified since last index without verifying the index version.

This mirrors the [BLOCKER] stale-index rule from `token-efficiency/retrieval-economics.md` G4, reframed for correctness.

## Transitive Propagation (dependency-graph staleness)

If file A is stale AND file B imports/depends on A, then B is TRANSITIVELY SUSPECT:
- Re-read B before trusting prior read of B if B was read BEFORE the A edit.
- Impact-radius: a change to symbol X -> all readers of X are suspect. Re-read readers before acting on prior context of them.

Source: colbymchenry/codegraph impact radius (getImpactRadius: change symbol -> affect readers). [V: https://github.com/colbymchenry/codegraph, accessed 2026-06-30]
Source: safishamsi/graphify incremental cache invalidation (SHA256 semantic cache, re-runs only modified files). [V: https://github.com/safishamsi/graphify, accessed 2026-06-30]

## Bi-Temporal Version Stamps (supersede-never-delete)

For durable context records: track valid-time (when the fact was true) AND transaction-time (when it was recorded). A fact that changes is CLOSED and linked to its successor -- NEVER overwritten. Queryable history. This is the credible answer to "is this still current?" without losing prior state.

Source: Universal Memory Protocol bi-temporal model. [V: https://universalmemoryprotocol.io/, accessed 2026-06-30] (UMP is a PROPOSAL, not a ratified standard -- see TO-DO in content/skills/README.md)

## Boundary

- Staleness COST (re-reading stale index wastes tokens): -> `token-efficiency` `retrieval-economics.md`.
- Staleness CORRECTNESS (when is context INVALID, how to propagate): owned HERE.
- Anti-hallucination labels (V/I/U): -> `operating-protocol`.
