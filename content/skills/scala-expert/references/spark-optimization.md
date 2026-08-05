# Spark Optimization Guide

## Partitioning
```scala
df.repartition(col("customer_id"))  // even distribution
df.coalesce(4)  // reduce partitions (no shuffle)
```
Repartition = shuffle (expensive). Coalesce = no shuffle (cheap for reduction).

## Broadcast Joins
```scala
import org.apache.spark.sql.functions.broadcast
val result = largeDF.join(broadcast(smallDF), "key")
```
Use for dimension tables <10MB. Broadcast threshold: spark.sql.autoBroadcastJoinThreshold.

## Shuffle Minimization
1. Filter early (reduce data before shuffle)
2. Select only needed columns
3. Use bucketing for join-heavy workloads

## Caching
```scala
df.cache()  // default MEMORY_AND_DISK
df.persist(StorageLevel.MEMORY_ONLY_SER)  // for reuse
```
Cache intermediate results used >1 time. Unpersist when done.

## AQE (Adaptive Query Execution)
```scala
spark.conf.set("spark.sql.adaptive.enabled", "true")
```
Benefits: dynamic partition coalescing, skew join optimization, plan re-optimization.
