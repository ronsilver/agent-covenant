# ConfigMaps and Secrets

## ConfigMaps

Store non-sensitive configuration data.

### Basic ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: production
data:
  LOG_LEVEL: "info"
  MAX_CONNECTIONS: "100"
  API_URL: "https://api.example.com"
```

### ConfigMap from File

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.conf: |
    server {
      listen 80;
      server_name example.com;
    }
  nginx.conf: |
    worker_processes auto;
    events {
      worker_connections 1024;
    }
```

### Using ConfigMap in Pod

#### As Environment Variables

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        envFrom:
        - configMapRef:
            name: myapp-config
        # All keys become env vars: LOG_LEVEL, MAX_CONNECTIONS, etc.
```

#### Selective Environment Variables

```yaml
env:
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: myapp-config
      key: LOG_LEVEL
- name: API_URL
  valueFrom:
    configMapKeyRef:
      name: myapp-config
      key: API_URL
```

#### As Volume Mount

```yaml
volumes:
- name: config-volume
  configMap:
    name: myapp-config
    items:
    - key: app.conf
      path: app.conf

containers:
- name: app
  volumeMounts:
  - name: config-volume
    mountPath: /etc/config
    readOnly: true
  # File available at /etc/config/app.conf
```

### Create ConfigMap with kubectl

```bash
# From literal values
kubectl create configmap myapp-config \
  --from-literal=LOG_LEVEL=info \
  --from-literal=MAX_CONNECTIONS=100

# From file
kubectl create configmap nginx-config \
  --from-file=nginx.conf

# From directory
kubectl create configmap app-configs \
  --from-file=configs/
```

## Secrets

Store sensitive data (passwords, tokens, keys).

**WARNING**: Secrets are only base64-encoded, NOT encrypted at rest by default!

### Basic Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
  namespace: production
type: Opaque
data:
  # Base64 encoded values
  DB_PASSWORD: bXlwYXNzd29yZDEyMw==  # mypassword123
  API_KEY: c2stYWJjMTIzZGVmNDU2==     # sk-abc123def456
```

**Encode/Decode**:
```bash
# Encode
echo -n "mypassword123" | base64
# bXlwYXNzd29yZDEyMw==

# Decode
echo "bXlwYXNzd29yZDEyMw==" | base64 -d
# mypassword123
```

### String Data (Auto-Encoded)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secret
type: Opaque
stringData:
  DB_PASSWORD: "mypassword123"  # Automatically base64 encoded
  API_KEY: "sk-abc123def456"
```

### Using Secrets in Pod

#### As Environment Variables

```yaml
containers:
- name: app
  envFrom:
  - secretRef:
      name: myapp-secret
  # Creates: DB_PASSWORD, API_KEY env vars
```

#### Selective Environment Variables

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: myapp-secret
      key: DB_PASSWORD
```

#### As Volume Mount

```yaml
volumes:
- name: secret-volume
  secret:
    secretName: myapp-secret
    defaultMode: 0400  # Read-only for owner

containers:
- name: app
  volumeMounts:
  - name: secret-volume
    mountPath: /etc/secrets
    readOnly: true
  # Files: /etc/secrets/DB_PASSWORD, /etc/secrets/API_KEY
```

### Create Secret with kubectl

```bash
# From literal values
kubectl create secret generic myapp-secret \
  --from-literal=DB_PASSWORD=mypassword123 \
  --from-literal=API_KEY=sk-abc123

# From file
kubectl create secret generic tls-secret \
  --from-file=tls.crt \
  --from-file=tls.key

# Docker registry secret
kubectl create secret docker-registry docker-secret \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass \
  --docker-email=user@example.com
```

## Secret Types

| Type | Use Case |
|------|----------|
| `Opaque` | Generic secrets (default) |
| `kubernetes.io/service-account-token` | ServiceAccount token |
| `kubernetes.io/dockercfg` | Docker registry auth |
| `kubernetes.io/dockerconfigjson` | Docker config JSON |
| `kubernetes.io/basic-auth` | Basic authentication |
| `kubernetes.io/ssh-auth` | SSH key |
| `kubernetes.io/tls` | TLS certificate and key |

### TLS Secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-cert>
  tls.key: <base64-encoded-key>
```

```bash
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```

## External Secrets Operator (RECOMMENDED)

**Never commit secrets to Git.** Use External Secrets Operator instead.

### Install External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace
```

### AWS Secrets Manager

```yaml
---
# SecretStore (namespace-scoped)
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa

---
# ExternalSecret (creates K8s Secret from AWS)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: myapp-secret
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: myapp-secret  # Creates this K8s Secret
    creationPolicy: Owner
  data:
  - secretKey: DB_PASSWORD
    remoteRef:
      key: prod/db/password  # AWS Secrets Manager key
  - secretKey: API_KEY
    remoteRef:
      key: prod/api/key
```

### GCP Secret Manager

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcp-secret-manager
spec:
  provider:
    gcpsm:
      projectID: "my-project"
      auth:
        workloadIdentity:
          clusterLocation: us-central1
          clusterName: my-cluster
          serviceAccountRef:
            name: external-secrets-sa
```

### HashiCorp Vault

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "myapp"
```

## Sealed Secrets (Alternative)

Encrypt secrets for Git storage.

### Install Sealed Secrets

```bash
# Install controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Install kubeseal CLI
brew install kubeseal
```

### Create Sealed Secret

```bash
# Create secret (don't apply)
kubectl create secret generic mysecret \
  --dry-run=client -o yaml \
  --from-literal=password=mypassword123 \
  > secret.yaml

# Seal it
kubeseal -f secret.yaml -w sealedsecret.yaml

# Safe to commit sealedsecret.yaml to Git
git add sealedsecret.yaml
git commit -m "Add sealed secret"
```

```yaml
# SealedSecret (encrypted)
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: mysecret
spec:
  encryptedData:
    password: AgBH8F7x...  # Encrypted, safe for Git
```

## ConfigMap/Secret Best Practices

### FAIL: Don't Hardcode in Deployment

```yaml
# FAIL: Bad - hardcoded
env:
- name: DB_PASSWORD
  value: "mypassword123"
```

### PASS: Use ConfigMap/Secret

```yaml
# PASS: Good - from Secret
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: myapp-secret
      key: DB_PASSWORD
```

### FAIL: Don't Commit Secrets to Git

```bash
# FAIL: NEVER do this
git add secret.yaml
git commit -m "Add database password"
```

### PASS: Use External Secrets or Sealed Secrets

```yaml
# PASS: Good - ExternalSecret
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
# Pulls from AWS Secrets Manager, safe to commit
```

## Immutable ConfigMaps/Secrets

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
immutable: true  # Cannot be updated
data:
  LOG_LEVEL: "info"
```

**Benefits**:
- Protects from accidental changes
- Better performance (no watch needed)
- Forces pod restart on config change

## Updating ConfigMaps/Secrets

### Mounted as Volume (Auto-Updates)

```yaml
volumeMounts:
- name: config-volume
  mountPath: /etc/config
  readOnly: true
# Files update automatically (eventually)
```

**Note**: Takes ~1 minute for changes to propagate

### Environment Variables (No Auto-Update)

```yaml
envFrom:
- configMapRef:
    name: myapp-config
# Requires pod restart to see changes
```

### Force Pod Restart on Change

```yaml
# Add annotation with hash of ConfigMap
template:
  metadata:
    annotations:
      checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
```

## Troubleshooting

```bash
# View ConfigMap
kubectl get configmap myapp-config -o yaml

# View Secret (base64 encoded)
kubectl get secret myapp-secret -o yaml

# Decode Secret
kubectl get secret myapp-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d

# Edit ConfigMap
kubectl edit configmap myapp-config

# Edit Secret
kubectl edit secret myapp-secret

# Delete and recreate
kubectl delete secret myapp-secret
kubectl create secret generic myapp-secret --from-literal=password=newpass
```

## Security Checklist

- [ ] Never commit Secrets to Git
- [ ] Use External Secrets Operator for production
- [ ] Or use Sealed Secrets for GitOps
- [ ] Enable encryption at rest in etcd
- [ ] Limit RBAC access to Secrets
- [ ] Use separate Secrets per environment
- [ ] Rotate secrets regularly
- [ ] Use immutable ConfigMaps/Secrets where possible

## Encryption at Rest

Enable in cluster (cloud provider specific):

```yaml
# AWS EKS
apiVersion: v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - kms:
      name: arn:aws:kms:us-east-1:123456789012:key/abc-123
  - identity: {}
```

## kubectl Commands

```bash
# ConfigMaps
kubectl create configmap myapp-config --from-literal=KEY=value
kubectl get configmaps
kubectl describe configmap myapp-config
kubectl delete configmap myapp-config

# Secrets
kubectl create secret generic mysecret --from-literal=password=pass
kubectl get secrets
kubectl describe secret mysecret  # Doesn't show values
kubectl delete secret mysecret

# View values
kubectl get secret mysecret -o jsonpath='{.data.password}' | base64 -d
```

## External Secrets vs Sealed Secrets

| Feature | External Secrets | Sealed Secrets |
|---------|------------------|----------------|
| **Storage** | Cloud provider (AWS/GCP/Vault) | Git (encrypted) |
| **Rotation** | Automatic from source | Manual |
| **Setup** | Requires cloud integration | Simpler |
| **Use Case** | Production (recommended) | GitOps, simple needs |
