# Go Performance & Profiling

## pprof
```bash
# CPU profile
go test -cpuprofile=cpu.prof -bench=.
go tool pprof -http :8080 cpu.prof

# Memory profile
go test -memprofile=mem.prof -bench=.
go tool pprof -alloc_objects mem.prof  # allocations

# Runtime profiling
import _ "net/http/pprof"
http.ListenAndServe(":6060", nil)
# curl http://localhost:6060/debug/pprof/heap
```

## Memory Optimization
- Pre-allocate slices: `make([]int, 0, capacity)`
- Avoid boxing values: use `[]int`, not `[]interface{}`
- sync.Pool for frequently allocated objects
- strings.Builder over += concatenation
- Avoid finalizers (SetFinalizer slows GC)

## Escape Analysis
```bash
go build -gcflags="-m" ./...  # shows what escapes to heap
```
Variables that escape heap: pointers returned, interface boxed, closure captures.

## GC Tuning
```go
debug.SetGCPercent(100)  // default. Higher = less GC, more memory
```
Monitor: GODEBUG=gctrace=1 for GC stats. Keep GC pause < 100micros.

## Benchmarks
```go
func BenchmarkProcess(b *testing.B) {
    for i := 0; i < b.N; i++ {
        Process(input)
    }
}
# go test -bench=. -benchmem -count=5 -benchtime=3s
```
Report: ns/op, B/op, allocs/op. Run multiple times, compare with benchstat.
