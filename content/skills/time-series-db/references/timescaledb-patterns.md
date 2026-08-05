# TimescaleDB Advanced Patterns

## Compression
```sql
ALTER TABLE metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'customer_id',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('metrics', INTERVAL '7 days');
```

## Continuous Aggregates
```sql
CREATE MATERIALIZED VIEW hourly_units_shipped
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    customer_id,
    SUM(quantity) as units_shipped,
    COUNT(*) as tx_count
FROM metrics
GROUP BY 1, 2
WITH NO DATA;

SELECT add_continuous_aggregate_policy('hourly_units_shipped',
    start_offset => INTERVAL '2 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);
```

## Data Retention
```sql
SELECT add_retention_policy('metrics', INTERVAL '90 days');
-- Drops chunks older than 90 days automatically
-- Chunks in compressed hypertables: drop policy applies to compressed data
```

## Query Optimization
```sql
-- Use time_bucket for aggregation
SELECT time_bucket('1 day', time) as day,
       customer_id,
       approx_percentile(0.50, quantity) as p50,
       approx_percentile(0.99, quantity) as p99
FROM metrics
WHERE time > NOW() - INTERVAL '30 days'
GROUP BY 1, 2;

-- Gap filling
SELECT time_bucket_gapfill('1 hour', time) as hour,
       customer_id,
       locf(SUM(quantity)) as units_shipped
FROM metrics
WHERE time > NOW() - INTERVAL '24 hours'
GROUP BY 1, 2;
```

## Partitioning for Multi-Tenant
```sql
-- Each customer gets time-based chunks
-- Compression segment_by = customer_id groups customer data together
-- Query planner pushes customer_id filter to compressed chunks
```
