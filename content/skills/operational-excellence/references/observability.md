# Observability Reference

## Three Pillars

1. **Logging**: Structured JSON logs with request IDs
2. **Metrics**: RED method (Rate, Errors, Duration)
3. **Tracing**: OpenTelemetry distributed traces

## Implementation

```python
# Structured logging
logger.info("Order processed", extra={"order_id": "123", "amount": 99.99})

# Metrics
http_requests_total.labels(method="POST", status="201").inc()
```

