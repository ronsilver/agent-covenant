# Context Loading Strategy

## Just-In-Time Loading
1. Understand objective first (NEVER start reading blindly)
2. Identify affected files (grep, glob, directory tree)
3. Scope check: >3 files? -> confirm with user first
4. Read entry points -> follow imports/deps -> expand as needed
5. Never pre-load entire codebase

## File Read Priority
1. README.md / package.json -> understand project
2. Entry points (main.go, app.ts, __init__.py)
3. Configuration (config, env, settings)
4. Interfaces/types -> understand contracts
5. Implementation -> only what's needed for task

## Re-read Decision
| Condition | Action |
|---|---|
| Modified since last read | Re-read |
| Read >10 turns ago | Re-read |
| Conflicting output | Re-read |
| Otherwise | Trust (reference by name) |

## Context Window Management
- Monitor: estimate token usage periodically
- At 70%: compact (summarize history)
- At 85%: aggressive compaction + offload to filesystem
- At 95%: critical -- drop non-essential context
- NEVER reach 100% (truncation = data loss)

## Progressive Disclosure -- 4-Level Read Ladder

When a file has prior observations, choose the CHEAPEST level that answers the need:

| Level | Action | Approx cost | When to use |
|---|---|---|---|
| 1 | Semantic priming (timeline/metadata only) | ~minimal | "What did this file contain last time?" |
| 2 | get_observations([IDs]) (compressed prior observations) | ~300 tokens each | Need specific prior content |
| 3 | smart_outline / smart_unfold (symbol-level: signatures + docstrings) | ~1-2k tokens | Need structure, not full body |
| 4 | Full file read | full | None of the above suffices, or file modified since last observation |

Escalate one level on signal: explicit request, error, complexity, type mismatch.

Source: claude-mem File Read Gate. [V: https://github.com/thedotmack/claude-mem, accessed 2026-06-30]

## Entity-Level Loading (pointer)

For per-symbol loading (signature -> docstring -> body), see [entity-level-loading.md](entity-level-loading.md). Distinct from progressive disclosure of PRIOR OBSERVATIONS (this section) vs loading CODE STRUCTURE (entity-level).

## Boundary

- Token SAVINGS from progressive disclosure / entity-level window: -> `token-efficiency` `retrieval-economics.md`.
- LOADING ORDER and ESCALATION for correctness (which level, when to escalate): owned HERE.
- Tool selection (which tool to call): -> `tool-usage`.
