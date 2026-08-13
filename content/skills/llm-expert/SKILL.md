---
name: llm-expert
description: "LLM operationalization in production: pre-deploy cost estimation (token projections, model price comparison), runtime observability (OpenTelemetry spans, Prometheus metrics, Grafana dashboards, LangSmith tracing), prompt caching strategies (90% input savings), prompt drift detection (embedding similarity alerts), model routing for cost optimization, PII-safe logging, and p50/p99 latency monitoring. Use when estimating LLM costs, setting up prompt caching, routing between model tiers, configuring LLM observability, or implementing prompt drift detection. Trigger: LLM cost estimation, prompt caching, model routing, LLM observability, LangSmith, LangFuse, prompt drift, PII-safe logging. Do NOT trigger for: general prompt engineering, LLM application feature design, training or fine-tuning models."
license: MIT
metadata:
  author: Community
  version: "1.2"
  category: ai-agents
  status: stable
---

# LLM Expert

**LLM operations: cost estimation, observability, tracing and monitoring.**

## Cost Estimation & Optimization
→ Detailed pricing + strategies: [references/model-costs.md](references/model-costs.md)

## Observability
→ OTel + Prometheus + Grafana guide: [references/observability.md](references/observability.md)

## Quick Cost Reference
| Model | Input $/1K | Output $/1K | Latency |
|---|---|---|---|
| Claude 3.5 Haiku | $0.0008 | $0.0040 | ~1s |
| Claude 3.5 Sonnet | $0.0030 | $0.0150 | ~3s |
| Claude 3 Opus | $0.0150 | $0.0750 | ~8s |

## Optimization Strategies (by savings)
1. Prompt Caching (up to 90% input)
2. Model Routing (50-70%)
3. Max Tokens Cap (20-40%)
4. Output Compression (30-50%)

## Core Rules
- NEVER log full prompts with PII in plain text
- NEVER skip cost estimation for new features
- ALWAYS set max_tokens to prevent runaway generation
- ALWAYS use sampling (10%) for high-volume tracing
- NEVER trust LLM output as ground truth for operational data

## Overview

LLMs in production require rigorous operational discipline beyond prompt engineering. This skill covers pre-deploy cost estimation (token projections × model pricing), runtime observability (OpenTelemetry spans, Prometheus metrics, LangSmith/LangFuse tracing), prompt caching (up to 90% input token savings), model routing (cheap model for classification, expensive for generation), PII-safe logging, and latency/cost dashboards via Grafana.

## Quick Reference

| Concern | Tool/Approach | Expected Saving |
|---|---|---|
| Cost estimation | Token proj. × model price matrix | Avoids 10x bill surprises |
| Prompt caching | Anthropic `cache_control` | 60-90% input cost |
| Model routing | Task → model map | 50-70% total cost |
| Latency tracking | OTel spans + Prometheus histograms | Detect p99 regressions |
| PII filtering | Pre-LLM scrubber + post-LLM scan | regulatory compliance |
| Drift detection | Embedding sim. + alert threshold | Catch prompt regressions |
| Max tokens cap | Per-task limits | 20-40% cost reduction |

## Prompt Token Audit (9 dimensions)

Before shipping a prompt, extract and verify 9 intent dimensions: task, input, output, constraints, context, audience, memory, success-criteria, examples. Strip every word that does not change the output. Cap clarifying questions at 3 per round. For thinking models (o3/o4 class): short clean instructions, NEVER add chain-of-thought scaffolding.

## Humanized-Output Quality Gate

Voice calibration: collect a 2-3 paragraph writing sample from the target author and match its rhythm and word choice. Final "obviously AI generated" audit pass, then a second rewrite if flagged. No-fabrication rule: never add facts, dates, or citations absent from the source material.

## Multi-Source Usage Monitoring

Track usage across the 15 CLI sources (claude, codex, opencode, amp, droid, codebuff, hermes, pi, goose, openclaw, kilo, kimi, qwen, copilot, gemini) with ccusage cadences: daily, weekly, monthly, session, blocks. Use `--instances` and `--project` for attribution; remember `blocks` = 5-hour billing windows.

## Workflow

1. **Estimate costs before building** — Project monthly token volume (input + output) for each task. Apply pricing per model tier. Add 20% buffer. If cost exceeds budget, choose a cheaper model or add caching.
2. **Implement model routing** — Classify task complexity. Route simple tasks (classification, short-summary) to Haiku, complex (multi-step SQL, analysis) to Sonnet. Use a routing function — never hardcode model per environment.
3. **Enable prompt caching** — Mark repeated system prompts and few-shot examples with `cache_control: { type: "ephemeral" }`. Monitor cache hit rate in LangSmith/LangFuse. Target > 60%.
4. **Add observability** — Wrap every LLM call in an OTel span with `llm.model`, `prompt_tokens`, `completion_tokens`, and `latency_ms` attributes. Export to Prometheus via OTel collector.
5. **Set cost and latency alerts** — Grafana alert: cost-per-service > 10% weekly increase. P99 latency > 3x baseline for 5 consecutive minutes.
6. **Implement PII-safe logging** — Scrub PII from prompts before sending to LLM (regex + NER model). Never log full prompt text in plain text — log truncated + anonymized versions only.

## Anti-patterns

FAIL: Using expensive model for every task regardless of complexity.
```python
# BAD: Sonnet for everything — 10x cost over necessary
client.messages.create(model="claude-3-5-sonnet-20241022", messages=[...])
```
```python
# GOOD: Route by task complexity
def select_model(task_type: str) -> str:
    return "haiku" if task_type in SIMPLE_TASKS else "sonnet"
```

FAIL: Logging full prompts with PII to CloudWatch.
```python
# BAD: Logging raw prompt with PII
logger.info(f"Prompt sent to LLM: {prompt}")  # contains customer PII
```
```python
# GOOD: Log metrics only, scrub PII
logger.info(f"LLM call: model={model}, tokens={token_count}")
```

FAIL: No max_tokens limit on generation tasks.
```python
# BAD: No cap — can generate 100K+ tokens
response = client.messages.create(model="sonnet", messages=[...])
```
```python
# GOOD: Hard cap prevents runaway cost
response = client.messages.create(model="sonnet", max_tokens=4096, messages=[...])
```

## References

| Resource | URL | Last verified |
|---|---|---|
| Anthropic — Prompt Caching | https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching | 2026-05-25 |
| OpenAI — Model Pricing | https://openai.com/api/pricing/ | 2026-05-25 |
| LangFuse — LLM Observability | https://langfuse.com/docs/ | 2026-05-25 |

## Verification Checklist

- [ ] Cost estimation completed with token projections × model price before feature launch
- [ ] Prompt caching enabled with `cache_control` on repeated system prompts/context
- [ ] Model routing implemented: simple tasks → cheap model, complex → expensive model
- [ ] `max_tokens` cap set per task to prevent runaway generation
- [ ] PII scrubbed from prompts before sending to LLM (no raw customer data)
- [ ] OpenTelemetry spans created for every LLM call with token and latency attributes
- [ ] Sampling rate ≤10% for high-volume trace export (never 100%)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Prompt cache hit rate near 0% | `cache_control` not set on static prefix blocks | Add `{"type": "ephemeral"}` to system prompt and few-shot sections |
| P50 latency spikes suddenly | Model routing sending all traffic to expensive model | Verify routing function logic; check for default fallback to Sonnet/Opus |
| Cost 10x above estimate | No `max_tokens` cap on generation tasks | Add per-task `max_tokens` limits; implement token budget tracking per request |
| Known issue: prompt cache misses after model deployment update | New model version resets server-side prompt cache | Schedule caching warm-up after deployments; monitor cache hit rate for 15min post-deploy and alert on drop > 20% |
| [WARN] Limitation: prompt drift detection via embedding similarity may miss semantic shifts | Cosine similarity threshold insensitive to subtle meaning changes for long prompts | Supplement embedding-based drift alerts with periodic human review of prompt output quality; flag false-negative drifts manually |
