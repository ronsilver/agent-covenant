# Kubernetes Deployment Checklist

## Pre-Deploy Manifest Review

### Security
- [ ] `runAsNonRoot: true` on all containers
- [ ] `readOnlyRootFilesystem: true` (or writable paths explicitly mounted)
- [ ] `allowPrivilegeEscalation: false`
- [ ] `capabilities.drop: [ALL]` — no capabilities unless justified
- [ ] No `privileged: true`
- [ ] No `hostNetwork`, `hostPID`, or `hostIPC`
- [ ] Image tag is pinned (not `:latest`)
- [ ] Secrets from Kubernetes Secrets or external secrets operator — not env vars with hardcoded values

### Resources
- [ ] `requests.cpu` and `requests.memory` set
- [ ] `limits.cpu` and `limits.memory` set
- [ ] Limits are 2-4x requests (not equal, not 10x)
- [ ] HorizontalPodAutoscaler configured (if variable load)

### Health Checks
- [ ] `livenessProbe` configured with `initialDelaySeconds` ≥ startup time
- [ ] `readinessProbe` configured (different from liveness if startup is slow)
- [ ] `startupProbe` configured for slow-starting containers (> 30s)
- [ ] Probe failure thresholds are reasonable (`failureThreshold: 3`)

### Disruption Budget
- [ ] `PodDisruptionBudget` configured for critical services
- [ ] `minAvailable: 1` or `maxUnavailable: 0` for single-replica critical services

### Network
- [ ] NetworkPolicy exists for the namespace (default deny)
- [ ] Explicit ingress rules for service consumers
- [ ] Explicit egress rules for external dependencies

### RBAC
- [ ] ServiceAccount named (not `default`)
- [ ] ServiceAccount has minimal permissions
- [ ] No cluster-admin binding without explicit justification

## Pre-Deploy Cluster State Check

```bash
# Check cluster capacity
kubectl top nodes

# Verify namespace exists and has resource quotas
kubectl describe namespace <ns>

# Check for existing PDBs
kubectl get pdb -n <ns>

# Validate manifest without applying
kubectl apply --dry-run=server -f deploy/

# Check for deprecated API versions
kubectl api-versions | grep -i <resource>
```

## Post-Deploy Verification

```bash
# Rollout status
kubectl rollout status deployment/<name> -n <ns>

# Pod state
kubectl get pods -n <ns> -l app=<name>

# Recent events (check for warnings)
kubectl get events -n <ns> --sort-by='.lastTimestamp' | tail -20

# Logs (first few seconds)
kubectl logs -n <ns> -l app=<name> --since=2m

# Health endpoint
kubectl port-forward -n <ns> svc/<name> 8080:80 &
curl -f http://localhost:8080/health
```

## Rollback Procedure

```bash
# View rollout history
kubectl rollout history deployment/<name> -n <ns>

# Rollback to previous version
kubectl rollout undo deployment/<name> -n <ns>

# Rollback to specific revision
kubectl rollout undo deployment/<name> -n <ns> --to-revision=3

# Verify rollback succeeded
kubectl rollout status deployment/<name> -n <ns>
```
