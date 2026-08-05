# Argo Rollouts

## Canary Strategy
```yaml
strategy:
  canary:
    steps:
      - setWeight: 10
      - pause: { duration: 60s }
      - setWeight: 30
      - pause: { duration: 120s }
      - setWeight: 100
```

## Blue/Green
```yaml
strategy:
  blueGreen:
    activeService: api-active
    previewService: api-preview
    autoPromotionEnabled: true
```

## Analysis Templates
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
spec:
  metrics:
    - name: error-rate
      interval: 30s
      successCondition: result < 0.01
      provider:
        prometheus:
          address: http://prometheus:9090
          query: rate(http_errors_total[5m]) / rate(http_requests_total[5m])
```

## Secrets Management
| Tool | Pattern |
|---|---|
| Sealed Secrets | Encrypt in-cluster, store in git |
| External Secrets Operator | Sync from AWS Secrets Manager/Vault |
| SOPS | Encrypt with KMS, PGP |
