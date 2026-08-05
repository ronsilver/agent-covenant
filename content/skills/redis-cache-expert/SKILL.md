---
name: redis-cache-expert
description: "Design and implement Redis caching strategies for cloud-native services. Use when adding caching to context-layer, items, or any service using go-redis, ioredis, or redis-py; choosing between cache-aside and write-through; designing TTL strategies; implementing pub/sub; writing Lua scripts for atomic operations; configuring connection pooling; or debugging cache stampede and hot-key issues. Trigger: Redis, cache, TTL, cache stampede, hot-key, pub/sub, go-redis, ioredis, redis-py. Do NOT trigger for: database schema design, application-level in-memory caching, CDN configuration."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---

# Redis Cache Expert

**Design and implement Redis caching strategies across services.**

**See [references/overview.md](references/overview.md)**

## Core Clients

| Language | Library | repos |
|---|---|---|
| Go | `go-redis/redis/v9` | items, message broker |
| Python | `redis-py` (async: `aioredis`) | context-layer |
| Node.js | `ioredis` | API middlewares |

## Data Structures Decision

```
String   → simple key-value, counters, session tokens
Hash     → object with multiple fields (user profile, config)
List     → queues, recent items (LPUSH + LTRIM)
Set      → unique members, tags
Sorted Set → leaderboards, rate-limit windows, priority queues
```

## Cache Patterns

**See [references/patterns.md](references/patterns.md)**

```python
# Cache-aside (read-through — preferred)
value = redis.get(key)
if not value:
    value = db.query(...)
    redis.setex(key, ttl=300, value=serialize(value))
return deserialize(value)

# Write-through: update DB + cache atomically
# Write-behind: update cache → async flush to DB (use sparingly)
```

## Workflow

1. Identify hot read path (measured, not assumed)
2. Choose data structure + pattern (cache-aside vs write-through)
3. Define TTL (short for volatile data, longer for reference data)
4. Implement with connection pool (never new connection per request)
5. Add cache invalidation on write path
6. Monitor: `INFO stats`, `MONITOR`, hit/miss ratio

→ [references/workflow.md](references/workflow.md) | [references/code-patterns.md](references/code-patterns.md)

## Constraints

- NEVER new Redis connection per request → reuse pool
- NEVER cache PII without encryption (personal identifiers, tokens, sensitive fields)
- NEVER cache without TTL (no unbounded memory growth)
- ALWAYS use `SETEX` / `SET EX` — never `SET` alone for cached data
- ALWAYS namespace keys: `<service>:<entity>:<id>` (e.g. `cache:context:customer_123`)
- ALWAYS invalidate cache on write (stale reads cause bugs worse than cache misses)
- NEVER use Redis as primary store for transactional data → PostgreSQL is SoT
- ALWAYS handle `ConnectionError` / `TimeoutError` with fallback to source

## Overview

Design and implement Redis caching strategies for cloud-native services including cache-aside, write-through, and write-behind patterns. Covers data structure selection (String, Hash, List, Set, Sorted Set), connection pooling, TTL management, and cache invalidation. Includes troubleshooting for cache stampede, hot-key issues, and memory eviction.

## Anti-patterns

FAIL: Creating a new Redis connection per request
```go
client := redis.NewClient(&redis.Options{Addr: "localhost:6379"})
defer client.Close()
```

PASS: Use a connection pool (single client reused)
```go
var rdb *redis.Client
func init() {
    rdb = redis.NewClient(&redis.Options{Addr: "localhost:6379", PoolSize: 100})
}
```

FAIL: Caching without TTL (unbounded memory growth)
```go
redis.Set(ctx, "key", value, 0) // 0 = no expiry
```

PASS: Always set TTL with SETEX or SET EX
```go
redis.SetEx(ctx, "key", value, 300 * time.Second)
```

FAIL: Redis as primary store for transactions
```go
if err := redis.Set(ctx, "rec:"+id, rec, 0).Err(); err != nil { ... }
```

PASS: PostgreSQL is source of truth; Redis is ephemeral cache
```go
db.Save(&rec)
redis.SetEx(ctx, "rec:"+id, rec, 5*time.Minute)
```

FAIL: Flat keys without namespace collision
```go
redis.Get(ctx, "user:123")
```

PASS: Namespaced keys to prevent collisions
```go
redis.Get(ctx, "items:user:123:profile")
```

FAIL: No cache stampede protection for hot keys (thundering herd)
```go
func getPopularItems(ctx context.Context) ([]Item, error) {
    val, err := rdb.Get(ctx, "popular:items").Result()
    if err == redis.Nil {
        items, _ := db.Query(...)  // all concurrent requests hit DB
        rdb.SetEx(ctx, "popular:items", items, 60*time.Second)
        return items, nil
    }
    ...
}
```

PASS: Use Lua locking — one computes, rest wait
```lua
-- Lua script: lock + get-or-compute
local key = KEYS[1]
local lock_key = key .. ":lock"
local ttl = ARGV[1]
local value = redis.call("GET", key)
if value then return value end
local locked = redis.call("SET", lock_key, "1", "NX", "EX", "2")
if locked then return "COMPUTE" end
for i = 1, 5 do
    value = redis.call("GET", key)
    if value then return value end
    redis.call("SLEEP", 0.1)
end
return nil
```

```go
// Go: call script, only COMPUTE caller queries DB
val, err := rdb.Eval(ctx, stampedeScript, []string{"popular:items"}, "300").Result()
if val == "COMPUTE" {
    items := loadFromDB()
    rdb.SetEx(ctx, "popular:items", items, 300*time.Second)
}
```

FAIL: Wrong serialization — storing Python dicts without encoding
```python
redis.set("user:123", {"role": "admin", "permissions": ["read", "write"]})
# TypeError: unhashable type: 'dict'
```

PASS: Always serialize with JSON or msgpack
```python
redis.setex("user:123", 300, json.dumps({"role": "admin", "permissions": ["read", "write"]}))
```

## References

| Resource | URL | Last verified |
|---|---|---|
| Redis docs — Data structures | https://redis.io/docs/data-types/ | 2026-03 |
| Redis docs — SETEX command | https://redis.io/commands/setex/ | 2026-03 |
| go-redis documentation | https://redis.uptrace.dev/guide/ | 2026-03 |

## Verification Checklist

- [ ] Redis connection uses pool (never new connection per request)
- [ ] All cached entries have explicit TTL (no unbounded memory growth)
- [ ] Keys namespaced: `<service>:<entity>:<id>`
- [ ] Cache invalidated on every relevant write path
- [ ] Fallback to source implemented on `ConnectionError` / `TimeoutError`
- [ ] No PII cached without encryption
- [ ] Redis is not used as primary store for transactional data

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| High cache miss ratio | TTL too short or cache-aside not populating on miss | Verify cache-aside fill path; increase TTL for stable reference data |
| Memory usage grows unbounded | Keys created without TTL (0 = no expiry) | Scan for `SET` without `EX`; add TTL to all cached entries |
| Cache stampede on popular key | Multiple concurrent misses for same key on expiry | Implement mutex/locking around cache fill; use write-through for hot keys |
| Connection refused / timeout | Pool exhausted or Redis maxclients limit hit | Reduce pool size; increase Redis `maxclients`; check for slow commands |
| Lua script returns `NOSCRIPT` error during failover (known issue: EVALSHA cache lost on failover) | EVALSHA script cache not replicated; promoted replica lacks script | Fall back to `EVAL` on `NOSCRIPT` error; use `SCRIPT LOAD` on connection establishment |
| `KEYS *` blocks Redis for seconds on datasets >10K keys | `KEYS` is O(N) blocking — scans all keys | Use `SCAN 0 COUNT 100` — non-blocking cursor-based iteration |
| `MGET` returns nil silently for missing keys (no error) | Redis returns nil for non-existent key, not error | Check each returned element for nil; NEVER rely on error return value |

## Quick Reference

| Concept | Rule | Example |
|---------|------|--------|
| TTL | Always set on cached data | `SETEX key 300 value` |
| Namespace | Prevent collisions across services | `items:user:123:profile` |
| Connection pool | Reuse, never per-request instantiation | `PoolSize: 100` |
| Eviction policy | Match workload pattern | `maxmemory-policy allkeys-lru` |
| Serialization | Always encode complex types | `json.dumps()` / `msgpack.packb()` |

| [WARN] Redis `SCAN` cursor wraps around silently, missing keys on large datasets | SCAN cursor is 64-bit; internal hash table rehashing can cause cursor reset to zero mid-scan | Implement multi-cursor tracking; count distinct keys returned vs expected; fall back to KEYS if scan fails |
