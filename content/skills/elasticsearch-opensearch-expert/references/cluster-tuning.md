# ES/OpenSearch Cluster Tuning

## JVM Configuration
```yaml
# jvm.options
-Xms50%_of_RAM   # heap = 50% of total RAM
-Xmx50%_of_RAM
-XX:MaxHeapSize < 32g  # compressed OOPs, better performance
```

## Shard Strategy
| Data Size | Primary Shards | Replicas |
|---|---|---|
| <10GB | 1 | 1 |
| 10-50GB | 2-5 | 1-2 |
| 50-200GB | 5-10 | 2 |
| >200GB | time-based indices | 2 |

Rule: shard size 10-50GB. More shards = more overhead.

## Index Settings
```json
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 2,
    "refresh_interval": "30s",
    "translog.durability": "async",
    "translog.sync_interval": "30s"
  }
}
```
- refresh_interval=30s (from 1s) for bulk ingest -> 50% throughput gain
- async translog for write-heavy workloads

## Monitoring
```bash
GET _cluster/health
GET _nodes/stats/jvm
GET _cat/nodes?v&h=name,heap.current,heap.percent,disk.total,disk.used
GET _cat/shards?v&h=index,shard,prirep,state,node
```

## Common Issues
| Symptom | Cause | Fix |
|---|---|---|
| RED cluster | Unassigned shards | Check disk space, node count |
| YELLOW | Missing replicas | Add nodes, check allocation |
| High CPU | Heavy query/aggregation | Add nodes, query optimization |
| OOM crashes | Heap too small for workload | Increase heap (max 32GB) |
| Slow ingest | refresh_interval too low | Increase to 30s |
