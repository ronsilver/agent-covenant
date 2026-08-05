# Runbook Structure

## Required Sections
```markdown
## Runbook: [Alert Name]
- **Alert**: [PromQL / CloudWatch expression]
- **Severity**: SEV1 | SEV2 | SEV3
- **Runbook URL**: [link to this doc]
- **Owner**: [team]

### Symptoms
- Dashboard: [what you'll see]
- Logs: [patterns to grep]

### Diagnosis (5 min)
1. Check [dashboard] for [metric]
2. Check logs: `grep "[pattern]" /var/log/api/*`
3. Verify [dependency] health: `curl [health endpoint]`

### Mitigation (10 min)
1. [Immediate action if service is down]
2. [Escalation path if step 1 fails]
3. [Longer-term fix for recurring issue]

### Validation
- [ ] Error rate returns to < 0.1%
- [ ] P99 latency < 500ms
- [ ] All health checks passing

### Escalation
If unresolved after 15 min → escalate to [team] via PagerDuty
```

## Example: DatabaseConnectionPoolExhausted
```markdown
## Runbook: DatabaseConnectionPoolExhausted
- **Alert**: rate(pg_stat_activity_count > max_connections * 0.9) > 0
- **Severity**: SEV2
- **Runbook URL**: https://wiki.example.com/runbooks/db-pool-exhausted

### Symptoms
- Dashboard: "Database Connections" panel shows >90% pool utilization
- API latency p99 > 2s across all endpoints
- Application logs show "FATAL: sorry, too many clients already"

### Diagnosis
1. Check DB pool dashboard: https://grafana.example.com/d/database
2. Check active connections:
   ```
   grep "active connections" /var/log/api/api.log | tail -50
   ```
3. Check for slow queries: `SELECT pid, now() - pg_stat_activity.query_start AS duration, query FROM pg_stat_activity WHERE state != 'idle' ORDER BY duration DESC;`
4. Verify pgbouncer health: `curl -s https://pgbouncer.example.com/health`

### Mitigation
1. If connection leak suspected: `kubectl rollout restart deploy/api`
   (recycles all connections, resolves leak temporarily)
2. If traffic spike: scale API replicas horizontally
3. If slow queries blocking: kill long-running queries via `SELECT pg_terminate_backend(pid);`

### Validation
- [ ] Database connections < 80% of max
- [ ] pgbouncer health check returns 200
- [ ] API p99 latency < 500ms

### Escalation
15 min → Database team on-call
30 min → Engineering Manager
```
