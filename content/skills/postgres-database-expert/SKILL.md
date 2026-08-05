---
name: postgres-database-expert
description: "Design and manage PostgreSQL databases with proper schema design, query optimization, GORM/pgx patterns, and Redis caching. Use when designing schemas, writing or optimizing SQL queries, analyzing EXPLAIN plans, managing indexes, implementing connection pooling, or setting up Redis caching layers. For zero-downtime migration strategies (expand-contract, backfills, rollbacks), consult the postgres references directory for migration guidance. Trigger: PostgreSQL, SQL, migration, query optimization, pgx, GORM, EXPLAIN ANALYZE. Do NOT trigger for: NoSQL databases, MongoDB, DynamoDB design, application-level caching strategies, N+1 query optimization in application code (use performance-expert)."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: data
  status: stable
---

# PostgreSQL Database Expert

**Design and manage PostgreSQL databases with proper schema, migrations, query optimization, and caching.**

**See [references/overview.md](references/overview.md)**

## Core Stack

**See [references/stack.md](references/stack.md)**

- Database: PostgreSQL 16
- Go: GORM + pgx/v5
- Migrations: golang-migrate
- Caching: Redis

## Naming Conventions

**See [references/naming.md](references/naming.md)**

- Tables: `snake_case`, plural
- Columns: `snake_case`
- PKs: `id` (UUID)
- FKs: `{table}_id`
- Indexes: `idx_{table}_{columns}`

## Schema Rules
- UUIDs for PKs | BIGINT for value amounts (NEVER FLOAT) | ALWAYS TIMESTAMPTZ
- Soft deletes with `deleted_at` | NOT NULL by default

→ [references/schema-design.md](references/schema-design.md) | [references/naming.md](references/naming.md)

## Migrations
- Safe: `ADD COLUMN`, `CREATE INDEX CONCURRENTLY`
- Dangerous: `ALTER TYPE`, `CREATE INDEX`(without CONCURRENTLY)
- EXPLAIN red flags: `Seq Scan` | high cost `Sort` | `Nested Loop`

→ [references/migrations.md](references/migrations.md) | [references/performance.md](references/performance.md)

## Workflow

**See [references/workflow.md](references/workflow.md)**

1. Schema design (UUIDs, BIGINT, TIMESTAMPTZ)
2. Safe migrations (up + down, CONCURRENTLY)
3. Index strategy (B-tree, composite, GIN)
4. Query optimization (EXPLAIN ANALYZE)
5. ORM patterns (GORM, pgx)
6. Redis caching (cache-aside, TTL)

## Security
Parameterized queries only | NEVER plaintext passwords | dedicated roles per service
→ [references/security.md](references/security.md) | [references/code-patterns.md](references/code-patterns.md)

## Constraints
- NEVER `FLOAT` for value → `BIGINT` in units
- NEVER `TIMESTAMP` without zone → `TIMESTAMPTZ`
- NEVER `OFFSET` on large tables → cursor-based pagination
- NEVER `SELECT *` in production → explicit columns
- NEVER `CREATE INDEX` without `CONCURRENTLY` on production
- ALWAYS write `up` + `down` migrations
- ALWAYS `EXPLAIN ANALYZE` before optimizing
- ALWAYS parameterized queries (NEVER string concat)
- ALWAYS set connection pool limits
- ALWAYS invalidate cache on data mutation

## Overview

PostgreSQL 16 schema design with UUID primary keys, `BIGINT` for value amounts, `TIMESTAMPTZ` for temporal data, and `snake_case` naming conventions. Paired with Redis cache-aside patterns and safe migrations using `CREATE INDEX CONCURRENTLY` and expand-contract for breaking changes.

## Quick Reference

| Concept | Rule | Example |
|---------|------|--------|
| PKs | UUID (not serial) | `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` |
| Value | BIGINT in units | `value BIGINT NOT NULL` |
| Timestamps | TIMESTAMPTZ always | `created_at TIMESTAMPTZ NOT NULL DEFAULT now()` |
| Indexes | CONCURRENTLY on production | `CREATE INDEX CONCURRENTLY idx_items_status ON items(status)` |
| Migrations | Up + Down always | `golang-migrate` with separate up/down files |
| Pagination | Cursor-based (no OFFSET) | `WHERE id > $1 ORDER BY id LIMIT 50` |
| Soft Deletes | `deleted_at TIMESTAMPTZ` | `WHERE deleted_at IS NULL` |

## Workflow

1. Design schema: UUID PKs, `BIGINT` for value, `TIMESTAMPTZ`, `snake_case` naming, NOT NULL by default
2. Write safe migrations: `ADD COLUMN` is safe, `ALTER TYPE` needs caution — always write up + down
3. Index strategy: B-tree for equality, composite for multi-column filters, GIN for full-text search; always `CONCURRENTLY` on production
4. Optimize queries: run `EXPLAIN ANALYZE`, watch for `Seq Scan` (needs index), high-cost `Sort`, or `Nested Loop` on large tables
5. Implement caching: cache-aside pattern with Redis, 5min default TTL, invalidate on mutation
6. Connection pooling: `pgx` pool with `MaxConns: 20` and statement timeout

## Anti-patterns

FAIL: Using FLOAT for value
```sql
-- BAD
amount DECIMAL(10,2) -- rounding errors
```
PASS: Use BIGINT in units
```sql
-- GOOD
value BIGINT NOT NULL CHECK (value >= 0)
```

FAIL: TIMESTAMP without timezone
```sql
-- BAD
deleted_at TIMESTAMP -- ambiguous across timezones
```
PASS: Always use TIMESTAMPTZ
```sql
-- GOOD
deleted_at TIMESTAMPTZ
```

FAIL: OFFSET pagination on large tables
```sql
-- BAD — scans all skipped rows
SELECT * FROM items ORDER BY id LIMIT 50 OFFSET 10000;
```
PASS: Cursor-based pagination
```sql
-- GOOD — constant time per page
SELECT * FROM items WHERE id > $1 ORDER BY id LIMIT 50;
```

FAIL: SELECT * in production code
```sql
-- BAD — fetches unused columns, breaks if schema changes
SELECT * FROM items WHERE id = $1;
```
PASS: Explicit column list
```sql
-- GOOD
SELECT id, value, status, created_at FROM items WHERE id = $1;
```

FAIL: Creating index without CONCURRENTLY
```sql
-- BAD — blocks writes
CREATE INDEX idx_items_tenant ON items(tenant_id);
```
PASS: Safe with CONCURRENTLY
```sql
-- GOOD — non-blocking
CREATE INDEX CONCURRENTLY idx_items_tenant ON items(tenant_id);
```

FAIL: N+1 query — fetching related entities in a loop
```go
items, _ := db.Items.FindAll()
for _, item := range items {
    subitems, _ := db.SubItems.FindByItemID(item.ID)  // N queries!
}
```
PASS: Eager loading with Preload
```go
items, _ := db.Items.Preload("SubItems").FindAll()  // 2 queries total
```
```sql
-- Single query with JOIN
SELECT i.*, s.* FROM items i
LEFT JOIN item_subitems s ON s.item_id = i.id
WHERE i.id = ANY($1);
```

FAIL: ORDER BY on unindexed column causing Seq Scan + Sort
```sql
-- BAD: Seq Scan + Sort on 1M rows
SELECT id, value, created_at
FROM items
WHERE tenant_id = $1
ORDER BY created_at DESC;
```
PASS: Add composite index matching ORDER BY
```sql
CREATE INDEX CONCURRENTLY idx_items_tenant_created
ON items(tenant_id, created_at DESC);
-- NOW: Index Scan Backward — constant-time
```

## References

- [PostgreSQL 16 Documentation](https://www.postgresql.org/docs/16/) · last_verified: 2025-05
- [Use the Index, Luke — PostgreSQL Indexing Guide](https://use-the-index-luke.com/) · last_verified: 2025-05
- [golang-migrate Documentation](https://github.com/golang-migrate/migrate) · last_verified: 2025-05

## Verification Checklist

- [ ] All value columns use `BIGINT` in units (never FLOAT/DECIMAL)
- [ ] All timestamp columns use `TIMESTAMPTZ` (never TIMESTAMP without zone)
- [ ] Production indexes created with `CONCURRENTLY` (never blocking writes)
- [ ] Migrations have both `up` and `down` files
- [ ] Pagination uses cursor-based pattern, not `OFFSET`
- [ ] Queries use parameterized inputs (no string concatenation)
- [ ] `EXPLAIN ANALYZE` run on new/modified query paths

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Query slow despite index | Wrong index type or column order | Run `EXPLAIN ANALYZE`; verify index matches filter + sort columns |
| Migration blocks writes on production | `CREATE INDEX` without `CONCURRENTLY` | Drop index; re-create with `CREATE INDEX CONCURRENTLY` |
| Connection pool exhausted | `MaxConns` too low or slow queries holding connections | Increase pool size; add statement timeout; check for long-running queries |
| Cache returns stale data | Cache not invalidated on write path | Add cache invalidation in the mutation code path |
| Index created CONCURRENTLY but not used by query planner (known issue: statistics stale) | Table statistics not updated after index creation | Run `ANALYZE` after `CREATE INDEX CONCURRENTLY` to refresh planner statistics |
| MVCC bloat causes table size to grow unbounded (autovacuum can't keep up) | Long-running transactions prevent vacuum from reclaiming dead tuples | Set `idle_in_transaction_session_timeout`; monitor `pg_stat_user_tables.n_dead_tup`; tune autovacuum scale_factor |
| Parameter sniffing: same plan used for different parameter values, causing slow queries on some inputs | PostgreSQL caches plan from first execution with specific params | Use `SET plan_cache_mode = 'force_custom_plan'` for skewed data; or use dynamic SQL with literals |

| [WARN] `VACUUM FULL` blocks writes and causes replication lag | VACUUM FULL takes ACCESS EXCLUSIVE lock; triggers WAL burst on replicas | Use `pg_repack` instead of VACUUM FULL; schedule during maintenance window with application drain |
| GORM AutoMigrate creates a constraint with a name that conflicts with an existing FK | AutoMigrate generates constraint names dynamically; name collision on concurrent migration | Disable AutoMigrate in production; use explicit migration with named ALTER TABLE ADD CONSTRAINT |
| Limitation: pg_stat_statements resets on server restart, losing long-term query performance history | pg_stat_statements is in-memory; restart or failover resets all accumulated statistics | Snapshot pg_stat_statements to a logging table every hour via pg_cron; monitor trends not absolute values |
