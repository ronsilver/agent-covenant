# Horizontal Pod Autoscaler (HPA)

## Basic HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Effect**: Scales between 2-10 replicas to maintain 70% CPU utilization

## CPU-Based Scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Target 70% CPU
```

## Memory-Based Scaling

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Target 80% memory
```

## Multi-Metric HPA

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-metric-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 50
  metrics:
  # CPU
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  # Memory
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  # Custom metric (requests per second)
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
```

**Behavior**: Scales based on whichever metric needs the most replicas

## Custom Metrics (Prometheus)

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: custom-metric-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 20
  metrics:
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"  # Scale at 1000 RPS per pod
```

**Requires**: Prometheus Adapter or similar metrics provider

## External Metrics

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: external-metric-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 50
  metrics:
  - type: External
    external:
      metric:
        name: queue_length
        selector:
          matchLabels:
            queue_name: "tasks"
      target:
        type: Value
        value: "100"  # Scale when queue has 100+ items
```

## Scaling Behavior

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: behavior-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0  # Scale up immediately
      policies:
      - type: Percent
        value: 100  # Double replicas
        periodSeconds: 15
      - type: Pods
        value: 4  # Or add 4 pods
        periodSeconds: 15
      selectPolicy: Max  # Use whichever adds more pods
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 minutes before scaling down
      policies:
      - type: Percent
        value: 50  # Reduce by 50%
        periodSeconds: 60
      - type: Pods
        value: 2  # Or remove 2 pods
        periodSeconds: 60
      selectPolicy: Min  # Use whichever removes fewer pods
```

**Effect**:
- Scale up quickly (0s stabilization)
- Scale down slowly (5min stabilization)
- Prevents flapping

## HPA with PodDisruptionBudget

```yaml
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 3
  maxReplicas: 20

---
# Use percentage for dynamic scaling
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 75%  # Adapts as HPA scales
  selector:
    matchLabels:
      app: myapp
```

## Scaling Strategies

### Aggressive Scaling (Traffic Spikes)

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 0
    policies:
    - type: Percent
      value: 100  # Double pods
      periodSeconds: 15
  scaleDown:
    stabilizationWindowSeconds: 300  # Wait 5 min
```

**Use for**: E-commerce, event-driven workloads

### Conservative Scaling (Stable Workloads)

```yaml
behavior:
  scaleUp:
    stabilizationWindowSeconds: 60  # Wait 1 min
    policies:
    - type: Pods
      value: 2  # Add 2 pods at a time
      periodSeconds: 60
  scaleDown:
    stabilizationWindowSeconds: 600  # Wait 10 min
    policies:
    - type: Pods
      value: 1  # Remove 1 pod at a time
      periodSeconds: 180
```

**Use for**: Databases, stateful apps

## Monitoring HPA

```bash
# View HPA status
kubectl get hpa -n production

# NAME        REFERENCE          TARGETS   MINPODS   MAXPODS   REPLICAS
# myapp-hpa   Deployment/myapp   45%/70%   2         10        3

# Describe HPA
kubectl describe hpa myapp-hpa -n production

# Watch HPA in real-time
kubectl get hpa myapp-hpa -w

# View HPA events
kubectl get events --field-selector involvedObject.name=myapp-hpa
```

## Requirements

### Metrics Server

```bash
# Check if metrics-server is running
kubectl get deployment metrics-server -n kube-system

# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify
kubectl top nodes
kubectl top pods -n production
```

### Resource Requests

```yaml
# FAIL: HPA won't work without resource requests
containers:
- name: app
  image: myapp:1.0.0
  # Missing resources!

# PASS: HPA requires requests
containers:
- name: app
  image: myapp:1.0.0
  resources:
    requests:
      cpu: "100m"
      memory: "128Mi"
    limits:
      cpu: "500m"
      memory: "256Mi"
```

## Common Patterns

### API Server

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "500"
```

### Worker Queue

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: worker
  minReplicas: 2
  maxReplicas: 100
  metrics:
  - type: External
    external:
      metric:
        name: queue_depth
      target:
        type: AverageValue
        averageValue: "10"  # 10 messages per worker
```

## Troubleshooting

### HPA Not Scaling

```bash
# Check HPA status
kubectl describe hpa myapp-hpa

# Common issues:
# 1. Missing metrics-server
kubectl get deployment metrics-server -n kube-system

# 2. No resource requests
kubectl get deployment myapp -o yaml | grep -A 5 "resources:"

# 3. Invalid metrics
kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/production/pods

# 4. Check HPA events
kubectl get events --field-selector involvedObject.name=myapp-hpa
```

### Metrics Unavailable

```
unable to get metrics for resource cpu: no metrics returned from resource metrics API
```

**Fix**: Install/check metrics-server

### HPA Flapping

```
Deployment scaled up/down repeatedly
```

**Fix**: Increase `stabilizationWindowSeconds` or adjust thresholds

## Best Practices

1. **Set appropriate min/max**: Don't set minReplicas too low
2. **Use stabilization windows**: Prevent flapping
3. **Monitor metrics**: Ensure metrics are accurate
4. **Test scaling**: Verify behavior under load
5. **Combine with PDB**: Use percentage-based PDB
6. **Set resource requests**: Required for CPU/memory metrics
7. **Use conservative scale-down**: Prevent disruptions

## Vertical Pod Autoscaler (VPA)

Adjusts resource requests/limits:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
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

**Note**: Don't use VPA and HPA on CPU/memory together

## Cluster Autoscaler

Scales nodes based on pod resource requests:

```yaml
# Not a K8s resource, configured per cloud provider
# Automatically adds/removes nodes when:
# - Pods can't be scheduled (adds nodes)
# - Nodes are underutilized (removes nodes)
```

**Works with**: HPA (scales pods) + CA (scales nodes)

## HPA Checklist

- [ ] metrics-server installed
- [ ] Resource requests defined
- [ ] minReplicas ≥ 2 for production
- [ ] maxReplicas set to reasonable limit
- [ ] Stabilization windows configured
- [ ] PDB compatible (use percentages)
- [ ] Tested under load
- [ ] Monitored in production

## Quick Reference

| Metric Type | Use Case | Example |
|-------------|----------|---------|
| CPU | General autoscaling | 70% utilization |
| Memory | Memory-intensive apps | 80% utilization |
| Custom (RPS) | Traffic-based scaling | 1000 requests/pod |
| External (Queue) | Worker pools | 10 messages/worker |

## kubectl Commands

```bash
# Create HPA (simple)
kubectl autoscale deployment myapp \
  --cpu-percent=70 \
  --min=2 \
  --max=10

# Get HPA
kubectl get hpa

# Describe HPA
kubectl describe hpa myapp-hpa

# Delete HPA
kubectl delete hpa myapp-hpa

# Watch HPA
kubectl get hpa -w
```
