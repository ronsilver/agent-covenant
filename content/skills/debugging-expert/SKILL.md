---
name: debugging-expert
description: "Structured debugging methodology: state reproduction, distributed tracing instrumentation (OpenTelemetry), stack trace analysis, memory/CPU profiling, git bisect for binary fault localization, and blameless post-mortem analysis. Use when investigating bugs, tracing errors, diagnosing unexpected behavior, reproducing and isolating failures, forming and testing hypotheses, or adding regression tests after a fix. Trigger: debugging, root cause analysis, git bisect. Do NOT trigger for: general code review without bug investigation context."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Debugging Expert

**Systematic debugging: root cause analysis and structured investigation.**

## Debugging Workflow

1. **Reproduce** — create minimal reproduction case
2. **Isolate** — narrow scope to smallest failing component
3. **Hypothesize** — form testable hypothesis about root cause
4. **Test** — validate hypothesis with targeted experiments
5. **Fix** — apply minimal fix addressing root cause
6. **Regression Test** — add test preventing recurrence

## Reproduction

```
BEST PRACTICES
- Minimal input that triggers the bug
- Deterministic (same result every time)
- Document: "Given X, When Y, Then Z" (Gherkin)

TOOLS
- Production logs (trace_id, request_id correlation)
- Error stack traces
- Metrics (latency spikes, error rate changes)
```

## Git Bisect

```bash
git bisect start
git bisect bad HEAD           # current state is broken
git bisect good v1.2.0        # known good release
# Git checks out midpoint commit
# Test -> git bisect good | bad
# Repeat until isolated to single commit
```

## Root Cause vs Symptom

| Symptom (Don't Fix) | Root Cause (Fix This) |
|---|---|
| "API returns 500" | Unhandled nil pointer in service layer |
| "Request failed" | backend timeout due to missing timeout guard |
| "Slow page load" | N+1 query in customer listing loop |

## The 5 Whys

```
Bug: Resource creation fails intermittently
Why? -> backend call times out after 30s
Why? -> No connection pooling, creating new TLS per request
Why? -> Default HTTP client, not custom Transport
Why? -> No service-level resilience patterns configured
Why? -> Resilience not in integration onboarding checklist for new integrations

Fix: Add timeout guard + connection pool. Update integration onboarding checklist.
```

## Post-Mortem Template (Blameless)

```
## Incident: <title>
**Date**: YYYY-MM-DD | **Duration**: X mins | **SEV**: 1|2|3

### Timeline (UTC)
- 14:32 alert fired: 5xx rate > 5%
- 14:34 on-call acknowledged
- 14:45 root cause identified
- 14:52 fix deployed
- 14:55 service recovered

### Root Cause
<what specifically caused the incident>

### 5 Whys
<analysis of underlying causes>

### Action Items
- [ ] <preventive measure>
- [ ] <detection improvement>
```

## Constraints

- NEVER fix symptoms instead of root causes
- NEVER close bug without regression test
- NEVER accept "it works now" as resolution (must understand why)
- ALWAYS reproduce before fixing (prevent guessing)
- ALWAYS check if the same bug exists in other services/endpoints
- NEVER blame individuals in post-mortems

## Overview

Systematic debugging methodology for production incidents and software defects. Covers reproduction, isolation via git bisect, root cause analysis with 5 Whys, distributed tracing with OpenTelemetry, profiling (CPU/memory), and blameless post-mortems.

## Quick Reference

| Scenario | Action |
|---|---|
| Bug is intermittent | Add structured logging with trace_id; correlation across services |
| Regression from a known working build | `git bisect` to isolate the offending commit |
| High latency / slow response | Profile CPU + memory; check N+1 queries; instrument hot paths |
| Production incident underway | Reproduce with minimal input → isolate → hypothesize → test → fix → regression test |
| Post-mortem after resolution | Blameless timeline + 5 Whys + action items with owners |

## References

| Resource | URL | Last verified |
|---|---|---|
| OpenTelemetry Documentation | https://opentelemetry.io/docs/ | 2026-05-25 |
| Git Bisect Docs | https://git-scm.com/docs/git-bisect | 2026-05-25 |
| Google SRE Handbook (Post-mortem Culture) | https://sre.google/workbook/postmortem-culture/ | 2026-05-25 |
| pprof (Go Profiling) | https://go.dev/blog/pprof | 2026-05-25 |

- [references/postmortem-template.md](references/postmortem-template.md)
- [references/postmortem.md](references/postmortem.md)
- [references/tools-reference.md](references/tools-reference.md)
- [references/tools.md](references/tools.md)

## Verification Checklist
- [ ] Reproduction case created with minimal deterministic input before fixing
- [ ] Root cause identified (not symptom) through 5 Whys or git bisect
- [ ] Regression test added to prevent recurrence of the same bug
- [ ] Same bug pattern checked across other services or endpoints
- [ ] Post-mortem written (blameless) for production incidents
- [ ] Monitoring/alerting improved if bug was detected by user instead of alarm

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Bug is intermittent, cannot reproduce consistently | Race condition; timing-dependent; environment difference (dev vs prod) | Add structured logging with trace_id; capture full request context; run in prod-like staging |
| `git bisect` results are inconsistent | Test criteria not deterministic; manual test steps vary | Define exact repro steps (Gherkin format); use automated test script for bisect |
| Fix applied but same bug reappears later | Fixed symptom, not root cause; no regression test added | Apply 5 Whys to find root cause; add regression test before closing |
| Memory grows continuously, eventually OOM | Goroutine leak; unbounded cache; slice not released under GC | Profile with pprof heap; check goroutine count; add cache TTL or LRU eviction |
| Distributed trace incomplete due to sampling (known limitation) | OpenTelemetry sampler drops spans from non-critical services or low-traffic paths | Use head-based sampling for high-priority services; add tail-based sampler for complete traces on errors |
