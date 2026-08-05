# Post-Mortem Template (Blameless)

## Incident: [Title]
| Field | Value |
|---|---|
| Date | YYYY-MM-DD |
| Duration | X minutes |
| Severity | SEV1 / SEV2 / SEV3 |
| Author | @handle |

### Summary
One paragraph: what happened, impact, duration.

### Timeline (UTC)
| Time | Event |
|---|---|
| 14:30 | Deploy to production |
| 14:32 | Alert fires |
| 14:34 | On-call acknowledges |
| 14:45 | Service recovered |

### Root Cause
Specific technical cause, with evidence.

### 5 Whys
1. Why? → ...
2. Why? → ...
(continue until root process gap found)

### Action Items
| # | Action | Owner | Due |
|---|---|---|---|
| 1 | ... | @handle | YYYY-MM-DD |

### Lessons Learned

### Detection
- Alert caught it in N minutes
- Could improve: ...
