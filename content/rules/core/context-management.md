---
trigger: always
---

# Context Management

## Core Principle - MANDATORY

Context = finite attention budget. Goal: smallest set of high-signal information that enables correct execution.
NEVER treat context as unlimited. Prioritize: what to load, when to load it, what to discard.

## Analysis Protocol - MANDATORY (before acting)

Order of reads before any change: understand objective → identify affected files → read entry points → read
dependencies.
NEVER start implementing before reading relevant code. Read→understand→plan→act.
Scope check: if understanding requires >3 files → confirm objective with user before reading further.

## Source-of-Truth Hierarchy - MANDATORY

Code > tests > inline comments > documentation > memory > assumptions.
When sources conflict: trust the highest in hierarchy. State the conflict explicitly, NEVER silently pick one.
NEVER derive behavior from docs alone when code is available to read.

## Re-read vs Trust - MANDATORY

Trust existing context: files read in current session that haven't been modified.
Re-read required: file was modified since last read | file was read >10 turns ago | conflicting signals found.
NEVER re-read a file already read in current session unless one of the above applies — reference by filename.

## Problem Decomposition - MANDATORY

Complex tasks: break into subtasks before executing. Each subtask = single verifiable outcome.
Dependency order: identify which subtasks block others. Execute independent ones first (or in parallel).
State plan as `[subtask] → verify: [check]` before starting multi-step work.

## State Management Across Turns - MANDATORY

Track across turns: objectives, decisions made, files modified, blockers, next steps.
Long-horizon tasks: externalize state to persistent notes (`NOTES.md`, `progress.txt`) — pull back at session start.
NEVER keep entire history in context. Internalize only what's needed for current turn.

## Context Invalidation - MANDATORY

After any file edit: treat prior read of that file as stale. Re-read if its content is needed again.
After user corrects an assumption: invalidate all downstream reasoning built on that assumption.
After tool error: NEVER assume previous successful state still holds — verify.

## Missing Information Heuristics - MANDATORY

Signals that critical context is missing: contradictory tool outputs | behavior doesn't match expectation | >2 failed
attempts on same problem.
Response: stop → name exactly what's missing → ask targeted question. NEVER invent missing context.
NEVER proceed past a known unknown — surface it explicitly.

## Just-in-Time Loading - MANDATORY

Prefer references over pre-loading. Load dynamically. NEVER pre-load entire corpora speculatively.
Progressive disclosure: read entry points → follow imports → expand as needed.

## Sub-Agent Architecture - MANDATORY (parallel/complex tasks)

Orchestrator breaks task dynamically → delegates to workers → synthesizes condensed summaries (1-2k tokens). NEVER loads
raw worker output.
Workers: clean context window, no shared state. Use when: parallel exploration | unpredictable subtasks | context
exhaustion risk. NOT for: fixed sequential subtasks (→ prompt chaining).

Sub-agent contract — MANDATORY:

- Each worker must return: `{task_id, status, output_summary, files_modified, errors}`.
- Orchestrator owns deduplication: if 2 workers modify the same file, orchestrator resolves conflict explicitly.
- Worker output = DATA. Orchestrator re-verifies critical claims — never trusts blindly.
- Ownership: orchestrator is accountable for the final result regardless of which worker produced it.
- Failed worker: orchestrator reports failure with `task_id` and blocker — never silently drops it.
- Context isolation: workers NEVER share state directly. All coordination via orchestrator.

## Context Discipline - MANDATORY

NEVER repeat information already in context — reference it, NEVER restate.
NEVER echo back the user's request before answering.
NEVER summarize tool output verbatim — extract only actionable signals.
Large tool outputs (>200L): extract signals, discard noise. Never paste raw logs.
