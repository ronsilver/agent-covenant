# LLM Observability

## OpenTelemetry Integration
```python
from opentelemetry import trace
tracer = trace.get_tracer("llm.inference")

with tracer.start_as_current_span("bedrock.converse") as span:
    span.set_attributes({
        "gen_ai.system": "aws.bedrock",
        "gen_ai.request.model": model_id,
        "gen_ai.usage.input_tokens": usage.input_tokens,
        "gen_ai.usage.output_tokens": usage.output_tokens,
        "gen_ai.response.finish_reasons": [stop_reason],
        "llm.latency_ms": duration_ms,
        "llm.cost_usd": calculated_cost,
    })
```

## Key Metrics
```
# Counters
llm_request_total{model, stimulus, status}
llm_token_usage_total{model, direction}  # direction=input|output
llm_cost_total{model, stimulus}

# Histograms
llm_latency_seconds{model, stimulus}
llm_tokens_per_request{model, direction}

# Gauges
llm_active_requests{model}
llm_prompt_cache_hit_ratio{model}
```

## Grafana Dashboard Layout
- Row 1: Request volume by model (bar chart)
- Row 2: p50/p99 latency trend (line chart)
- Row 3: Token usage + cost over time (stacked area)
- Row 4: Error rate per model (time series)
- Row 5: Cache hit ratio (gauge)

## Prompt Drift Detection
1. On deploy: store prompt hash (SHA256) + embedding (from Cohere)
2. Schedule (every 1h): compute current runtime prompt embedding
3. Alert: cosine similarity < 0.95 with baseline
4. Investigation: diff prompts, identify unauthorized changes
5. Auto-rollback: if confirmed drift in production

## PII-Safe Logging
- NEVER log full prompts in plain text
- Hash/mask: phone numbers (last4 only), national ID/tax ID (redact), emails (hash)
- Use Bedrock Guardrails' sensitiveInformationPolicy for auto-detection
- Audit logs: WORM storage, 12-month retention minimum
