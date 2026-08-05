# Redis Cache Expert — Overview

## this project Redis Usage

| Service | Client | Use case |
|---|---|---|
| `AI context layer` | `redis-py` (aioredis) | Agent context cache, session state |
| `orders` | `go-redis/redis/v9` | Rate limiting, idempotency keys |
| `api-gateway` | `go-redis/redis/v9` | external provider response cache |
| Partner middlewares | `ioredis` | Session tokens, webhook dedup |

## Key Namespace Convention

```
<service>:<entity>:<identifier>
ai:context:customer_123
orders:idempotency:txn_abc_123
api-gateway:provider_response:hash_xyz
```

## Connection Pool (Go)

```go
import "github.com/redis/go-redis/v9"

var rdb *redis.Client

func NewRedisClient(cfg Config) *redis.Client {
    return redis.NewClient(&redis.Options{
        Addr:         cfg.RedisAddr,
        Password:     cfg.RedisPassword,
        DB:           0,
        PoolSize:     20,                   // per-host connections
        MinIdleConns: 5,
        DialTimeout:  5 * time.Second,
        ReadTimeout:  3 * time.Second,
        WriteTimeout: 3 * time.Second,
    })
}
```

## Connection Pool (Python)

```python
import redis.asyncio as aioredis

pool = aioredis.ConnectionPool.from_url(
    settings.REDIS_URL,
    max_connections=20,
    socket_connect_timeout=5,
    socket_timeout=3,
)
redis_client = aioredis.Redis(connection_pool=pool)
```

## Cache-Aside Pattern (canonical)

```python
async def get_customer_context(customer_id: str) -> dict:
    key = f"ai:context:{customer_id}"
    cached = await redis_client.get(key)
    if cached:
        return json.loads(cached)

    data = await db.fetch_customer_context(customer_id)
    await redis_client.setex(key, 300, json.dumps(data))   # TTL=5min
    return data

async def invalidate_customer_context(customer_id: str) -> None:
    await redis_client.delete(f"ai:context:{customer_id}")
```

## Pub/Sub (event fan-out)

```python
# Publisher (orders service)
await redis_client.publish("orders:events", json.dumps({
    "type": "order.processed",
    "txn_id": txn_id,
}))

# Subscriber (the AI service context refresh)
async with redis_client.pubsub() as ps:
    await ps.subscribe("orders:events")
    async for message in ps.listen():
        if message["type"] == "message":
            handle_event(json.loads(message["data"]))
```

## Lua Script (atomic check-and-set)

```lua
-- Idempotency check (atomic get-or-set)
local key = KEYS[1]
local value = ARGV[1]
local ttl = ARGV[2]
if redis.call("EXISTS", key) == 1 then
    return redis.call("GET", key)
end
redis.call("SET", key, value, "EX", ttl)
return nil
```

## TTL Strategy

| Data type | TTL |
|---|---|
| Idempotency key | 24 hours (match order window) |
| external provider response cache | 5 minutes |
| Agent context | 5–15 minutes (activity-based) |
| Session token | Match JWT expiry |
| Rate limit window | 1 minute (sliding) |
| Reference data (config) | 1 hour |

## Error Handling

```go
val, err := rdb.Get(ctx, key).Result()
if err == redis.Nil {
    // cache miss — fetch from DB
} else if err != nil {
    // Redis unavailable — fallback to DB, log warning
    log.Warn("redis unavailable, falling back", zap.Error(err))
    return fetchFromDB(ctx, key)
}
```

## Cache Stampede Prevention (Lua atomic lock)

```python
# Problem: cache miss under high load -> N goroutines all hit DB simultaneously
# Solution: atomic SET NX as distributed lock before DB fetch

import redis, json, hashlib

LOCK_TTL_MS = 5000   # max time to hold lock while fetching DB

def get_with_lock(r: redis.Redis, key: str, fetch_fn, ttl_s: int):
    val = r.get(key)
    if val:
        return json.loads(val)

    lock_key = f"lock:{key}"
    acquired = r.set(lock_key, "1", px=LOCK_TTL_MS, nx=True)

    if acquired:
        try:
            data = fetch_fn()
            r.set(key, json.dumps(data), ex=ttl_s)
            return data
        finally:
            r.delete(lock_key)
    else:
        # another process is fetching -- short poll
        import time
        for _ in range(10):
            time.sleep(0.05)
            val = r.get(key)
            if val:
                return json.loads(val)
        return fetch_fn()   # fallback: fetch directly
```

## Cluster Mode — Hash Tags

```python
# In Redis Cluster, all keys in a Lua script must be on the same slot
# Use hash tags {user:123} to colocate related keys

# WRONG: different keys may land on different cluster nodes
r.mset({"user:123:cart": ..., "user:123:session": ...})

# RIGHT: hash tag {} forces same slot
r.mset({"{user:123}:cart": ..., "{user:123}:session": ...})

# Lua scripts in cluster mode REQUIRE same-slot keys:
script = r.register_script("""
local cart    = redis.call('GET', KEYS[1])
local session = redis.call('GET', KEYS[2])
-- both keys must share same slot
return {cart, session}
""")
result = script(keys=["{user:123}:cart", "{user:123}:session"])

# EVALSHA fallback on NOSCRIPT (cluster failover can evict scripts):
try:
    result = script(keys=keys, args=args)
except redis.exceptions.NoScriptError:
    r.script_load(script.script)     # re-register
    result = script(keys=keys, args=args)
```

## BlockingConnectionPool (Python async)

```python
import redis.asyncio as aioredis

# BlockingConnectionPool: raises after timeout rather than growing unbounded
pool = aioredis.BlockingConnectionPool(
    max_connections=20,
    timeout=2,               # raise after 2s waiting for available connection
    socket_connect_timeout=5,
    decode_responses=True,
)
r = aioredis.Redis(connection_pool=pool)
# Under load spikes, fail fast (2s) rather than queue unboundedly
```
