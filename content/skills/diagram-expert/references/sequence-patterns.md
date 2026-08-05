# Sequence Diagram Patterns

## API Flow with Error Handling
```mermaid
sequenceDiagram
    Client->>+API: POST /v1/items
    API->>+DB: BEGIN transaction
    API->>+external service: validate(token,value)
    alt ok
        external service-->>API: {status:ok}
        API->>DB: INSERT item
        API-->>Client: 201 Created
    else rejected
        external service-->>API: {status:rejected, code:51}
        API->>DB: ROLLBACK
        API-->>Client: 422 Unprocessable
    else timeout
        external service--xAPI: timeout 5s
        API->>DB: ROLLBACK
        API-->>Client: 504 Gateway Timeout
    end
```

## Async Event Flow
```mermaid
sequenceDiagram
    participant P as Orders
    participant Q as SQS Queue
    participant N as Notifications
    participant E as Email
    P->>Q: ShipmentReserved event
    Q->>N: consume event
    N->>E: send confirmation email
```

## Key Rules
- ALWAYS include error paths (alt/else)
- Participants: use descriptive names
- Notes for important context
- NEVER omit failure modes
