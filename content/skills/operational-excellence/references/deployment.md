# Deployment Safety Reference

## Deployment Strategies

### Blue-Green Deployment
```
1. Deploy new version (Green) alongside current (Blue)
2. Test Green in production
3. Switch traffic from Blue to Green
4. Keep Blue for quick rollback
```

**Pros**: Instant rollback, zero downtime
**Cons**: Requires 2x resources

### Canary Deployment
```
1. Deploy to small subset (5%)
2. Monitor metrics
3. Gradually increase (10% → 25% → 50% → 100%)
4. Rollback if issues detected
```

**Pros**: Risk mitigation, early issue detection
**Cons**: Slower rollout

### Rolling Deployment
```
1. Update pods one at a time
2. Wait for health checks
3. Continue to next pod
```

**Pros**: Resource efficient
**Cons**: Longer rollout, mixed versions

## Feature Flags

### Implementation
```go
// Feature flag check
if featureFlags.IsEnabled("new-payment-flow", userID) {
    return newPaymentFlow()
}
return oldPaymentFlow()
```

### Benefits
- Deploy code separately from feature release
- Gradual rollout to users
- A/B testing
- Quick disable if issues

### Best Practices
- Use percentage rollouts
- Target specific user segments
- Monitor metrics per variant
- Clean up old flags

## Rollback Strategy

### Fast Rollback (< 5 minutes)
```bash
# Kubernetes
kubectl rollout undo deployment/app

# Docker
docker service update --rollback app

# Helm
helm rollback app 0
```

### Rollback Checklist
- [ ] Database migrations are backward compatible
- [ ] No destructive schema changes
- [ ] Feature flags can disable new code
- [ ] Rollback tested in staging

## Pre-Deployment Checks

### Automated
```bash
# Tests pass
npm test

# Security scan
trivy image myapp:v1.0.0

# Performance test
k6 run load-test.js
```

### Manual
- [ ] Change request approved
- [ ] Rollback plan documented
- [ ] On-call engineer notified
- [ ] Deployment window scheduled
- [ ] Database migrations reviewed

## Deployment Monitoring

### Key Metrics (5 min after deploy)
- Error rate
- Latency (P50, P95, P99)
- Request rate
- Resource usage (CPU, memory)

### Auto-Rollback Triggers
```yaml
# Example: Argo Rollouts
analysis:
  metrics:
  - name: error-rate
    successCondition: result < 0.05
    failureLimit: 3
  - name: latency-p95
    successCondition: result < 1000
```

## Database Migrations

### Safe Migration Pattern
```sql
-- Phase 1: Add new column (nullable)
ALTER TABLE orders ADD COLUMN new_status VARCHAR(50);

-- Phase 2: Deploy code to write both columns
-- (code writes to old_status AND new_status)

-- Phase 3: Backfill data
UPDATE orders SET new_status = old_status WHERE new_status IS NULL;

-- Phase 4: Make NOT NULL
ALTER TABLE orders ALTER COLUMN new_status SET NOT NULL;

-- Phase 5: Deploy code to use new column only

-- Phase 6: Drop old column
ALTER TABLE orders DROP COLUMN old_status;
```

### Rules
- Migrations must be backward compatible
- Never drop columns in same release as code change
- Use expand-contract pattern
- Test rollback scenario

## Deployment Checklist

### Pre-Deployment
- [ ] All tests pass
- [ ] Security scan clean
- [ ] Performance acceptable
- [ ] Rollback plan ready
- [ ] On-call notified

### During Deployment
- [ ] Monitor error rates
- [ ] Watch latency metrics
- [ ] Check logs for errors
- [ ] Verify health checks pass

### Post-Deployment
- [ ] Smoke tests pass
- [ ] Metrics stable for 30 min
- [ ] No alerts triggered
- [ ] Users not reporting issues
