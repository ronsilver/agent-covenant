# Go Concurrency Patterns

## Goroutines
```go
go func() {
    // concurrent work
}()
```
Lightweight (4KB stack, grows as needed). Thousands of goroutines = normal.

## Channels
```go
ch := make(chan int, 10)    // buffered
ch := make(chan int)         // unbuffered (sync)

// Fan-out
for i := 0; i < 10; i++ {
    go worker(ch)
}

// Fan-in with select
select {
case result := <-ch1: ...
case result := <-ch2: ...
case <-ctx.Done(): return
}

// Close signal
close(ch)  // receivers get zero value
```

## sync Package
```go
var mu sync.Mutex; mu.Lock(); defer mu.Unlock()
var wg sync.WaitGroup; wg.Add(1); go func() { defer wg.Done() }(); wg.Wait()
sync.Once: ensure one-time initialization
sync.Pool: object reuse, reduce allocations
```

## Context Propagation
```go
ctx, cancel := context.WithTimeout(parent, 5*time.Second); defer cancel()
ctx = context.WithValue(ctx, key, value)  // rarely needed
// ALWAYS first parameter in functions
// NEVER store nil contexts
```

## Error Handling
```go
// Sentinel errors
var ErrNotFound = errors.New("not found")

// Custom types
type ValidationError struct { Field string; Reason string }
func (e *ValidationError) Error() string { return fmt.Sprintf("%s: %s", e.Field, e.Reason) }

// Wrapping
return fmt.Errorf("create payment: %w", err)
errors.Is(err, ErrNotFound)
errors.As(err, &valErr)
```

## Concurrency Gotchas
- NEVER share maps without sync (use sync.Map or mutex)
- ALWAYS close channels from sender side
- NEVER use time.Sleep for synchronization
- Race detector: `go test -race ./...` ALWAYS in CI
- Goroutine leaks: verify goroutines exit (pprof goroutine dump)
