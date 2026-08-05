---
name: argocd-expert
description: "GitOps implementation with ArgoCD: declarative synchronization of Kubernetes applications, App-of-Apps pattern, ApplicationSets, Argo Rollouts for canary/blue-green, secret management with Sealed Secrets/External Secrets Operator, and troubleshooting of sync failures and drift. Use when setting up ArgoCD for continuous delivery, designing GitOps repo structure, implementing progressive delivery strategies, managing secrets in GitOps workflows, or debugging out-of-sync applications. Trigger: ArgoCD, GitOps, Argo Rollouts, ApplicationSet. Do NOT trigger for: raw Kubernetes manifest authoring without GitOps context."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: cloud
  status: stable
---
# ArgoCD Expert

**GitOps with ArgoCD: declarative sync, progressive delivery and secrets.**

## Core Stack

- GitOps Engine: ArgoCD (declarative sync, webhook triggers, auto-healing)
- Progressive Delivery: Argo Rollouts (canary, blue-green, analysis templates)
- Secrets: Sealed Secrets + External Secrets Operator + SOPS
- Sync: App-of-Apps pattern, ApplicationSets, sync waves, resource hooks

## App-of-Apps Pattern

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/example-org/infrastructure-helm
    targetRevision: main
    path: apps/
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Each sub-app in `apps/` deploys a specific service. Root app auto-discovers changes.

## Secrets in GitOps

| Tool | Pattern | Use Case |
|---|---|---|
| Sealed Secrets | Encrypt in-cluster, safe in Git | Simple, single-cluster |
| External Secrets Operator | Sync from AWS Secrets Manager/Vault | Multi-cluster, external source-of-truth |
| SOPS | Encrypt with KMS/PGP | Multi-tool, no K8s dependency |

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: api-db
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: ClusterSecretStore
  target:
    name: api-db-secret
  data:
  - secretKey: password
    remoteRef:
      key: prod/api/db
      property: password
```

## Argo Rollouts

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  replicas: 5
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: { duration: 60s }
      - setWeight: 40
      - pause: { duration: 60s }
      - setWeight: 100
  template: { ... }
```

- Analysis templates validate canary before promotion (Prometheus queries, Datadog monitors)
- Automatic rollback on analysis failure

## Sync Waves & Hooks

```yaml
annotations:
  argocd.argoproj.io/sync-wave: "1"    # lower = first
  argocd.argoproj.io/hook: PreSync     # run before sync
  argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
```

Wave ordering: ConfigMaps -> Secrets -> Deployments -> Jobs.

## Troubleshooting

| Issue | Check |
|---|---|
| OutOfSync | Manual changes? `kubectl diff` vs git |
| SyncError | Invalid YAML? Missing CRD? RBAC deny? |
| Degraded | Pod not ready? Health check failing? |
| Unknown | Network timeout to repo? Webhook not firing? |

- `argocd app get <app> --refresh hard` for forced reconciliation
- NEVER manually edit ArgoCD-managed resources (drift)

## Constraints

- NEVER store plaintext secrets in Git — use Sealed Secrets/ESO/SOPS
- NEVER run without `selfHeal: true` in production (drift protection)
- NEVER skip analysis templates for canary deployments
- ALWAYS use sync waves for ordered dependency deployment
- ALWAYS pin image tags (never `:latest`) in ArgoCD sources
- NEVER bypass ArgoCD for production changes (manual `kubectl apply`)

## Overview

GitOps delivery with ArgoCD for team K8s infrastructure. Covers declarative sync, App-of-Apps pattern, progressive delivery via Argo Rollouts, secrets management (Sealed Secrets/ESO/SOPS), and troubleshooting sync failures and drift.

## Anti-patterns

FAIL: **Storing plaintext secrets in Git**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-password
data:
  password: c3VwZXJzZWNyZXQ=  # BAD: base64 != encrypted
```
PASS: Use Sealed Secrets (`kubeseal`) or External Secrets Operator referencing AWS Secrets Manager/Vault.

FAIL: **Bypassing ArgoCD with manual `kubectl apply`**
```bash
kubectl apply -f deployment.yaml  # BAD: creates drift
```
PASS: Push changes to Git repo and let ArgoCD sync. Set `selfHeal: true` for auto-correction.

FAIL: **Skipping analysis templates in canary rollouts**
```yaml
strategy:
  canary:
    steps:
    - setWeight: 100  # BAD: no validation, immediate full traffic
```
PASS: Add analysis template with Prometheus queries to auto-rollback on failure.

FAIL: **Using `:latest` image tag in ArgoCD sources**
```yaml
source:
  targetRevision: :latest  # BAD: unreproducible deployments
```
PASS: Pin to immutable tag (e.g. `v1.2.3` or commit SHA).

## References

| Resource | URL | Last verified |
|---|---|---|
| ArgoCD Documentation | https://argo-cd.readthedocs.io/en/stable/ | 2025-05 |
| Argo Rollouts | https://argoproj.github.io/rollouts/ | 2025-05 |
| External Secrets Operator | https://external-secrets.io/latest/ | 2025-05 |
| Sealed Secrets | https://github.com/bitnami-labs/sealed-secrets | 2025-05 |
| SOPS | https://github.com/getsops/sops | 2025-05 |

- [references/application-patterns.md](references/application-patterns.md)
- [references/progressive-delivery.md](references/progressive-delivery.md)
- [references/troubleshooting.md](references/troubleshooting.md)

## Verification Checklist
- [ ] Secrets stored in Git are encrypted (Sealed Secrets/ESO/SOPS) — no plaintext
- [ ] Argo Rollouts analysis templates configured for canary deployments
- [ ] `selfHeal: true` enabled for production applications
- [ ] Sync waves ordered correctly (ConfigMaps → Secrets → Deployments → Jobs)
- [ ] Image tags pinned to immutable version (never `:latest`)
- [ ] Sync policy configured: prune enabled, auto-sync turned on

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Application stuck in `OutOfSync` state | Manual `kubectl apply` created drift; resource modified outside ArgoCD | Revert manual changes; enable `selfHeal: true`; re-sync via `argocd app sync` |
| `SyncError` after commit | Invalid YAML in manifest; missing CRD; RBAC deny | Run `kubectl apply --dry-run=client` locally; verify CRD installed; check RBAC |
| Rollout paused at canary step and not promoting | Analysis template not passing health checks | Check analysis run logs in Argo Rollouts UI; verify Prometheus query works |
| App shows `Unknown` status | Network timeout reaching Git repo; webhook not firing | Verify repo URL reachable from ArgoCD; check webhook delivery logs |
| Gotcha: sync wave ordering non-deterministic within same wave | Resources in same wave (weight 0, 10, 20) deploy in parallel — no guaranteed order | Use separate waves for sequential dependencies; add `--sync-wave` annotation with different weights for ordered resources |
| Edge case: `argocd app diff` shows no diff but `sync` still fails | Kubernetes CRD schema validation rejects valid manifest; API version mismatch (v1 vs v1beta1) | Verify CRD API version matches manifest; run `kubectl validate` against the cluster's CRD schema |
