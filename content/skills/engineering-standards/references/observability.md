# Observability Rules

## Structured Logging — MANDATORY

JSON format with required fields:
```json
{"level":"INFO","ts":"2026-04-23T10:00:00Z","service":"api","trace_id":"abc123","span_id":"def456","msg":"request processed"}
```

| Level | When |
|---|---|
| ERROR | Needs human action |
| WARN | Degraded / self-recoverable |
| INFO | Business events |
| DEBUG | NEVER in PR — remove before closing |

## Correlation IDs — MANDATORY

Propagate `trace_id` / `request_id` across ALL service calls and logs.
Every log line must include `trace_id` to enable distributed tracing.

## Metrics — MANDATORY

Every new service boundary must emit:
- Request count
- Error count
- Latency p50 and p99

## Rules

NEVER log: secrets | tokens | passwords | PII fields.
Debug cleanup: remove ALL debug print statements before closing task.
