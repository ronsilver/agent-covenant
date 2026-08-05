---
name: mysql-expert
description: "MySQL/MariaDB administration: InnoDB internals, master-slave/group replication, partitioning, buffer pool and redo log tuning, online migrations with pt-online-schema-change, support for Aurora MySQL and RDS MySQL on AWS. Use when tuning InnoDB buffer pool, configuring replication, performing online schema changes, optimizing slow queries, or managing AWS RDS/Aurora MySQL. Trigger: MySQL InnoDB, pt-online-schema-change, buffer pool tuning, replication lag, Aurora MySQL. Do NOT trigger for: PostgreSQL schema design, MongoDB aggregation pipelines, general NoSQL database administration."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: data
  status: stable
---
# MySQL Expert

**MySQL/MariaDB: InnoDB tuning, replication, and AWS managed.**

## Core Stack

- Database: MySQL 8.0 / MariaDB 10.6 / Amazon Aurora MySQL / RDS MySQL
- Engine: InnoDB (buffer pool, redo log, doublewrite buffer)
- Replication: Master-slave, Group Replication, Aurora read replicas
- Tools: pt-online-schema-change, mysqldump, mysqlbinlog
- JDBC: MySQL Connector/J

## InnoDB Tuning

```ini
[mysqld]
innodb_buffer_pool_size = 70%_of_RAM    # single most important param
innodb_log_file_size = 2G                # larger = less checkpoint IO
innodb_flush_log_at_trx_commit = 1       # 1=ACID, 2=fast+crashable
innodb_flush_method = O_DIRECT           # avoid double buffering
innodb_io_capacity = 2000                # SSD: 2000, HDD: 200
```

## Replication

| Type | Use When |
|---|---|
| Async Master-Slave | Read scaling, reporting |
| Semi-Sync | Reduced data loss risk |
| Group Replication | HA with auto-failover |
| Aurora Read Replicas | AWS managed, <100ms lag |

## Online Schema Changes

```bash
# NEVER ALTER TABLE directly on large tables (locks)
pt-online-schema-change \
  --alter "ADD COLUMN external_id VARCHAR(64)" \
  --execute \
  D=appdb,t=items
```



## Constraints

- NEVER run `ALTER TABLE` on >1M rows without pt-online-schema-change
- NEVER skip backups before schema changes
- NEVER use MyISAM engine (no transactions, crash-unsafe)
- ALWAYS monitor buffer pool hit rate (target: >99%)
- ALWAYS use parameterized queries (never string concat)
- NEVER disable `sql_mode` strict mode (`STRICT_TRANS_TABLES`)
- NEVER use `SELECT *` in production queries (column drift breaks clients)

## Overview

MySQL (InnoDB) is a transactional relational database for production workloads. This skill covers InnoDB tuning (buffer pool, redo log, flush methods), replication topology (async, semi-sync, Group Replication, Aurora), online schema changes via pt-online-schema-change, query optimization through EXPLAIN plan analysis, and AWS-managed MySQL deployment (RDS, Aurora).

## Quick Reference

| Parameter | Recommended | Impact |
|---|---|---|
| `innodb_buffer_pool_size` | 70% of RAM | Single most important InnoDB tuning |
| `innodb_log_file_size` | 2GB | Reduces checkpoint IO frequency |
| `innodb_flush_log_at_trx_commit` | 1 (ACID) / 2 (faster) | Durability vs performance trade-off |
| `innodb_flush_method` | O_DIRECT | Avoids OS double buffering |
| `innodb_io_capacity` | 2000 (SSD) | Background IOPS limit |
| `max_connections` | 200 (+ proxy) | Connection pool saturation guard |

## Workflow

1. **Tune InnoDB** — Set `innodb_buffer_pool_size` to 70% of RAM. Set `innodb_log_file_size` to 2GB. Set `innodb_flush_method=O_DIRECT`. Verify with `SHOW ENGINE INNODB STATUS\G`.
2. **Configure replication** — Choose topology: async for reporting slaves, semi-sync for reduced data-loss risk, Group Replication for HA auto-failover, Aurora for AWS-managed HA.
3. **Perform online schema changes** — Never `ALTER TABLE` directly on >1M rows. Use `pt-online-schema-change` with `--check-alter` and `--max-load` thresholds. Run during low traffic.
4. **Optimize queries** — Run `EXPLAIN` on slow queries. Verify `type` is not `ALL` (full scan). Add covering indexes. Check `rows_examined` vs actual rows.
5. **Monitor buffer pool** — Target hit rate > 99% (`SHOW STATUS LIKE 'innodb_buffer_pool_reads%'`). Increase buffer pool if hit rate drops below threshold.
6. **Backup before changes** — Always take a snapshot or `mysqldump` before schema changes. Test restore from backup regularly.

## Anti-patterns

FAIL: Running `ALTER TABLE` directly on production tables >1M rows (acquires table lock).
```sql
-- BAD: Locks table for minutes/hours on large tables
ALTER TABLE items ADD COLUMN external_id VARCHAR(64);
```
```bash
# GOOD: pt-online-schema-change with zero-downtime
pt-online-schema-change --alter "ADD COLUMN external_id VARCHAR(64)" \
  --execute D=appdb,t=items
```

FAIL: Using MyISAM engine (no transactions, table-level locking, crash-unsafe).
```sql
-- BAD: MyISAM — no transactions, data loss on crash
CREATE TABLE items (id INT) ENGINE=MyISAM;
```
```sql
-- GOOD: InnoDB with ACID compliance
CREATE TABLE items (id INT) ENGINE=InnoDB;
```

FAIL: Using `SELECT *` in production code (column order drift breaks clients).
```python
# BAD: SELECT * — breaks when columns are added/reordered
cursor.execute("SELECT * FROM items")
row = cursor.fetchone()
return {"id": row[0], "amount": row[1]}
```
```python
# GOOD: Explicit column list — stable contract
cursor.execute("SELECT id, quantity, status FROM items")
```

## References

| Resource | URL | Last verified |
|---|---|---|
| MySQL 8.0 — InnoDB Tuning Guide | https://dev.mysql.com/doc/refman/8.0/en/innodb-tuning.html | 2026-05-25 |
| Percona Toolkit — pt-online-schema-change | https://docs.percona.com/percona-toolkit/pt-online-schema-change.html | 2026-05-25 |
| Amazon Aurora MySQL — Best Practices | https://docs.aws.amazon.com/AmazonRDS/latest/AuroraMySQLGuide/ | 2026-05-25 |

- [references/pt-online-schema.md](references/pt-online-schema.md)
- [references/replication.md](references/replication.md)

## Verification Checklist

- [ ] `innodb_buffer_pool_size` set to 70% of available RAM
- [ ] Buffer pool hit rate > 99% confirmed via `SHOW STATUS` monitoring
- [ ] Online schema changes use `pt-online-schema-change` for tables >1M rows
- [ ] Backup taken before any schema change operation
- [ ] Replication topology chosen and verified (async/semi-sync/group per requirements)
- [ ] No MyISAM tables in production (all InnoDB for ACID compliance)
- [ ] `SELECT *` eliminated from production queries (explicit column lists)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Buffer pool hit rate < 95% | `innodb_buffer_pool_size` too small for working dataset | Increase buffer pool size; consider data archiving or partitioning |
| Replication lag > 5 minutes | Slave running long read queries or under-provisioned | Optimize queries; use `pt-slave-delay` for reporting; scale up slave instance |
| `pt-online-schema-change` fails with timeout | Table has triggers or foreign key constraints | Add `--alter-foreign-keys-method=auto`; increase `--chunk-time` parameter |
| Known issue: Aurora MySQL read replica lag spikes during writer DDL | Aurora replicas pause apply during DDL on writer to maintain consistency | Schedule DDL during low traffic; use `pt-online-schema-change` which minimizes Aurora replica lag vs direct ALTER TABLE |
| [WARN] Gotcha: `utf8mb4` vs `utf8mb3` character set causes index size limit errors | MySQL `utf8mb3` max index length is 767 bytes per column (3 bytes/char = 255 chars) | Use `utf8mb4` with `ROW_FORMAT=DYNAMIC` or `COMPRESSED` for longer varchar indexes; verify with `SHOW CREATE TABLE` |
