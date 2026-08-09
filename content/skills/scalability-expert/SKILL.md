---
name: scalability-expert
description: "Design of elastic and high-availability systems: data sharding (consistent hashing), distributed cache (CDN, Redis Cluster), message queues for decoupling (SQS, Kafka), metric-based auto-scaling, CQRS/Event Sourcing patterns, circuit breakers and rate limiting, and elimination of single points of failure. Use when scaling services horizontally, implementing circuit breakers and bulkheads, designing cache invalidation strategies, setting up read replicas, or handling traffic spikes. Trigger: scalability, horizontal scaling, circuit breaker, bulkhead, sharding, auto-scaling, rate limiting, CQRS. Do NOT trigger for: single-file edits, daily operations monitoring, routine database queries."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Scalability Expert

**Elastic systems: sharding, caching, async processing, resilience.**

## Resilience Patterns

| Pattern | Purpose | Implementation |
|---|---|---|
| Circuit Breaker | Stop calling failing service | Closed -> Open (after N failures) -> Half-Open (test) |
| Bulkhead | Isolate failures | Separate thread pools per dependency |
| Retry + Backoff | Transient failures | Exponential: 100ms -> 200ms -> 400ms -> max |
| Timeout | Prevent hanging | Always set: connect + read timeout per call |
| Rate Limiting | Protect from overload | Token bucket / sliding window per client |
| Shed Load | Graceful degradation | Return 429/503 early when overloaded |

## Caching Strategy
```
Write-through: write to cache + DB simultaneously (consistent, slower writes)
Cache-aside: read from cache, fill on miss (lazy, possible stampede)
Write-behind: write to cache, async flush to DB (fast, data loss risk)
```

## Sharding
```
Consistent Hashing: hash(key) -> virtual nodes -> physical shards
Lookup-Based: shard_registry[key] -> shard_id -> connection pool
```

## Auto-Scaling
```
Scale triggers: CPU > 70% | Queue depth > 1000 | Request latency p99 > 2s
Scale out: add instances (seconds-minutes, depends on warmup)
Scale in: remove instances (graceful shutdown + drain connections)
Cooldown: 300s minimum between scale events
```

## Anti-Patterns
- Shared database across services (contention)
- No connection pooling (resource exhaustion)
- Synchronous chains >3 deep (latency multiplication)
- Single point of failure (no redundancy)
- Unbounded queues (memory exhaustion under load)

## Constraints
- NEVER deploy without circuit breakers on external dependencies
- NEVER accept unbounded queue growth (dead letter queue + alerts)
- NEVER cache user-specific data in shared caches without isolation
- ALWAYS set timeouts on every outbound call
- ALWAYS plan for graceful degradation (what degrades, not what fails)

## Security

- ALWAYS rate limit per client as API security (OWASP API4 Unrestricted Resource Consumption, API10 Unsafe Consumption of APIs)
- ALWAYS return 429 with `Retry-After` and shed load before overload causes DoS
- ALWAYS protect against DoS: bounded queues, circuit breakers, connection limits
- ALWAYS validate and cap request sizes and concurrency at the edge

## Overview

Scalability in this project means elastic systems that handle traffic spikes (peak traffic) without degradation and absorb failures without cascading. This skill covers horizontal scaling via sharding and consistent hashing, distributed caching (Redis Cluster, CDN), async decoupling via message queues (SQS, Kafka), resilience patterns (circuit breakers, bulkheads, retries), auto-scaling based on real-time metrics, and systematic elimination of single points of failure.

## Quick Reference

| Pattern | Protection | Failure Mode |
|---|---|---|
| Circuit Breaker | Stop cascading failures | Open → Half-Open recovery |
| Bulkhead | Isolate dependency failures | One pool exhausts, others survive |
| Retry + Backoff | Transient failures | Exponential backoff up to N attempts |
| Rate Limiting | Client overload | 429 with Retry-After header |
| Cache-Aside | Read throughput | Cache miss → DB load spike |
| Sharding | Write throughput | Rebalance cost during reshards |
| Graceful Degradation | System-wide overload | Slow path degrades, critical path stays |

## Workflow

1. **Identify bottlenecks** — Profile: which service saturates first under load? Database CPU? Queue depth? Connection pool exhaustion? Use load testing to find the weakest link.
2. **Decouple with async** — Replace synchronous chains >3 hops with message queues (SQS, Kafka). Commands go to queue, consumers process independently. Never block on cross-service calls for the main flow.
3. **Add caching** — Cache-aside for read-heavy workloads. Write-through for consistency-sensitive data. Set TTL based on staleness tolerance (>24h for reference data, <5min for transactional).
4. **Implement resilience** — Wrap every external dependency call in a circuit breaker. Configure bulkhead per dependency (separate connection pool). Set timeout per call: connect + read.
5. **Configure auto-scaling** — Set scale triggers: CPU > 70%, queue depth > 1000, P99 latency > 2s. Minimum 300s cooldown between events. Test scaling under realistic load.
6. **Design for degradation** — Define what degrades first when system is overloaded: disable reports, stale cache, delayed notifications. Keep core processing and core always at full capacity.

## Anti-patterns

FAIL: Synchronous chain >3 deep (latency multiplies, no isolation).
```go
// BAD: Synchronous chain — Process waits for Core, Audit, Notify all inline
func Process(ctx context.Context, req Request) error {
    user, err := coreService.Validate(ctx, req.UserID)  // 200ms
    result, err := coreService.Validate(ctx, req.Value)  // 500ms
    err = notifyService.Send(ctx, result.ID)                  // 300ms
    return nil  // total: >1s synchronous
}
```
```go
// GOOD: Critical path first, non-critical async
func Process(ctx context.Context, req Request) error {
    result, err := coreService.Validate(ctx, req.Value) // critical — wait
    go notifyService.Send(ctx, result.ID)                     // non-critical — fire & forget
    return nil
}
```

FAIL: No circuit breaker on external dependency (cascading failure).
```go
// BAD: Calling failing external service without protection
func Validate(ctx context.Context, req Request) (*Response, error) {
    resp, err := http.Post(externalURL, "application/json", body) // hangs when external service is down
    return resp, err
}
```
```go
// GOOD: Circuit breaker wraps the call
func Validate(ctx context.Context, req Request) (*Response, error) {
    if !cb.AllowRequest() {
        return nil, ErrCircuitOpen // fast-fail, NEVER wait for timeout
    }
    resp, err := http.Post(externalURL, "application/json", body)
    if err != nil { cb.RecordFailure() } else { cb.RecordSuccess() }
    return resp, err
}
```

FAIL: Unbounded queue growth under load (memory exhaustion).
```
BAD: Queue with no max size → producer fills memory → OOM crash.
GOOD: Bounded queue with dead letter + back-pressure. When queue reaches limit,
producer gets 429 and must retry with backoff.
```

## References

| Resource | URL | Last verified |
|---|---|---|
| AWS Well-Architected — Reliability Pillar | https://docs.aws.amazon.com/wellarchitected/latest/reliability-pillar/ | 2026-05-25 |
| Martin Fowler — Circuit Breaker Pattern | https://martinfowler.com/bliki/CircuitBreaker.html | 2026-05-25 |
| Google SRE Book — Handling Overload | https://sre.google/sre-book/handling-overload/ | 2026-05-25 |

- [references/resilience-patterns.md](references/resilience-patterns.md)
- [references/sharding.md](references/sharding.md)

## Verification Checklist

- [ ] Every external dependency call wrapped in circuit breaker
- [ ] Timeout configured on every outbound call (connect + read)
- [ ] Synchronous chains reduced to ≤3 hops; non-critical calls made async
- [ ] Auto-scaling triggers defined with minimum 300s cooldown
- [ ] Graceful degradation plan documented (what degrades, what stays at full capacity)
- [ ] No shared database across services (no contention)
- [ ] Queues bounded with dead letter handling and back-pressure
- [ ] Per-client rate limiting returns 429 + `Retry-After`; DoS protections (bounded queues, caps) active

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Cascading failure across services | Missing circuit breaker on external dependency | Wrap each downstream call with circuit breaker; configure Open → Half-Open recovery |
| Scale-out does not improve throughput | Shared bottleneck (DB, cache) not scaled | Check DB connection pool, cache hit ratio, and write lock contention |
| Queue grows unbounded under load | No max queue size or back-pressure mechanism | Set bounded queue with dead letter; return 429 to producer at capacity limit |
| Circuit breaker stays open after recovery (known issue: half-open threshold too conservative) | Recovery test interval too short or success threshold mismatched | Increase `halfOpenMaxRequests` or extend `waitDurationInOpenState` to match recovery time of downstream |
| [WARN] Gotcha: rate limiter with per-key buckets can cause memory exhaustion | Unlimited unique keys (user IDs, IPs) create unbounded bucket map | Use fixed bucket count with LRU eviction; set `maxKeys` on rate limiter implementation |
