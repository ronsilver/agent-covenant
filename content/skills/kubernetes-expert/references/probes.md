# Health Probes in Kubernetes

## Probe Types

| Probe | Purpose | Action on Failure |
|-------|---------|-------------------|
| **Liveness** | Is the container alive? | Restart container |
| **Readiness** | Can container accept traffic? | Remove from Service endpoints |
| **Startup** | Has container finished starting? | Wait, then check liveness |

## Liveness Probe

Detects when container is in a broken state and needs restart.

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 15    # Wait before first check
  periodSeconds: 10          # Check every 10s
  timeoutSeconds: 3          # Request timeout
  failureThreshold: 3        # Restart after 3 failures
  successThreshold: 1        # 1 success = healthy
```

**When to use**: Detect deadlocks, infinite loops, unrecoverable errors

**Caution**: Too aggressive = restart loops

## Readiness Probe

Determines if container should receive traffic.

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5     # Start checking after 5s
  periodSeconds: 5           # Check every 5s
  timeoutSeconds: 3
  failureThreshold: 3        # Mark unready after 3 failures
  successThreshold: 1        # Mark ready after 1 success
```

**When to use**:
- Application warming up (cache loading)
- Temporary unavailability (database connection lost)
- Graceful shutdown

**Difference from liveness**: Doesn't restart, just stops sending traffic

## Startup Probe

For slow-starting containers (legacy apps, large JVMs).

```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 30       # Allow 30 * 10s = 5 minutes to start
  successThreshold: 1
```

**When to use**: Container takes > 30s to start

**Effect**: Liveness/readiness disabled until startup succeeds

## Probe Types

### HTTP GET

```yaml
httpGet:
  path: /healthz
  port: 8080
  httpHeaders:
  - name: Custom-Header
    value: Awesome
  scheme: HTTP  # or HTTPS
```

### TCP Socket

```yaml
tcpSocket:
  port: 8080
```

**Use when**: No HTTP endpoint (databases, TCP services)

### Exec Command

```yaml
exec:
  command:
  - cat
  - /tmp/healthy
```

**Use when**: Custom health check logic needed

**Caution**: Command runs inside container, creates overhead

### gRPC

```yaml
grpc:
  port: 9090
  service: health  # Optional
```

**Requires**: gRPC health checking protocol implementation

## Health Endpoint Implementation

### Go (HTTP)

```go
package main

import (
    "net/http"
    "sync/atomic"
)

var (
    healthy int32 = 1
    ready   int32 = 0
)

func main() {
    // Health endpoints
    http.HandleFunc("/healthz", healthzHandler)
    http.HandleFunc("/ready", readyHandler)

    // Initialize
    go initialize()

    // Start server
    http.ListenAndServe(":8080", nil)
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
    if atomic.LoadInt32(&healthy) == 1 {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
        return
    }
    w.WriteHeader(http.StatusServiceUnavailable)
}

func readyHandler(w http.ResponseWriter, r *http.Request) {
    if atomic.LoadInt32(&ready) == 1 {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("Ready"))
        return
    }
    w.WriteHeader(http.StatusServiceUnavailable)
}

func initialize() {
    // Warm up caches, connect to DB, etc.
    // ...
    atomic.StoreInt32(&ready, 1)
}
```

### Python (Flask)

```python
from flask import Flask, jsonify
import threading

app = Flask(__name__)

healthy = True
ready = False

@app.route('/healthz')
def healthz():
    if healthy:
        return jsonify(status="OK"), 200
    return jsonify(status="Unhealthy"), 503

@app.route('/ready')
def ready_check():
    if ready:
        return jsonify(status="Ready"), 200
    return jsonify(status="Not ready"), 503

def initialize():
    global ready
    # Warm up caches, etc.
    # ...
    ready = True

if __name__ == '__main__':
    threading.Thread(target=initialize, daemon=True).start()
    app.run(host='0.0.0.0', port=8080)
```

### Node.js (Express)

```javascript
const express = require('express');
const app = express();

let healthy = true;
let ready = false;

app.get('/healthz', (req, res) => {
  if (healthy) {
    res.status(200).send('OK');
  } else {
    res.status(503).send('Unhealthy');
  }
});

app.get('/ready', (req, res) => {
  if (ready) {
    res.status(200).send('Ready');
  } else {
    res.status(503).send('Not ready');
  }
});

// Initialize
async function initialize() {
  // Load data, warm up caches
  // ...
  ready = true;
}

initialize();

app.listen(8080);
```

## Advanced Health Checks

### Database Connection Check

```go
func healthzHandler(w http.ResponseWriter, r *http.Request) {
    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
    defer cancel()

    if err := db.PingContext(ctx); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        return
    }
    w.WriteHeader(http.StatusOK)
}
```

### Multiple Dependencies

```go
type HealthChecker struct {
    db    *sql.DB
    cache *redis.Client
}

func (h *HealthChecker) Check(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()

    // Check database
    if err := h.db.PingContext(ctx); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]string{
            "status": "unhealthy",
            "error":  "database unreachable",
        })
        return
    }

    // Check cache
    if err := h.cache.Ping(ctx).Err(); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        json.NewEncoder(w).Encode(map[string]string{
            "status": "unhealthy",
            "error":  "cache unreachable",
        })
        return
    }

    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}
```

## Graceful Shutdown

```go
func main() {
    srv := &http.Server{Addr: ":8080"}

    go func() {
        if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
            log.Fatal(err)
        }
    }()

    // Wait for interrupt signal
    quit := make(chan os.Signal, 1)
    signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
    <-quit

    // Mark as not ready (stop receiving traffic)
    atomic.StoreInt32(&ready, 0)

    // Wait for existing requests to complete
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()

    if err := srv.Shutdown(ctx); err != nil {
        log.Fatal("Server forced to shutdown:", err)
    }
}
```

## Common Mistakes

### FAIL: Liveness = Readiness

```yaml
# Don't use same endpoint/config for both
livenessProbe:
  httpGet:
    path: /health
readinessProbe:
  httpGet:
    path: /health  # FAIL: Same as liveness
```

**Problem**: Temporary issues cause restarts instead of graceful degradation

### FAIL: Too Aggressive

```yaml
livenessProbe:
  initialDelaySeconds: 5
  periodSeconds: 3
  failureThreshold: 1  # FAIL: Restart after 1 failure
```

**Problem**: Restart loops during normal operations

### FAIL: Checking External Dependencies in Liveness

```go
// FAIL: Don't check database in liveness
func healthz(w http.ResponseWriter, r *http.Request) {
    if err := db.Ping(); err != nil {
        w.WriteHeader(503)  // Will restart pod!
        return
    }
    w.WriteHeader(200)
}
```

**Problem**: Database downtime causes all pods to restart

**Fix**: Check external dependencies in readiness only

### FAIL: No Startup Probe for Slow Apps

```yaml
# FAIL: JVM takes 2 minutes to start, but liveness kills it at 30s
livenessProbe:
  initialDelaySeconds: 30
  failureThreshold: 3
  periodSeconds: 10
# Pod killed at 30 + (3 * 10) = 60s, but needs 120s to start
```

**Fix**: Add startup probe with higher failureThreshold

## Best Practices

1. **Separate endpoints**: Different for liveness and readiness
2. **Liveness checks app health**: Not external dependencies
3. **Readiness checks everything**: Including dependencies
4. **Use startup probe**: For slow-starting apps
5. **Set appropriate thresholds**: Avoid restart loops
6. **Return quickly**: Health checks should be <1s
7. **Log failures**: Debug why probes fail

## Probe Configuration Recommendations

### Fast-Starting API

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 2
```

### Slow-Starting Application (JVM, large cache)

```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
  failureThreshold: 30  # 5 minutes

livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
  failureThreshold: 2
```

### Database

```yaml
livenessProbe:
  tcpSocket:
    port: 5432
  initialDelaySeconds: 30
  periodSeconds: 10
  failureThreshold: 3

readinessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```

## Debugging Probe Failures

```bash
# Check probe events
kubectl describe pod my-pod

# Look for:
# Liveness probe failed: HTTP probe failed with statuscode: 503
# Readiness probe failed: Get "http://10.0.0.1:8080/ready": dial tcp 10.0.0.1:8080: connect: connection refused

# Test probe manually
kubectl exec my-pod -- wget -O- http://localhost:8080/healthz

# Check logs
kubectl logs my-pod
```

## Probe Checklist

- [ ] Liveness probe checks internal app health only
- [ ] Readiness probe checks app + dependencies
- [ ] Startup probe for slow-starting apps
- [ ] initialDelaySeconds allows app to start
- [ ] failureThreshold prevents restart loops
- [ ] Health endpoints return quickly (<1s)
- [ ] Different endpoints for liveness vs readiness
- [ ] Tested under load
