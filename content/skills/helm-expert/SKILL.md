---
name: helm-expert
description: "Design and manage Helm charts for Kubernetes application packaging. Use when creating Helm charts, managing chart releases, configuring values overrides, or deploying applications via Helm. Trigger: Helm chart creation, chart debugging, release management, values override, subchart management, Helmfile GitOps, Go template. Do NOT trigger for: raw Kubernetes manifest creation, kubectl commands, general cluster troubleshooting."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---

# Helm Expert Skill

**Create production-ready Helm charts for repeatable K8s deployments.**

**See [references/overview.md](references/overview.md) for complete guide**

## Chart Structure

**See [references/chart-structure.md](references/chart-structure.md)**

- `Chart.yaml`: Metadata
- `values.yaml`: Configuration
- `templates/`: K8s manifests

## Chart.yaml

**See [references/chart-yaml.md](references/chart-yaml.md)**

```yaml
apiVersion: v2
name: app
version: 1.2.3
appVersion: "2.1.0"
```

## values.yaml

**See [references/values.md](references/values.md)**

## Templates

**See [references/templates.md](references/templates.md)**

```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
labels: { { - include "app.labels" . | nindent 4 } }
```

## Commands

**See [references/commands.md](references/commands.md)**

```bash
helm install app ./chart -f values.yaml
helm upgrade --install app ./chart
helm rollback app 0
```

## Dependencies & Repos

**See [references/dependencies.md](references/dependencies.md)
and [references/repositories.md](references/repositories.md)**

```bash
helm dependency update ./chart
helm repo add bitnami https://charts.bitnami.com/bitnami
```

## GitOps

**See [references/gitops.md](references/gitops.md) for ArgoCD and Flux examples**

## Best Practices

**See [references/best-practices.md](references/best-practices.md)**

- Use helpers for labels | add config checksums | set resource limits
- Pin dependency versions | use variables (avoid hardcoded values)

## Overview

Helm is the Kubernetes package manager, enabling repeatable application deployments through templated charts and dependency management. Charts bundle YAML manifests with configurable values for environment-specific customization.

## Quick Reference

| Command | Purpose | Example |
|---------|---------|--------|
| `helm install` | Deploy a chart | `helm install myapp ./chart -f prod.yaml` |
| `helm upgrade --install` | Idempotent install/upgrade | `helm upgrade --install myapp ./chart --set image.tag=v2` |
| `helm rollback` | Revert to previous revision | `helm rollback myapp 1` |
| `helm dependency update` | Resolve chart dependencies | `helm dependency update ./chart` |
| `helm template` | Render locally for debugging | `helm template ./chart --debug` |
| `helm lint` | Validate chart syntax | `helm lint ./chart` |

## Workflow

1. Scaffold chart: `helm create <name>` or build manually with `Chart.yaml`, `values.yaml`, `templates/`
2. Define templates using Go template syntax with helpers in `_helpers.tpl`
3. Set default values in `values.yaml` and environment overrides in separate files
4. Validate with `helm lint` and render locally with `helm template --debug`
5. Install: `helm upgrade --install <release> ./chart -f <env>.yaml`
6. Monitor with `helm list` and `helm status <release>`; rollback with `helm rollback` if needed

## Anti-patterns

FAIL: Hardcoding values in templates instead of using `values.yaml`
```yaml
# BAD
image: myapp:v1.2.3
```
PASS: Parameterize all configurable values
```yaml
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

FAIL: Missing resource limits in chart templates
```yaml
# BAD
resources: {}
```
PASS: Define requests and limits with sensible defaults
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

FAIL: Unpinned dependency versions causing unexpected upgrades
```yaml
# BAD
dependencies:
  - name: postgresql
    version: ">=8.0"
```
PASS: Pin exact versions
```yaml
dependencies:
  - name: postgresql
    version: "8.6.2"
```

FAIL: Using `latest` tag with no `imagePullPolicy`
```yaml
# BAD
image: myapp:latest
```
PASS: Explicit tag with pull policy
```yaml
image: myapp:v1.2.3
imagePullPolicy: IfNotPresent
```

FAIL: Hardcoding image tag directly in template or values without CI injection
```yaml
# BAD: values.yaml — tag is manual, never auto-updated by CI
image:
  repository: myapp
  tag: v1.2.3
```

```yaml
# GOOD: CI injects tag at deploy time via --set
# values.yaml
image:
  repository: myapp
  tag: ""  # CI sets this: --set image.tag=$CI_COMMIT_TAG

# template uses appVersion as fallback
image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}"
```

FAIL: Setting only CPU requests/limits without memory limits
```yaml
# BAD: CPU limits protect CPU, but memory OOM kills the pod
resources:
  requests:
    cpu: 500m
  limits:
    cpu: 1000m
# No memory limit → pod can consume all node memory → node pressure
```

```yaml
# GOOD: memory limits protect the node; CPU limits throttle (not kill)
resources:
  requests:
    cpu: 500m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 512Mi
# Node stability over max throughput
```

## References

- [Helm official docs — Chart Template Guide](https://helm.sh/docs/chart_template_guide/) · last_verified: 2026-05-25
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/) · last_verified: 2026-05-25
- [Artifact Hub — Discover Helm Charts](https://artifacthub.io/) · last_verified: 2026-05-25

## Verification Checklist

- [ ] Chart passes `helm lint` without errors or warnings
- [ ] All configurable values parameterized in `values.yaml` (no hardcoded strings in templates)
- [ ] Resource requests and limits defined with sensible defaults
- [ ] Liveness, readiness, and startup probes configured
- [ ] Dependency versions pinned to exact semver (no range like `>=8.0`)
- [ ] `helm template --debug` renders manifests as expected for all environments

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Error: release already exists` | Previous install failed or not cleaned up | Run `helm uninstall <release>` before retrying `helm install` |
| Template renders empty values | Wrong indentation in values.yaml or missing `.Values` prefix | Check template syntax with `helm template --debug` |
| `Error: failed to download` dependency | Repository not added or wrong URL | Run `helm repo add` with correct URL before `helm dependency update` |
| Limitation: `helm template` output differs from actual deployed resources | Template conditions evaluate differently with `--set` vs `values.yaml` defaults | Use `helm install --dry-run=server` to validate against actual cluster state, not just local template rendering |
| `helm template` fails with `lookup function error` on fresh cluster | `lookup` function queries the cluster for existing resources; on first install no prior release exists, causing nil pointer | NEVER use `lookup` for resources managed by the same chart; gate `lookup` calls behind `{{ if .Release.IsInstall }}` check or use `.Capabilities.APIVersions.Has` instead |
| CRD resources deleted on `helm uninstall` even though CRDs are still in use by other charts | Default Helm behavior deletes all resources including CRDs; `helm.sh/resource-policy: keep` annotation not set | Add `helm.sh/resource-policy: keep` to CRD manifests; manage CRDs via a separate "crds" chart or Helm CRD install hook (`"helm.sh/hook": crd-install`) to prevent cascading deletion |

| [WARN] `helm template` renders different output with `.Values` vs `--set` | YAML type coercion differs between YAML parsing (in values.yaml) and CLI string parsing | Always use `--set-string` for string values; validate with `helm template --debug` and `helm lint` |
