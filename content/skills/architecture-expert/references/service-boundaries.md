# Service Boundaries

Bounded-context partitioning determines where services split, what each owns, and how they communicate. The goal: minimize coupling between services while keeping each autonomous and independently deployable.

## Decide service boundaries by

| Signal | Strong boundary | Weak boundary |
|--------|-----------------|---------------|
| Change rate | Different teams ship at different cadences | Same team, same release train |
| Data ownership | Separate lifecycle, separate storage | Shared tables, shared schema evolution |
| Failure isolation | One failing part must not take down another | Tightly coupled availability |
| Scaling profile | Different traffic/latency characteristics | Same traffic profile, scales together |
| Business capability | Distinct capability with its own vocabulary | Cross-cutting concern without clear owner |

## Boundary rules

- **Data is private by default.** A service owns its tables/collections; other services read only via its API or events. NEVER share a database schema between services without a documented reason.
- **Communicate by contract, not by internals.** Publish an API contract (OpenAPI) or event schema; consumers depend on the contract, not the implementation.
- **One capability, one owner.** Every capability has exactly one responsible team; ownership is explicit in the repository and ADRs.
- **Split on volatility, not on noun.** Two "related" entities (e.g., document + metadata) may belong in one service if they change and scale together; split only when lifecycle, scale, or team cadence diverge.

## Boundary anti-patterns

- [X] "Shared kernel" databases where every service reads the same tables — creates hidden coupling and blocks independent deployment.
- [X] Splitting services so finely that a single feature change spans 5+ repos — latency, transaction, and coordination costs exceed the benefit.
- [OK] Start as a modular monolith with explicit module boundaries; extract a service only when a boundary demonstrably pulls apart.

## Verification checklist

- [ ] Every capability has exactly one owning service/team
- [ ] No cross-service direct DB access (only API/events)
- [ ] Contracts versioned; breaking changes follow the deploy-first, change-contract-second rule
- [ ] Boundary choice recorded in an ADR with rejected alternatives
