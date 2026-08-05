# Saga Compensation Patterns

## Orchestration Saga
```go
type SagaStep struct {
    Action      func(ctx, state) error
    Compensate  func(ctx, state) error
}

func ExecuteSaga(ctx, req) error {
    saga := Saga{ID: uuid.New()}
    saga.AddStep(reserveInventory, releaseInventory)
    saga.AddStep(confirmOrder, cancelOrder)
    saga.AddStep(sendNotification, nil)
    return saga.Execute(ctx)
}
```

## Compensation Rules
- Each step MUST have compensating action (or be non-critical)
- Compensations are idempotent (safe to retry)
- Compensations run in reverse order of actions
- Track saga state in persistent store (for crash recovery)
- NEVER use distributed transactions (2PC) - sagas are eventually consistent

## Failure Scenarios
| Failure Point | Compensation |
|---|---|
| Reserve inventory -> DB error | Release reservation |
| Confirm order -> service timeout | Cancel order or check status first |
| Send notification -> email fails | Retry 3x, then alert (non-critical) |

## Anti-Pattern: 2PC
Distributed transactions lock resources across services - deadlock risk, single point of failure.
Sagas are the correct pattern for microservice coordination.
