# Kubernetes Expert Overview

## Skill Purpose

Deploy secure, production-ready Kubernetes workloads with proper security contexts, resource limits, health probes, and network policies.

## Core Principles

1. **Least privilege**: pods run as non-root, with read-only root filesystem and dropped capabilities
2. **Resource guardrails**: every container has CPU/memory requests and limits
3. **Health-first**: liveness + readiness probes on every container
4. **Network isolation**: default deny all, explicit allow with NetworkPolicy
5. **No latest tags**: always pin image versions for reproducibility

## Manifest Checklist

Every Deployment must have:

```yaml
# Security
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]

# Resources
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi

# Health
livenessProbe:
  httpGet: { path: /health, port: 8080 }
  initialDelaySeconds: 10
  periodSeconds: 10
readinessProbe:
  httpGet: { path: /health, port: 8080 }
  initialDelaySeconds: 5
  periodSeconds: 5

# Disruption
podDisruptionBudget: minAvailable: 1
```

## Reference Navigation

| Topic | File | When to Use |
|-------|------|-------------|
| Pre-deploy checklist | `checklist.md` | Before any deployment |
| SKILL.md | Security contexts, probes, NetworkPolicy | Writing manifests |

## Namespace Strategy

```
production/
  api-service
  customer-service
  auth-service

staging/
  api-service
  ...

monitoring/
  prometheus
  grafana

ingress-nginx/
  ingress-controller
```

Each namespace gets its own RBAC roles and NetworkPolicy default-deny.
