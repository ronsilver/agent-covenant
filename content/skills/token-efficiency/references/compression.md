# Compression, Caching & Context Management

## Caching — MANDATORY

Cache stable content ONLY. Min 1024t prefix for cache hit. Cost: up to 90% reduction.
Ordering (ALWAYS): `tool_defs → system_prompt → static_docs → dynamic_user_content`
NEVER embed current time/date in system prompt — invalidates cache prefix.
NEVER cache: user queries | search results | realtime data.
Max 4 cache breakpoints/request at end of tools/system/ref_docs. TTL: 5min (1hr extended).

## RAG Compression Pipeline

```
retrieved chunks → selection (keep/discard by relevance) → extraction (verbatim relevant sentences) → inject
```
Max inject: 2000t. Compress first if over.

## Agentic Loop Compression

Each step observation → compress to `{action, outcome, key_state}` before next step.
Keep last 3 observations full. Replace older with `[obs@T{n}: {summary}]`.

## Context Window Management

Context >70% full → summarize → reinitiate with compressed summary + last 5 files.
Preserve: arch decisions + unresolved bugs.
Discard: redundant tool outputs + duplicate messages.

## Middle Truncation

Keep first 30% + last 30%, drop middle 40%.
Separator: `[... N lines omitted ...]`

## Compression Ratios by Method

| Method | What to compress | How |
|---|---|---|
| Logs (4000L) | Extract signals (CPU/mem spikes, anomalies) | → ~300t |
| RAG (5 docs, 4000t) | Summarize by relevance | → ~200t |
| History (full) | `{issue, actions, status}` per exchange | → ~150t |
| Tool outputs (verbose) | `func(params): brief result` | → ~200t |

→ Full compression strategies with profiles: this compression guide
