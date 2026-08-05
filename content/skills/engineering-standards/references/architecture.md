# Architecture Patterns Reference

## Scope

Architectural quality standards for this project codebases. This file covers pattern
selection guidance for common architectures. Deep system design, trade-off
matrices, and ADR authoring belong to `architecture-expert` skill.

## Pattern Quick Reference

| Pattern | When to use | When NOT to use | Key risk |
|---|---|---|---|
| Modular monolith | Single team, <50k LOC, domain cohesion low | Multi-team, need independent scaling | Becoming a big ball of mud |
| Microservices | Multi-team, independent scaling, clear bounded contexts | Single team, distributed system expertise low | Operational complexity, network latency |
| Hexagonal (ports-adapters) | Domain logic isolation, testability critical | Simple CRUD, no domain complexity | Abstraction overhead for simple cases |
| CQRS | Read/write asymmetry, complex queries | Simple CRUD, eventual consistency unacceptable | Stale reads, event synchronization |
| Event-driven | Async workflows, loose coupling, audit trail | Request-response semantics, low latency required | Eventual consistency, debugging complexity |
| Event Sourcing | Full audit trail, temporal queries, state reconstruction | Simple state, storage cost concern | Replay complexity, schema evolution |
| Saga | Distributed transactions across services | Single-service transactions | Compensation logic complexity |
| Outbox pattern | Reliable event publishing with DB writes | No event publishing needed | Dual-write complexity |

## Selection Criteria

1. Team size and Conway's Law: architecture follows communication paths
2. Domain complexity: DDD bounded contexts for complex domains
3. Deployment frequency: microservices enable independent deploys
4. Scaling needs: identify which dimensions scale independently
5. Operational maturity: microservices require observability + on-call

## this project Context

- Go microservices (api-gateway, message-broker): microservices + gRPC
- Python/FastAPI (AI service): modular monolith evolving to microservices
- Node.js/TypeScript (web client): modular monolith
- 55+ provider integrations: adapter pattern + strategy pattern
- Request flows: Saga pattern for distributed transactions

## Architecture Anti-patterns

- Big ball of mud: no clear boundaries, everything depends on everything
- Distributed monolith: microservices deployed as a monolith (shared DB, tight coupling)
- Premature microservices: splitting before domain boundaries are clear
- Shared database across services: couples deployment cycles
- Synchronous chains: cascading failures, no bulkheads

## Boundary

- Deep system design, ADR authoring, trade-off matrices: -> `architecture-expert` skill
- API contract design (REST/gRPC/GraphQL): -> `openapi-expert` / `golang-expert`
- This file = pattern SELECTION guidance at the engineering-standards level.
