# State Management & Context Discipline

## State Across Turns -- MANDATORY

Track across turns: objectives | decisions made | files modified | blockers | next steps.

For long-horizon tasks (>10 turns), externalize to `progress.txt` or `NOTES.md`:
```markdown
## Objective
[one sentence]

## Decisions made
- [decision]: [reason]

## Files modified
- path/to/file.go: [what changed]

## Blockers
- [blocker]: [what tried]

## Next steps
1. [next action]
```

Pull this file back at session start. NEVER rely on conversation history alone for long tasks.

## Context Invalidation -- MANDATORY

After any file edit: treat prior read of that file as stale. Re-read if content is needed again.
After user corrects an assumption: invalidate ALL downstream reasoning built on that assumption.
After tool error: NEVER assume previous successful state still holds -- verify.

## Context Discipline -- MANDATORY

NEVER repeat information already in context -- reference it, NEVER restate.
NEVER echo back the user's request before answering.
NEVER summarize tool output verbatim -- extract only actionable signals.
Large tool outputs (>200L): extract signals, discard noise. Never paste raw logs.

## Context Window Management

Context >70% full -> summarize -> reinitiate with compressed summary + last 5 files.
Preserve: arch decisions + unresolved bugs.
Discard: redundant tool outputs + duplicate messages.

Middle truncation technique: keep first 30% + last 30%, drop middle 40%.
Separator: `[... N lines omitted ...]`.

-> Full compression strategies: token-efficiency reference for compression strategies

## PreCompact Hook -- Save Before Compaction

When compaction is imminent (context >85%): save critical state to filesystem BEFORE compaction runs, restore after. Pattern from context-mode PreCompact hook + claude-mem Endless Mode.

1. Before compaction: externalize decisions + blockers + next steps + last 5 files to progress.txt.
2. Compaction runs (drops earlier turns).
3. After compaction: reload progress.txt + last 5 files. Resume.

NEVER rely on compaction to preserve decision traces -- it drops them.

Source: mksglu/context-mode PreCompact hook. [V: https://github.com/mksglu/context-mode, accessed 2026-06-30]
Source: claude-mem Endless Mode (two-tier: working memory + archive). [V: https://github.com/thedotmack/claude-mem, accessed 2026-06-30]

## Session Summarization (pointer)

For structured summarization schema (two-tier memory, resumption protocol, Capture Tasks, crash recovery): see [session-summarization.md](session-summarization.md).

## Boundary

- Token COMPRESSION of summary content: -> `token-efficiency` skill.
- SUMMARIZATION SCHEMA for correctness of resumption (what to preserve, how to resume): owned HERE.
- WHEN to persist (triggers): -> `operating-protocol`.
