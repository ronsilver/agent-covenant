# Debugging Tools by Stack

## Go
```bash
# CPU profile
go test -cpuprofile=cpu.prof -bench=. && go tool pprof cpu.prof

# Memory profile
go test -memprofile=mem.prof -bench=. && go tool pprof mem.prof

# Goroutine dump
curl http://localhost:6060/debug/pprof/goroutine?debug=2

# Race detector
go test -race ./...

# Delve debugger
dlv debug cmd/server/main.go
dlv attach $(pgrep api)
# Breakpoint: break api/handler.go:42
# Print vars: print req.Amount
```

## Python
```bash
# CPU profiling with py-spy
py-spy record -o profile.svg -- python app.py

# Memory profiling with memray
python -m memray run -o output.bin app.py
python -m memray flamegraph output.bin

# tracemalloc for leak detection
import tracemalloc; tracemalloc.start()
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

# pdb debugger
import pdb; pdb.set_trace()
# Commands: n(next), s(step), c(continue), p var, l(list), b 42(breakpoint)
```

## JVM (Java/Scala/Kotlin)
```bash
# Thread dump
jstack $(pgrep java)

# Heap dump
jmap -dump:live,format=b,file=heap.hprof $(pgrep java)
# Analyze with Eclipse MAT or jhat

# JFR (Java Flight Recorder)
jcmd $(pgrep java) JFR.start duration=60s filename=recording.jfr

# async-profiler
./profiler.sh -d 60 -f flamegraph.svg $(pgrep java)
```

## Node.js
```bash
# CPU profile with clinic
clinic doctor -- node server.js

# Flamegraph with 0x
0x -o node server.js

# Heap snapshot
node --inspect server.js
# Chrome: chrome://inspect -> take heap snapshot

# Basic debugger
node --inspect-brk server.js
# Chrome DevTools: Sources -> set breakpoints
```

## Kubernetes
```bash
# Pod debugging
kubectl logs -f deployment/api --tail=100 --previous
kubectl exec -it deployment/api -- /bin/sh
kubectl describe pod api-abc123
kubectl get events --sort-by=.metadata.creationTimestamp

# Ephemeral debug container
kubectl debug -it api-abc123 --image=busybox --target=api
```

## Network/DNS
```bash
# DNS resolution
nslookup api.production.svc.cluster.local
dig +short api.example.com

# Connection test
nc -zv postgres.production 5432
curl -v https://api.example.com/healthz

# SSL/TLS inspection
openssl s_client -connect api.example.com:443 -servername api.example.com
```
