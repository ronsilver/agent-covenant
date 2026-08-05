# Debugging Tools by Stack

## Go
```bash
go test -cpuprofile=cpu.prof -bench=. && go tool pprof cpu.prof
go test -memprofile=mem.prof -bench=. && go tool pprof mem.prof
curl http://localhost:6060/debug/pprof/goroutine?debug=2
go test -race ./...
dlv debug cmd/server/main.go
```

## Python
```bash
py-spy record -o profile.svg -- python app.py
python -m memray run -o output.bin app.py
python -m memray flamegraph output.bin
import pdb; pdb.set_trace()  # n=next, s=step, c=continue, p var
```

## JVM
```bash
jstack $(pgrep java)
jmap -dump:live,format=b,file=heap.hprof $(pgrep java)
jcmd $(pgrep java) JFR.start duration=60s filename=recording.jfr
```

## Node.js
```bash
clinic doctor -- node server.js
node --inspect-brk server.js  # Chrome: chrome://inspect
```

## Kubernetes
```bash
kubectl logs -f deploy/api --tail=100 --previous
kubectl exec -it deploy/api -- /bin/sh
kubectl describe pod api-abc123
kubectl debug -it api-abc123 --image=busybox --target=api
```
