# Session Summarization -- Compression-Safe Schema + Resumption

## Scope

Structured summarization schema for compression-safe session summaries. WHAT to preserve vs discard, HOW to resume a compacted session. COMPRESSION of summary content is owned by `token-efficiency`. This file owns the schema + resumption protocol for correctness.

## Two-Tier Memory Architecture

| Tier | Location | Content | Purpose |
|---|---|---|---|
| Working memory | context window | compressed observations (~500 tokens each) | active reasoning |
| Archive memory | filesystem (transcript) | full tool outputs on disk | retrieval on demand |

After each tool use: (1) compressed observation enters working memory, (2) full output written to archive, (3) agent resumes with compressed context. Transforms O(N^2) context growth -> O(N).

Source: claude-mem Endless Mode. [V: https://github.com/thedotmack/claude-mem, accessed 2026-06-30]

## PreCompact Hook Pattern

Before compaction: save state to filesystem. After compaction: restore critical context. Graceful degradation if restore fails (fall back to summary + re-read).

Source: mksglu/context-mode PreCompact hook. [V: https://github.com/mksglu/context-mode, accessed 2026-06-30]

## Resumption Protocol (re-enter a compacted session)

To resume WITHOUT re-reading everything:
1. Load the session summary (decisions + blockers + next steps).
2. Load last 5 relevant files (the active working set).
3. Load unresolved blockers.
4. Resume from next steps.

NEVER re-read the entire prior transcript.

## Evidence-Chain Preservation

When compacting, preserve the chain: which findings led to which decisions. A summary that drops the evidence chain produces decisions without justifications -> unverifiable. Keep decision + the finding that motivated it.

## Periodic Summary Triggers

Trigger a summary write: at session end AND periodically (message count threshold OR elapsed time threshold). Prevents loss on unexpected termination.

Source: hivemind summaries (periodic triggers, AI-written, stored with embeddings). [V: https://github.com/activeloopai/hivemind, accessed 2026-06-30]

## Capture Tasks (Save<->Resume with confirmation gate)

For tangents ("save this for later"): agent writes the tangent as a goal. Confirmation step: user can save, edit, or decline (NEVER silent save). Reuses the mine pipeline (dedup + confirm).

Source: hivemind Capture Tasks. [V]

## Crash Recovery (snapshot/restore)

`snapshot(label)` + `restore(label)` for deterministic rollback. Recovery should be near-instant. Use before risky operations so a failed attempt is recoverable.

Source: Octopoda-OS crash recovery (snapshot/restore, <1ms). [V: https://github.com/RyjoxTechnologies/Octopoda-OS, accessed 2026-06-30]

## Memory Consolidation

Periodically: merge duplicate memories, forget stale entries, report memory health. Keeps the store navigable.

Source: Octopoda-OS consolidate + memory_health. [V]

## Boundary

- Token COMPRESSION of summary content: -> `token-efficiency`.
- SUMMARIZATION SCHEMA + resumption protocol for correctness: owned HERE.
- WHEN to persist (triggers): -> `operating-protocol`.
