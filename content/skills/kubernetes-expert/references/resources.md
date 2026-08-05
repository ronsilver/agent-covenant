# Resource Management in Kubernetes

## Resource Requests vs Limits

| Type | Purpose | Effect |
|------|---------|--------|
| **requests** | Minimum guaranteed resources | Used for scheduling |
| **limits** | Maximum allowed resources | Pod killed if exceeded (OOMKilled for memory) |

## Resource Units

### CPU

- **1 CPU** = 1 vCPU/core
- **1000m (millicores)** = 1 CPU
- **100m** = 0.1 CPU (10% of one core)

```yaml
resources:
  requests:
    cpu: "100m"    # 0.1 CPU
  limits:
    cpu: "500m"    # 0.5 CPU
```

### Memory

- **Ki, Mi, Gi** = 1024-based (binary)
- **K, M, G** = 1000-based (decimal)

```yaml
resources:
  requests:
    memory: "128Mi"  # 128 mebibytes
  limits:
    memory: "256Mi"  # 256 mebibytes
```

## Resource Guidelines by Workload

### Small API/Service

```yaml
resources:
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

**Use case**: Simple REST API, low traffic

### Standard API/Service

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**Use case**: Production API with moderate traffic

### Worker/Batch Job

```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

**Use case**: Background workers, cron jobs

### Memory-Intensive Application

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

**Use case**: Data processing, analytics, caching

### Frontend (Static Assets)

```yaml
resources:
  requests:
    memory: "32Mi"
    cpu: "10m"
  limits:
    memory: "64Mi"
    cpu: "50m"
```

**Use case**: Nginx serving static files

## Best Practices

### 1. Always Set Requests and Limits

```yaml
# FAIL: Bad - no resource control
containers:
- name: app
  image: myapp:1.0.0

# PASS: Good - defined resources
containers:
- name: app
  image: myapp:1.0.0
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "500m"
```

### 2. Memory Limit = 2x Request

```yaml
# PASS: Good ratio for handling spikes
resources:
  requests:
    memory: "256Mi"
  limits:
    memory: "512Mi"  # 2x request
```

**Why**: Allows room for traffic spikes without OOMKills while preventing runaway memory usage.

### 3. CPU Limits Optional

```yaml
# PASS: Often better without CPU limits
resources:
  requests:
    cpu: "100m"
  limits:
    cpu: null  # No limit, can burst to available CPU
```

**Why**: CPU is compressible (pod slows down), memory is not (pod kills). CPU limits can cause unnecessary throttling.

### 4. Set Limits Based on Profiling

```bash
# Profile memory usage
kubectl top pod my-app-xyz

# View detailed metrics
kubectl exec my-app-xyz -- cat /sys/fs/cgroup/memory/memory.usage_in_bytes
```

## Quality of Service (QoS) Classes

Kubernetes assigns QoS based on requests/limits:

| QoS Class | Condition | Priority | Use Case |
|-----------|-----------|----------|----------|
| **Guaranteed** | requests = limits | Highest | Critical production workloads |
| **Burstable** | requests < limits | Medium | Most applications |
| **BestEffort** | No requests/limits | Lowest | Non-critical, can be evicted first |

### Guaranteed QoS

```yaml
# All containers have requests = limits
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

**Use for**: Critical databases, stateful applications

### Burstable QoS

```yaml
# Requests < limits
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"
```

**Use for**: Most web applications, APIs

### BestEffort QoS

```yaml
# No resources defined
# FAIL: Avoid in production
```

## Resource Quotas (Namespace Level)

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "100"        # Total CPU requests
    requests.memory: "200Gi"   # Total memory requests
    limits.cpu: "200"          # Total CPU limits
    limits.memory: "400Gi"     # Total memory limits
    pods: "50"                 # Max number of pods
    services: "20"             # Max number of services
    persistentvolumeclaims: "10"
```

## LimitRange (Default Resources)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - default:
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:
      memory: "256Mi"
      cpu: "100m"
    max:
      memory: "4Gi"
      cpu: "2000m"
    min:
      memory: "64Mi"
      cpu: "50m"
    type: Container
```

**Effect**: Pods without resources get defaults; pods exceeding max are rejected.

## Monitoring Resources

### View Current Usage

```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n production

# Specific pod
kubectl top pod my-app-xyz

# All containers in pod
kubectl top pod my-app-xyz --containers
```

### Metrics Server

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl get deployment metrics-server -n kube-system
```

## Vertical Pod Autoscaler (VPA)

Automatically adjusts requests/limits:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  updatePolicy:
    updateMode: "Auto"  # Or "Recreate", "Initial", "Off"
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: "100m"
        memory: "128Mi"
      maxAllowed:
        cpu: "2000m"
        memory: "4Gi"
```

## Troubleshooting

### Pod Pending (Insufficient Resources)

```bash
# Check events
kubectl describe pod my-pod

# Look for:
# Warning  FailedScheduling  0/3 nodes are available: insufficient cpu.
```

**Fix**: Increase cluster capacity or reduce resource requests

### Pod OOMKilled

```bash
# Check exit code
kubectl get pod my-pod

# NAME     READY   STATUS      RESTARTS   AGE
# my-pod   0/1     OOMKilled   5          10m
```

**Fix**: Increase memory limits or fix memory leak

### CPU Throttling

```bash
# Check throttling
kubectl exec my-pod -- cat /sys/fs/cgroup/cpu/cpu.stat | grep throttled

# If throttled_time is high, consider:
# 1. Removing CPU limits
# 2. Increasing CPU limits
# 3. Optimizing application
```

## Resource Calculation Examples

### Calculate Total Cluster Resources

```bash
# Available
kubectl top nodes

# Requested
kubectl get pods -A -o json | \
  jq -r '.items[] | .spec.containers[] | .resources.requests.memory' | \
  awk '{sum+=$1} END {print sum}'
```

### Find Pods Without Resources

```bash
kubectl get pods -A -o json | \
  jq -r '.items[] | select(.spec.containers[].resources.requests == null) | .metadata.name'
```

## Best Practices Summary

1. **Always define requests and limits**
2. **Memory limit = 2x memory request**
3. **Profile before setting resources**
4. **Use VPA for automated tuning**
5. **Monitor with metrics-server**
6. **Set ResourceQuota on namespaces**
7. **CPU limits optional (can throttle unnecessarily)**
8. **Test under load before production**

## Resource Sizing Worksheet

| Workload Type | Memory Request | Memory Limit | CPU Request | CPU Limit |
|---------------|----------------|--------------|-------------|-----------|
| Nginx (static) | 32Mi | 64Mi | 10m | 50m |
| Simple API | 128Mi | 256Mi | 100m | 500m |
| Standard API | 256Mi | 512Mi | 250m | 1000m |
| Worker | 512Mi | 1Gi | 250m | 1000m |
| Database (small) | 1Gi | 2Gi | 500m | 2000m |
| Cache (Redis) | 2Gi | 4Gi | 500m | 2000m |
| ML/Analytics | 4Gi | 8Gi | 1000m | 4000m |

**Adjust based on your application's actual usage.**
