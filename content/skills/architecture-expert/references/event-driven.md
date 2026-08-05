# Event-Driven Architecture

## When to Use
- Async workflows, loose coupling needed
- Multiple consumers of same data
- Cross-domain coordination without tight coupling

## Event Types
| Type | Purpose | Example |
|---|---|---|
| Domain Event | Business state change | ShipmentReserved |
| Integration Event | Cross-service notification | OrderShipped |
| Command | Intent to change state | ProcessReturn |
| Query | Request for data | GetCustomerSummary |

## Event Schema Design
```json
{
  "specversion": "1.0",
  "type": "com.example.items.processed",
  "source": "/items/item_abc",
  "id": "evt_xyz",
  "time": "2026-05-16T14:30:00Z",
  "datacontenttype": "application/json",
  "data": { "item_id": "item_abc", "status": "completed" }
}
```
Follow CloudEvents spec. Include correlation_id for tracing.

## Event Ordering
- Per aggregate: guaranteed order (same partition/queue group)
- Cross-aggregate: eventual consistency (out of order by design)
- Use sequence numbers for deduplication

## Dead Letter Queue
- Unprocessable events -> DLQ after N retries
- Alert on DLQ depth > threshold
- Manual investigation + replay capability
