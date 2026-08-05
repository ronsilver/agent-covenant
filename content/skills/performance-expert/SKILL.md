---
name: performance-expert
description: "Systematic profiling with observability tools (pprof, async-profiler, py-spy): hot path identification, memory allocation and garbage collection analysis, N+1 query optimization, multi-level cache implementation, connection pooling, and kernel tuning for low-latency workloads. Use when reducing P99 latency, analyzing flamegraphs, fixing memory leaks, optimizing slow database queries, reducing CPU usage, improving throughput, or tuning garbage collection. Trigger: performance, profiling, flamegraph, GC tuning, p99 latency. Do NOT trigger for: UI design, frontend development, database schema design, PostgreSQL-specific N+1/SQL optimization (use postgres-database-expert)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Performance Expert

**Profiling, flamegraphs, memory leaks, N+1 queries and GC tuning.**

## Performance Analysis Stack

| Language | CPU Profiling | Memory Profiling | Tracing |
|---|---|---|---|
| Go | pprof, go tool trace | pprof (-alloc_objects) | OTEL spans |
| Python | py-spy, cProfile | memray, tracemalloc | OTEL spans |
| JVM | async-profiler, JFR | jmap, MAT | OTEL + JFR |
| Node | clinic.js, 0x | heapdump | OTEL spans |

## Profiling Workflow

1. **Establish baseline** — current p50/p99 latency + throughput
2. **Profile CPU** — identify hot paths consuming >5% of CPU
3. **Profile memory** — find allocations, check GC pressure
4. **Trace latency** — find wait time (DB, network, locks)
5. **Fix top bottleneck** — measure impact before moving to next
6. **Re-baseline** — verify improvement, detect regressions

## Common Patterns

| Bottleneck | Fix |
|---|---|
| N+1 queries | Batch load with IN clause, preload associations |
| Repeated allocations | Object pooling, pre-allocation |
| GC pressure | Reduce allocation rate, tune GC |
| Connection exhaustion | Connection pooling, connection reuse |
| Serialization overhead | Streaming parsers, binary formats |
| Lock contention | Reduce lock scope, use lock-free structures |

## Caching Strategy

```
L1: In-memory (application cache, TTL: seconds)
L2: Redis/Valkey (distributed cache, TTL: minutes)
L3: CDN (static assets, TTL: hours/days)
```

- Cache aside: app checks cache, fills on miss
- Write-through: app writes to cache + store
- NEVER cache user-specific PII data in shared caches

## Constraints

- NEVER optimize without profiling first (measure, don't guess)
- NEVER micro-optimize non-hot paths (focus on >5% CPU consumers)
- NEVER add caching without measuring hit rate impact
- ALWAYS re-baseline after optimization (verify improvement)
- ALWAYS test under production-like load (not local only)
- NEVER sacrifice correctness for performance

## Overview

Systematic performance profiling and optimization covering CPU profiling (pprof, py-spy, async-profiler), memory analysis, GC tuning, N+1 query detection, multi-level caching strategies (L1 in-memory, L2 Redis, L3 CDN), and connection pooling. Focused on reducing P99 latency and improving throughput for cloud-native services.

## Anti-patterns

FAIL: Optimizing without profiling first
```go
// Premature: optimizing a function that runs 0.1% of CPU
func fastPath() { ... }
```

PASS: Always profile before optimizing — measure, don't guess
```bash
go tool pprof -http=:8080 http://localhost:6060/debug/pprof/profile
```

FAIL: Adding caching without measuring hit rate impact
```go
cache.Set(key, value) // no hit/miss tracking
```

PASS: Always instrument cache with hit/miss counters
```go
if val, ok := cache.Get(key); ok {
    metrics.CacheHits.Inc()
} else {
    metrics.CacheMisses.Inc()
}
```

FAIL: Micro-optimizing non-hot paths while hot path remains unoptimized
```
Optimizing string concat in a function called 10x/day
while a DB query running 10,000x/min has no index.
```

PASS: Focus on the top 5% CPU consumers
```
Profile → identify top consumer → fix → re-profile → repeat
```

FAIL: Sacrificing correctness for performance
```go
func processRequest(value float64) {
    // skip validation to make it faster
}
```

PASS: Keep validation; optimize the real bottleneck
```go
func processRequest(value float64) error {
    if value <= 0 { return ErrInvalidValue }
    ...
}
```

## References

| Resource | URL | Last verified |
|---|---|---|
| Go pprof documentation | https://go.dev/blog/pprof | 2026-04 |
| py-spy profiling tool | https://github.com/benfred/py-spy | 2026-04 |
| async-profiler for JVM | https://github.com/async-profiler/async-profiler | 2026-03 |
| Clinic.js for Node.js | https://clinicjs.org/ | 2026-03 |

- [references/caching-strategy.md](references/caching-strategy.md)
- [references/profiling-recipes.md](references/profiling-recipes.md)

## Verification Checklist

- [ ] Baseline p50/p99 latency and throughput established before any optimization
- [ ] CPU profile collected to identify hot paths (>5% CPU consumers)
- [ ] Memory profile analyzed for allocation rate and GC pressure
- [ ] N+1 queries detected and resolved (batch loading, preloaded associations)
- [ ] Re-baseline measurement taken after each optimization to verify improvement
- [ ] Caching added only after measuring miss rate and hit ratio
- [ ] No optimization performed on non-hot paths (focus on top consumers)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| p99 latency spikes every 2 minutes | GC cycle — high allocation rate causing frequent GC pauses | Reduce allocation rate (object pooling); tune GC frequency with `GOGC` or JVM flags |
| Throughput flat despite low CPU | Lock contention blocking goroutines/threads | Profile with mutex profiler; reduce lock scope; use lock-free structures |
| Cache hit rate < 50% | TTL too short or cache key not matching access patterns | Extend TTL; review cache key design; use write-through instead of cache-aside |
| Profiling in production causes <1% latency overhead (known issue with async-profiler safemode) | async-profiler safemode adds safety instrumentation overhead | Use `--safemode=0` or profile staging environment first |

| [WARN] pprof heap profile shows live objects but GC already freed them (gotcha: GC vs profiler timing) | pprof samples heap at time of allocation; objects may be freed between allocation and profile read | Take multiple samples at different GC cycles; use `runtime.GC()` before allocating to isolate new objects |
