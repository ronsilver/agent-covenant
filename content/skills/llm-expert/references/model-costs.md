# Bedrock Model Costs & Optimization

## Pricing (us-east-1, May 2026)
| Model | Input $/1K tokens | Output $/1K tokens | Latency (avg) |
|---|---|---|---|
| Claude 3.5 Haiku | $0.0008 | $0.0040 | ~1s |
| Claude 3.5 Sonnet | $0.0030 | $0.0150 | ~3s |
| Claude 3 Opus | $0.0150 | $0.0750 | ~8s |

## Cost Estimation Formula
```python
monthly_cost = (
    (requests_per_month * avg_input_tokens * input_price) +
    (requests_per_month * avg_output_tokens * output_price)
) / 1000
```

## Optimization Strategies
| Strategy | Savings | Implementation |
|---|---|---|
| Prompt Caching | Up to 90% input | Static system instructions at prompt start |
| Model Routing | 50-70% | Route 80% queries to Haiku, 20% to Sonnet |
| Max Tokens Cap | 20-40% | Set reasonable max_tokens per use case |
| Output Compression | 30-50% | Request concise output format |
| Batch Processing | 20% | Combine similar queries with shared context |

## Cost Monitoring
- Track cost per stimulus (the AI service workflows)
- Budget alerts at 80% of monthly allocation
- Per-model cost dashboard in Grafana
- Auto-throttle expensive models when budget exceeded

## Prompt Caching Details
- Bedrock caches prompt prefix for 5 minutes
- Place static content at BEGINNING of prompt
- Cached content = free on subsequent calls
- Ideal for: system prompts, few-shot examples, schemas
