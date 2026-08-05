# Multi-Level Cache Strategy

## Cache Levels
| Level | Location | TTL | Size | Hit Rate Target |
|---|---|---|---|---|
| L1 | In-memory (sync.Map/ristretto) | 10s | 10k keys | >80% |
| L2 | Redis/Valkey | 300s | Unlimited | >95% |
| L3 | CDN (CloudFront) | 1h-24h | Static only | >98% |

## Patterns
- Cache-Aside: check cache -> miss -> load from DB -> populate cache
- Write-Through: write to cache + DB simultaneously
- Write-Behind: write to cache, async flush to DB (data loss risk!)

## Invalidation
- On update: Redis Pub/Sub -> subscribers invalidate L1 + L2
- Lua script for atomic DELETE + SET
- NEVER use SET + DEL pattern (non-atomic, cache stampede risk)
- NEVER cache PII in shared caches
