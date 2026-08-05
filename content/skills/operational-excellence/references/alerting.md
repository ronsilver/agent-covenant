# Alerting Reference

## SLI/SLO/SLA Framework

### Service Level Indicators (SLI)
Quantitative measures of service quality:
- **Availability**: % of successful requests
- **Latency**: Response time (P50, P95, P99)
- **Error Rate**: % of failed requests
- **Throughput**: Requests per second

### Service Level Objectives (SLO)
Internal targets for SLIs:
```
Availability: 99.9% of requests succeed
Latency: 95% of requests complete in < 200ms
Error Rate: < 0.1% of requests fail
```

### Service Level Agreements (SLA)
External commitments with consequences:
```
99.95% uptime guarantee
Refunds if SLA breached
```

**Relationship**: SLI (measure) → SLO (target) → SLA (promise)

## Alert Best Practices

### Alert on Symptoms, Not Causes
```yaml
# FAIL: Bad: Alert on cause
- alert: HighCPU
  expr: cpu_usage > 80

# PASS: Good: Alert on symptom
- alert: HighLatency
  expr: http_request_duration_p95 > 1s
  for: 5m
```

### Reduce Alert Fatigue
- Only alert on actionable issues
- Use appropriate severity levels
- Set proper thresholds and durations
- Group related alerts

### Alert Severity Levels

**Critical (Page)**
- Service completely down
- Data loss occurring
- Security breach
- Immediate action required

**Warning (Ticket)**
- SLO at risk
- Degraded performance
- Resource constraints
- Action required within hours

**Info (Log)**
- Normal operational events
- No action required

## Prometheus Alert Examples

### Availability
```yaml
- alert: HighErrorRate
  expr: |
    rate(http_requests_total{status=~"5.."}[5m]) /
    rate(http_requests_total[5m]) > 0.05
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "High error rate on {{ $labels.service }}"
    description: "Error rate is {{ $value | humanizePercentage }}"
```

### Latency
```yaml
- alert: HighLatency
  expr: |
    histogram_quantile(0.95,
      rate(http_request_duration_seconds_bucket[5m])
    ) > 1.0
  for: 10m
  labels:
    severity: warning
  annotations:
    summary: "High P95 latency on {{ $labels.service }}"
    description: "P95 latency is {{ $value }}s"
```

### Saturation
```yaml
- alert: DiskSpaceRunningOut
  expr: |
    (node_filesystem_avail_bytes / node_filesystem_size_bytes) < 0.10
  for: 30m
  labels:
    severity: warning
  annotations:
    summary: "Disk space running out on {{ $labels.instance }}"
    description: "Only {{ $value | humanizePercentage }} space remaining"
```

## Runbooks

Every alert should have a runbook:

```yaml
annotations:
  runbook_url: "https://wiki.company.com/runbooks/high-latency"
```

### Runbook Template
```markdown
# Alert: HighLatency

## Severity
Warning

## Description
P95 latency exceeds 1 second for 10 minutes

## Impact
Users experiencing slow responses

## Diagnosis
1. Check metrics dashboard
2. Review recent deployments
3. Check database performance
4. Check external dependencies

## Remediation
1. If recent deployment: Rollback
2. If database slow: Check slow queries
3. If dependency slow: Enable circuit breaker
4. Scale up resources if needed

## Escalation
- After 30 min: Page on-call engineer
- After 1 hour: Escalate to manager
```

## On-Call Best Practices

### Rotation
- 24/7 coverage
- Max 1 week shifts
- Clear handoff process
- Backup on-call

### Response Times
- **Critical**: < 5 minutes
- **Warning**: < 30 minutes
- **Info**: Next business day

### Post-Incident
- Acknowledge alert
- Investigate and fix
- Document in incident log
- Create postmortem if needed
