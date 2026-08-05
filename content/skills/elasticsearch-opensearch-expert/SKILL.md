---
name: elasticsearch-opensearch-expert
description: "Design and operation of Elasticsearch/OpenSearch: mappings and analyzers, complex queries (bool, nested, aggregations), cluster tuning (shards, replicas, segment merging), JVM heap management, ILM for index management, and security (TLS, RBAC). Use when designing search indexes for cloud-native services, writing complex search queries, tuning cluster performance, configuring index lifecycle management, or debugging slow queries. Trigger: Elasticsearch mapping, OpenSearch query, cluster tuning, shard optimization, ILM policy, search index. Do NOT trigger for: standard SQL optimization, relational DB schema design, Redis caching."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: data
  status: stable
---
# Elasticsearch/OpenSearch Expert

**Search engine: mappings, queries, aggregations and tuning.**

## Core Stack

- Engine: Elasticsearch / AWS OpenSearch Service
- Query DSL: bool, match, term, range, nested, aggregations
- Mappings: field types, analyzers (standard, custom, language-specific)
- Lifecycle: ILM policies (hot -> warm -> cold -> delete)
- Monitoring: JVM heap, segment merging, shard distribution

## Mapping Design

```json
{
  "mappings": {
    "properties": {
      "doc_id": { "type": "keyword" },
      "customer": {
        "type": "nested",
        "properties": {
          "id":    { "type": "keyword" },
          "name":  { "type": "text", "analyzer": "standard" }
        }
      },
      "size":         { "type": "long" },
      "category":     { "type": "keyword" },
      "description":  { "type": "text", "analyzer": "english" },
      "created_at":   { "type": "date" }
    }
  }
}
```

- `keyword` for exact matches (IDs, statuses, enums)
- `text` for full-text search with language analyzer
- `nested` for arrays of objects needing independent queries
- NEVER change mapping of existing field (reindex required)

## Query DSL

```json
{
  "query": {
    "bool": {
      "must": [
        { "term": { "category": "standard" } },
        { "range": { "size": { "gte": 1000 } } }
      ],
      "filter": [
        { "term": { "status": "active" } }
      ],
      "must_not": [
        { "term": { "is_blocked": true } }
      ]
    }
  },
  "aggs": {
    "by_category": {
      "terms": { "field": "category", "size": 10 },
      "aggs": {
        "avg_size": { "avg": { "field": "size" } }
      }
    }
  }
}
```

- `filter` over `must` when score doesn't matter (fast, cached)
- Aggregations: terms, date_histogram, percentiles, cardinality

## Cluster Tuning

| Parameter | Recommendation | Reason |
|---|---|---|
| Shards per index | 1-5 for <50GB | More shards = more overhead |
| Replicas | 1 minimum (2 in prod) | Availability > cost |
| JVM heap | 50% of RAM, max 32GB | GC overhead after 32GB |
| Refresh interval | 30s (from 1s default) | Trading near-real-time for throughput |
| Segment merge | Force merge after bulk writes | Reduce segment count for search speed |

## ILM (Index Lifecycle Management)

```
Hot (active writes) -> Warm (read-only, merged) -> Cold (cheap storage) -> Delete
```

```json
{
  "policy": {
    "phases": {
      "hot":   { "min_age": "0ms", "actions": { "rollover": { "max_size": "50GB" } } },
      "warm":  { "min_age": "7d", "actions": { "forcemerge": { "max_num_segments": 1 } } },
      "cold":  { "min_age": "30d" },
      "delete": { "min_age": "90d", "actions": { "delete": {} } }
    }
  }
}
```

## Constraints

- NEVER change mapping on existing field (reindex required, can lose data)
- NEVER run without replicas in production (data loss on node failure)
- NEVER use scroll API for real-time user queries (use search_after)
- ALWAYS set `index.refresh_interval: 30s` for bulk ingestion workloads
- ALWAYS monitor JVM heap pressure (GC overhead >20% = scale up)
- NEVER use `*` query prefix (performance disaster)

## Overview

Design and operate Elasticsearch / AWS OpenSearch Service for search indexes, complex queries, aggregations, cluster tuning, and index lifecycle management across services.

## Quick Reference

| Task | Tool/Pattern | Best Practice |
|---|---|---|
| Exact match | `keyword` field + `term` query | Use for IDs, statuses, enums |
| Full-text search | `text` field + `match` query | Set language analyzer per field |
| Nested objects | `nested` type + `nested` query | Avoid — reindex if structure changes |
| Aggregation | `terms`, `date_histogram`, `percentiles` | Use `filter` aggs for scoped counts |
| Bulk ingestion | `_bulk` API + refresh_interval=30s | Force merge after bulk |

## Workflow

1. Define search requirements and access patterns before mapping
2. Design mappings with appropriate field types and analyzers
3. Set ILM policy for index rotation and retention
4. Implement queries using bool + filter for cached performance
5. Monitor JVM heap pressure and segment counts
6. Tune shard count, refresh interval, and replica count per workload

## Anti-patterns

FAIL: Wildcard prefix queries on large indexes
```json
// BAD: unbounded prefix scan
{ "query": { "prefix": { "description": "pay" } } }

// GOOD: ngram analyzer or search-as-you-type field
{ "query": { "match_phrase_prefix": { "description": "pay" } } }
```

FAIL: Changing field mapping on existing data without reindex
```json
// BAD: trying to change type of existing field
PUT /documents/_mapping { "properties": { "size": { "type": "text" } } }

// GOOD: create new index with correct mapping, reindex
POST /_reindex { "source": { "index": "documents_v1" }, "dest": { "index": "documents_v2" } }
```

FAIL: Using scroll for user-facing search requests
```python
# BAD: scroll API for paginated search results
client.scroll(scroll_id=sid, scroll="1m")

# GOOD: search_after for real-time pagination
results = client.search(index="documents", body={"search_after": last_sort, "size": 20})
```

FAIL: Dynamic template causing mapping explosion with user-generated data
```json
// BAD: catch-all dynamic template creates unlimited unique fields
{
  "dynamic_templates": [{
    "strings": { "match_mapping_type": "string", "mapping": { "type": "text" } }
  }]
}
// Result: 10K unique field names from user metadata → mapping limit exceeded
```

```json
// GOOD: bounded dynamic template with path_match + index:false for unknown
{
  "dynamic_templates": [{
    "known_metadata": {
      "path_match": "metadata.*",
      "match_mapping_type": "string",
      "mapping": { "type": "keyword", "index": false }
    }
  }, {
    "reject_unknown": {
      "match_mapping_type": "*",
      "mapping": { "type": "object", "enabled": false }
    }
  }]
}
```

FAIL: Deep pagination with from/size on large indexes
```json
// BAD: from/size forces deep scroll — O(n) per page
GET /documents/_search
{
  "from": 10000,
  "size": 100
}
```

```json
// GOOD: search_after for cursor-based pagination (constant time)
GET /documents/_search
{
  "size": 100,
  "sort": [{ "created_at": "asc" }, { "doc_id": "asc" }],
  "search_after": ["2026-05-01T00:00:00Z", "doc_99999"]
}
```

## References

- OpenSearch documentation: https://opensearch.org/docs/latest/ (last_verified: 2026-05)
- Elasticsearch guide: https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html (last_verified: 2026-05)
- AWS OpenSearch Service: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/ (last_verified: 2026-05)

- [references/cluster-tuning.md](references/cluster-tuning.md)
- [references/query-patterns.md](references/query-patterns.md)
- [references/security.md](references/security.md)

## Verification Checklist
- [ ] Mapping designed with correct field types (keyword for exact, text for full-text, nested for arrays)
- [ ] ILM policy configured with hot/warm/cold/delete phases matching retention requirements
- [ ] `index.refresh_interval` set to 30s (or appropriate) for bulk ingestion workloads
- [ ] JVM heap monitored and below 75% (GC overhead < 20%)
- [ ] Shard count per index kept between 1-5 for indexes < 50GB
- [ ] No wildcard prefix queries (`*` prefix) in production query patterns
- [ ] Replicas ≥ 1 in production (≥2 for critical indexes)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Search returns no results for text field | Mapping uses `keyword` type (exact match only) instead of `text` (full-text analysis) | Reindex with `text` type and appropriate analyzer; adjust query to use `match` instead of `term` |
| Cluster health `yellow` (unassigned shards) | Primary shard allocated but replicas cannot be placed — insufficient nodes | Add data nodes; reduce replica count temporarily if nodes are limited |
| Query latency > 1s on small index | No filter context for cached queries; wildcard prefix query used | Replace non-scoring `must` clauses with `filter` (cached); avoid prefix queries on large fields |
| Indexing slows down over time | Segment count growing; refresh interval too frequent (1s default) | Increase `refresh_interval` to 30s; force merge after bulk; reduce shard count |
| Latency spikes during normal business hours (no query pattern change) | Shard rebalancing triggered by node add/remove or replica count change competes with write throughput | Schedule rebalancing during maintenance windows: `PUT _cluster/settings {"transient":{"cluster.routing.rebalance.enable":"none"}}` during peak hours |
| `Fielddata circuit breaker` exception on terms aggregation with high-cardinality field | `fielddata=true` on `text` field with millions of unique terms; aggregation loads all terms into memory | Use `keyword` type with `doc_values` enabled (not `fielddata`); limit `terms` aggregation `size`; use `composite` aggregation for high-cardinality pagination |
| Gotcha: `match_phrase` query returns no results despite matching words | Tokenizer position gaps from stopwords or synonyms disrupt phrase matching | Use `match_phrase` with `slop` parameter; prefer `intervals` query for complex phrase matching; verify tokenization with `_analyze` API |
| Workaround: frozen indices search fails when shards are partially allocated | Frozen index requires all shards online before search returns | Use `POST _freeze` to fully freeze before period; avoid hot data in frozen tier; convert cold indices to frozen tier when no longer written |
