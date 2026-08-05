# Kubernetes Manifest Validation

## Validation Tools

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **kubeconform** | Schema validation | Every manifest change |
| **kube-linter** | Policy & best practices | Pre-commit |
| **kubectl --dry-run** | Cluster-side validation | Before apply |
| **kubeval** | Schema validation (deprecated, use kubeconform) | Legacy |

## kubeconform

### Installation

```bash
# macOS
brew install kubeconform

# Linux
wget https://github.com/yannh/kubeconform/releases/download/v0.6.4/kubeconform-linux-amd64.tar.gz
tar xf kubeconform-linux-amd64.tar.gz
sudo mv kubeconform /usr/local/bin/
```

### Usage

```bash
# Validate single file
kubeconform deployment.yaml

# Validate directory
kubeconform -strict manifests/

# Validate with specific Kubernetes version
kubeconform -kubernetes-version 1.28.0 manifests/

# Summary mode
kubeconform -summary manifests/

# Output formats
kubeconform -output json manifests/
kubeconform -output junit manifests/ > results.xml
```

### Options

```bash
kubeconform \
  -strict \                          # Reject additional properties
  -ignore-missing-schemas \          # Don't fail on missing CRD schemas
  -schema-location default \         # Use default schema location
  -kubernetes-version 1.28.0 \       # K8s version to validate against
  -verbose \                         # Verbose output
  manifests/
```

## kube-linter

### Installation

```bash
# macOS
brew install kube-linter

# Linux
wget https://github.com/stackrox/kube-linter/releases/download/v0.6.8/kube-linter-linux.tar.gz
tar xf kube-linter-linux.tar.gz
sudo mv kube-linter /usr/local/bin/
```

### Usage

```bash
# Lint directory
kube-linter lint manifests/

# Lint with config
kube-linter lint --config .kube-linter.yaml manifests/

# Output formats
kube-linter lint --format json manifests/
kube-linter lint --format sarif manifests/
```

### Configuration (.kube-linter.yaml)

```yaml
checks:
  addAllBuiltIn: true
  exclude:
    - "no-read-only-root-fs"  # If your app needs writable root
    - "unset-cpu-requirements"  # If you deliberately don't set CPU

customChecks: []

# Ignore specific resources
ignoreFilesPatterns:
  - "test/**/*.yaml"
  - "**/*-test.yaml"
```

### Common Checks

| Check | Description |
|-------|-------------|
| `no-read-only-root-fs` | Container must have readOnlyRootFilesystem |
| `run-as-non-root` | Must not run as root |
| `no-privilege-escalation` | allowPrivilegeEscalation must be false |
| `required-label-owner` | Must have owner label |
| `required-annotation-email` | Must have email annotation |
| `cpu-requirements` | CPU requests/limits required |
| `memory-requirements` | Memory requests/limits required |
| `liveness-probe` | Liveness probe required |
| `readiness-probe` | Readiness probe required |

### Inline Suppression

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  annotations:
    ignore-check.kube-linter.io/no-read-only-root-fs: "App needs writable /tmp"
```

## kubectl Dry Run

### Server-Side Dry Run

```bash
# Validate against cluster (recommended)
kubectl apply --dry-run=server -f deployment.yaml

# Validate directory
kubectl apply --dry-run=server -f manifests/

# Show diff
kubectl diff -f deployment.yaml
```

### Client-Side Dry Run

```bash
# Basic validation (doesn't hit API server)
kubectl apply --dry-run=client -f deployment.yaml

# Generate YAML
kubectl create deployment nginx --image=nginx --dry-run=client -o yaml
```

## Validation Pipeline

### Pre-commit Hook

```yaml
# .pre-commit-config.yaml
repos:
  - repo: local
    hooks:
      - id: kubeconform
        name: Validate K8s manifests
        entry: kubeconform
        args: ['-strict', 'k8s/']
        language: system
        files: \.yaml$
        pass_filenames: false
        
      - id: kube-linter
        name: Lint K8s manifests
        entry: kube-linter
        args: ['lint', 'k8s/']
        language: system
        files: \.yaml$
        pass_filenames: false
```

### CI/CD Pipeline

```yaml
# GitHub Actions
name: Validate Manifests

on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup kubeconform
        run: |
          wget https://github.com/yannh/kubeconform/releases/download/v0.6.4/kubeconform-linux-amd64.tar.gz
          tar xf kubeconform-linux-amd64.tar.gz
          sudo mv kubeconform /usr/local/bin/
      
      - name: Validate schemas
        run: kubeconform -strict -summary k8s/
      
      - name: Setup kube-linter
        run: |
          wget https://github.com/stackrox/kube-linter/releases/download/v0.6.8/kube-linter-linux.tar.gz
          tar xf kube-linter-linux.tar.gz
          sudo mv kube-linter /usr/local/bin/
      
      - name: Lint manifests
        run: kube-linter lint k8s/
```

## Custom Resource Definitions (CRDs)

### Validate CRDs

```bash
# Add CRD schemas
kubeconform \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/{{.Group}}/{{.ResourceKind}}/{{.ResourceAPIVersion}}/{{.Kind}}.json' \
  manifests/
```

### Local CRD Schemas

```bash
# Extract CRD schemas from cluster
kubectl get crds -o json | \
  jq -r '.items[] | .spec.versions[] | .schema.openAPIV3Schema' \
  > crd-schemas.json

# Validate with local schemas
kubeconform -schema-location 'file://crd-schemas.json' manifests/
```

## Helm Chart Validation

### Render and Validate

```bash
# Render Helm chart
helm template my-release ./my-chart > rendered.yaml

# Validate rendered manifests
kubeconform -strict rendered.yaml
kube-linter lint rendered.yaml

# Or combined
helm template my-release ./my-chart | kubeconform -strict -
```

### Helm Lint

```bash
# Lint Helm chart
helm lint ./my-chart

# With values
helm lint ./my-chart -f values-prod.yaml
```

## Kustomize Validation

```bash
# Build and validate
kustomize build overlays/production | kubeconform -strict -

# With kube-linter
kustomize build overlays/production | kube-linter lint -
```

## Policy Enforcement

### OPA/Gatekeeper

```bash
# Install conftest
brew install conftest

# Validate with OPA policies
conftest test -p policy/ k8s/deployment.yaml
```

### Polaris

```bash
# Install
kubectl apply -f https://github.com/FairwindsOps/polaris/releases/latest/download/dashboard.yaml

# CLI
polaris audit --audit-path k8s/
```

## Common Validation Errors

### Invalid API Version

```
Error: deployment.yaml - Deployment.apps/v1beta1 is deprecated, use apps/v1
```

**Fix**: Update apiVersion to `apps/v1`

### Missing Required Field

```
Error: missing required field "spec.selector"
```

**Fix**: Add selector matching labels

### Invalid Resource Limits

```
Error: limits.memory must be greater than or equal to requests.memory
```

**Fix**: Ensure limits ≥ requests

### Label Selector Mismatch

```
Error: selector does not match template labels
```

**Fix**: Ensure `spec.selector.matchLabels` matches `spec.template.metadata.labels`

## Validation Checklist

Before deploying:

- [ ] `kubeconform -strict` passes
- [ ] `kube-linter lint` passes
- [ ] `kubectl apply --dry-run=server` succeeds
- [ ] `kubectl diff` reviewed
- [ ] No deprecated API versions
- [ ] Resource limits defined
- [ ] SecurityContext configured
- [ ] Probes configured
- [ ] Labels follow conventions
- [ ] Secrets not in manifests

## Automated Validation Script

```bash
#!/bin/bash
set -e

echo "Validating Kubernetes manifests..."

# Schema validation
echo "→ kubeconform"
kubeconform -strict -summary manifests/

# Policy validation
echo "→ kube-linter"
kube-linter lint manifests/

# Cluster dry-run
echo "→ kubectl dry-run"
kubectl apply --dry-run=server -f manifests/

echo "PASS: All validations passed"
```

Make executable: `chmod +x validate.sh`
