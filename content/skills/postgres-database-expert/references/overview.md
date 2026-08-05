# PostgreSQL Database Expert Overview

## Skill Purpose

Design and implement production-grade PostgreSQL databases with proper schema design, migrations, query optimization, GORM/pgx patterns, and Redis caching for Go microservice stack.

## Core Principles

- **Schema-first**: Design schema before writing application code
- **Migration-driven**: All schema changes via versioned migrations (never manual DDL in production)
- **Index discipline**: Create indexes based on actual query patterns, measure first
- **Connection pooling**: Always use PgBouncer or pgx pool — never raw connections per request
- **Security**: Row-level security, least privilege, encrypted at rest

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Database | PostgreSQL 15+ |
| ORM (simple queries) | GORM v2 |
| Driver (complex/performance) | pgx v5 |
| Connection pool | pgxpool or PgBouncer |
| Migrations | golang-migrate |
| Cache | Redis 7+ |
| Cache client | go-redis v9 |

## Reference Navigation

| Topic | File | When to Use |
|-------|------|-------------|
| Tech stack details | `stack.md` | Setup, dependencies |
| Naming conventions | `naming.md` | Schema design |
| Schema patterns | `schema-design.md` | Table structure |
| Migration patterns | `migrations.md` | Adding/changing schema |
| Query optimization | `performance.md` | Slow queries |
| Dev workflow | `workflow.md` | Day-to-day |
| Security patterns | `security.md` | Access control |

## Quick Health Check

```sql
-- Active connections by state
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;

-- Slow queries (>1s)
SELECT query, calls, mean_exec_time::int, total_exec_time::int
FROM pg_stat_statements
WHERE mean_exec_time > 1000
ORDER BY mean_exec_time DESC LIMIT 10;

-- Table sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(oid))
FROM pg_class WHERE relkind = 'r'
ORDER BY pg_total_relation_size(oid) DESC LIMIT 10;

-- Missing indexes (sequential scans on large tables)
SELECT relname, seq_scan, idx_scan
FROM pg_stat_user_tables
WHERE seq_scan > idx_scan AND n_live_tup > 10000
ORDER BY seq_scan DESC;
```
