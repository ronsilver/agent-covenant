# Retry with Exponential Backoff

```go
func RetryWithBackoff(ctx context.Context, maxRetries int, fn func() error) error {
    backoff := 100 * time.Millisecond
    for i := 0; i < maxRetries; i++ {
        err := fn()
        if err == nil { return nil }
        if i == maxRetries-1 { return err }
        select {
        case <-time.After(backoff):
            backoff *= 2  // 100ms -> 200ms -> 400ms -> 800ms
        case <-ctx.Done():
            return ctx.Err()
        }
    }
    return nil
}
```
Max delay: 30s. ALWAYS respect context cancellation.
