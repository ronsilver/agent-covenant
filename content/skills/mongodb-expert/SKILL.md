---
name: mongodb-expert
description: "MongoDB document modeling, schema design, aggregation pipelines, transactions, change streams, and driver usage for Go and Python. Use when building document databases with flexible schemas, analytics pipelines, CDC, or migrating to AWS DocumentDB. Trigger: MongoDB, aggregation, indexing, transactions. Do NOT trigger for: relational DB design, SQL queries, PostgreSQL/MySQL aggregation queries, window functions, caching patterns."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: data
  status: stable
---
# MongoDB Expert

**MongoDB Atlas + DocumentDB: schemas, aggregations and CDC.**

## Core Stack

- Database: MongoDB Atlas (analytics database), AWS DocumentDB compatible
- Drivers: Go `mongo-driver`, Python `motor` (async)
- Patterns: Embed vs Reference, aggregation pipelines, change streams
- Operations: Multi-doc transactions, indexes, Atlas Search

## Schema Design

| Pattern | Use When | Example |
|---|---|---|
| Embed | Data read together, rarely changes independently | Record + line items |
| Reference | Entities accessed independently, many-to-many | User -> Events |
| Bucket | Time-series, IoT, event streams | Metrics per hour/day |

```go
type Record struct {
    ID         primitive.ObjectID `bson:"_id,omitempty"`
    UserID     string             `bson:"user_id"`
    Amount     int64              `bson:"amount"`     // units
    Category   string             `bson:"category"`
    Items      []RecordItem       `bson:"items"`       // embedded
    CreatedAt  time.Time          `bson:"created_at"`
}
```

## Aggregation Pipeline

```go
pipeline := mongo.Pipeline{
    {{Key: "$match", Value: bson.D{{Key: "user_id", Value: "usr_123"}}}},
    {{Key: "$group", Value: bson.D{
        {Key: "_id", Value: "$category"},
        {Key: "total", Value: bson.D{{Key: "$sum", Value: "$amount"}}},
        {Key: "count", Value: bson.D{{Key: "$sum", Value: 1}}},
    }}},
    {{Key: "$sort", Value: bson.D{{Key: "total", Value: -1}}}},
}
cursor, err := collection.Aggregate(ctx, pipeline)
```

## Indexes

```go
// Compound index for query patterns
indexModel := mongo.IndexModel{
    Keys: bson.D{
        {Key: "customer_id", Value: 1},
        {Key: "created_at", Value: -1},
    },
}
collection.Indexes().CreateOne(ctx, indexModel)
```

- Index on query fields in ESR order (Equality -> Sort -> Range)
- Use `explain()` to verify index usage

## Change Streams (CDC)

```go
stream, err := collection.Watch(ctx, mongo.Pipeline{})
for stream.Next(ctx) {
    var changeEvent bson.M
    stream.Decode(&changeEvent)
    // process insert/update/delete event
}
```

## Constraints

- NEVER use unbounded arrays in documents (can exceed 16MB limit)
- NEVER skip indexes on query fields (full collection scan)
- NEVER use `$lookup` without indexes on foreign field
- ALWAYS use `context.Context` with timeouts on all operations
- ALWAYS use transactions for multi-doc atomic updates
- ALWAYS monitor slow queries via Atlas profiler
- NEVER store unencrypted PII/CHD in MongoDB documents

## Overview

MongoDB Atlas is team document database for semi-structured data, flexible schemas, and high-write workloads (analytics database). This skill covers document schema design (embed vs reference), aggregation pipelines for analytics, compound and multikey index strategies, multi-document ACID transactions via sessions, change streams for CDC, and AWS DocumentDB compatibility for migration scenarios.

## Quick Reference

| Pattern | Decision Rule | Max Size |
|---|---|---|
| Embed | Data read together, sub-doc < 16MB total | 16MB/doc hard limit |
| Reference | Entity accessed independently, M:N relations | No limit (separate collection) |
| Bucket | Time-series, event streams, 1 doc per hour/day | 16MB/doc hard limit |
| Index | ESR rule: Equality → Sort → Range fields | 64 indices/collection max |
| Change Streams | Sequenced per shard, exactly-once with idempotency | 16MB event batch |
| Transactions | Multi-doc ACID, max 60s duration | 1K doc limit per txn |

## Workflow

1. **Design documents** — Identify entity relationships. Embed sub-documents that are always read together and rarely change independently. Reference entities that are queried separately or have many-to-many relationships.
2. **Build indexes** — Apply ESR order: Equality filters first, Sort keys second, Range scans last. Use `explain("executionStats")` to verify IXSCAN (not COLLSCAN). Add compound indexes for multi-field queries.
3. **Write aggregation pipelines** — Chain stages: `$match` (early filter) → `$group`/`$sort` → `$project` (shape output). Use `$lookup` sparingly — prefer embedded docs. Add indexes on `$lookup` foreign fields.
4. **Implement change streams** — Open `collection.Watch()` for CDC. Process in order per document key. Use `resumeAfter` with checkpoint token for at-least-once delivery.
5. **Use transactions** — For multi-document atomicity: start session → start transaction → execute operations → commit. Keep transactions under 1000 documents and 60 seconds.
6. **Monitor performance** — Atlas profiler for slow queries (>100ms). Index usage stats. Connection pool utilization. Replica set lag.

## Anti-patterns

FAIL: Unbounded array growth in a single document (will exceed 16MB).
```go
// BAD: Embedded array grows forever
type AuditLog struct {
    Entries []AuditEntry `bson:"entries"` // thousands over time → 16MB+
}
```
```go
// GOOD: Separate collection for high-cardinality sub-items
type AuditLog struct {
    LogID   string `bson:"_id"`
}
// Audit entries in separate collection with log_id reference
```

FAIL: Using `$lookup` without indexes on the foreign field.
```go
// BAD: $lookup with no index on user_id in events collection
pipeline := bson.A{
    bson.D{{Key: "$lookup", Value: bson.D{
        {Key: "from", Value: "events"},
        {Key: "foreignField", Value: "user_id"},
    }}}
}
```
```go
// GOOD: Create index first, then $lookup
eventsCollection.Indexes().CreateOne(ctx, mongo.IndexModel{
    Keys: bson.D{{Key: "user_id", Value: 1}},
})
```

FAIL: No timeout on database operations (goroutine leak under load).
```go
// BAD: Default context — no timeout
cursor, _ := collection.Find(context.Background(), bson.D{})
```
```go
// GOOD: Explicit timeout
ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
cursor, _ := collection.Find(ctx, bson.D{})
```

## References

| Resource | URL | Last verified |
|---|---|---|
| MongoDB — Schema Design Best Practices | https://www.mongodb.com/docs/manual/core/data-modeling-introduction/ | 2026-05-25 |
| MongoDB — Aggregation Pipeline Reference | https://www.mongodb.com/docs/manual/aggregation/ | 2026-05-25 |
| MongoDB — Change Streams Production Best Practices | https://www.mongodb.com/docs/manual/changeStreams/ | 2026-05-25 |

- [references/aggregation.md](references/aggregation.md)
- [references/indexing.md](references/indexing.md)

## Verification Checklist

- [ ] Document schema designed with correct embed vs reference decision for access patterns
- [ ] Indexes created following ESR order (Equality → Sort → Range) with `explain()` verification
- [ ] `context.Context` with timeout used on all database operations
- [ ] Aggregation pipeline stages ordered with early `$match` filter
- [ ] No unbounded arrays in documents (16MB doc size limit)
- [ ] `$lookup` foreign fields indexed to prevent full collection scans
- [ ] Change streams idempotent with `resumeAfter` token for at-least-once delivery

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Query returns COLLSCAN instead of IXSCAN | Missing index on filter fields or wrong index order | Run `explain("executionStats")`; create compound index matching query ESR order |
| `Document too large` error (16MB+ limit) | Embedded array grew unbounded over time | Split high-cardinality data into separate collection with reference |
| Change stream disconnects on replica set election | `resumeAfter` token lost after primary change | Use `startAfter` instead of `resumeAfter` for global resumption across elections |
| Known issue: `$lookup` with `let` variables silently returns empty arrays | Variable reference syntax error in `let` block or pipeline stage mismatch | Verify `let` variable names match exactly in `$expr`; test the pipeline stage in isolation before composing |
| Gotcha: `$text` search requires a `text` index | Missing `text` index causes full COLLSCAN even on small collections | Create `text` index on the search field: `db.collection.createIndex({field: "text"})`; verify with `explain()` |
| [WARN] Known limitation: change stream `$lookup` results may be stale | Change events captured before `$lookup` target documents are fully committed | Use post-image or transactional consistency guarantees; avoid `$lookup` in change stream pipeline when cross-document consistency is required |
