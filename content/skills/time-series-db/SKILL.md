---
name: time-series-db
description: "Time-series database patterns for cloud-native metrics and analytics: TimescaleDB, InfluxDB, and Amazon Timestream selection; continuous aggregates, retention policies, downsampling, and integration with Prometheus/Grafana. Use when storing business metrics over time, building custom business dashboards, designing high-frequency event storage, or querying time-bucketed aggregations. Trigger: time-series, TimescaleDB, InfluxDB, Prometheus, Grafana, hypertable, continuous aggregate, retention policy. Do NOT trigger for: relational PostgreSQL schema design, NoSQL document stores, Kafka event streaming."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: data
  status: stable
  tags: [timeseries, timescaledb, influxdb, metrics, analytics, grafana, prometheus]
compatibility: Integrates with PostgreSQL (TimescaleDB extension), Prometheus remote write, Grafana, and data warehouse analytics pipeline
---

# Time-Series Databases

**See [references/overview.md](references/overview.md)** for schema design, aggregation queries, retention policies, and Grafana integration.

## When to Use Each

```
TimescaleDB (preferred for cloud-native projects):
  + PostgreSQL-compatible (same tooling, same ops team)
  + SQL queries, JOINs with relational data
  + Use for: business throughput, API latency
  Use when: data needs JOINs with entities/events tables

InfluxDB:
  + Better write throughput at very high cardinality
  + Flux query language
  Use when: IoT-style high-frequency sensor data (not typical platform)

Prometheus:
  + Metrics scraping + short retention (15 days default)
  + PromQL for dashboards and alerting
  Use for: infra/app metrics -- NOT business KPIs (ephemeral)

Amazon Timestream:
  + Serverless, AWS-native
  Use when: Lambda-sourced metrics without PostgreSQL ops overhead
```

## TimescaleDB Core Patterns

```sql
-- Hypertable: auto-partition by time
CREATE TABLE business_metrics (
    time        TIMESTAMPTZ NOT NULL,
    entity_id UUID        NOT NULL,
    region         TEXT        NOT NULL,
    status      TEXT        NOT NULL,
    quantity BIGINT     NOT NULL,
    latency_ms  INT
);
SELECT create_hypertable('business_metrics', 'time');

-- Continuous aggregate: pre-compute hourly rollups
CREATE MATERIALIZED VIEW business_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    entity_id,
    region,
    count(*) FILTER (WHERE status = 'completed') AS completed_count,
    sum(quantity) FILTER (WHERE status = 'completed') AS completed_volume,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99_latency
FROM business_metrics
GROUP BY bucket, entity_id, region;

-- Retention: drop data older than 90 days
SELECT add_retention_policy('business_metrics', INTERVAL '90 days');
```

## Quick Rules

- Chunk interval: 1 day for high-frequency, 1 week for lower
- Always index on `(time DESC, entity_id)` — most queries filter both
- Use continuous aggregates for any query spanning >1 hour of raw data
- Prometheus handles infra metrics; TimescaleDB handles business metrics

**→ [references/overview.md](references/overview.md)** for compression, downsampling ladder, Grafana datasource config, and data warehouse sync patterns.

## Overview

Time-series database selection and patterns for cloud-native metrics: TimescaleDB (preferred — PostgreSQL compatible with JOINs to relational data), InfluxDB (high cardinality), Prometheus (infra metrics, short retention), and Amazon Timestream (serverless). Hypertables with automatic partitioning by time and continuous aggregates are the core pattern.

## Quick Reference

| Database | Best For | Key Feature | Limitations |
|----------|----------|-------------|------------|
| TimescaleDB | Business metrics with SQL JOINs | Hypertables + continuous aggregates + retention policies | Requires PostgreSQL instance |
| InfluxDB | IoT / very high cardinality | Flux query, high write throughput | Separate ops, no JOINs |
| Prometheus | Infra metrics, short retention | PromQL, scrape-based, 15d default | Not for business KPIs |
| Amazon Timestream | Serverless, Lambda-sourced metrics | Managed, auto-scaling, SQL-like | Cross-region latency, AWS-locked |

## Workflow

1. Select database: TimescaleDB for business metrics needing JOINs, Prometheus for infra metrics (ephemeral), Timestream for serverless Lambda metrics
2. For TimescaleDB: create hypertable with `time` as partition column, set chunk interval (1d for high frequency, 1w for low)
3. Create continuous aggregate for any query spanning >1h of raw data (e.g. hourly business throughput)
4. Set retention policy: `SELECT add_retention_policy('table', INTERVAL '90 days')`
5. Configure Grafana datasource: connect to TimescaleDB via PostgreSQL driver, Prometheus via native
6. Index on `(time DESC, entity_id / other filter columns)` for query performance

## Anti-patterns

FAIL: Querying raw hypertable for frequent dashboard refreshes
```sql
-- BAD: scans years of raw data every dashboard load
SELECT count(*), time_bucket('1h', time) AS bucket
FROM business_metrics
WHERE time > now() - INTERVAL '30 days'
GROUP BY bucket;
```
PASS: Use continuous aggregate for pre-computed rollups
```sql
-- GOOD: reads pre-aggregated data
SELECT bucket, completed_count, completed_volume
FROM business_hourly
WHERE bucket > now() - INTERVAL '30 days';
```

FAIL: No retention policy — unbounded storage growth
```sql
-- BAD — data accumulates forever
-- No retention policy configured
```
PASS: Always set retention policy
```sql
-- GOOD
SELECT add_retention_policy('business_metrics', INTERVAL '90 days');
```

FAIL: Using Prometheus for business KPIs
```
# BAD — Prometheus is for infra, not business metrics
business_throughput_total{entity_id="123"}  # cardinality explosion
```
PASS: Prometheus for infra, TimescaleDB for business
```
# GOOD — infra metrics in Prometheus
container_memory_usage_bytes{namespace="businesss"}
# Business metrics in TimescaleDB hypertables
```

FAIL: No index on time + filter columns
```sql
-- BAD — Seq Scan on every time-bounded query
CREATE TABLE business_metrics (time TIMESTAMPTZ, entity_id UUID, ...);
-- No index created
```
PASS: Always index on time DESC + filter columns
```sql
-- GOOD
CREATE INDEX idx_business_metrics_time_entity
ON business_metrics (time DESC, entity_id);
```

## References

- [TimescaleDB Documentation](https://docs.timescale.com/) · last_verified: 2025-05
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/) · last_verified: 2025-05
- [Amazon Timestream Developer Guide](https://docs.aws.amazon.com/timestream/latest/developerguide/) · last_verified: 2025-05

- [references/vendor-comparison.md](references/vendor-comparison.md)
- [references/timescaledb-patterns.md](references/timescaledb-patterns.md)

## Verification Checklist

- [ ] Database selected matches use case: TimescaleDB for business metrics, Prometheus for infra, Timestream for serverless
- [ ] Hypertable created with appropriate chunk interval (1d high-freq, 1w low-freq)
- [ ] Continuous aggregate defined for any query spanning >1h of raw data
- [ ] Retention policy configured (unbounded storage prevented)
- [ ] Index on `(time DESC, entity_id)` for common query patterns
- [ ] Prometheus not used for business KPIs (cardinality explosion risk)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Dashboard query takes >10s | Querying raw hypertable instead of continuous aggregate | Create continuous aggregate for hourly/daily rollups; point dashboard to the aggregate |
| Disk usage grows without bound | No retention policy on hypertable | `SELECT add_retention_policy('table', INTERVAL '90 days')` |
| Prometheus OOM on startup | Too many series (high cardinality labels) | Remove high-cardinality labels like `user_id` or `entity_id`; use TimescaleDB for business dimensions |
| Continuous aggregate refresh fails after schema change (known issue: materialized view staleness) | Underlying hypertable column renamed or dropped | Re-create continuous aggregate after DDL changes; use `WITH (timescaledb.refresh_lag)` to control staleness window |

| [WARN] TimescaleDB chunk size mismatch causes slow INSERT perf on high-cardinality data | Default chunk_time_interval (7 days) too large for 100K+ entities writing every second | Set `chunk_time_interval` to 6-24 hours for high-ingestion workloads; monitor chunk count |
