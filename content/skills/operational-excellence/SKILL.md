---
name: operational-excellence
description: "Implement SRE best practices including observability, alerting, incident management, and deployment safety. Use when defining SLOs, setting up alerting thresholds, implementing incident response procedures, or designing deployment safety gates. Trigger: SLO error budget, RED metrics, canary deployment, incident SEV, blameless postmortem, runbook. Do NOT trigger for: application-level logging configuration, specific monitoring tool setup (e.g. Datadog agent), infrastructure cost optimization."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: process
  status: stable
---

# Operational Excellence
**See [references/overview.md](references/overview.md)**

## Core Principles

Core: Observability by default | Automation first | Fail fast, recover faster | Blameless postmortems.

## Observability (Three Pillars)
- Logging: structured JSON + request IDs
- Metrics: RED method (Rate, Errors, Duration)
- Tracing: OpenTelemetry across services

→ [references/observability.md](references/observability.md)

## Alerting
- SLI/SLO/SLA defined | alert on symptoms (not causes) | every alert links to runbook | pages MUST be actionable
→ [references/alerting.md](references/alerting.md)

## Deployment Safety
Feature flags | canary deployments | automated rollbacks
→ [references/deployment.md](references/deployment.md)

## Incident Management
SEV1: 15min | SEV2: 30min | SEV3: 4h | Post-incident: RCA + action items + timeline
→ [references/incidents.md](references/incidents.md)

## Constraints
- NEVER log sensitive data (passwords, tokens, PII)
- ALWAYS structured logging (JSON, not free-text)
- ALWAYS propagate request/trace IDs | ALWAYS link every alert to runbook

## Overview

Site Reliability Engineering (SRE) practices for maintaining reliable production systems: observability (logs, metrics, traces), SLI/SLO-based alerting, blameless incident management, and safe deployment strategies including canary releases and automated rollbacks.

## Quick Reference

| Practice | Description | Target |
|----------|-------------|--------|
| SLO | Service Level Objective — target reliability | 99.9% uptime (8.7h downtime/year) |
| Error Budget | Allowed downtime = 100% - SLO | 8.7h/year for 99.9% SLO |
| RED Metrics | Rate, Errors, Duration — three golden signals | Per-service dashboard |
| Alert Severity | SEV1=pages, SEV2=pages, SEV3=ticket | SEV1 < 15min response |
| Canary Deploy | Roll out to 5% → 25% → 100% | Automated rollback on error spike |
| Postmortem | Blameless RCA with action items | Within 48h of incident close |

## Workflow

1. Define SLOs for each service (latency p99 < 500ms, availability > 99.9%, error rate < 0.1%)
2. Instrument with RED metrics: request rate, error count, duration histograms via OpenTelemetry
3. Configure alerts on symptoms (high latency, elevated error rate), not causes (low disk space)
4. Every alert links to a runbook with diagnosis and mitigation steps
5. Deploy with canary: 5% traffic → monitor 5min → 25% → monitor → 100%; auto-rollback on error spike
6. After incidents: blameless postmortem within 48h with RCA, timeline, and tracked action items

## Anti-patterns

FAIL: Alerting on causes instead of symptoms
```
# BAD
Alert: CPU > 80%
# CPU high is a cause, not a symptom — may not affect users
```
PASS: Alert on symptoms
```
# GOOD
Alert: p99 latency > 1s for 5min
# Latency directly affects users
```

FAIL: Unactionable alerts without runbooks
```
# BAD
Alert: High error rate
# On-call engineer: "What do I do?"
```
PASS: Every alert links to a runbook
```
# GOOD
Alert: api latency > 1s
Runbook: https://github.com/example/ops/runbooks/service-latency.md
Diagnosis: 1. Check api-throttle dashboard  2. Check provider status page
Mitigation: 1. Throttle traffic to failing provider 2. Escalate if > 5min
```

FAIL: Manual deployment without canary
```
# BAD
kubectl apply -f prod.yaml  # deploy directly to 100%
```
PASS: Canary deployment with monitoring
```
# GOOD
1. Deploy to 5% of instances
2. Monitor error rate for 5 minutes
3. If error rate < baseline, ramp to 25%
4. Monitor 5 more minutes
5. Ramp to 100%
6. Auto-rollback if error rate spikes
```

FAIL: Blaming individuals in postmortems
```
# BAD
Root cause: Engineer X pushed bad config
# Creates fear culture, hides systemic issues
```
PASS: Blameless RCA
```
# GOOD
Root cause: No pre-prod validation for config changes
Action: Add CI check that validates config against schema before merge
```

## References

- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) · last_verified: 2026-05-25
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/) · last_verified: 2026-05-25
- [RED Method — Monitoring Microservices](https://grafana.com/blog/2018/08/02/the-red-method-how-to-instrument-your-services/) · last_verified: 2026-05-25

## Verification Checklist

- [ ] SLOs defined per service with explicit latency, availability, and error rate targets
- [ ] RED metrics (Rate, Errors, Duration) instrumented via OpenTelemetry
- [ ] Alerts configured on symptoms (not causes) with linked runbooks
- [ ] Canary deployment strategy implemented with automated rollback triggers
- [ ] Blameless postmortem process documented with RCA timeline and action items
- [ ] Every alert has a defined severity (SEV1/SEV2/SEV3) with response time SLA
- [ ] Error budget burn rate tracked and reviewed weekly

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Pager fatigue from noisy alerts | Alert threshold too sensitive or on causes instead of symptoms | Review alert rules; switch to symptom-based alerting (latency/error rate over CPU/disk) |
| Canary rolled back but root cause unknown | Missing automated rollback analysis in CI/CD pipeline | Add diff logging between canary and baseline; capture metrics spike details during rollback |
| SLO burn rate exceeds budget in one day | Single large-scale failure or gradual degradation not detected | Set faster alert on burn rate (e.g., 10% budget consumed in <1h triggers SEV2) |
| Known issue: canary auto-rollback triggers on transient provider latency spikes | External dependency degradation triggers false rollback | Add external dependency health gate in canary evaluation; exclude known provider outages from rollback signal |

| [WARN] Canary deployment passes metrics but breaks business logic silently | Canary only checks HTTP-level metrics (latency/error rate), not business outcome | Add business metric gates to canary evaluation (e.g., conversion rate, request success %) |
| Rollback reverts traffic to old version but the bug persists because it was pre-existing | Bug was latent in the old version too; rollback does not resolve the underlying issue | Rollback is not a fix: create new hotfix branch from working commit; apply proper regression test |
| Gotcha: canary auto-promotion at 30min ignores slow-burn degradation visible at 60min | Short canary window misses gradual performance regression that only manifests after warm-up | Extend canary evaluation to 2h for performance-critical changes; add step-weight decay analysis |
