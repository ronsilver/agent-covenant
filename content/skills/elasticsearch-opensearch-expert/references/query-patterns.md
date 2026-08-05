# Elasticsearch/OpenSearch Query Patterns

## Bool Query (most common)
```json
{
  "query": {
    "bool": {
      "must": [{ "term": { "status": "label_created" } }],
      "filter": [{ "range": { "quantity": { "gte": 1000 } } }],
      "must_not": [{ "term": { "anomaly_flag": true } }],
      "should": [{ "match": { "description": "premium" } }]
    }
  }
}
```
- `must`: contributes to score, required
- `filter`: no score contribution, cached, faster
- `must_not`: excluded, no score
- `should`: optional, boosts score if matched

## Nested Query (arrays of objects)
```json
{
  "query": {
    "nested": {
      "path": "items",
      "query": {
        "bool": {
          "must": [
            { "match": { "items.product_id": "PROD-123" } },
            { "range": { "items.quantity": { "gte": 5 } } }
          ]
        }
      }
    }
  }
}
```

## Aggregations
```json
{
  "aggs": {
    "by_customer": {
      "terms": { "field": "customer_id", "size": 10 },
      "aggs": {
        "stats": {
          "stats": { "field": "quantity" }
        },
        "over_time": {
          "date_histogram": {
            "field": "created_at",
            "calendar_interval": "day"
          }
        }
      }
    }
  }
}
```

## Full-Text Search
```json
{
  "query": {
    "multi_match": {
      "query": "premium membership",
      "fields": ["description^2", "customer_name"],
      "type": "best_fields",
      "fuzziness": "AUTO"
    }
  }
}
```

## Highlighting
```json
{
  "query": { "match": { "description": "return" } },
  "highlight": {
    "fields": { "description": {} },
    "pre_tags": ["<mark>"],
    "post_tags": ["</mark>"]
  }
}
```
