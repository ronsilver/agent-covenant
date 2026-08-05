# High Availability with PodDisruptionBudget

## What is PodDisruptionBudget?

PodDisruptionBudget (PDB) ensures minimum availability during voluntary disruptions:
- Node drains (upgrades, scaling down)
- Pod evictions
- Cluster maintenance

**Does NOT protect against**:
- Hardware failures
- Node crashes
- Application bugs

## Basic Example

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp
```

**Effect**: At least 2 pods with label `app: myapp` must remain available during disruptions.

## minAvailable vs maxUnavailable

### minAvailable (Absolute or Percentage)

```yaml
# At least 2 pods must be available
spec:
  minAvailable: 2

# At least 75% of pods must be available
spec:
  minAvailable: 75%
```

### maxUnavailable (Absolute or Percentage)

```yaml
# At most 1 pod can be unavailable
spec:
  maxUnavailable: 1

# At most 25% of pods can be unavailable
spec:
  maxUnavailable: 25%
```

## Choosing the Right Value

| Replicas | minAvailable | maxUnavailable | Use Case |
|----------|--------------|----------------|----------|
| 3 | 2 | 1 | Standard (allows 1 down) |
| 5 | 3 | 2 | Allow 2 simultaneous disruptions |
| 10 | 8 | 2 | Large deployment (20% buffer) |

### Percentage-Based

```yaml
# For variable replica counts (HPA)
spec:
  minAvailable: 75%
  # If 10 replicas: min 8 available (max 2 disrupted)
  # If 4 replicas: min 3 available (max 1 disrupted)
```

## Complete Example

```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:1.0.0

---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
  namespace: production
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

## Multiple PDBs (Advanced)

### By Component

```yaml
---
# Frontend PDB
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: frontend-pdb
spec:
  minAvailable: 3
  selector:
    matchLabels:
      tier: frontend

---
# API PDB
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: api-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      tier: api
```

### Overlapping Selectors

```yaml
# [WARN] Multiple PDBs can select the same pods
# The most restrictive constraint applies

# PDB 1: minAvailable 2
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: myapp

# PDB 2: minAvailable 3 (more restrictive)
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: myapp
      env: production
```

## Common Patterns

### Web Application

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2  # Always 2+ pods serving traffic
  selector:
    matchLabels:
      app: web
```

### Database (StatefulSet)

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: database-pdb
spec:
  maxUnavailable: 0  # Never disrupt database pods voluntarily
  selector:
    matchLabels:
      app: postgres
```

### Worker Pool

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: worker-pdb
spec:
  minAvailable: 50%  # Allow disruption of half the workers
  selector:
    matchLabels:
      app: worker
```

## With Horizontal Pod Autoscaler

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
  maxReplicas: 10

---
# Use percentage for dynamic scaling
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 75%  # Adapts to HPA scaling
  selector:
    matchLabels:
      app: myapp
```

## Node Drains

When draining a node:

```bash
# Drain node (respects PDB)
kubectl drain node-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=5m

# If PDB blocks drain:
# "error when evicting pod: Cannot evict pod as it would violate the pod's disruption budget"
```

**Behavior**:
- Drain waits for pods to terminate gracefully
- Respects `terminationGracePeriodSeconds`
- Won't evict if PDB constraint violated
- Can timeout if PDB too restrictive

## PDB and Cluster Autoscaler

```yaml
# Allow scale-down but maintain availability
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  maxUnavailable: 1  # Cluster autoscaler can drain 1 pod at a time
  selector:
    matchLabels:
      app: myapp
```

## Troubleshooting

### Check PDB Status

```bash
# List PDBs
kubectl get pdb -n production

# Describe PDB
kubectl describe pdb myapp-pdb -n production

# Look for:
# Allowed Disruptions: 1
# Current: 3
# Desired: 2
```

### PDB Blocking Drain

```bash
# If drain stuck:
kubectl describe pdb -n production

# Options:
# 1. Wait for PDB to allow disruption
# 2. Temporarily delete PDB (not recommended)
# 3. Scale up replicas
# 4. Adjust PDB minAvailable
```

### Pod Eviction Blocked

```yaml
# Event in pod:
# Warning  EvictionBlocked  Cannot evict pod as it would violate the pod's disruption budget
```

**Solutions**:
1. Wait for other pods to become ready
2. Scale up deployment
3. Review PDB constraints
4. Check if pods are actually ready

## Common Mistakes

### FAIL: Too Restrictive

```yaml
# FAIL: Blocks all disruptions
spec:
  minAvailable: 3
  # But only 3 replicas total!
```

**Fix**: Ensure `minAvailable` < total replicas

### FAIL: Wrong Selector

```yaml
# FAIL: Selector doesn't match any pods
spec:
  selector:
    matchLabels:
      app: wrong-label  # No pods have this label
```

**Fix**: Verify labels with `kubectl get pods --show-labels`

### FAIL: No PDB for Critical Apps

```yaml
# FAIL: Production app without PDB
# Any node drain can disrupt all pods simultaneously
```

**Fix**: Always create PDB for production deployments

### FAIL: Conflicting with Single Replica

```yaml
# FAIL: minAvailable 1 with replicas: 1
# Blocks all voluntary disruptions
spec:
  replicas: 1
---
spec:
  minAvailable: 1
```

**Fix**: Scale to at least 2 replicas or use `maxUnavailable: 0`

## Best Practices

1. **Always use PDB for production** - Prevents accidental disruptions
2. **minAvailable < replicas** - Leave room for disruptions
3. **Use percentages with HPA** - Adapts to scaling
4. **Consider StatefulSets** - May need `maxUnavailable: 0`
5. **Test node drains** - Verify PDB works as expected
6. **Monitor disruptions** - Track eviction events
7. **Set realistic values** - Balance availability vs maintenance

## PDB with StatefulSets

```yaml
# Database with ordered shutdown
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: postgres-pdb
spec:
  maxUnavailable: 0  # No voluntary disruptions
  selector:
    matchLabels:
      app: postgres

# Or allow disruptions but keep quorum
spec:
  minAvailable: 2  # For 3-node cluster (quorum = 2)
  selector:
    matchLabels:
      app: postgres
```

## Monitoring

```bash
# Watch PDB during drain
kubectl get pdb -w

# Check allowed disruptions
kubectl get pdb myapp-pdb -o jsonpath='{.status.disruptionsAllowed}'

# Check current/desired pods
kubectl get pdb myapp-pdb -o jsonpath='{.status.currentHealthy}/{.status.desiredHealthy}'
```

## PDB in Multi-Zone Deployments

```yaml
# Ensure availability across zones
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: myapp

---
# Allow disruption but maintain per-zone availability
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: myapp-pdb
spec:
  minAvailable: 4  # Allow 2 disruptions across zones
  selector:
    matchLabels:
      app: myapp
```

## PDB Checklist

- [ ] PDB created for all production deployments
- [ ] `minAvailable` < `replicas` (or use `maxUnavailable`)
- [ ] Selector matches pod labels
- [ ] Tested with node drain
- [ ] Compatible with HPA (use percentages)
- [ ] Documented why specific values chosen
- [ ] Monitored during cluster maintenance
- [ ] Reviewed periodically as app scales

## Quick Reference

| Scenario | Replicas | Recommended PDB |
|----------|----------|-----------------|
| Critical API | 3 | `minAvailable: 2` |
| Scalable Web | 5-20 (HPA) | `minAvailable: 75%` |
| Worker Pool | 10 | `maxUnavailable: 3` |
| Database | 3 | `minAvailable: 2` (quorum) |
| Single Replica | 1 | `maxUnavailable: 0` (blocks drains) |
