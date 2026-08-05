# Vector Databases — Overview

## pgvector (Generic default)

### Why pgvector for this project
- the AI service already uses PostgreSQL (AI service platform)
- Same operational team, same backup/monitoring toolchain
- HNSW index: ~1ms p99 for < 500K vectors
- Native SQL filtering (no separate metadata store)
- Supports exact NN (for small corpora) and ANN (for scale)

### Complete Schema

```sql
-- Enable extension
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;  -- for BM25-style text search

-- Main embeddings table
CREATE TABLE customer_embeddings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id     VARCHAR(255)  NOT NULL,
    doc_type        VARCHAR(50)   NOT NULL,
    doc_id          VARCHAR(255)  NOT NULL,     -- source document ID
    chunk_index     INT           NOT NULL,     -- position within document
    content         TEXT          NOT NULL,
    embedding       vector(1024)  NOT NULL,     -- Titan v2 = 1024 dims
    model_id        VARCHAR(255)  NOT NULL,     -- embedding model version
    metadata        JSONB         NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    UNIQUE (customer_id, doc_id, chunk_index)  -- dedup
);

-- HNSW vector index (better recall, faster build than IVFFlat for < 1M rows)
CREATE INDEX customer_embeddings_hnsw_idx
    ON customer_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Metadata filters (always prefix vector search with these)
CREATE INDEX ON customer_embeddings (customer_id, doc_type);
CREATE INDEX ON customer_embeddings (customer_id, doc_id);

-- Text search for hybrid retrieval
CREATE INDEX ON customer_embeddings USING gin(to_tsvector('english', content));
```

### Hybrid Search Query

```sql
-- Combine vector similarity + full-text search
WITH vector_results AS (
    SELECT id, content, metadata, doc_type,
           1 - (embedding <=> $1) AS vector_score
    FROM customer_embeddings
    WHERE customer_id = $2
      AND doc_type = ANY($3)
    ORDER BY embedding <=> $1
    LIMIT 20
),
text_results AS (
    SELECT id,
           ts_rank(to_tsvector('english', content),
                   plainto_tsquery('english', $4)) AS text_score
    FROM customer_embeddings
    WHERE customer_id = $2
      AND to_tsvector('english', content) @@ plainto_tsquery('english', $4)
    LIMIT 20
)
SELECT v.id, v.content, v.metadata, v.doc_type,
       COALESCE(v.vector_score * 0.6, 0) + COALESCE(t.text_score * 0.4, 0) AS combined_score
FROM vector_results v
LEFT JOIN text_results t ON v.id = t.id
ORDER BY combined_score DESC
LIMIT 10;
```

### HNSW Tuning

```sql
-- At query time: higher ef_search = better recall, more latency
SET hnsw.ef_search = 100;  -- default 40, increase for better recall
-- For production: benchmark ef_search 40/100/200 vs recall@10
```

## Pinecone (for scale > 500K vectors)

```python
from pinecone import Pinecone, ServerlessSpec

pc = Pinecone(api_key=settings.PINECONE_API_KEY)  # from secrets manager

# Create index (once)
pc.create_index(
    name="customer-docs",
    dimension=1024,          # Titan v2
    metric="cosine",
    spec=ServerlessSpec(cloud="aws", region="us-east-1"),
)

index = pc.Index("customer-docs")

# Upsert with customer namespace (tenant isolation)
index.upsert(
    vectors=[{
        "id": chunk_id,
        "values": embedding,
        "metadata": {"customer_id": customer_id, "doc_type": doc_type, "content": content},
    }],
    namespace=customer_id,  # strict tenant isolation via namespace
)

# Query within customer namespace
results = index.query(
    vector=query_embedding,
    top_k=10,
    namespace=customer_id,
    include_metadata=True,
)
```

## Embedding Model Comparison

| Model | Dimensions | Multilingual | Cost | this project fit |
|---|---|---|---|---|
| `amazon.titan-embed-text-v2:0` | 1024 | Yes (100+ langs) | Low | Default — AWS-native |
| `text-embedding-3-small` | 1536 | Yes | Low | Alternative (OpenAI) |
| `text-embedding-3-large` | 3072 | Yes | Medium | Higher quality (overkill for most) |
| `cohere.embed-multilingual-v3` | 1024 | Yes (Spanish/Portuguese) | Low | Good for LATAM docs |

**The default: `amazon.titan-embed-text-v2:0`** — AWS-native, multilingual, same region as Bedrock.
