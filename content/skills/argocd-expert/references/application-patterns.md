# ArgoCD Application Patterns

## App of Apps
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
spec:
  source:
    repoURL: https://github.com/org/infra
    path: apps/
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated: { prune: true, selfHeal: true }
```

## ApplicationSets
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
spec:
  generators:
    - git:
        repoURL: https://github.com/org/infra
        revision: main
        files: [{ path: "customers/*.yaml" }]
  template:
    spec:
      source: { path: "{{path.basename}}" }
      destination: { namespace: "example-{{name}}" }
```

## Sync Waves
```yaml
annotations:
  argocd.argoproj.io/sync-wave: "1"   # lower = deploy first
```

## Resource Hooks
```yaml
annotations:
  argocd.argoproj.io/hook: PreSync     # before sync
  argocd.argoproj.io/hook: PostSync    # after sync
  argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
```
