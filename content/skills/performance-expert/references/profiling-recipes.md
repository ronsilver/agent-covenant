# Performance Profiling Recipes

## Go: Find Hot Path
```bash
go test -cpuprofile=cpu.prof -bench=.
go tool pprof -top cpu.prof  # top CPU consumers
go tool pprof -http :8080 cpu.prof  # flamegraph UI
```

## Python: Find Memory Leak
```bash
python -m memray run -o leak.bin app.py
python -m memray flamegraph leak.bin
python -m memray table leak.bin  # largest allocations
```

## Node.js: Find Event Loop Blockage
```bash
clinic doctor -- node server.js
# Shows: event loop delay, GC pauses, async operations
```

## N+1 Query Detection
```bash
# Enable query logging
grep "SELECT" postgresql.log | sort | uniq -c | sort -nr | head -10
# Trace with OTel: look for repeated spans with same pattern
```

## Connection Pool Exhaustion
```bash
# Go: pprof goroutine dump -> look for blocked in acquireSem
# PG: SELECT count(*) FROM pg_stat_activity WHERE state = 'active';
```
