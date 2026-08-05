# Service Accounts & RBAC

## Service Accounts

Every pod runs with a ServiceAccount for API access.

### Default Behavior

```yaml
# FAIL: Uses default ServiceAccount (has API access)
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
      # automountServiceAccountToken: true by default
```

### Best Practice

```yaml
# PASS: Create dedicated ServiceAccount, disable auto-mount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
automountServiceAccountToken: false  # Disable by default
---
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      serviceAccountName: myapp
      automountServiceAccountToken: false  # Explicit disable
```

**Rule**: Only enable `automountServiceAccountToken: true` if pod needs K8s API access.

### With Cloud IAM (AWS/GCP)

```yaml
# AWS EKS with IAM Roles for Service Accounts (IRSA)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/myapp-role
automountServiceAccountToken: false

---
# GCP GKE with Workload Identity
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
  annotations:
    iam.gke.io/gcp-service-account: myapp@project-id.iam.gserviceaccount.com
automountServiceAccountToken: false
```

## RBAC (Role-Based Access Control)

### Components

| Resource | Scope | Description |
|----------|-------|-------------|
| **Role** | Namespace | Permissions within a namespace |
| **ClusterRole** | Cluster-wide | Permissions across cluster |
| **RoleBinding** | Namespace | Binds Role to subjects |
| **ClusterRoleBinding** | Cluster-wide | Binds ClusterRole to subjects |

### Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

### RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### Complete Example: App with ConfigMap Access

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: myapp
  namespace: production
automountServiceAccountToken: true  # Needs API access

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: configmap-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "watch"]
  resourceNames: ["myapp-config"]  # Restrict to specific ConfigMap

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: myapp-configmap-access
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production
roleRef:
  kind: Role
  name: configmap-reader
  apiGroup: rbac.authorization.k8s.io

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  template:
    spec:
      serviceAccountName: myapp
      automountServiceAccountToken: true
      containers:
      - name: app
        image: myapp:1.0.0
```

## ClusterRole

For cluster-wide resources or multiple namespaces:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
```

### ClusterRoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: read-nodes-global
subjects:
- kind: ServiceAccount
  name: monitoring
  namespace: monitoring
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

## Common Permissions

### Read-Only Access

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: read-only
rules:
- apiGroups: ["", "apps", "batch"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
```

### Deployment Manager

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
```

### Secret Reader (Dangerous!)

```yaml
# [WARN] Use with caution - secrets contain sensitive data
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["specific-secret"]  # Limit to specific secrets
```

## API Groups

Common API groups:

| API Group | Resources |
|-----------|-----------|
| `""` (core) | pods, services, configmaps, secrets, namespaces |
| `apps` | deployments, replicasets, statefulsets, daemonsets |
| `batch` | jobs, cronjobs |
| `networking.k8s.io` | ingresses, networkpolicies |
| `rbac.authorization.k8s.io` | roles, rolebindings, clusterroles |
| `autoscaling` | horizontalpodautoscalers |

## Verbs

| Verb | Description |
|------|-------------|
| `get` | Get a specific resource |
| `list` | List resources |
| `watch` | Watch for changes |
| `create` | Create new resources |
| `update` | Update existing resources |
| `patch` | Partially update resources |
| `delete` | Delete resources |
| `deletecollection` | Delete collection of resources |
| `*` | All verbs (avoid in production) |

## Least Privilege Examples

### CI/CD Deployment

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: cicd-deployer
  namespace: production
rules:
# Deployments
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
# ConfigMaps
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create", "update"]
# Secrets (read-only for existing)
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
# Services
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list", "create", "update"]
```

### Monitoring

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: prometheus
rules:
- apiGroups: [""]
  resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get"]
- nonResourceURLs: ["/metrics"]
  verbs: ["get"]
```

### Log Viewer

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: log-viewer
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
```

## Testing RBAC

```bash
# Check if ServiceAccount can perform action
kubectl auth can-i get pods \
  --as=system:serviceaccount:production:myapp \
  -n production

# List permissions for ServiceAccount
kubectl auth can-i --list \
  --as=system:serviceaccount:production:myapp \
  -n production

# Test with impersonation
kubectl get pods --as=system:serviceaccount:production:myapp -n production
```

## Default ServiceAccounts

```bash
# View default ServiceAccount
kubectl get serviceaccount default -n production -o yaml

# Disable auto-mount globally
kubectl patch serviceaccount default -n production \
  -p '{"automountServiceAccountToken": false}'
```

## Aggregated ClusterRoles

```yaml
# Define aggregated role
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-aggregated
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.example.com/aggregate-to-monitoring: "true"
rules: []  # Rules automatically aggregated

---
# Component roles
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-pods
  labels:
    rbac.example.com/aggregate-to-monitoring: "true"
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

## Common RBAC Mistakes

### FAIL: Too Permissive

```yaml
# FAIL: Grants cluster-admin (full access)
roleRef:
  kind: ClusterRole
  name: cluster-admin
```

### FAIL: Wildcard Permissions

```yaml
# FAIL: Allow all verbs on all resources
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### FAIL: Unnecessary API Access

```yaml
# FAIL: App doesn't use K8s API but has token mounted
spec:
  serviceAccountName: myapp
  automountServiceAccountToken: true  # Not needed!
```

## Security Best Practices

1. **Disable auto-mount by default**: Only enable for pods that need it
2. **Least privilege**: Grant minimum necessary permissions
3. **Namespace-scoped**: Use Role instead of ClusterRole when possible
4. **Specific resources**: Use `resourceNames` to limit access
5. **Audit access**: Monitor ServiceAccount usage
6. **Rotate credentials**: Regularly review and update
7. **Avoid wildcards**: Don't use `*` for verbs or resources

## RBAC Checklist

- [ ] ServiceAccount created for each app
- [ ] `automountServiceAccountToken: false` by default
- [ ] Role/ClusterRole follows least privilege
- [ ] RoleBinding/ClusterRoleBinding properly configured
- [ ] No `cluster-admin` or wildcard permissions
- [ ] Tested with `kubectl auth can-i`
- [ ] Specific `resourceNames` when possible
- [ ] Documented why permissions are needed

## Troubleshooting

```bash
# Check effective permissions
kubectl auth can-i --list \
  --as=system:serviceaccount:production:myapp \
  -n production

# View Role
kubectl get role pod-reader -n production -o yaml

# View RoleBinding
kubectl get rolebinding read-pods -n production -o yaml

# Describe for details
kubectl describe role pod-reader -n production
kubectl describe rolebinding read-pods -n production

# Test specific action
kubectl auth can-i create deployments \
  --as=system:serviceaccount:production:myapp \
  -n production
```

## Useful kubectl Commands

```bash
# Create ServiceAccount
kubectl create serviceaccount myapp -n production

# Create Role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n production

# Create RoleBinding
kubectl create rolebinding read-pods \
  --role=pod-reader \
  --serviceaccount=production:myapp \
  -n production

# View all RBAC resources
kubectl get roles,rolebindings,clusterroles,clusterrolebindings -A
```
