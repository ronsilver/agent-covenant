---
name: dynamodb-expert
description: "DynamoDB table design based on access patterns (single-table design): PK/SK strategies, secondary indexes LSI/GSI, streams for event-driven, on-demand vs provisioned capacity, transactions, and cost optimization. Use when designing DynamoDB tables for cloud-native services, implementing single-table design, configuring GSI/LSI for query patterns, using DynamoDB Streams with Lambda triggers, or writing aws-sdk-go-v2 DynamoDB code. Trigger: DynamoDB, single-table design, access patterns. Do NOT trigger for: relational database schema design or SQL optimization questions."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: data
  status: stable
---
# DynamoDB Expert

**Single-table design, access patterns, streams and optimization.**

## Core Stack

- Database: AWS DynamoDB (on-demand or provisioned)
- Design: Single-table, PK/SK, GSI/LSI overloaded keys
- Streams: DynamoDB Streams + Lambda triggers (CDC)
- Transactions: TransactWriteItems for atomic multi-table ops
- SDK: `aws-sdk-go-v2` + `example.org/dynamodb`

## Single-Table Design

```
PK              SK              | GSI1PK          GSI1SK          | Attributes
----------------------------------------------------------------------------
CUST#cust456    METADATA        |                                 | {name, status}
CUST#cust456    ITEM#item001    | ITEM#item001     ACTIVE          | {value, kind}
CUST#cust456    ITEM#item002    | ITEM#item002     ACTIVE          | {value, kind}
TOK#tok789      METADATA        |                                 | {type, info}
```

- PK = primary entity, SK = sub-entity or relationship
- GSI1 overloaded for different query patterns
- NEVER design tables around relational normalization

## Access Patterns

```go
// Get customer + all items (single query with begins_with)
input := &dynamodb.QueryInput{
    TableName:              aws.String("example-data"),
    KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :sk)"),
    ExpressionAttributeValues: map[string]types.AttributeValue{
        ":pk": &types.AttributeValueMemberS{Value: "CUST#cust456"},
        ":sk": &types.AttributeValueMemberS{Value: "ITEM#"},
    },
}

// Get items by status via GSI
input := &dynamodb.QueryInput{
    TableName:              aws.String("example-data"),
    IndexName:              aws.String("GSI1"),
    KeyConditionExpression: aws.String("GSI1PK = :pk"),
    ExpressionAttributeValues: map[string]types.AttributeValue{
        ":pk": &types.AttributeValueMemberS{Value: "ITEM#item001"},
    },
}
```

## Streams + Lambda

```go
func handler(ctx context.Context, event events.DynamoDBEvent) error {
    for _, record := range event.Records {
        switch record.EventName {
        case "INSERT":
            newItem := record.Change.NewImage
            // process new item
        case "MODIFY":
            // handle status change
        }
    }
    return nil
}
```

- Guaranteed ordering per PK. Exactly-once with idempotency.
- Batch size: 100 records default. Max 1,000.

## Capacity

| Mode | Use When |
|---|---|
| On-Demand | Unknown/spiky workloads, new services |
| Provisioned | Predictable traffic, cost optimization |

- On-demand: ~7x more expensive per request, zero management
- Provisioned: reserve capacity, use auto-scaling
- NEVER switch between modes more than once per 24h per table

## Constraints

- NEVER design tables before listing all access patterns (NoSQL design = access-first)
- NEVER use `Scan` in production (full table read) — use Query with GSI
- NEVER exceed 400KB item size limit
- NEVER use more than 5 GSI per table (20 default limit, 5 is operational safe)
- ALWAYS use `TransactWriteItems` for multi-table atomic updates
- ALWAYS set TTL on ephemeral data (sessions, tokens)
- NEVER store PII in PK/SK (visible in all GSIs)

## Security

- ALWAYS grant IAM least-privilege per table and per action — never `dynamodb:*` on all tables
- ALWAYS enable KMS encryption (SSE-KMS) on tables with CMK rotation
- NEVER put PII in PK/SK or GSI keys — store hashed references, PII in encrypted attributes
- ALWAYS restrict stream consumers via IAM conditions and validate Lambda event sources

## Overview

DynamoDB is team primary NoSQL database for high-throughput, low-latency workloads. Unlike relational databases, DynamoDB design starts with access patterns, not data normalization. This skill covers single-table design, PK/SK modelling, GSI/LSI indexing, streams-based CDC, capacity planning, and cost optimization using `aws-sdk-go-v2` and `example.org/dynamodb`.

## Quick Reference

| Concept | Rule | Why |
|---|---|---|
| PK/SK design | One table, overloaded keys | Single-table = single query for any access pattern |
| GSIs | Max 5 per table | Each GSI doubles write cost and storage |
| Items | Max 400KB | DynamoDB hard limit; design for <100KB |
| Streams | ORDERED per PK | Guaranteed sequence for CDC consumers |
| Transactions | TransactWriteItems | Cross-item atomicity but 2x cost |
| Scan | NEVER in production | Full table read = O(N) cost, unpredictable latency |

## Workflow

1. **List all access patterns** — Interview every consumer. Collect every query (`getCustomerById`, `listItemsByStatus`, `getItemsByDateRange`).
2. **Design PK/SK** — PK = primary entity identifier (`CUST#{id}`). SK = sub-entity or sortable timestamp (`ITEM#{ts}#{id}`). Overload PK/SK for different entity types in the same table.
3. **Define GSIs** — For each access pattern that cannot be satisfied by PK/SK alone, add a GSI with overloaded PK/SK. Never exceed 5 GSIs.
4. **Choose capacity mode** — On-demand for new/spiky services. Provisioned with auto-scaling for predictable workloads. Switch at most once per 24h.
5. **Configure streams** — Enable DynamoDB Streams for each table that needs CDC. Set Lambda batch size to 100 with bisect on error for poison-pill handling.
6. **Set TTL** — Enable TTL on ephemeral data (sessions, OTP codes, temporary tokens). DynamoDB deletes expired items within 48h at no extra cost.

## Anti-patterns

FAIL: Normalized relational schema in DynamoDB (joins via application code).
```go
// BAD: Separate tables with application-level JOIN
customer := getCustTable(ctx, "cust456")
items := getItemTable(ctx, "cust456") // second query
```
PASS: Single-table with hierarchical PK/SK.
```go
// GOOD: One query returns customer + all items
result, _ := table.Query(ctx, &dynamodb.QueryInput{
    KeyConditionExpression: aws.String("PK = :pk"),
})
```

FAIL: Using Scan for production queries.
```go
// BAD: Scan reads entire table
result, _ := table.Scan(ctx, &dynamodb.ScanInput{TableName: aws.String("example-data")})
```
```go
// GOOD: Query with specific PK + optional GSI
result, _ := table.Query(ctx, &dynamodb.QueryInput{
    KeyConditionExpression: aws.String("PK = :pk AND begins_with(SK, :prefix)"),
})
```

FAIL: Overloading a single GSI with too many distinct entity types (hot key).
```
BAD: GSI1PK = "STATUS#done" — every completed item maps to same partition key → throttling.
GOOD: GSI1PK = "STATUS#done#CUST#{tenant_id}" — distributes writes across partitions.
```

## References

| Resource | URL | Last verified |
|---|---|---|
| AWS DynamoDB — Best Practices | https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html | 2026-05-25 |
| Alex DeBrie — DynamoDB Book | https://www.dynamodbbook.com/ | 2026-05-25 |
| AWS re:Invent — Advanced DynamoDB Design | https://www.youtube.com/watch?v=HaEPXoXVf2k | 2026-05-25 |

- [references/advanced-patterns.md](references/advanced-patterns.md)
- [references/cost-optimization.md](references/cost-optimization.md)
- [references/operations.md](references/operations.md)
- [references/single-table-design.md](references/single-table-design.md)

## Verification Checklist
- [ ] All access patterns listed before designing PK/SK schema
- [ ] Single-table design used with overloaded PK/SK (no relational normalization)
- [ ] GSI count ≤ 5 per table (operational safe limit)
- [ ] Item size stays below 400KB DynamoDB limit (target < 100KB)
- [ ] TTL configured on ephemeral data (sessions, tokens)
- [ ] No `Scan` operations in production code — all access via `Query` with PK
- [ ] PII not stored in PK/SK (visible in all GSIs)
- [ ] IAM least-privilege per table; KMS encryption enabled; PII absent from keys

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Query returns only matching items for one entity type | GSII PK not overloaded; single entity type per partition | Overload GSI PK with prefix + entity type for multi-entity access pattern |
| High throttling on write-heavy partition | Hot key — one PK receiving disproportionate traffic | Add sharding suffix to PK; use write sharding pattern; distribute writes across partitions |
| Stream processing duplicate records | Lambda retry on failure without idempotency | Implement idempotency key dedup in stream handler; use `eventSourceMapping` with bisect on error |
| Item too large to write (ValidationException) | Item exceeds 400KB limit | Store large attributes in S3 with DynamoDB pointer; split into multiple items |
| DynamoDB auto-scaling lags behind traffic spikes (known limitation) | Provisioned capacity auto-scaling reacts to traffic, not ahead of it — takes 5-15 min to scale up | Use on-demand for spiky workloads; pre-warm provisioned capacity for known traffic events; implement application-level backpressure |
