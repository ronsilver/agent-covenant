# Time-Series DB Provider Comparison

## Decision Matrix
| Feature | TimescaleDB | InfluxDB v3 | Amazon Timestream |
|---|---|---|---|
| Query language | SQL (PostgreSQL) | Flux / InfluxQL | SQL |
| Compression | 90%+ with native | Good with ZSTD | Automatic tiering |
| Continuous aggregates | Yes (materialized views) | Tasks | Scheduled queries |
| Retention policies | Yes (chunk-based) | Yes (bucket-based) | Auto-tiering (memory -> magnetic) |
| High availability | PG replication | Clustering (Enterprise) | AWS managed |
| Max ingest (single node) | ~1.5M metrics/sec | ~2M metrics/sec | Unlimited (serverless) |
| Operational complexity | Medium (PG ops) | Low (InfluxDB Cloud) | Low (AWS managed) |
| Cost | Self-managed infra | Per GB ingested | Per GB scanned + stored |

## When to Choose
- **TimescaleDB**: Team knows PostgreSQL, need SQL + joins, self-hosted preferred, budget-sensitive
- **InfluxDB**: Dedicated TSDB features, high-cardinality data, want managed service
- **Timestream**: AWS-native, serverless scaling, unpredictable workload, don't want to manage infra

## Migration Considerations
- TimescaleDB -> Timestream: use AWS DMS for ongoing replication
- InfluxDB -> TimescaleDB: export to CSV, import via pg COPY, validate counts
- Schema mapping: tags -> labels/columns, fields -> values, timestamps -> time column
