---
name: diagram-expert
description: "Creation of architecture diagrams with C4 Model (Context, Containers, Components, Code), UML (sequence, class, activity), data flow diagrams DFD, entity-relationship models ERD, and deployment architectures. Tools: Mermaid, PlantUML, Structurizr. Use when creating architecture diagrams, visualizing system design, documenting data flows, building C4 context/container/component diagrams, or generating sequence diagrams from API flows. Trigger: C4 Model, Mermaid, architecture diagrams. Do NOT trigger for: UI mockups or wireframes that are not text-based diagrams."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: process
  status: stable
---
# Diagram Expert

**Architecture diagrams: C4 Model, sequence, ERD, deployment.**

## C4 Model (Levels of Abstraction)

| Level | Audience | Shows |
|---|---|---|
| Context | Everyone | System + users + external systems |
| Container | Technical | Apps, DBs, file systems |
| Component | Dev team | Modules, services, APIs |
| Code | Developers | Classes, functions (auto-generated) |

### C4 Container Example (Mermaid)
```
graph TB
    User((User))
    Mobile[Mobile App]
    SessionAPI[Session API]
    AccountAPI[Account API]
    external service[external service Adapters]
    DB[(PostgreSQL)]
    
    User --> Mobile
    Mobile --> SessionAPI
    SessionAPI --> AccountAPI
    AccountAPI --> external service
    AccountAPI --> DB
```

## Sequence Diagram

```
sequenceDiagram
    Client->>+SessionAPI: POST /v1/sessions
    SessionAPI->>+AccountAPI: POST /v1/accounts
    AccountAPI->>+external service: validate()
    external service-->>-AccountAPI: {status: ok}
    Items-->>-ItemWorkflow: {item_id, status}
    SessionAPI-->>-Client: {session_url}
```

## ERD (Entity Relationship)
```
erDiagram
    USER ||--o{ ACCOUNT : creates
    ACCOUNT ||--|| SESSION : "may have"
    USER {
        string id PK
        string name
        string region
    }
    ACCOUNT {
        string id PK
        int quota_units
        string status
    }
```

## Deployment Diagram
```
graph LR
    subgraph AWS
        CF[CloudFront] --> ALB
        ALB --> ECS[ECS Service]
        ECS --> RDS[(RDS PostgreSQL)]
        ECS --> Redis[(ElastiCache)]
    end
```

## Constraints
- NEVER use images for diagrams in docs (not diffable in git)
- ALWAYS use Mermaid/PlantUML (text-based, version-controllable)
- NEVER skip context level (C4 Level 1) for new architecture proposals
- ALWAYS include legend for custom symbols or abbreviations

## Overview

Diagrams bridge the gap between abstract architecture decisions and shared team understanding. This skill covers text-based diagram creation (Mermaid, PlantUML, Structurizr) across C4 Model levels, UML, ERD, DFD, and deployment diagrams — all git-diffable and version-controllable.

## Quick Reference

| Diagram Type | Tool | Best For |
|---|---|---|
| C4 Context (L1) | Structurizr / Mermaid | System landscape for stakeholders |
| C4 Container (L2) | Structurizr / Mermaid | App + DB boundaries for dev team |
| Sequence | Mermaid / PlantUML | API interaction flows and time ordering |
| ERD | Mermaid / PlantUML | Database schema design and reviews |
| Deployment | Mermaid / PlantUML | Infrastructure topology and network zones |

## Workflow

1. **Identify audience** — Stakeholders need Context (L1), developers need Container (L2) + Component (L3), implementers need Code (L4).
2. **Choose C4 level** — Always start at Context (L1); never skip levels. Only drill to the level that adds clarity.
3. **Select tool** — Mermaid for quick inline docs (renders in GitHub/Notion). Structurizr for full C4 workspace. PlantUML for complex UML (state machines, activity diagrams).
4. **Write as text** — Use `.mmd`, `.puml`, or `.dsl` files. Keep diagrams in `/docs/diagrams/` next to source.
5. **Review with stakeholders** — Validate that every arrow and box matches the current architecture. Update when architecture changes.
6. **Version control** — Commit alongside code changes. Never commit generated PNG/SVG — generate from source in CI.

## Anti-patterns

FAIL: Embedded images in documentation (not diffable, no history).
```markdown
<!-- BAD: binary image, cannot review in PR -->
![Architecture](diagrams/arch-v3-final-real.png)
```
```markdown
<!-- GOOD: text-based, diffable in every PR -->
```mermaid
graph TB; User-->API; API-->DB;
``` ```

FAIL: Diagram-only design without text documentation.
```
BAD: A giant C4 diagram with no written context — viewers cannot infer constraints or rationale.
GOOD: Each diagram is preceded by a paragraph explaining the key decisions the diagram visualizes.
```

FAIL: Over-detailed diagrams at wrong abstraction level.
```
BAD: Showing every class and method in a Context (L1) diagram meant for executives.
GOOD: L1 has 5-8 boxes (users, systems, boundaries). Save classes for L4 auto-generated docs.
```

## References

| Resource | URL | Last verified |
|---|---|---|
| C4 Model — Official Guide | https://c4model.com/ | 2026-05-25 |
| Mermaid — Official Docs | https://mermaid.js.org/ | 2026-05-25 |
| PlantUML — Language Guide | https://plantuml.com/guide | 2026-05-25 |

- [references/c4-model.md](references/c4-model.md)
- [references/mermaid-syntax.md](references/mermaid-syntax.md)
- [references/sequence-patterns.md](references/sequence-patterns.md)

## Verification Checklist
- [ ] C4 Context (L1) diagram created before lower-level diagrams
- [ ] All diagrams are text-based (Mermaid/PlantUML/Structurizr) — no embedded images
- [ ] Diagram audience matched to abstraction level (stakeholders → L1, devs → L2+)
- [ ] Legend included for custom symbols or abbreviations
- [ ] Diagrams committed alongside code changes in `/docs/diagrams/`
- [ ] Each diagram preceded by explanatory text (context and key decisions)

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Mermaid diagram renders incorrectly on GitHub | Unsupported syntax; whitespace indentation issues | Use standard Mermaid flowchart/sequence syntax; align indentation; test rendering in GitHub preview before commit |
| C4 diagram causes confusion with stakeholders | Wrong abstraction level (too detailed for audience) | Drop to Context (L1) — max 8 boxes; save Container (L2) for developer audience only |
| Sequence diagram doesn't show async flows | Synchronous arrows used for all interactions | Use dotted lines for async responses; add note labels for timing or latency expectations |
| Deployment diagram missing network boundaries | No network zones (public, private, isolated) represented | Add subgraph blocks for VPC, public subnet, private subnet, and security group boundaries |
| Mermaid flowchart direction breaks on complex graphs (known limitation) | Mermaid layout engine reorders nodes unpredictably at scale | Use `subgraph` blocks to enforce visual grouping; reduce node count per diagram; split into multiple diagrams
