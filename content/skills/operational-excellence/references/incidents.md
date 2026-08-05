# Incident Management Reference

## Incident Severity

### SEV 1 (Critical)
- Complete service outage
- Data loss or corruption
- Security breach
- Financial impact

**Response**: Immediate, all hands

### SEV 2 (Major)
- Partial service degradation
- Major feature broken
- Performance severely degraded

**Response**: Within 30 minutes

### SEV 3 (Minor)
- Minor feature broken
- Workaround available
- Affects small user subset

**Response**: Within 4 hours

## Incident Response Process

### 1. Detection (0-5 min)
- Alert fires or user report
- Acknowledge immediately
- Create incident channel (#incident-YYYY-MM-DD)

### 2. Assessment (5-10 min)
- Determine severity
- Identify affected systems
- Estimate user impact
- Assign incident commander

### 3. Communication (10-15 min)
```
Internal: Post in #incidents
External: Update status page
Stakeholders: Notify leadership
```

### 4. Mitigation (15+ min)
- Rollback recent changes
- Scale resources
- Enable circuit breakers
- Apply hotfix

### 5. Resolution
- Verify metrics are normal
- Confirm users can access
- Monitor for 30 minutes
- Close incident

### 6. Postmortem (Within 48h)
- Timeline of events
- Root cause analysis
- Action items
- Lessons learned

## Incident Roles

### Incident Commander
- Lead response effort
- Make decisions
- Coordinate team
- Communicate status

### Communications Lead
- Update status page
- Notify stakeholders
- Post updates every 30min

### Technical Lead
- Debug and fix issue
- Execute remediation
- Coordinate with engineers

## Incident Communication

### Internal Updates (Every 30 min)
```
Status: Investigating | Identified | Monitoring | Resolved
Severity: SEV 1 | SEV 2 | SEV 3
Impact: X% of users affected
Next Update: HH:MM
```

### External Status Page
```
Investigating: We are investigating reports of slow response times.
Identified: We have identified the cause and are working on a fix.
Monitoring: A fix has been deployed. We are monitoring the situation.
Resolved: The issue has been resolved. All systems are operational.
```

## Blameless Postmortem

### Template
```markdown
# Incident Postmortem: [Title]

## Summary
Brief description of the incident.

## Impact
- Duration: 2 hours (14:00 - 16:00 UTC)
- Affected users: 15% of total
- Units shipped impact: $X
- Support tickets: Y

## Timeline
| Time | Event |
|------|-------|
| 14:00 | Alert: High error rate |
| 14:05 | Incident declared |
| 14:15 | Root cause identified |
| 14:30 | Fix deployed |
| 15:00 | Monitoring |
| 16:00 | Resolved |

## Root Cause
Database connection pool exhausted due to...

## Resolution
Increased connection pool size and deployed fix.

## What Went Well
- Fast detection (alert fired immediately)
- Clear communication
- Rollback plan ready

## What Went Wrong
- No canary deployment
- Missing connection pool metrics
- Insufficient load testing

## Action Items
- [ ] Add connection pool monitoring (Owner: Alice, Due: 2024-01-15)
- [ ] Implement canary deployments (Owner: Bob, Due: 2024-01-30)
- [ ] Improve load testing (Owner: Carol, Due: 2024-02-01)

## Lessons Learned
Always monitor resource pools (connections, threads, etc.)
```

## On-Call Handoff

### Handoff Checklist
- [ ] Review open incidents
- [ ] Share escalation contacts
- [ ] Review recent deployments
- [ ] Note any known issues
- [ ] Transfer on-call device/credentials

### Handoff Template
```
Outgoing: Alice
Incoming: Bob
Date: 2024-01-15

Open Incidents: None
Recent Changes: Shipment service deployed v2.1.0
Known Issues: Database replica lag ~5 seconds
Escalation: See PagerDuty schedule
Notes: Peak traffic expected this weekend
```

## Incident Prevention

### Reduce MTBF (Mean Time Between Failures)
- Comprehensive testing
- Gradual rollouts
- Feature flags
- Chaos engineering

### Reduce MTTR (Mean Time To Recovery)
- Fast rollback
- Good observability
- Runbooks
- Practice incidents
