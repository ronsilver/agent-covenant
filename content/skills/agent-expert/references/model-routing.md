# Model Routing Strategy

## Decision Matrix
| Task Complexity | Model Tier | Cost/1K tokens |
|---|---|---|
| Simple (classification, extraction) | Claude Haiku | $0.0008 in / $0.004 out |
| Medium (code review, analysis) | Claude Sonnet | $0.003 in / $0.015 out |
| Complex (architecture, audit) | Claude Opus | $0.015 in / $0.075 out |

## Routing Rules
1. Default to cheapest model that meets quality bar
2. Route up on: confidence < threshold, task requires multi-step reasoning
3. Route down on: cache hit >90%, task is deterministic (SQL gen)
4. Measure: track model_quality_score per task type, optimize routing

## Cost Optimization
- Prompt caching: static system instructions at beginning -> 90% input savings
- Batch similar queries: reuses cached context
- Max tokens: cap per response, don't let runaway generation
- Monitor: cost per task type, cost per user session
