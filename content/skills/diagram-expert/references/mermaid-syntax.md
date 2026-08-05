# Mermaid Diagram Syntax

## Sequence Diagram
```mermaid
sequenceDiagram
    Client->>+API: POST /v1/items
    API->>+external service: validate()
    external service-->>-API: {status: ok}
    API-->>-Client: 201 Created
    alt timeout
        external service--xAPI: timeout
        API-->>Client: 504
    end
```

## ER Diagram
```mermaid
erDiagram
    CUSTOMER ||--o{ SHIPMENT : creates
    CUSTOMER { string id PK; string name }
    SHIPMENT { string id PK; int quantity }
```

## Flowchart
```mermaid
flowchart LR
    A[Request] --> B{Valid?}
    B -->|Yes| C[Process]
    B -->|No| D[Reject]
```

## State Diagram
```mermaid
stateDiagram-v2
    [*] --> Pending
    Pending --> Processing
    Processing --> Approved
    Processing --> Declined
    Approved --> Refunded
```

## Gantt Chart
```mermaid
gantt
    title Sprint Plan
    section API
    Design :a1, 2026-05-01, 3d
    Build  :a2, after a1, 5d
```

## Deployment Diagram
```mermaid
graph TB
    subgraph AWS
        ALB --> ECS
        ECS --> RDS
    end
    subgraph On-Prem
        Legacy --> VPN
    end
    VPN --> ALB
```
