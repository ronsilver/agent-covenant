# Labels and Annotations

## Recommended Labels (app.kubernetes.io)

Kubernetes recommends these standard labels:

| Label | Description | Example |
|-------|-------------|---------|
| `app.kubernetes.io/name` | Application name | `mysql` |
| `app.kubernetes.io/instance` | Unique instance name | `prod-us-east-1` |
| `app.kubernetes.io/version` | Application version | `1.2.3` |
| `app.kubernetes.io/component` | Component role | `database`, `api`, `frontend` |
| `app.kubernetes.io/part-of` | Higher-level app name | `wordpress` |
| `app.kubernetes.io/managed-by` | Tool managing the resource | `helm`, `kubectl` |

### Complete Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: wordpress-mysql
  labels:
    app.kubernetes.io/name: mysql
    app.kubernetes.io/instance: prod-us-east-1
    app.kubernetes.io/version: "5.7.21"
    app.kubernetes.io/component: database
    app.kubernetes.io/part-of: wordpress
    app.kubernetes.io/managed-by: helm
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: mysql
      app.kubernetes.io/instance: prod-us-east-1
  template:
    metadata:
      labels:
        app.kubernetes.io/name: mysql
        app.kubernetes.io/instance: prod-us-east-1
        app.kubernetes.io/version: "5.7.21"
        app.kubernetes.io/component: database
        app.kubernetes.io/part-of: wordpress
        app.kubernetes.io/managed-by: helm
    spec:
      containers:
      - name: mysql
        image: mysql:5.7.21
```

## Common Labels

```yaml
metadata:
  labels:
    # Standard
    app.kubernetes.io/name: myapp
    app.kubernetes.io/version: "1.2.3"
    app.kubernetes.io/component: api
    
    # Environment
    environment: production
    
    # Ownership
    team: platform
    owner: platform-team@example.com
    
    # Cost allocation
    cost-center: engineering
    project: user-service
```

## Label Selectors

### Equality-Based

```yaml
# Deployment selector
spec:
  selector:
    matchLabels:
      app: myapp
      tier: frontend

# Service selector
spec:
  selector:
    app: myapp
    tier: frontend
```

### Set-Based

```yaml
spec:
  selector:
    matchExpressions:
    - key: tier
      operator: In
      values: [frontend, backend]
    - key: environment
      operator: NotIn
      values: [dev, test]
    - key: app
      operator: Exists
```

## Annotations

### Common Annotations

```yaml
metadata:
  annotations:
    # Description
    description: "User authentication service"
    
    # Ownership
    owner: "platform-team@example.com"
    oncall: "https://oncall.example.com/platform"
    
    # Documentation
    documentation: "https://docs.example.com/auth-service"
    runbook: "https://runbook.example.com/auth-service"
    
    # Prometheus
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    
    # Deployment info
    deployment.timestamp: "2024-01-15T10:30:00Z"
    deployment.git-commit: "abc123def456"
    deployment.deployed-by: "jane.doe@example.com"
```

### AWS Annotations

```yaml
metadata:
  annotations:
    # EKS
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789:role/my-role"
    
    # ALB Ingress
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/healthcheck-path: /health
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:..."
```

### GCP Annotations

```yaml
metadata:
  annotations:
    # Workload Identity
    iam.gke.io/gcp-service-account: "my-app@project.iam.gserviceaccount.com"
```

## Label Best Practices

### 1. Use Consistent Labels

```yaml
# PASS: Good - consistent across resources
labels:
  app: myapp
  env: production
  tier: backend

# FAIL: Bad - inconsistent naming
labels:
  application: myapp  # Should be 'app'
  environment: prod   # Should be 'env'
  layer: backend      # Should be 'tier'
```

### 2. Keep Labels Short

```yaml
# PASS: Good - short and clear
labels:
  app: myapp
  env: prod

# FAIL: Bad - too verbose
labels:
  application-name: my-application-name
  deployment-environment: production
```

### 3. Use Annotations for Non-Identifying Data

```yaml
# PASS: Labels for selection
labels:
  app: myapp
  version: "1.2.3"

# PASS: Annotations for metadata
annotations:
  description: "Authentication service for user management"
  git-commit: "abc123"
```

## Organizing by Labels

### Query by Labels

```bash
# Get pods by app
kubectl get pods -l app=myapp

# Get pods by multiple labels
kubectl get pods -l app=myapp,env=production

# Get pods by label existence
kubectl get pods -l version

# Get pods by label non-existence
kubectl get pods -l '!version'

# Set-based selector
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l 'env notin (dev,test)'
```

### Delete by Labels

```bash
# Delete all pods with label
kubectl delete pods -l app=myapp

# Delete deployments in test environment
kubectl delete deployments -l env=test
```

## Label Namespaces

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    team: platform
    
    # Pod Security
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## Node Labels

```bash
# Label node
kubectl label nodes node-1 disktype=ssd

# Node selector in pod
spec:
  nodeSelector:
    disktype: ssd

# Node affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
```

## Label Constraints

- **Max length**: 63 characters (value), prefix can be 253 chars
- **Allowed characters**: alphanumeric, `-`, `_`, `.`
- **Must start/end**: with alphanumeric
- **Prefix** (optional): `example.com/key`

### Valid Labels

```yaml
labels:
  app: myapp                                    # PASS:
  version: "1.2.3"                             # PASS:
  example.com/environment: production          # PASS: With prefix
  kubernetes.io/component: apiserver           # PASS: K8s label
```

### Invalid Labels

```yaml
labels:
  app: "my app"            # FAIL: Space not allowed
  -app: myapp              # FAIL: Cannot start with -
  app-: myapp              # FAIL: Cannot end with -
  my.very.long.label.name.that.exceeds.sixty.three.characters: value  # FAIL: Too long
```

## Common Label Patterns

### Environment Labels

```yaml
labels:
  environment: production  # prod, staging, dev
  region: us-east-1
  zone: us-east-1a
```

### Ownership Labels

```yaml
labels:
  team: platform
  owner: jane.doe
  cost-center: engineering
```

### Version Labels

```yaml
labels:
  version: "1.2.3"
  release: stable
  track: canary  # canary, stable, beta
```

## Label Propagation

```yaml
# Deployment labels propagate to ReplicaSet and Pods
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp  # On Deployment
spec:
  selector:
    matchLabels:
      app: myapp  # Must match template labels
  template:
    metadata:
      labels:
        app: myapp  # On Pods
```

## Monitoring & Alerting Labels

```yaml
metadata:
  labels:
    # Prometheus
    monitoring: enabled
    alert-severity: critical
    
  annotations:
    # Prometheus scrape config
    prometheus.io/scrape: "true"
    prometheus.io/port: "9090"
    prometheus.io/path: "/metrics"
    
    # Alert routing
    alert.pagerduty.com/service-key: "abc123"
    alert.slack.com/channel: "#platform-alerts"
```

## Multi-Tenancy Labels

```yaml
labels:
  tenant: customer-a
  tier: premium
  quota-group: large
```

## Debugging with Labels

```bash
# Find all resources with label
kubectl get all -l app=myapp

# Find resources across all namespaces
kubectl get pods -A -l app=myapp

# Show labels
kubectl get pods --show-labels

# Add label to running pod
kubectl label pod my-pod tier=frontend

# Update label
kubectl label pod my-pod tier=backend --overwrite

# Remove label
kubectl label pod my-pod tier-
```
