# Microservice Patterns

## Saga Orchestration
```go
type Saga struct {
    ID     string
    Steps  []SagaStep
    State  map[string]interface{}
}
type SagaStep struct {
    Action      func(ctx, state) error
    Compensate  func(ctx, state) error
}
```
Each step has compensating action. Sagas are eventually consistent.

## Circuit Breaker States
```
Closed (normal) -> Open (after N failures) -> Half-Open (1 test after timeout)
```
If test succeeds: close. If test fails: re-open.
NEVER use without logging state transitions.

## Outbox Pattern
```sql
-- Transactional outbox: write to outbox in same DB transaction
INSERT INTO outbox (aggregate_id, event_type, payload) VALUES (...);
-- Outbox processor reads and publishes, then marks as sent
```

## Strangler Fig Migration
```
Phase 1: route 10% traffic to new service
Phase 2: increase to 50% (validate metrics)
Phase 3: 100% new, deprecate old
Phase 4: remove old code
```
