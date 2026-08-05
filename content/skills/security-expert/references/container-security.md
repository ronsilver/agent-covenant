# Container Security

## Image Hardening
```dockerfile
# Distroless base (no shell, no package manager)
FROM gcr.io/distroless/static-debian12

# Non-root user
USER 1000:1000

# Read-only filesystem
# In K8s: securityContext.readOnlyRootFilesystem: true

# No latest tag — pin exact digest
FROM golang:1.23-alpine@sha256:abc123...
```

## Scanning Pipeline
```bash
# SAST in Dockerfile
hadolint Dockerfile

# Image vulnerability scan
trivy image orders:latest

# SBOM generation
syft orders:latest -o spdx-json > sbom.json

# Sign image
cosign sign --key cosign.key orders:latest
```

## Kubernetes Security Context
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

## Runtime Protection
- Falco: detect anomalous syscalls (shell spawn, unexpected network)
- OPA/Gatekeeper: enforce pod security policies
- ImagePolicyWebhook: block unsigned/tampered images
- NetworkPolicy: deny all, allow specific ingress/egress

## Supply Chain (SLSA)
| Level | Requirements |
|---|---|
| SLSA 1 | Build scripted, provenance generated |
| SLSA 2 | Version control + hosted build service |
| SLSA 3 | Non-falsifiable provenance, isolated builds |
| SLSA 4 | Hermetic, reproducible, two-person review |

ALWAYS generate SBOM for every release.
