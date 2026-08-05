---
name: idempotency-expert
description: "Design of idempotent operations in distributed systems: idempotency key generation and validation, request deduplication with time windows, compensating transactions (Saga, TCC), state precondition validation (conditional updates with ETags), retry handling with exponential backoff, and exactly-once semantics guarantee. Use when designing idempotent APIs, implementing exactly-once semantics, adding idempotency keys, or handling retry safety. Trigger: idempotency key, exactly-once, deduplication, Saga pattern, TCC, ETag conditional update, retry backoff. Do NOT trigger for: general API design, database schema versioning, feature flag implementation."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Idempotency Expert

**Exactly-once semantics, idempotency keys, deduplication and retry safety.**

## Idempotency Keys

```
POST /v1/items
Idempotency-Key: key_abc123
```

1. Client generates unique key per operation attempt
2. Server checks key existence -> if found, return stored response
3. If not found, process operation + store key->response mapping
4. Key expires after TTL window (e.g., 24h)

```go
func (s *ItemService) Create(ctx context.Context, key string, req ItemRequest) (*Item, error) {
    if cached, err := s.idempotency.Get(ctx, key); err == nil {
        return cached, nil              // duplicate — return stored result
    }
    item, err := s.process(ctx, req)
    if err != nil {
        return nil, err
    }
    s.idempotency.Set(ctx, key, item, 24*time.Hour)
    return item, nil
}
```

## Exactly-Once Semantics

| Guarantee | How |
|---|---|
| At-most-once | Send once, no retry (can lose messages) |
| At-least-once | Retry until ACK (can duplicate) |
| Exactly-once | Deduplication + idempotent processing |

## Saga — Compensating Operations

```
Step 1: Create account       -> success
Step 2: Provision workspace  -> FAILS
Compensate: Deactivate account  (undo step 1)
```

- Each step has a compensating action
- Sagas are eventually consistent (not atomic like DB transactions)
- Track saga state in persistent store for crash recovery

## De-duplication Patterns

| Pattern | When |
|---|---|
| Key-based (Redis/DB) | Critical write operations, API calls |
| Conditional update (ETags/version) | Resource updates |
| Idempotent receiver (message queues) | Event consumers |

## Constraints

- NEVER skip idempotency on critical write operations (CRITICAL)
- NEVER accept idempotency keys from untrusted sources (generate client-side or validate server-side)
- NEVER use idempotency keys shorter than UUID (collision risk)
- ALWAYS set TTL on stored idempotency responses (NEVER grow unbounded)
- ALWAYS return same response for duplicate keys (not just same status)
- NEVER process operations before confirming key is unique (race condition)

## Overview

Exactly-once semantics for distributed systems. Covers idempotency key generation and validation, request deduplication with TTL windows, Saga compensating transactions (TCC), conditional updates with ETags, and retry-safe processing.

## Quick Reference

| Scenario | Pattern |
|---|---|
| Critical write operation — must prevent duplicate side effects | Idempotency key (UUID) + Redis/DB check + stored response |
| Resource update — must detect concurrent modifications | Conditional update with ETag/version field |
| Multi-step transaction — must handle partial failure | Saga pattern with compensating actions per step |
| Message consumer — must handle duplicate deliveries | Idempotent receiver: dedup by message ID, store processed IDs |
| Retry with backoff — must not amplify load | Exponential backoff + jitter + idempotency on receiver |

## Workflow

1. **Client generates key** — Unique idempotency key (UUID recommended) per operation attempt.
2. **Server checks key existence** — Look up key in cache/DB. If found: return stored response (idempotent replay).
3. **Key is unique** — Acquire distributed lock or use conditional insert to prevent race.
4. **Process operation** — Execute business logic. For multi-step flows, use Saga (each step has a compensating action).
5. **Store key→response** — Persist the result mapped to the idempotency key with a TTL.
6. **Return response** — Return stored result for all subsequent retries with same key.

## Anti-patterns

FAIL: **Skipping idempotency on critical write endpoints**
```go
func (s *Service) CreateItem(w http.ResponseWriter, r *http.Request) {
    extSvc.Process(r.Body) // BAD: no idempotency — retry = duplicate
}
```
PASS: Always check idempotency key before processing. Use `Idempotency-Key` header.

FAIL: **Using timestamp-based idempotency keys**
```go
key := fmt.Sprintf("%d", time.Now().UnixNano()) // BAD: collision risk on retry
```
PASS: Use UUID v4: `key := uuid.New().String()`.

FAIL: **Processing before confirming key uniqueness (race)**
```go
if _, err := cache.Get(ctx, key); err != nil {
    result := processItem(req) // BAD: two goroutines can both pass this check
}
```
PASS: Use atomic conditional insert or distributed lock (Redis `SETNX`).

FAIL: **Returning different responses for duplicate keys**
```go
// BAD: first call returns "processing", retry returns "completed"
```
PASS: Always return the exact same response (status code, body, headers) for all retries with the same key.

FAIL: **No TTL on stored idempotency responses**
```go
cache.Set(ctx, key, response) // BAD: unbounded storage growth
```
PASS: Always set TTL: `cache.Set(ctx, key, response, 24*time.Hour)`.

## References

| Resource | URL | Last verified |
|---|---|---|
| IETF HTTP Idempotency Key Draft | https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/ | 2026-07-23 |
| AWS Lambda Idempotency | https://docs.aws.amazon.com/lambda/latest/dg/idempotency.html | 2026-05-25 |
| Saga Pattern (Microsoft) | https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/saga/saga | 2026-05-25 |
| HTTP Idempotency (RFC 7231 §4.2.2) | https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.2 | 2026-05-25 |

- [references/patterns.md](references/patterns.md)
- [references/retry-backoff.md](references/retry-backoff.md)
- [references/saga-compensation.md](references/saga-compensation.md)

## Verification Checklist

- [ ] Critical write operations check idempotency key before processing
- [ ] Idempotency key is UUID v4 (not timestamp or sequential number)
- [ ] Distributed lock or conditional insert prevents race condition on key check
- [ ] Stored response returned identically for all retries with same key
- [ ] TTL set on all stored idempotency responses
- [ ] Saga pattern has compensating actions defined for every step

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Duplicate operations despite idempotency key | Race condition: two requests checked key simultaneously | Use Redis `SETNX` or DB unique constraint for atomic check-and-set |
| Idempotency key collision | Client generating non-unique keys | Ensure client uses UUID v4; validate server-side uniqueness |
| Stored idempotency responses growing unbounded | Missing TTL on cache entries | Add TTL (e.g., 24h) to all `Set()` calls for idempotency responses |
| Known issue: idempotency key TTL expiry during long-running operation | Operation exceeds TTL window; duplicate request accepted after expiry | Set TTL > max expected operation time; use sliding TTL refresh during processing |

| [WARN] Client retry with same key sends different payload | Spec requires same payload for same idempotency key but client violates it | Return `422 Unprocessable Entity` if payload differs for existing key; log mismatch for audit |
| Idempotency key stored in Redis but Redis cluster node goes down before replication | Async replication delay; second request routed to replica without the key entry | Use WAIT command or configure quorum = majority for strong consistency |
| Limitation: idempotency key alone cannot prevent duplicate in Kafka exactly-once delivery | Kafka producer retries can produce duplicates even with idempotent producer if broker fails between ack and commit | Use transactional outbox pattern: write event + idempotency state in same DB transaction before Kafka produce |
