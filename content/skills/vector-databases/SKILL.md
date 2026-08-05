---
name: vector-databases
description: "Design and operate vector databases for cloud-native AI features. Use when selecting between pgvector, Pinecone, or Weaviate for AI context layer or integration-hub; designing embedding schemas and index parameters; implementing ANN search with metadata filtering; managing embedding model versions; optimizing query latency; or debugging low retrieval quality. Pairs with rag-architecture for pipeline design and postgres-database-expert for pgvector specifics. Trigger: vector database, pgvector, Pinecone, Weaviate, embedding, ANN search, HNSW, cosine similarity. Do NOT trigger for: relational SQL optimization, standard PostgreSQL schema design, Redis caching."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: ai-agents
  status: stable
---

# Vector Databases

**Design and operate vector stores for cloud-native AI features (AI context layer).**

**See [references/overview.md](references/overview.md)**

## Database Selection

| DB | Use when | team fit |
|---|---|---|
| `pgvector` | < 1M vectors, PostgreSQL already in stack, exact + ANN | AI context layer (reuse existing PG) |
| Pinecone | > 1M vectors, managed, multi-tenant filtering critical | High-scale production RAG |
| Weaviate | Need hybrid search built-in, graph-style traversal | Complex document graphs |
| Qdrant | On-premise, GDPR, payload filtering | Self-hosted requirement |

**recommended: `pgvector`** (leverages existing PostgreSQL infrastructure).

## pgvector Schema

```sql
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE customer_embeddings (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id VARCHAR(255) NOT NULL,          -- tenant isolation
    doc_type    VARCHAR(50)  NOT NULL,           -- manual|policy|config
    content     TEXT         NOT NULL,           -- original chunk text
    embedding   vector(1536) NOT NULL,           -- text-embedding-3-small dim
    metadata    JSONB        NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- HNSW index (better recall than IVFFlat for < 1M rows)
CREATE INDEX ON customer_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Always filter by customer first (tenant isolation + perf)
CREATE INDEX ON customer_embeddings (customer_id, doc_type);
```

## Embedding Generation

```python
from langchain_aws import BedrockEmbeddings

embeddings = BedrockEmbeddings(
    model_id="amazon.titan-embed-text-v2:0",  # 1024 dims, multilingual
    region_name="us-east-1",
)

# Batch embed for indexing (cost-efficient)
texts = [chunk.page_content for chunk in chunks]
vectors = embeddings.embed_documents(texts)  # list of 1024-dim vectors

# Single embed for query
query_vector = embeddings.embed_query(user_question)
```

## ANN Search (pgvector)

```python
from sqlalchemy import text

async def search(customer_id: str, query_vector: list[float], k: int = 10) -> list[dict]:
    result = await db.execute(
        text("""
            SELECT content, metadata, doc_type,
                   1 - (embedding <=> :query_vec) AS cosine_similarity
            FROM customer_embeddings
            WHERE customer_id = :customer_id
              AND doc_type = ANY(:doc_types)
            ORDER BY embedding <=> :query_vec
            LIMIT :k
        """),
        {
            "query_vec": query_vector,
            "customer_id": customer_id,
            "doc_types": ["manual", "policy"],
            "k": k,
        }
    )
    return result.mappings().all()
```

## Embedding Model Version Management

```python
# Track model version per embedding (critical for reindex decisions)
# If you change model, ALL embeddings must be reindexed

class EmbeddingRecord:
    model_id: str     # "amazon.titan-embed-text-v2:0"
    model_dim: int    # 1024
    created_at: datetime
```

→ [references/overview.md](references/overview.md) | [references/pgvector-patterns.md](references/pgvector-patterns.md)

## Constraints

- NEVER mix embedding models in the same index (cosine similarity breaks across models)
- NEVER query without `customer_id` filter (cross-tenant data leak)
- ALWAYS use HNSW over IVFFlat for < 1M vectors (better recall)
- ALWAYS store `model_id` with each embedding (reindex detection)
- NEVER store raw PII in vector store
- ALWAYS batch embed at index time (cheaper than per-document calls)
- ALWAYS set `ef_search` HNSW param at query time (higher = better recall, slower)
- NEVER delete and re-create index in production — use `ALTER INDEX` or incremental upsert

## Overview

Vector database design and operation for team AI features (AI context layer, RAG). Covers selection (pgvector/Pinecone/Weaviate/Qdrant), pgvector schema design with HNSW indexing, embedding generation via Bedrock, ANN search with tenant isolation, and embedding model version management.

## Quick Reference

| Scenario | Solution |
|---|---|
| < 1M vectors + PostgreSQL already in stack | pgvector (recommended) |
| > 1M vectors + managed service needed | Pinecone |
| Need built-in hybrid search + graph traversal | Weaviate |
| Changing embedding models | Reindex all embeddings — cosine breaks across models |
| Slow ANN queries | Check HNSW `ef_search` param; verify `customer_id` filter applied first |

## Workflow

1. **Select database** — Default pgvector for < 1M vectors fitting existing PostgreSQL; evaluate Pinecone/Weaviate for larger scale.
2. **Design schema** — PK (UUID), tenant field (`customer_id`), doc type, content TEXT, `embedding vector(N)`, metadata JSONB.
3. **Create HNSW index** — `USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64)`.
4. **Generate embeddings** — Batch embed via Bedrock (Titan/Cohere). Store `model_id` and dimension with each record.
5. **Query with tenant filter** — Always filter `customer_id` first, then `ORDER BY embedding <=> :query_vec LIMIT :k`.
6. **Monitor recall quality** — If retrieval degrades, check if model changed (requires reindex). Tune `ef_search`.

## References

| Resource | URL | Last verified |
|---|---|---|
| pgvector GitHub | https://github.com/pgvector/pgvector | 2026-05-25 |
| Pinecone Documentation | https://docs.pinecone.io/ | 2026-05-25 |
| Weaviate Documentation | https://weaviate.io/developers/weaviate | 2026-05-25 |
| AWS Bedrock Embeddings | https://docs.aws.amazon.com/bedrock/latest/userguide/knowledge-base.html | 2026-05-25 |
| HNSW Algorithm (Malkov et al.) | https://arxiv.org/abs/1603.09320 | 2026-05-25 |

## Verification Checklist

- [ ] Embedding model version tracked with every record (`model_id`, `model_dim`)
- [ ] All queries include `customer_id` filter (no cross-tenant data leak)
- [ ] HNSW index used (not IVFFlat) for < 1M vectors
- [ ] No mixing of embedding models in the same index
- [ ] No raw PII stored in vector store
- [ ] Batch embedding used at index time (not per-document calls)
- [ ] `ef_search` HNSW parameter tuned at query time for recall/speed trade-off

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| ANN query returns irrelevant results | Embedding model changed but old vectors not reindexed | Reindex all embeddings with new model; verify `model_id` consistent across index |
| ANN query is slow (>500ms) | `ef_search` too high or missing `customer_id` filter | Lower `ef_search`; verify query filters `customer_id` before vector search |
| Cosine similarity scores are negative or inconsistent | Vectors from different embedding models mixed in same index | Drop and recreate index with single embedding model; verify `model_id` on all records |
| HNSW index build memory usage spikes | `ef_construction` or `m` parameter too high | Reduce `m` from 16 to 8; reduce `ef_construction` from 64 to 32 |
| ANN query returns 0 results for exact-match filter criteria (known issue: recall vs exactness tradeoff) | HNSW is approximate; filter + vector combo may miss matching records | Lower `ef_search` threshold for higher recall; or fall back to exact KNN for critical queries |

| [WARN] pgvector `ORDER BY embedding <-> $1 LIMIT 10` ignores GIST index on small tables | PostgreSQL optimizer chooses sequential scan when table < 1000 rows, ignoring vector index | Set `enable_seqscan = off` for vector queries on small tables; or seed table with dummy vectors |
## Anti-patterns

FAIL: Mixing embedding models in the same index
```sql
-- WRONG: rows with different model_id in same index
INSERT INTO customer_embeddings (embedding) VALUES
  ('[0.1, 0.2, ...]'::vector(1024)),  -- Titan v1 (1024d)
  ('[0.3, 0.4, ...]'::vector(1536));  -- text-embedding-3-small (1536d)
```
```sql
-- CORRECT: one model per index; version via table partitioning or separate tables
-- Create dimension-specific table or enforce model_id filter at query time
CREATE TABLE embeddings_titan_v1 (embedding vector(1024), model_id TEXT DEFAULT 'titan-v1');
CREATE TABLE embeddings_openai_v3 (embedding vector(1536), model_id TEXT DEFAULT 'text-embedding-3-small');
```
**Why:** Cosine similarity between vectors of different models/dimensions is meaningless and produces garbage results.

FAIL: Querying without tenant isolation filter
```python
# WRONG: no customer_id filter — cross-tenant data leak
results = db.execute("SELECT * FROM customer_embeddings ORDER BY embedding <=> :q LIMIT 10")
```
```python
# CORRECT: always filter by customer_id first
results = db.execute("""
    SELECT * FROM customer_embeddings
    WHERE customer_id = :customer_id
    ORDER BY embedding <=> :q LIMIT 10
""", {"customer_id": customer_id})
```
**Why:** Without tenant filter, ANN search returns results from ALL customers — data leak and worse recall.

FAIL: Using IVFFlat when HNSW is available
```sql
-- WRONG: IVFFlat needs training pass, lower recall
CREATE INDEX ON items USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
```
```sql
-- CORRECT: HNSW has better recall, no training pass needed
CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops) WITH (m = 16, ef_construction = 64);
```
**Why:** HNSW consistently beats IVFFlat on recall@10 for < 1M vectors, no training pass required.
