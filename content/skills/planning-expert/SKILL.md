---
name: planning-expert
description: "Development planning based on technical documentation: RFCs for architecture proposals, TRDs for solution specification, ADRs for decision records, pre-coding clarifying interviews (need: scope, technical constraints), multi-week roadmaps, and trade-off analysis. Use when starting ambiguous feature work, receiving vague requirements, planning implementation before writing code, designing multi-week roadmaps, or needing to surface unstated assumptions. Trigger: planning, roadmap, ADR, RFC, TRD, scope definition, pre-coding interview. Do NOT trigger for: debugging, code review, deployment operations."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: process
  status: stable
---

# Planning Expert

**Pre-coding planning: interviews, specs, ADRs and roadmaps.**

## Pre-Coding Interview (3 phases)

### Phase 1: Understand Need
- What problem are we solving?
- Who is the user/stakeholder?
- What does success look like? (measurable outcome)

### Phase 2: Scope Boundaries
- What is explicitly IN scope?
- What is explicitly OUT of scope?
- What are the constraints (time, budget, tech)?

### Phase 3: Technical Constraints
- Existing systems this must integrate with?
- Data or schema changes needed?
- Security/compliance requirements?
- Performance targets (latency, throughput)?

## Planning Depth

| Level | Output | Duration |
|---|---|---|
| Standard | Objectives + scope + milestones + risks + dependencies | Single feature, 1-2 weeks |
| Deep | Above + alternative analysis + trade-offs + ADR + RFC | Multi-week, cross-team |

## Output Templates

### Standard Plan
```
## Objective
<one-sentence goal>

## Scope
In: <what's covered>
Out: <what's explicitly excluded>

## Milestones
1. <milestone> — <definition of done>
2. <milestone> — <definition of done>

## Risks
- <risk>: <mitigation>

## Dependencies
- <what must be done first, by whom>
```

### ADR (Architecture Decision Record)
```
# ADR-###: <Title>
Status: Proposed | Accepted | Deprecated
Date: YYYY-MM-DD
Context: <problem + constraints>
Decision: <what we're doing>
Alternatives: <what we considered + why rejected>
Consequences: <what becomes easier/harder>
```

## Constraints
- NEVER start coding without defined scope and success criteria
- NEVER plan without identifying external dependencies first
- ALWAYS document trade-offs for non-obvious decisions
- NEVER accept "it should be fast" — quantify: p95 < Xms
- ALWAYS identify what's OUT of scope (prevents creep)
- ALWAYS classify assumptions as `verified | unverified | critical` before including them in a plan
- NEVER include unverified claims about third-party software capabilities in a plan — verify against official docs first

## Overview

Pre-coding planning reduces rework by surfacing assumptions, constraints, and trade-offs before writing code. This skill structures the discovery-to-plan pipeline using ADRs, RFCs, and multi-level planning templates.

## Quick Reference

| Artifact | Purpose | Audience |
|---|---|---|
| ADR | Record architectural decisions with context + alternatives | Engineering team |
| RFC | Propose designs with trade-off analysis + stakeholder feedback | Cross-team stakeholders |
| TRD | Translate requirements into implementable specification | Developers |

## Workflow

0. **Feature Existence Check (MANDATORY)** — Scan the plan for ALL named third-party tools, services, and specific capabilities. For each found: verify the capability exists in official docs BEFORE planning. If zero external references found → proceed (no third-party claims to verify). If any external reference found and capability does not exist → BLOCK planning, notify user, propose alternatives. This step cannot be skipped or deferred.
1. Conduct pre-coding interview (understand need → scope → constraints)
2. Choose planning depth (standard for single feature, deep for cross-team)
3. Write ADR for each architecturally-significant decision
4. Draft RFC if the change affects multiple teams or systems
5. Output structured plan with milestones, risks, and dependencies
6. Share with stakeholders for review before coding begins
7. **Assumption Audit** — Review the plan for: (a) every external tool mentioned → is capability verified? (b) every "will" or "can" statement → is it a claim or a plan step? (c) every dependency → is it confirmed available? Output: `## Assumptions: <list> | Status: <verified/unverified per item>`. If any unverified assumption affects a milestone → BLOCK plan.

## Anti-patterns

FAIL: Writing code directly from a Slack thread without scope definition
PASS: Always write a 3-line scope doc before touching the editor

```text
FAIL: Plan: "Build import page"
PASS: Plan: "Build import page — In: file upload, validation summary, error states. Out: scheduling, deduplication"
```

FAIL: Accepting "it should be fast" without a target
PASS: Quantify: "p95 response time must be <300ms under 1000 RPS"

```text
FAIL: "Make the report export faster" — no baseline, no target
PASS: "Reduce p95 from 800ms to <300ms — verified by k6 load test"
```

FAIL: Planning in isolation then surprising stakeholders with the design
PASS: Share RFC early; invite feedback before committing to implementation

```text
FAIL: Week 1: design in private. Week 3: present to team → rejected
PASS: Day 1: one-pager RFC. Day 3: async feedback. Day 5: final ADR
```

FAIL: Accepting user claims about third-party software capabilities without verification
PASS: Verify against official docs before planning; flag unverified claims as `UNVERIFIED PREMISE`

```text
FAIL: "Tool X has daemon mode with Web UI" — accepted without checking Tool X docs
PASS: "Tool X daemon mode: verify against official docs before including in plan"
```

## References

- [ADR Pattern — Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) (last_verified: 2025-01)
- [RFCs as Engineering Culture — Martin Fowler](https://martinfowler.com/articles/exploring-tech-radar.html) (last_verified: 2024-11)
- [Shape Up — Basecamp](https://basecamp.com/shapeup) (last_verified: 2024-09)

- [references/interview-guide.md](references/interview-guide.md)
- [references/rfc-template.md](references/rfc-template.md)

## Verification Checklist

- [ ] Pre-coding interview completed: understood need, scope boundaries, and technical constraints
- [ ] Scope document explicitly states what is IN and OUT of scope
- [ ] ADR written for each architecturally-significant decision with alternatives considered
- [ ] External dependencies identified and confirmed before planning milestones
- [ ] Step 0 MANDATORY: all third-party tool capabilities verified against official docs (no conditional skip)
- [ ] Success criteria quantified (e.g., p95 < 300ms, not "make it fast")
- [ ] RFC shared with stakeholders for feedback before coding begins
- [ ] Risks documented with specific mitigation strategies
- [ ] Assumption Audit completed: all external claims verified, all "will/can" statements classified as claims vs plan steps

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Scope creep mid-implementation | OUT-of-scope items not explicitly stated in planning phase | Add explicit OUT section to scope doc; defer new requests to follow-up iteration |
| Stakeholder rejects design after implementation | RFC shared too late or not shared at all | Share one-pager RFC early in planning phase; schedule async feedback window |
| Team misses deadline by 2x | Dependencies not identified during planning | Map all external dependencies upfront; add buffer time for unblocking blocked items |
| ADR documented but not followed (known issue: ADR becomes shelfware) | ADR not linked to implementation tasks or review gates | Convert ADR decisions to checklist items in the implementation plan; review ADR compliance at code review stage |
| [WARN] Gotcha: planning with fake precision (estimates in hours) creates false confidence | Overly precise estimates ignored; low-precision estimates (t-shirt sizes) more accurate | Use t-shirt sizing (S/M/L/XL) for early estimates; only commit to hours after spike/prototype validates scope |
