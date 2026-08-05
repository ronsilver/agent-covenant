# Context Audit Trail -- Decision Trace

## Scope

Record WHAT context was loaded, invalidated, dropped, delegated, and WHY. Distinct from state-management.md progress.txt (task state: decisions/files/blockers/next) -- this is the CONTEXT-DECISION trace (what entered/left the context window and why).

## CRITICAL: Externalize to Filesystem

The audit trail MUST be externalized to filesystem (`context-decisions.jsonl` or similar), NEVER stored only in conversation context. Storing it in conversation context loses it during compaction -- the very event the audit trail is meant to diagnose.

## Record Format (append-only JSONL)

Each line:
```json
{"ts":"2026-07-01T14:32:00Z","action":"load|invalidate|drop|delegate","target":"path/to/file.go","reason":"...","actor":"orchestrator|worker:task_id","version":"<hash|mtime>"}
```

- `action`: load (entered context), invalidate (marked stale), drop (removed), delegate (sent to sub-agent).
- `version`: file hash or mtime at load time (for staleness verification -- see staleness-protocol.md).
- NEVER truncate. Append-only.

## Provenance

Every record has actor + method (how the decision was made). Pattern from UMP provenance (W3C PROV + DID). [V: https://universalmemoryprotocol.io/, accessed 2026-06-30] (UMP is a PROPOSAL -- see TO-DO in content/skills/README.md)

## Hook Trigger Points

- SessionStart: log session begin.
- PostToolUse (read): log load.
- After edit: log invalidate for edited file + transitively suspect dependents.
- PreCompact: SAVE the audit trail to filesystem before compaction (NEVER let compaction drop it).
- SessionEnd: log session end.

Source: claude-mem hook lifecycle (6 events). [V: https://github.com/thedotmack/claude-mem, accessed 2026-06-30]
Source: Octopoda-OS audit trail (every write versioned, history queryable). [V: https://github.com/RyjoxTechnologies/Octopoda-OS, accessed 2026-06-30]

## Boundary

- Evidence-tier LABELS (V/I/U, EXECUTED/STATIC/INFERRED): -> `operating-protocol`.
- Context-decision TRACE (what was loaded/dropped/invalidated and why): owned HERE.
- Task STATE (decisions/files/blockers/next): -> state-management.md.
