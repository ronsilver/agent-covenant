# Model Routing Strategy -- Cache-Aware

## Task Complexity -> Model Tier

| task_tier | model | $/MTok in/out | cache_eligible |
|-----------|-------|---------------|----------------|
| Trivial (reads, searches) | Haiku-class | $0.25 / $1.25 | Yes (4096 min for Haiku 4.5) |
| Simple (single edits, format) | Haiku-class | $0.25 / $1.25 | Yes |
| Medium (multi-file, review) | Sonnet-class | $3.00 / $15.00 | Yes (4096 min for Sonnet 4.5; 1024 for 4.6) |
| Complex (design, debug) | Opus-class | $15.00 / $75.00 | Yes (4096 min for Opus 4.5/4.6; 1024 for Opus 4) |
| Critical (audit, security) | Opus-class | $15.00 / $75.00 | Yes |

> $/MTok figures are approximate as of 2026-06-30. Re-verify monthly at https://www.anthropic.com/pricing and https://aws.amazon.com/bedrock/pricing/

last_verified: 2026-06-30

## Routing Decision Tree

```

Is the task read-only? -> Haiku
Does it touch >3 files? -> Sonnet
Is it a security-sensitive operation? -> Opus
Is it an architectural decision? -> Opus
Default -> Haiku

```

## Cache-Aware Routing

Cache hit reduces input token cost by ~90%. Factor cache eligibility into routing:

```

cache_factor = (1 - cache_hit_ratio x 0.9)
effective_cost = base_cost x cache_factor

```

Example: Opus with 80% cache hit: effective = $15.00 x (1 - 0.72) = $4.20/MTok.
Cached Opus prefix < uncached Haiku full prompt for static portions.

Rule: if a task has high static-content ratio (system prompts, tool defs, reused templates) AND cache hit >70%, Opus with caching can be cheaper than Haiku without caching for the static portion. Measure, NEVER assume.

Note: model-specific cache checkpoint minimums are 1,024 or 4,096 tokens depending on the model (see optimization.md model-min table).

## Cost Optimization

- Feed large model pre-compressed context (summarize before sending)
- Cache common prompts (system instructions re-used across calls)
- Batch similar queries to share cached context
- Measure model performance per task type, adjust routing
- Verify cache checkpoint meets model minimum (see optimization.md model-min table)

## NEVER

- Use Opus for simple tasks (file reads, search, format)
- Use Haiku for security audits or financial calculations
- Assume model tier without measuring actual task complexity
- Assume cache hit without verifying checkpoint meets model minimum
- Use $/MTok figures without verifying against current pricing (re-check monthly)
