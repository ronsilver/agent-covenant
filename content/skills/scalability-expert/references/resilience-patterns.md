# Resilience Pattern Reference

## Circuit Breaker
```go
cb := gobreaker.NewCircuitBreaker(gobreaker.Settings{
    Name:        "carrier-external-service",
    MaxRequests: 1,              // half-open: 1 test
    Interval:    30 * time.Second, // reset timeout
    Timeout:     30 * time.Second, // open duration
    ReadyToTrip: func(counts gobreaker.Counts) bool {
        failureRatio := float64(counts.TotalFailures) / float64(counts.Requests)
        return counts.Requests >= 5 && failureRatio >= 0.6
    },
})
```
States: Closed -> Open (after threshold) -> Half-Open (after timeout) -> Closed/Open

## Bulkhead
```go
type Bulkhead struct {
    sem chan struct{}  // capacity
}
func (b *Bulkhead) Do(fn func() error) error {
    select {
    case b.sem <- struct{}{}:
        defer func() { <-b.sem }()
        return fn()
    case <-time.After(timeout):
        return ErrBulkheadFull
    }
}
```
Isolate thread pools per dependency. One slow dep doesn't exhaust all workers.

## Rate Limiter — Token Bucket
```go
limiter := rate.NewLimiter(rate.Limit(100), 10) // 100 req/s, burst 10
if !limiter.Allow() { return ErrRateLimited }
```
Per client bucket. Return 429 + Retry-After header on exhaustion.
