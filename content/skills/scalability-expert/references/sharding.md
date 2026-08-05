# Data Sharding Strategies

## Consistent Hashing
```go
func shard(key string, numShards int) int {
    h := fnv.New32a()
    h.Write([]byte(key))
    return int(h.Sum32()) % numShards
}
```

## Lookup-Based
```go
shardMap := map[string]int{
    "mer_high_vol": 0,  // dedicated shard
    "default":      1,  // shared
}
```

## Shard Count
| TPS | Shards |
|---|---|
| <500 | 2-4 |
| 500-2000 | 8-16 |
| >2000 | 32+ |

## Migration (Re-sharding)
1. Double shard count
2. Dual-write to old + new shard system
3. Background migration of old data
4. Cutover reads to new system
5. Deprecate old shards

NEVER change shard function without migration plan.
