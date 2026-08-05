---
name: architecture-expert
description: "Software architecture design (modular monolith, decoupled microservices, event-driven, hexagonal/ports-adapters), formal API definition (REST, gRPC, GraphQL, async events), technology stack selection with weighted decision matrices, distributed patterns (CQRS, Event Sourcing, Saga, Outbox), deployment strategies (canary, blue-green, rolling, feature flags), and bounded context partitioning with ADRs. Use when designing greenfield systems, choosing between architectural patterns, evaluating monolith vs microservices trade-offs, defining API contracts across services, selecting technology stacks, planning zero-downtime deployments, or documenting architecture decisions. Trigger: system architecture, API contracts, deployment strategies. Do NOT trigger for: single-service CRUD applications without distributed system concerns."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: process
  status: stable
---

# Architecture Expert

**System architecture: patterns, API design, stack selection, deployment strategies, bounded contexts, ADRs.**

## Architectural Styles

→ Deep patterns + Saga + Outbox: [references/patterns.md](references/patterns.md)

| Style                   | Best For                        | Avoid When                           |
| ----------------------- | ------------------------------- | ------------------------------------ |
| Modular Monolith        | Single team, <5 domains         | 10+ teams needing independent deploy |
| Microservices           | Independent deploy, polyglot    | Data joins across services needed    |
| Event-Driven            | Async workflows, loose coupling | Simple CRUD, no async needs          |
| Hexagonal/Ports-Adapter | Testability, swappable adapters | Small services (overhead > value)    |
| CQRS + Event Sourcing   | Audit trail, state machines     | Simple CRUD, no audit compliance     |

## API Design & Contracts

→ Event-driven patterns + schema: [references/event-driven.md](references/event-driven.md)

### API Style Selection

| Requirement                                   | API Style                            |
| --------------------------------------------- | ------------------------------------ |
| Public/external consumers                     | REST (OpenAPI 3.1)                   |
| Internal service-to-service, high performance | gRPC (Protobuf)                      |
| Flexible client queries, mobile first         | GraphQL                              |
| Cross-service async coordination              | Async Events (CloudEvents + SQS/SNS) |
| Real-time bidirectional                       | WebSocket / SSE                      |

### Contract Design Rules

- Contract-first: define API spec BEFORE implementation
- Version in URL path (`/v1/`, `/v2/`) or `Accept` header
- Additive changes only in active versions (never remove fields)
- Deprecation: `Sunset` header + 6-month migration window
- Idempotency: `Idempotency-Key` header for POST/PATCH/PUT

## Stack Selection Framework

1. **Define constraints**: latency target (p95 < Xms), throughput (N TPS), data size, team expertise
2. **List candidates**: 2-4 options that could work
3. **Weight criteria**: performance (0.3), team skill (0.25), operational cost (0.2), ecosystem fit (0.15), vendor risk (0.1)
4. **Score each candidate** (1-5 per criterion)
5. **Select winner + document why others rejected** (ADR)

### Stack Defaults

| Domain           | Default                         | Why                                           |
| ---------------- | ------------------------------- | --------------------------------------------- |
| Backend services | Go + Gin + GORM/pgx             | Team expertise, performance, go-kit ecosystem |
| AI/ML pipelines  | Python + FastAPI + LangGraph    | Bedrock integration, data science ecosystem   |
| Frontend/SDKs    | TypeScript + Next.js 14 + React | SSR performance, team expertise               |
| IaC              | Terraform/OpenTofu              | AWS native, policy enforcement                |
| Data warehouse   | Columnar database               | Analytics at scale                            |

## Deployment Strategies

→ Service boundaries: [references/service-boundaries.md](references/service-boundaries.md)

| Strategy       | Downtime | Rollback Time | Risk   | Use               |
| -------------- | -------- | ------------- | ------ | ----------------- |
| Rolling Update | 0        | Minutes       | Low    | Standard deploys  |
| Blue-Green     | 0        | Seconds       | Low    | Critical services |
| Canary         | 0        | Seconds       | Lowest | High-risk changes |
| Feature Flag   | 0        | Instant       | Lowest | Gradual rollout   |

### Canary Deployment Pattern

```
1. Deploy new version alongside old (10% traffic)
2. Monitor: error rate, latency p95, business metrics
3. If healthy for 5 min -> increase to 50%
4. If healthy for 10 min -> 100%
5. If ANY metric degrades -> instant rollback
```

## ADR Template

```markdown
# ADR-###: Title

Status: Proposed | Accepted | Deprecated
Date: YYYY-MM-DD
Context: problem + constraints
Decision: what we're doing (one sentence)
Alternatives: what we considered + why rejected
Consequences: what becomes easier/harder
```

## Anti-Patterns

- Distributed monolith (can't deploy independently)
- Shared database (bypasses service API contract)
- Entity services (CRUD wrappers, no domain logic)
- Nano-services (1 function = 1 service)
- No bulkhead (slow service blocks all callers)

## Core Rules

- NEVER design distributed system without async boundaries + fallbacks
- NEVER share databases between services (API is the contract)
- NEVER skip observability in architecture design
- NEVER optimize for scale before proving need
- ALWAYS document architecture decisions as ADRs
- ALWAYS define bounded contexts before designing services

## Overview

System architecture decisions are the highest-leverage technical choices in any project. This skill provides patterns, frameworks, and decision matrices for designing software architectures (modular monolith through microservices), defining API contracts, selecting technology stacks, planning deployment strategies, and documenting decisions via ADRs — all within team ecosystem constraints.

## Quick Reference

| Decision            | Framework                                        | Output                           |
| ------------------- | ------------------------------------------------ | -------------------------------- |
| Architecture style  | Trade-off matrix (6 criteria × 4 styles)         | ADR with rejected alternatives   |
| API protocol        | Requirement-query table (perf, consumers, async) | OpenAPI / proto / GraphQL schema |
| Stack selection     | Weighted decision matrix (5 axes)                | technology-choices ADR           |
| Service boundary    | Bounded context map (DDD)                        | Context map + data ownership     |
| Deployment strategy | Risk × rollback-time × downtime matrix           | Deployment plan per service      |

## Workflow

1. **Discover bounded contexts** — Map domains with event-storming or DDD workshops. Define data ownership per context.
2. **Select architecture style** — Evaluate modular monolith vs microservices vs event-driven against team size, deploy independence needs, and data join requirements.
3. **Design API contracts** — Contract-first: write OpenAPI 3.1 / proto / CloudEvents spec before implementation. Decide REST vs gRPC vs async per bounded context boundary.
4. **Build stack selection matrix** — Weight criteria (perf, team skill, ops cost, ecosystem fit, vendor risk). Score 2-4 candidates. Document rejection rationale.
5. **Choose deployment strategy** — Select rolling vs blue-green vs canary based on service criticality and rollback requirements. Define metrics gates.
6. **Write ADRs** — Document every non-trivial decision with context, decision, alternatives considered, and consequences.

## Anti-patterns

FAIL: Distributed monolith: services that cannot be deployed or scaled independently.

```go
// BAD: Document creation requires Renderer AND Auth to be up
func CreateDocument(ctx context.Context, d Document) error {
    user, err := authClient.GetUser(ctx, d.OwnerID) // synchronous coupling
    template, err := renderClient.GetTemplate(ctx, d.TemplateID)
    // ...
}
```

PASS: Clear bounded contexts with async boundaries.

```go
// GOOD: Document emits event, Renderer consumes async
func CreateDocument(ctx context.Context, d Document) error {
    // own data, own logic, own lifecycle
    return docRepo.Save(ctx, d)
}
// Processor listens on event bus, not blocking on core call
```

FAIL: Shared database across services bypassing API contracts.

```sql
-- BAD: Service A reads Service B's tables directly
SELECT * FROM events WHERE entity_id = ?;
```

PASS: Each service owns its data; cross-service queries go through APIs.

FAIL: Nano-services: one function per service (deploy complexity > value).

```
BAD: 12 microservices for a CRUD form (auth-svc, validate-svc, save-svc, notify-svc...)
GOOD: 1 modular monolith or 3 bounded services (write-svc, read-svc, notify-svc)
```

## References

| Resource                            | URL                                                           | Last verified |
| ----------------------------------- | ------------------------------------------------------------- | ------------- |
| Martin Fowler — Microservices Guide | https://martinfowler.com/microservices/                       | 2026-05-25    |
| AWS Well-Architected Framework      | https://docs.aws.amazon.com/wellarchitected/latest/framework/ | 2026-05-25    |
| Google Cloud Architecture Framework | https://cloud.google.com/architecture/framework               | 2026-05-25    |

## Verification Checklist

- [ ] Bounded contexts defined before service boundaries designed
- [ ] API contract defined first (contract-first) before implementation begins
- [ ] ADR written for every non-trivial architecture decision with rejected alternatives
- [ ] Deployment strategy selected with rollback plan documented
- [ ] No shared database across services (API is the contract)
- [ ] Observability designed in from the start (logs, metrics, traces per service)

## Troubleshooting

| [WARN] Known issue                                                            | Likely cause                                                                             | Fix                                                                                                      |
| ----------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Services cannot be deployed independently                                     | Distributed monolith — synchronous coupling between bounded contexts                     | Define async boundaries; add event-driven communication; decouple with message queue                     |
| API breaking changes cause downstream failures                                | No contract-first approach; versioning absent                                            | Switch to contract-first with OpenAPI; version APIs at `/v1/`, `/v2/`                                    |
| Deployment rollback takes > 10 minutes                                        | No blue-green or canary strategy configured                                              | Implement blue-green with load balancer switch or canary with metrics gates                              |
| Teams blocked waiting for other teams to finish                               | Nano-services causing dependency chains                                                  | Merge nano-services into modular monolith within bounded context                                         |
| Event-driven systems hide latency from bounded context boundaries (edge case) | Async events can queue up silently; no visibility into end-to-end timing across contexts | Add trace_id propagation across event boundaries; monitor queue depth and processing latency per context |
