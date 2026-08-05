# Redis Code Patterns

Common code patterns for this project Redis usage.

## Go (go-redis)

```go
client := redis.NewClient(&redis.Options{
    Addr: "localhost:6379",
    PoolSize: 10,
})

cacheAside := func(ctx context.Context, key string) (string, error) {
    val, err := client.Get(ctx, key).Result()
    if err == redis.Nil {
        // fetch from DB
        val = db.Get(key)
        client.SetEX(ctx, key, val, 5*time.Minute)
    }
    return val, nil
}
```

## Python (redis-py)

```python
import redis

r = redis.Redis.from_url("redis://localhost:6379", decode_responses=True)

value = r.get(key)
if not value:
    value = db.query(key)
    r.setex(key, 300, value)
```

## Constraints

- NEVER new connection per request → reuse pool.
- NEVER cache PII without encryption.
- ALWAYS use `SETEX` / `SET EX` for TTL.
