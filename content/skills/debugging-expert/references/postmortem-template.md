# Post-Mortem Template (Blameless)

## Incident: [Title]
| Field | Value |
|---|---|
| **Date** | YYYY-MM-DD |
| **Duration** | X minutes |
| **Severity** | SEV1 | SEV2 | SEV3 |
| **Author** | @handle |
| **Status** | Draft | Review | Final |

### Summary
[One paragraph: what happened, impact, duration]

### Timeline (UTC)
| Time | Event |
|---|---|
| 14:30 | [Deploy v2.3.1 to production] |
| 14:32 | [Alert: 5xx rate > 5% for api] |
| 14:34 | [On-call @jane acknowledged] |
| 14:38 | [Root cause identified: config typo in circuit breaker] |
| 14:42 | [Rollback initiated] |
| 14:45 | [Service recovered, error rate 0%] |

### Impact
- Users: ~3,200 api calls failed (3% of traffic)
- Units affected: ~124 shipments delayed (all recovered within 1h)
- Duration: 13 minutes

### Root Cause
[Specific technical cause, with evidence]

### 5 Whys
1. Why did shipment dispatch fail? → Circuit breaker opened on first call
2. Why did it open? → Config had open_threshold=0 instead of 5
3. Why was the wrong value deployed? → Config change not reviewed
4. Why wasn't it reviewed? → Config-only changes skip review policy
5. Why does the policy exempt configs? → Policy written before config-as-code migration

### Action Items
| # | Action | Owner | Due | Status |
|---|---|---|---|---|
| 1 | Add config validation pipeline | @devops | 2026-05-20 | TODO |
| 2 | Update review policy: no exemptions | @eng-mgr | 2026-05-18 | TODO |
| 3 | Add canary deploy for config changes | @sre | 2026-05-25 | TODO |
| 4 | Add circuit breaker state alert | @observability | 2026-06-01 | TODO |

### Detection
- Alert caught it in 2 minutes (good)
- Could improve: synthetic canary would catch 0 threshold before users

### Lessons Learned
- Config-as-code means config is also code (same review rigor)
- Circuit breaker defaults must have minimum guards

### Timeline of Key Events
```
14:30:00 deploy v2.3.1
14:30:15 first 500 error
14:32:00 alert fires
14:34:00 on-call ACKs
14:38:00 root cause identified
14:42:00 rollback starts
14:45:00 service recovered
```
