# Time-Series Databases — Overview

## TimescaleDB Schema Design (Generic Events)

```sql
-- Core hypertable: raw business events
CREATE TABLE business_events (
    time            TIMESTAMPTZ     NOT NULL,
    customer_id     UUID            NOT NULL,
    event_id      TEXT            NOT NULL,
    provider             TEXT            NOT NULL,
    status          TEXT            NOT NULL,   -- completed | failed | pending
    quantity    BIGINT          NOT NULL,
    category        TEXT            NOT NULL,
    latency_ms      INT,
    error_code      TEXT
);

-- Partition by 1 day (high insert volume)
SELECT create_hypertable(
    'business_events', 'time',
    chunk_time_interval => INTERVAL '1 day'
);

-- Indexes: time + customer for most queries
CREATE INDEX ON business_events (customer_id, time DESC);
CREATE INDEX ON business_events (provider, time DESC);

-- Compression: compress chunks older than 7 days (10-20x size reduction)
ALTER TABLE business_events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'customer_id, provider',
    timescaledb.compress_orderby = 'time DESC'
);
SELECT add_compression_policy('business_events', INTERVAL '7 days');

-- Retention: drop raw data older than 90 days (keep aggregates forever)
SELECT add_retention_policy('business_events', INTERVAL '90 days');
```

## Continuous Aggregates (Rollup Ladder)

```sql
-- Minute aggregate (for real-time dashboards)
CREATE MATERIALIZED VIEW business_1min
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 minute', time)   AS bucket,
    customer_id,
    provider,
    count(*)                        AS total,
    count(*) FILTER (WHERE status = 'completed') AS completed,
    sum(quantity) FILTER (WHERE status = 'completed') AS volume_cents,
    avg(latency_ms)                 AS avg_latency_ms,
    percentile_cont(0.95) WITHIN GROUP (ORDER BY latency_ms) AS p95_latency_ms
FROM business_events
GROUP BY bucket, customer_id, provider
WITH NO DATA;

SELECT add_continuous_aggregate_policy('business_1min',
    start_offset => INTERVAL '10 minutes',
    end_offset   => INTERVAL '1 minute',
    schedule_interval => INTERVAL '1 minute'
);

-- Hour aggregate (built from minute aggregate for efficiency)
CREATE MATERIALIZED VIEW business_1hr
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', bucket)   AS bucket,
    customer_id,
    provider,
    sum(total)                      AS total,
    sum(completed)                   AS completed,
    sum(volume_cents)               AS volume_cents
FROM business_1min
GROUP BY time_bucket('1 hour', bucket), customer_id, provider
WITH NO DATA;

-- Day aggregate
CREATE MATERIALIZED VIEW business_1day
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', bucket)    AS bucket,
    customer_id,
    sum(total) AS total, sum(completed) AS completed, sum(volume_cents) AS volume_cents
FROM business_1hr
GROUP BY time_bucket('1 day', bucket), customer_id
WITH NO DATA;
```

## Query Patterns

```sql
-- Current hour delivery rate per carrier (use minute aggregate)
SELECT provider,
    sum(completed)::float / NULLIF(sum(total), 0) AS delivery_rate,
    sum(volume_cents) / 100.0 AS volume_usd
FROM business_1min
WHERE bucket >= now() - INTERVAL '1 hour'
GROUP BY provider
ORDER BY volume_usd DESC;

-- Customer dashboard: last 30 days daily summary (use day aggregate)
SELECT bucket, sum(completed) AS business, sum(volume_cents)/100.0 AS revenue
FROM business_1day
WHERE customer_id = $1
  AND bucket >= now() - INTERVAL '30 days'
GROUP BY bucket
ORDER BY bucket;

-- Point-in-time latency (use raw table for last 7 days only)
SELECT time_bucket('5 minutes', time) AS bucket,
    percentile_cont(0.99) WITHIN GROUP (ORDER BY latency_ms) AS p99
FROM business_events
WHERE customer_id = $1
  AND time >= now() - INTERVAL '6 hours'
GROUP BY bucket
ORDER BY bucket;
```

## Grafana Datasource Config

```yaml
# datasources/timescaledb.yaml
apiVersion: 1
datasources:
  - name: TimescaleDB
    type: postgres
    url: timescaledb.internal.example:5432
    database: business_metrics
    user: grafana_ro
    secureJsonData:
      password: $GRAFANA_DB_PASSWORD
    jsonData:
      sslmode: require
      postgresVersion: 1500
      timescaledb: true          # enables time_bucket function in query builder
```

```sql
-- Grafana panel query (time series format)
-- Variable: $customer_id, $__timeFilter, $__interval
SELECT
    time_bucket('$__interval', bucket) AS time,
    sum(completed)::float / NULLIF(sum(total), 0) AS "Approval Rate"
FROM business_1min
WHERE customer_id = '$customer_id'
  AND $__timeFilter(bucket)
GROUP BY 1
ORDER BY 1;
```

## Downsampling Ladder

```
Raw events     → 90 days  (for forensics, exact queries)
1-min rollups  → 1 year   (real-time dashboards)
1-hour rollups → 3 years  (trend analysis)
1-day rollups  → forever  (business reporting)

Query routing rule:
  Range < 6h  → use raw (if < 90 days) or 1-min aggregate
  Range 6h-7d → use 1-min aggregate
  Range 7d-3m → use 1-hour aggregate
  Range > 3m  → use 1-day aggregate
```

## Data Warehouse Sync (Business Analytics)

```python
# Sync daily aggregate to data warehouse for analytics
# Run as scheduled ETL job

import boto3
import psycopg2

def sync_daily_to_warehouse(execution_date: str):
    # Read from TimescaleDB
    with psycopg2.connect(os.getenv("TIMESCALE_DSN")) as pg:
        rows = pg.execute(
            "SELECT * FROM metrics_1day WHERE bucket = %s",
            (execution_date,)
        ).fetchall()

    # Write to data warehouse staging table
    with warehouse_connect(**dw_config()) as dw:
        dw.execute("BEGIN")
        dw.execute(
            f"DELETE FROM metrics_daily_staging WHERE bucket = '{execution_date}'"
        )
        dw.executemany(
            "INSERT INTO metrics_daily_staging VALUES (%s, %s, %s, %s, %s)",
            rows
        )
        dw.execute("COMMIT")
```

## Production Gotchas

### Chunk Interval Must Match Query Window
```sql
-- Default chunk_time_interval is 7 days
-- If your queries always filter WHERE time > now() - interval '1 hour',
-- a 7-day chunk means every query scans a mostly-empty chunk
-- Rule: chunk_time_interval = 1-2x your most common query range

-- High-frequency (minute-level queries): 1 day
SELECT create_hypertable('business_events', 'time', chunk_time_interval => INTERVAL '1 day');

-- Low-frequency (daily queries): 1 week is fine
SELECT create_hypertable('daily_stats', 'time', chunk_time_interval => INTERVAL '1 week');
```

### Continuous Aggregate end_offset Must Be >= 1 Bucket
```sql
-- WRONG: end_offset => INTERVAL '0' causes real-time consistency issues
-- (partially-filled buckets are included, values change as new events arrive)
SELECT add_continuous_aggregate_policy('business_1min',
    start_offset => INTERVAL '10 minutes',
    end_offset   => INTERVAL '0',    -- NEVER
    schedule_interval => INTERVAL '1 minute');

-- RIGHT: end_offset >= 1 bucket guarantees complete buckets only
SELECT add_continuous_aggregate_policy('business_1min',
    start_offset => INTERVAL '10 minutes',
    end_offset   => INTERVAL '1 minute',    -- at least 1 bucket
    schedule_interval => INTERVAL '1 minute');
```

### compress_segmentby Cardinality Tradeoff
```sql
-- High-cardinality segmentby (e.g., UUID per customer) reduces compression ratio
-- but speeds up queries that always filter by that column
-- Low-cardinality segmentby (e.g., provider, category) maximizes compression

-- Best compression (fewer, larger segments):
ALTER TABLE business_events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'provider, category',   -- low cardinality
    timescaledb.compress_orderby   = 'time DESC'
);

-- Faster queries per-customer (more segments, less compression):
ALTER TABLE business_events SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'customer_id',     -- high cardinality, but always filtered
    timescaledb.compress_orderby   = 'time DESC'
);
-- Choose based on whether queries are always scoped to a single customer_id

-- Check compression ratio:
SELECT pg_size_pretty(before_compression_total_bytes) AS before,
       pg_size_pretty(after_compression_total_bytes) AS after,
       ROUND(100 - (after_compression_total_bytes::numeric / before_compression_total_bytes) * 100, 1) AS pct_saved
FROM chunk_compression_stats('business_events')
ORDER BY chunk_name;
```

## InfluxDB (when applicable)

```python
# For high-frequency device metrics (not typical usage, but pattern reference)
from influxdb_client import InfluxDBClient, Point

client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
write_api = client.write_api()

# Write
point = (Point("business_latency")
    .tag("provider", "carrier-a")
    .tag("customer_id", customer_id)
    .field("latency_ms", latency)
    .time(datetime.utcnow()))
write_api.write(bucket="business", record=point)

# Query (Flux)
query = '''
from(bucket: "business")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "business_latency")
  |> aggregateWindow(every: 1m, fn: mean)
'''
```
