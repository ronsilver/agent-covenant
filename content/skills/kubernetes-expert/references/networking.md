# Network Policies

## Default Deny All

Always start with default deny, then allow specific traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}  # Applies to all pods in namespace
  policyTypes:
  - Ingress
  - Egress
```

## Allow Specific Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

## Allow Specific Egress

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

## Complete 3-Tier Application

```yaml
---
# Frontend → Internet (ingress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-ingress
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 3000

---
# Frontend → API (egress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-to-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 8080

---
# API → Frontend (ingress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-from-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---
# API → Database (egress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-to-database
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432

---
# Database → API only (ingress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-from-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: api
    ports:
    - protocol: TCP
      port: 5432
  egress: []  # No outbound traffic
```

## Allow DNS

Most policies need DNS resolution:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}  # All pods
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

## Allow External Traffic

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api-allow-external
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Egress
  egress:
  # DNS
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # External APIs (HTTPS)
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 10.0.0.0/8    # Block private IPs
        - 172.16.0.0/12
        - 192.168.0.0/16
    ports:
    - protocol: TCP
      port: 443
```

## Namespace Selector

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090  # Metrics endpoint
```

## CIDR Block (IP Ranges)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-office
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: admin-panel
  policyTypes:
  - Ingress
  ingress:
  - from:
    - ipBlock:
        cidr: 203.0.113.0/24  # Office IP range
    ports:
    - protocol: TCP
      port: 443
```

## Multiple Selectors (AND)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: strict-policy
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: production
      podSelector:  # AND (same item)
        matchLabels:
          tier: frontend
```

## Multiple Selectors (OR)

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: multiple-sources
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:
  - from:
    - podSelector:  # OR (separate items)
        matchLabels:
          tier: frontend
    - podSelector:
        matchLabels:
          tier: admin
```

## Testing Network Policies

```bash
# Test connectivity between pods
kubectl run test-pod --rm -it --image=busybox -- sh

# From inside pod
wget -O- http://api-service:8080
nc -zv database-service 5432

# Check if NetworkPolicy is applied
kubectl get networkpolicies
kubectl describe networkpolicy <name>

# Debug with curl pod
kubectl run curl --rm -it --image=curlimages/curl -- sh
```

## Common Patterns

### Monitoring/Metrics Access

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-prometheus
spec:
  podSelector:
    matchLabels:
      prometheus: scrape
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
    ports:
    - protocol: TCP
      port: 9090
```

### Health Check from Load Balancer

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-healthcheck
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/8  # Internal load balancer range
    ports:
    - protocol: TCP
      port: 8080
```

## Network Policy Providers

NetworkPolicy requires a network plugin:

| Plugin | Provider | Features |
|--------|----------|----------|
| **Calico** | Most popular | Full NetworkPolicy support, eBPF |
| **Cilium** | eBPF-based | L7 policies, observability |
| **Weave Net** | Simple | Basic NetworkPolicy |
| **Canal** | Calico + Flannel | NetworkPolicy + routing |

**Note**: Cloud providers (EKS, GKE, AKS) have native support

## Calico Network Policies (Extended)

Calico adds additional policy types:

```yaml
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: advanced-policy
spec:
  selector: app == "api"
  types:
  - Ingress
  ingress:
  - action: Allow
    protocol: TCP
    source:
      selector: tier == "frontend"
    destination:
      ports:
      - 8080
  - action: Log
    protocol: TCP
    source:
      selector: tier == "unknown"
```

## Debugging

```bash
# Check if NetworkPolicy is created
kubectl get networkpolicies -n production

# Describe policy
kubectl describe networkpolicy api-allow-frontend -n production

# Check pod labels
kubectl get pods --show-labels -n production

# Verify traffic
kubectl exec -it frontend-pod -n production -- curl api-service:8080

# Check network plugin logs
kubectl logs -n kube-system -l k8s-app=calico-node
```

## Common Mistakes

### FAIL: Forgetting DNS

```yaml
# FAIL: Blocks DNS resolution
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
  # Missing DNS egress!
```

### FAIL: Not Specifying policyTypes

```yaml
# FAIL: Only ingress is enforced
spec:
  podSelector:
    matchLabels:
      app: api
  ingress:  # policyTypes not specified
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

**Fix**: Always specify `policyTypes`

### FAIL: Wrong Selector Logic

```yaml
# FAIL: This is AND, not OR
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        env: prod
    podSelector:  # AND (same level)
      matchLabels:
        tier: frontend

# PASS: This is OR
ingress:
- from:
  - namespaceSelector:  # OR (different items)
      matchLabels:
        env: prod
  - podSelector:
      matchLabels:
        tier: frontend
```

## Best Practices

1. **Default deny all** - Start restrictive, allow specific
2. **Least privilege** - Only allow necessary traffic
3. **Label pods** - Use consistent labels for selection
4. **Allow DNS** - Most apps need DNS
5. **Test policies** - Verify before production
6. **Document policies** - Comment why traffic is allowed
7. **Monitor blocked traffic** - Use logs to detect issues

## NetworkPolicy Checklist

- [ ] Default deny policy in place
- [ ] DNS egress allowed
- [ ] Only required ingress allowed
- [ ] Only required egress allowed
- [ ] Tested connectivity between pods
- [ ] Monitoring/metrics access configured
- [ ] Health check endpoints accessible
- [ ] Documented allowed traffic patterns
