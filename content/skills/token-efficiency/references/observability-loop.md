# Observability Loop -- ccusage Cadence

Source: ryoppippi/ccusage (accessed 2026-06-30).

## Install

```bash
# Homebrew
brew install ccusage

# npm
npm install -g ccusage
```

## Cadence Table

| Cadence     | Command                   | What it shows                                |
| ----------- | ------------------------- | -------------------------------------------- |
| Daily       | `ccusage daily`           | Token usage + cost per day                   |
| Session     | `ccusage blocks --active` | Active session blocks with cache hit/miss    |
| Statusline  | `ccusage statusline`      | One-line status for shell prompt integration |
| JSON export | `ccusage --json`          | Machine-readable for dashboards/alerting     |

## Cost Modes

ccusage tracks: input tokens, output tokens, cache write tokens, cache read tokens. Cache read = discounted rate. Cache write = premium rate (higher than uncached). Net cost = all four combined.

## 3 Metrics to Track

1. **cache_hit_ratio** -- target 70%+ (per optimization.md KV-cache section). Below 70% -> reorder context (system prompt + tools first, dynamic content last).
2. **cost_per_session** -- trend over time. Rising cost with stable task = context bloat or model drift.
3. **tokens_per_task** -- normalize by task complexity. Compare trivial (Haiku) vs complex (Opus) tasks separately.

## 3 Adjust Rules

1. cache_hit_ratio < 70% -> reorder context per KV-cache optimization (see optimization.md). Check for dynamic values in system prompt invalidating cache.
2. cost_per_session rising -> check for observation accumulation (mask old observations), stale context (compress before reinitiation), or model misrouting (Haiku tasks on Sonnet).
3. tokens_per_task high for trivial tasks -> verify model routing (trivial should be Haiku-class, 0t thinking budget).

## NOTE: --live REMOVED in v18.0.0

`ccusage --live` was REMOVED in ccusage v18.0.0. Use `ccusage blocks --active` for near-real-time session monitoring instead. NEVER recommend `--live` in any documentation or workflow.

## Quality Mandate

Observability measures cost WITHOUT degrading quality. Metrics inform routing and compression decisions. If a metric suggests an optimization that would reduce quality, NEVER apply it -- quality trumps cost (see SKILL.md Precedence section).
