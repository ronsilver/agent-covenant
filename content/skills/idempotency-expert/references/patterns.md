# Idempotency Patterns

## Idempotency Key Flow
```
1. Client: POST /v1/shipments { Idempotency-Key: key_abc }
2. Server: check Redis GET key_abc
   - Found -> return cached response (same status + body)
   - Not found -> process + SET key_abc = response, TTL 24h
```

## Distributed Lock (Race Condition)
```go
lockKey := "lock:" + idempotencyKey
acquired := redis.SetNX(ctx, lockKey, "locked", 10*time.Second).Val()
if !acquired { time.Sleep(50*time.Millisecond); return s.Create(ctx, key, req) }
defer redis.Del(ctx, lockKey)
```

## Saga Compensation
```
Step: Reserve(A) -> Capture(B) -> FAIL
Compensate: Release(A)  // undo step 1
```
Each step has compensating action. Track saga state in DB.
