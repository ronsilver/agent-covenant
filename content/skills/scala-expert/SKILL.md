---
name: scala-expert
description: "Distributed computing with Apache Spark for modern projects: DataFrame/Dataset API in Scala, ETL reconciliation processing, PySpark interoperability, functional testing with ScalaTest, build management with sbt, and static analysis with scalafmt/scalafix. Use when working in data-processing-spark, writing Spark DataFrame/Dataset transformations, optimizing partitions/shuffles/broadcast joins, tuning executors, working with Delta Lake, integrating with AWS Glue, or writing Spark jobs in PySpark from Python. Trigger: Scala, Spark, ETL, Delta Lake, PySpark, sbt, ScalaTest, reconciliation, Glue. Do NOT trigger for: real-time stream processing with Kafka Streams, frontend development, general Python scripting."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: data
  status: stable
---
# Scala Expert

**Scala ecosystem: Apache Spark, ETL, sbt, testing and PySpark.**

## Core Stack

- Language: Scala 2.13 / 3 (case classes, pattern matching, futures, implicit/given)
- Engine: Apache Spark (DataFrame/Dataset API, RDD fallback)
- Python interop: PySpark (shared SparkContext, DataFrame API from Python)
- Build: sbt (plugins, multi-project, dependency management)
- Testing: ScalaTest (FlatSpec/WordSpec, matchers, before/after)
- Linting: scalafmt + scalafix
- Storage: Delta Lake, S3, Glue Data Catalog

## Project Structure

```
src/main/scala/com/example/spark/
  jobs/           # Spark job entry points
  transformations/ # DataFrame/Dataset transformations
  sources/        # Read connectors (S3, JDBC, Glue)
  sinks/          # Write connectors (S3, Delta, data warehouse)
  models/         # case classes for schemas
src/test/scala/
  unit/
  integration/
```

## Spark Patterns

```scala
import org.apache.spark.sql.SparkSession
import org.apache.spark.sql.functions._

val spark = SparkSession.builder()
  .appName("reconciliation")
  .config("spark.sql.adaptive.enabled", "true")
  .getOrCreate()

import spark.implicits._

val records = spark.read
  .option("header", "true")
  .csv("s3://example-data/records/")
  .select($"record_id", $"measure".cast("long"), $"status")
  .filter($"measure" > 0)
```

- Partitioning: `repartition(col("entity_id"))` for even distribution
- Broadcast joins: `broadcast(smallDF)` for dimension tables (<10MB)
- Shuffle minimization: filter early, select only needed columns
- NEVER `collect()` on large datasets — use `take(n)` or aggregation
- Cache intermediate results: `df.cache()` for reused DataFrames

## Delta Lake

```scala
records.write
  .format("delta")
  .mode("append")
  .partitionBy("date")
  .save("s3://example-data/delta/records/")

// Time travel
spark.read.format("delta")
  .option("versionAsOf", 5)
  .load("s3://example-data/delta/records/")
```

- ALWAYS use Delta for ACID guarantees on S3
- Enable `spark.sql.adaptive.enabled` for dynamic partition pruning

## PySpark Interop (Python-side)

```python
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("recon").getOrCreate()

df = spark.read.csv("s3://example-data/records/", header=True)
df_filtered = df.filter(df.measure > 0).select("record_id", "measure")
df_filtered.write.mode("append").parquet("s3://example-data/output/")
```

- Same DataFrame API, same execution engine
- Scala for performance-critical UDFs, Python for glue/orchestration

## Testing

```scala
import org.scalatest.flatspec.AnyFlatSpec
import org.apache.spark.sql.SparkSession

class ReconciliationSpec extends AnyFlatSpec {
  val spark = SparkSession.builder()
    .master("local[2]")
    .appName("test")
    .getOrCreate()

  "Reconciliation" should "match records" in {
    import spark.implicits._
    val source = Seq(("tx1", 1000L)).toDF("id", "measure")
    val result = ReconciliationJob.matchRecords(source)
    assert(result.count() == 1)
  }
}
```

- ALWAYS `master("local[2]")` in tests — never connect to cluster

## Constraints

- NEVER `collect()` on >1000 rows — use `take(n)` or write to file
- NEVER broadcast >10MB DataFrames — causes OOM
- NEVER skip partition columns on write — full table scan on read
- ALWAYS filter before join — reduces shuffle volume
- ALWAYS cache reused DataFrames (`.cache()` / `.persist()`)
- NEVER use `var` in Spark closures — serialization issues
- ALWAYS enable AQE (`spark.sql.adaptive.enabled=true`)

## Overview

Apache Spark and Scala ecosystem for distributed ETL processing: DataFrame/Dataset API, Delta Lake for ACID on S3, sbt for builds, ScalaTest for testing, and PySpark interoperability for mixed-language pipelines.

## Quick Reference

| Component | Purpose | Configuration |
|-----------|---------|---------------|
| DataFrame API | Primary abstraction for structured data | `spark.read.parquet("s3://...")` |
| Delta Lake | ACID transactions on S3 with time travel | `spark.sql.extensions: io.delta.sql.DeltaSparkSessionExtension` |
| AQE | Adaptive Query Execution — auto-optimizes joins, partitions, skew | `spark.sql.adaptive.enabled: true` |
| Broadcast Join | Efficient join of small dimension tables | `import org.apache.spark.sql.functions.broadcast` |
| sbt | Build tool with multi-project support | `build.sbt` with `project/` plugins |
| ScalaTest | Testing framework (FlatSpec, WordSpec) | `master("local[2]")` for tests |
| PySpark | Python interop — same execution engine | Shared SparkContext via `spark` variable |

## Workflow

1. Build with sbt: define dependencies, Scala version, assembly plugin for fat JARs
2. Read source data from S3, JDBC, or Glue Catalog into DataFrames with explicit schema (avoid schema inference)
3. Transform: filter early → select needed columns → join (broadcast for small tables) → aggregate
4. Enable AQE (`spark.sql.adaptive.enabled=true`) for automatic optimization
5. Write output: Delta Lake for ACID (partitioned), Parquet for raw output, or S3 by date partitions
6. Test: ScalaTest with `master("local[2]")`, test with minimal data, never `collect()` > 1000 rows

## Anti-patterns

FAIL: collect() on large datasets
```scala
// BAD — pulls all data to driver, OOM on large sets
val allData = df.collect()
```
PASS: Use take(n) or aggregation
```scala
// GOOD
val sample = df.take(100)
val count = df.count()
```

FAIL: Broadcasting large DataFrames
```scala
// BAD — broadcast > 10MB causes driver OOM
val result = largeDF.join(broadcast(anotherLargeDF), "key")
```
PASS: Only broadcast small dimension tables
```scala
// GOOD
val smallDim = spark.read.parquet("s3://example-data/dimensions/customers")
val result = largeDF.join(broadcast(smallDim), "entity_id")
```

FAIL: Skipping partition columns on write
```scala
// BAD — full scan on read
records.write.parquet("s3://example-data/records/")
```
PASS: Partition by date or customer
```scala
// GOOD
records.write.partitionBy("date", "customer_id").parquet("s3://example-data/records/")
```

FAIL: Using var in Spark closures (serialization issues)
```scala
// BAD — var in lambda breaks serialization
var threshold = 1000L
df.filter($"measure" > threshold)
```
PASS: Use val or pass as DataFrame variable
```scala
// GOOD
val threshold: Long = 1000L
df.filter($"measure" > threshold)
```

FAIL: Not caching reused DataFrames
```scala
// BAD — recomputes the entire lineage twice
val filtered = df.filter($"status" === "active")
val count1 = filtered.count()
val count2 = filtered.groupBy("customer_id").count()
```
PASS: Cache intermediate results
```scala
// GOOD
val filtered = df.filter($"status" === "active").cache()
val count1 = filtered.count()
val count2 = filtered.groupBy("customer_id").count()
```

## References

- [Apache Spark SQL Guide](https://spark.apache.org/docs/latest/sql-programming-guide.html) · last_verified: 2025-05
- [Delta Lake Documentation](https://docs.delta.io/latest/index.html) · last_verified: 2025-05
- [ScalaTest User Guide](https://www.scalatest.org/user_guide) · last_verified: 2025-05

- [references/sbt-patterns.md](references/sbt-patterns.md)
- [references/spark-optimization.md](references/spark-optimization.md)

## Verification Checklist

- [ ] `collect()` never called on datasets >1000 rows — `take(n)` or aggregation used instead
- [ ] Broadcast joins limited to dimension tables <10MB
- [ ] Filter applied before joins to reduce shuffle volume
- [ ] Partition columns specified on all writes (avoid full scan on read)
- [ ] `spark.sql.adaptive.enabled` set to `true`
- [ ] Reused DataFrames cached via `.cache()` or `.persist()`
- [ ] `var` not used inside Spark closures (serialization-safe)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Job OOM on driver | `collect()` called on large DataFrame | Replace with `take(n)`, `count()`, or write to file instead |
| Shuffle too large / slow | Filter applied after join instead of before | Move filter expressions before join in the transformation chain |
| Delta table reads take full scan | Write skipped `partitionBy` on date/customer | Re-write with `partitionBy("date", "customer_id")` and read with partition filter |
| Broadcast join causes OOM | Broadcast DF exceeds 10MB | Remove `broadcast()` hint — join will fall back to SortMergeJoin automatically |
| Delta table time travel query returns wrong data (edge case: retention expiration) | Delta log retention cleaned up old commits via `vacuum` | Check `delta.logRetentionDuration` config; set to match max expected time travel window (default 7d may be insufficient) |

| [WARN] Spark `repartition()` causes full shuffle even when no data redistribution needed | repartition(n) always triggers shuffle; coalesce(n, shuffle=false) preferred for reducing partitions | Use `coalesce(n)` instead of `repartition(n)` when decreasing partitions; use `repartitionByRange` for ordering |
| Spark groupBy followed by join triggers unnecessary shuffle because data already partitioned | Spark planner does not always propagate partitioning information across operators | Use repartition(partitionExprs) before groupBy to align partitions; check plan with .explain() |
| Gotcha: Spark broadcast variable sent to every task even when only used in one partition | Broadcast variable serialized and sent to all executors regardless of actual partition usage | Use accumulator or per-partition singleton instead of broadcast for single-partition operations |
