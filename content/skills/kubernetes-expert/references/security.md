# Kubernetes Security

## Security Principles

1. **Least Privilege**: Only grant minimum necessary permissions
2. **Defense in Depth**: Multiple security layers
3. **Non-Root**: Never run as root (UID 0)
4. **Read-Only Filesystem**: Prevent tampering
5. **Drop All Capabilities**: Remove unnecessary Linux capabilities

## Strictly Forbidden Settings

| Setting | Risk | Never Use Because |
|---------|------|-------------------|
| `privileged: true` | CRITICAL | Full host access, bypasses all security |
| `runAsUser: 0` | CRITICAL | Running as root |
| `allowPrivilegeEscalation: true` | HIGH | Can gain root privileges |
| `hostNetwork: true` | HIGH | Bypasses NetworkPolicies, sees all network traffic |
| `hostPID: true` | HIGH | Can see/kill all host processes |
| `hostIPC: true` | MEDIUM | Can access host IPC resources |
| `hostPath` volumes | HIGH | Direct host filesystem access |

## Required SecurityContext

### Pod-Level

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true        # Kubernetes will reject if container tries to run as root
        runAsUser: 10001          # Non-root UID
        runAsGroup: 10001         # Non-root GID
        fsGroup: 10001            # Group ownership for mounted volumes
        seccompProfile:
          type: RuntimeDefault    # Use default seccomp profile
```

### Container-Level

```yaml
containers:
- name: app
  securityContext:
    allowPrivilegeEscalation: false  # Cannot gain more privileges
    readOnlyRootFilesystem: true     # Immutable root filesystem
    runAsNonRoot: true               # Must run as non-root
    capabilities:
      drop:
        - ALL                         # Drop all Linux capabilities
      add: []                         # Don't add any back (unless absolutely necessary)
```

### Complete Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: secure-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: secure-app
  template:
    metadata:
      labels:
        app: secure-app
    spec:
      # Pod-level security
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        runAsGroup: 10001
        fsGroup: 10001
        seccompProfile:
          type: RuntimeDefault
      
      # Service account
      serviceAccountName: secure-app
      automountServiceAccountToken: false
      
      containers:
      - name: app
        image: myapp:1.0.0
        
        # Container-level security
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop: ["ALL"]
        
        # Writable tmp (since root is read-only)
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

## Pod Security Standards

Kubernetes defines three policy levels:

| Level | Description | Use Case |
|-------|-------------|----------|
| **privileged** | Unrestricted | FAIL: Avoid in production |
| **baseline** | Minimal restrictions | Development/testing |
| **restricted** | Hardened (best practices) | PASS: Production |

### Enforce at Namespace Level

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    # Enforce restricted policy
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    
    # Audit violations
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: latest
    
    # Warn on violations
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: latest
```

### Check Compliance

```bash
# Check if pod meets restricted standard
kubectl label --dry-run=server --overwrite ns production \
  pod-security.kubernetes.io/enforce=restricted
```

## Linux Capabilities

### Common Capabilities (Usually Not Needed)

```yaml
# FAIL: Don't add capabilities unless absolutely necessary
capabilities:
  add:
    - NET_ADMIN      # Network administration (iptables, routing)
    - SYS_ADMIN      # Almost everything (basically root)
    - SYS_TIME       # Set system time
    - SYS_MODULE     # Load kernel modules
    - DAC_OVERRIDE   # Bypass file permissions
```

### When You Might Need Capabilities

```yaml
# Example: ping requires NET_RAW
containers:
- name: network-tool
  securityContext:
    capabilities:
      drop: ["ALL"]
      add: ["NET_RAW"]  # For ping/traceroute
```

**Rule**: Only add specific capabilities you need, never use `SYS_ADMIN`.

## AppArmor

```yaml
# Ubuntu/Debian systems
metadata:
  annotations:
    container.apparmor.security.beta.kubernetes.io/app: runtime/default
```

## SELinux

```yaml
spec:
  securityContext:
    seLinuxOptions:
      level: "s0:c123,c456"
```

## Image Security

### Use Specific Tags

```yaml
# FAIL: Bad - mutable
image: myapp:latest

# PASS: Good - immutable digest
image: myapp@sha256:abc123...

# PASS: Good - specific version
image: myapp:v1.2.3
```

### Image Pull Policies

```yaml
containers:
- name: app
  image: myapp:v1.2.3
  imagePullPolicy: Always  # Always pull (slower but safer)
  # imagePullPolicy: IfNotPresent  # Use cached if available
```

### Private Registries

```yaml
spec:
  imagePullSecrets:
  - name: docker-registry-secret
```

```bash
# Create registry secret
kubectl create secret docker-registry docker-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=password \
  --docker-email=user@example.com
```

## Runtime Security

### Falco (Runtime Threat Detection)

```bash
# Install Falco
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco

# Custom rules
- rule: Unexpected Container Privilege Escalation
  desc: Detect privilege escalation attempts
  condition: spawned_process and container and proc.name in (sudo, su)
  output: Privilege escalation attempt (user=%user.name command=%proc.cmdline)
  priority: WARNING
```

## Secrets Management

### FAIL: Never Do This

```yaml
# FAIL: NEVER hardcode secrets
env:
- name: DB_PASSWORD
  value: "mypassword123"

# FAIL: NEVER commit Secret manifests with real data
apiVersion: v1
kind: Secret
data:
  password: bXlwYXNzd29yZDEyMw==  # Just base64, not encrypted!
```

### PASS: Use External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: app-secrets
  data:
  - secretKey: db-password
    remoteRef:
      key: prod/db/password
```

### Alternative: Sealed Secrets

```bash
# Install kubeseal
brew install kubeseal

# Create sealed secret
kubectl create secret generic mysecret --dry-run=client -o yaml \
  --from-literal=password=mypassword | \
  kubeseal -o yaml > sealed-secret.yaml

# Safe to commit sealed-secret.yaml
git add sealed-secret.yaml
```

## RBAC (Role-Based Access Control)

See [rbac.md](rbac.md) for detailed RBAC configuration.

## Network Security

See [networking.md](networking.md) for NetworkPolicy examples.

## Audit Logging

```yaml
# Enable audit logging
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods", "deployments"]
```

## Security Scanning

### Trivy (Container Scanning)

```bash
# Scan image
trivy image myapp:1.0.0

# Scan for high/critical only
trivy image --severity HIGH,CRITICAL myapp:1.0.0

# Scan Kubernetes manifests
trivy config deployment.yaml
```

### Kubesec

```bash
# Scan manifest
kubesec scan deployment.yaml

# Score (higher is better)
kubesec scan deployment.yaml | jq '.[0].score'
```

## Security Checklist

Before deploying to production:

- [ ] `runAsNonRoot: true` at pod and container level
- [ ] `allowPrivilegeEscalation: false`
- [ ] `readOnlyRootFilesystem: true` (with emptyDir for writable paths)
- [ ] `capabilities.drop: ["ALL"]`
- [ ] No `privileged: true`
- [ ] No `hostNetwork/hostPID/hostIPC: true`
- [ ] No `runAsUser: 0`
- [ ] Pod Security Standard: `restricted` enforced on namespace
- [ ] Secrets from external source (not hardcoded)
- [ ] Image tags are specific (not `:latest`)
- [ ] ServiceAccount with `automountServiceAccountToken: false`
- [ ] NetworkPolicy restricts traffic
- [ ] Scanned with Trivy/Kubesec

## Common Security Issues

### Issue: "container has runAsNonRoot and image will run as root"

```yaml
# FAIL: Image runs as root by default
FROM node:18
COPY . .
CMD ["node", "app.js"]

# PASS: Dockerfile creates non-root user
FROM node:18
RUN groupadd -r app && useradd -r -g app app
COPY --chown=app:app . .
USER app
CMD ["node", "app.js"]
```

### Issue: "readOnlyRootFilesystem breaks app"

```yaml
# PASS: Mount emptyDir for writable paths
volumeMounts:
- name: tmp
  mountPath: /tmp
- name: cache
  mountPath: /app/.cache
- name: logs
  mountPath: /var/log

volumes:
- name: tmp
  emptyDir: {}
- name: cache
  emptyDir: {}
- name: logs
  emptyDir: {}
```

## Security Tools

| Tool | Purpose |
|------|---------|
| **Trivy** | Image & manifest scanning |
| **Kubesec** | Manifest security scoring |
| **Falco** | Runtime threat detection |
| **Polaris** | Best practices validation |
| **OPA/Gatekeeper** | Policy enforcement |
| **kube-bench** | CIS benchmark compliance |

## References

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [NIST SP 800-190](https://csrc.nist.gov/publications/detail/sp/800-190/final)
