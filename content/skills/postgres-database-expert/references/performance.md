# Query Performance & Optimization

## Step 1: Identify Slow Queries

```sql
-- Enable pg_stat_statements (must be in shared_preload_libraries)
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top 10 slowest queries by mean time
SELECT
    LEFT(query, 100) AS query,
    calls,
    mean_exec_time::numeric(10,2) AS mean_ms,
    total_exec_time::numeric(10,2) AS total_ms,
    rows / calls AS avg_rows
FROM pg_stat_statements
WHERE calls > 10
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Reset stats after optimization
SELECT pg_stat_statements_reset();
```

## Step 2: EXPLAIN ANALYZE

```sql
-- Always use ANALYZE + BUFFERS for real execution data
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT p.*, m.name AS customer_name
FROM events p
JOIN customers m ON m.id = p.owner_id
WHERE p.status = 'pending'
  AND p.created_at > NOW() - INTERVAL '1 hour';
```

**Red flags in EXPLAIN output:**
- `Seq Scan` on large tables — needs index
- `cost=` is very high — N+1 or missing index
- `actual rows` >> `estimated rows` — stale statistics
- `Nested Loop` with large row counts — may need Hash Join

## Step 3: Index Strategies

```sql
-- Partial index: only index active records (smaller, faster)
CREATE INDEX idx_events_pending ON events(created_at)
    WHERE status = 'pending' AND deleted_at IS NULL;

-- Covering index: avoids heap access (index-only scan)
CREATE INDEX idx_events_list ON events(owner_id, created_at DESC)
    INCLUDE (value_units, status, currency_code);

-- Expression index
CREATE INDEX idx_events_lower_email ON users(LOWER(email));

-- Update statistics if planner is making bad choices
ANALYZE events;
```

## Step 4: Query Optimization Patterns

### Avoid SELECT *

```sql
-- Bad: fetches all columns, bloats network
SELECT * FROM events WHERE owner_id = $1;

-- Good: only needed columns
SELECT id, value_units, status, created_at
FROM events WHERE owner_id = $1;
```

### Use CTEs for Readability, Not Performance

```sql
-- CTE is NOT always faster (PostgreSQL 12+ inlines them by default)
-- Use MATERIALIZED only when forcing a subquery boundary helps
WITH recent_events AS MATERIALIZED (
    SELECT * FROM events
    WHERE created_at > NOW() - INTERVAL '1 day'
)
SELECT owner_id, SUM(value_units) FROM recent_events
GROUP BY owner_id;
```

### Pagination: Keyset > OFFSET

```sql
-- Bad: OFFSET gets slower as page increases (full table scan)
SELECT * FROM events ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- Good: keyset pagination (constant performance)
SELECT * FROM events
WHERE created_at < $last_seen_created_at
   OR (created_at = $last_seen_created_at AND id < $last_seen_id)
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

### Batch Inserts

```go
// Bad: N individual inserts
for _, p := range events {
    db.Create(&p)
}

// Good: single batch insert
db.CreateInBatches(events, 500)

// pgx: COPY for bulk loads
_, err = pool.CopyFrom(
    ctx,
    pgx.Identifier{"events"},
    []string{"id", "owner_id", "value_units"},
    pgx.CopyFromRows(rows),
)
```

## Connection Pooling (pgxpool)

```go
poolConfig, _ := pgxpool.ParseConfig(os.Getenv("DATABASE_URL"))
poolConfig.MaxConns = 20           // max connections
poolConfig.MinConns = 5            // keep warm
poolConfig.MaxConnLifetime = 30 * time.Minute
poolConfig.MaxConnIdleTime = 5 * time.Minute
poolConfig.HealthCheckPeriod = 1 * time.Minute

pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
```

## Vacuum & Maintenance

```sql
-- Check for bloat / dead tuples
SELECT relname, n_dead_tup, n_live_tup, last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 10000
ORDER BY n_dead_tup DESC;

-- Manual vacuum on hot tables
VACUUM ANALYZE events;

-- Full vacuum (locks table — use carefully)
VACUUM FULL events;
```
