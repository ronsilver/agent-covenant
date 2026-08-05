---
name: kubernetes-expert
description: "Deploy secure, production-ready Kubernetes workloads with proper security contexts, resource limits, probes, and network policies. Use when creating Kubernetes manifests, configuring Deployments/StatefulSets/Services, setting up RBAC, or tuning resource limits. Trigger: Kubernetes Deployment, StatefulSet, Service, Ingress, ConfigMap, RBAC, HPA, kubeconform, kube-linter. Do NOT trigger for: Helm chart creation, Dockerfile optimization, Terraform infrastructure provisioning."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---

# Kubernetes Expert

**Deploy secure, production-ready K8s workloads with proper security contexts, resources, and probes.**

**See [references/overview.md](references/overview.md)**

## Validation
`kubeconform -strict` | `kube-linter lint` | `kubectl apply --dry-run=server`
→ [references/validation.md](references/validation.md)

## Security (NON-NEGOTIABLE)
- Forbidden: `privileged` | `runAsUser: 0` | `hostNetwork`
- Required: `runAsNonRoot` | drop ALL capabilities | Pod Security Standard: `restricted`

→ [references/security.md](references/security.md)

## Resources (MANDATORY)
Define requests/limits on all containers. Rule: memory limit = 2x request.
→ [references/resources.md](references/resources.md)

## Probes (MANDATORY)
Liveness + Readiness + Startup → [references/probes.md](references/probes.md)

## Components
[labels](references/labels.md) | [networking](references/networking.md)(Services/NetworkPolicies/Ingress) | [rbac](references/rbac.md)(ServiceAccounts/Roles) | [availability](references/availability.md)(PDB/anti-affinity) | [autoscaling](references/autoscaling.md)(HPA) | [config-secrets](references/config-secrets.md)

## Checklist
SecurityContext | Resources | Probes | Labels | NetworkPolicy | PDB | HPA | Secrets | Validation
→ [references/checklist.md](references/checklist.md)

## Constraints
- NEVER `privileged` | `runAsUser: 0` | `hostNetwork` | secrets in manifests
- ALWAYS define resources+probes | ALWAYS validate with `kubeconform`+`kube-linter`

## Overview

Production-grade Kubernetes deployments require mandatory security contexts (non-root, dropped capabilities), resource limits, health probes, and validation pipelines. Every workload must pass `kubeconform` and `kube-linter` before deployment.

## Quick Reference

| Component | Mandatory Requirement | Example |
|-----------|----------------------|--------|
| SecurityContext | `runAsNonRoot: true`, drop ALL capabilities | `securityContext: { runAsNonRoot: true, capabilities: { drop: ["ALL"] } }` |
| Resources | Requests + limits on all containers | `requests.cpu: 100m`, `limits.memory: 256Mi` |
| Probes | Liveness + Readiness + Startup | `httpGet: { path: /health, port: 8080 }` |
| NetworkPolicy | Restrict pod-to-pod traffic | `podSelector: {}`, `policyTypes: [Ingress]` |
| PDB | Minimum available pods | `minAvailable: 2` |
| HPA | Auto-scale based on CPU/memory | `targetCPUUtilizationPercentage: 70` |
| PodAntiAffinity | Spread across nodes | `preferredDuringSchedulingIgnoredDuringExecution` |

## Workflow

1. Create Deployment with non-root security context, resource requests/limits, and all three probes (startup, liveness, readiness)
2. Define Service, NetworkPolicy, and Ingress for networking with least-privilege access
3. Set up PDB (minAvailable) and HPA (target CPU 70%) for availability and scaling
4. Add ConfigMaps and Secrets (never inline secrets) with proper volume mounts
5. Validate: `kubeconform -strict` → `kube-linter lint` → `kubectl apply --dry-run=server`
6. Deploy via ArgoCD or CI/CD with rollout monitoring

## Anti-patterns

FAIL: Running containers as root
```yaml
# BAD
securityContext:
  runAsUser: 0
```
PASS: Run as non-root user
```yaml
# GOOD
securityContext:
  runAsNonRoot: true
  runAsUser: 1001
  runAsGroup: 1001
  capabilities:
    drop: ["ALL"]
  readOnlyRootFilesystem: true
```

FAIL: Missing resource limits
```yaml
# BAD — container can consume all node resources
resources: {}
```
PASS: Always set requests and limits
```yaml
# GOOD
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

FAIL: Using hostNetwork without justification
```yaml
# BAD
spec:
  hostNetwork: true
```
PASS: Use proper Service networking
```yaml
# GOOD — never use hostNetwork
apiVersion: v1
kind: Service
spec:
  type: ClusterIP
  ports:
    - port: 8080
```

FAIL: Privileged container
```yaml
# BAD
securityContext:
  privileged: true
```
PASS: Drop all capabilities
```yaml
# GOOD
securityContext:
  capabilities:
    drop: ["ALL"]
  allowPrivilegeEscalation: false
```

## References

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/pod-security-standards/) · last_verified: 2026-05-25
- [kube-linter Documentation](https://docs.kube-linter.io/) · last_verified: 2026-05-25
- [Kubernetes Production Best Practices Checklist](https://learnk8s.io/production-best-practices) · last_verified: 2026-05-25

## Verification Checklist

- [ ] SecurityContext configured: `runAsNonRoot: true`, `capabilities.drop: ["ALL"]`
- [ ] Resource requests and limits defined on every container
- [ ] Liveness, readiness, and startup probes configured for all deployments
- [ ] NetworkPolicy restricts pod-to-pod traffic to minimum required
- [ ] PodDisruptionBudget (PDB) set with `minAvailable` or `maxUnavailable`
- [ ] HPA configured with target CPU utilization (or custom metric)
- [ ] Manifests pass `kubeconform -strict` and `kube-linter lint`

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Pod stuck in `CrashLoopBackOff` | Startup probe failing or resource limits too low | Check probe endpoint and timing; increase `initialDelaySeconds` or resource limits |
| ImagePullBackOff | Wrong image tag or registry credentials missing | Verify image name and tag in deployment; check imagePullSecrets |
| Pod evicted due to disk pressure | Node disk space exhausted | Review logging configuration; add log rotation; increase node disk size |
| Known issue: HPA fails to scale when using custom metrics | Metrics adapter not deployed or custom metric name mismatch | Verify metrics-server or Prometheus adapter is running; check metric name in HPA matches exported metric exactly |

| [WARN] HPA scales down too aggressively after traffic spike | Default `scaleDown` stabilization window (5 min) too short for sporadic workloads | Set `behavior.scaleDown.stabilizationWindowSeconds: 300`; add `pods` metric with longer window |
| Pod anti-affinity with topologyKey hostname prevents scheduling when node count < replica count | preferredDuringScheduling blocks all pods on same node due to soft constraint conflict | Use requiredDuringScheduling only for must-have; soften with preferred + weight: 50 for flexibility |
| Gotcha: kubectl apply --server-side conflicts with client-side ownerReferences | Server-side apply uses field management; ownerReferences set by controller cause manageFields conflict | Use --server-side=true or disable ownership in controller; check managedFields before apply |
