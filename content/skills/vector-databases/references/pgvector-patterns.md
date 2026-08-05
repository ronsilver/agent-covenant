# pgvector Patterns

PostgreSQL vector store patterns for this project.

## HNSW Index

```sql
CREATE INDEX ON customer_embeddings
  USING hnsw (embedding vector_cosine_ops)
  WITH (m = 16, ef_construction = 64);
```

## Hybrid Search

```python
from sqlalchemy import text

result = await db.execute(
    text("""
        SELECT content, metadata, doc_type,
               1 - (embedding <=> :query_vec) AS cosine_similarity
        FROM customer_embeddings
        WHERE customer_id = :customer_id
        ORDER BY embedding <=> :query_vec
        LIMIT :k
    """),
    {"query_vec": query_vector, "customer_id": customer_id, "k": k}
)
```

## Constraints

- NEVER mix embedding models in the same index.
- NEVER query without `customer_id` filter.
- ALWAYS use HNSW over IVFFlat for < 1M vectors.
