# RAG Pipeline Architecture

## Pipeline Stages
Documents -> Ingestion -> Chunking -> Embedding -> Indexing -> Retrieval -> Reranking -> Generation

## Chunking Strategies
| Method | Size | Overlap | Use Case |
|---|---|---|---|
| Fixed-size | 512-1024 tokens | 10-20% | Simple, no structure |
| Semantic (heading) | Per section | 0% | Structured docs |
| Recursive | 256-2048 tokens | 20% | Mixed content |
| Sentence Window | Sentence + 2 neighbors | N/A | QA, fact extraction |

## Embedding Models (AWS Bedrock)
| Model | Dims | Languages |
|---|---|---|
| Titan Embeddings G1 | 1536 | EN primary |
| Titan Embeddings V2 | 1024 | EN, limited ES/PT |
| Cohere Embed v3 | 1024 | EN, ES, PT (Generic recommended) |

## Retrieval Strategies
| Strategy | How | When |
|---|---|---|
| Vector (ANN) | HNSW/IVF similarity | Semantic search |
| Keyword (BM25) | Sparse retrieval | Exact terms, codes |
| Hybrid | Vector + BM25 with RRF | Best accuracy |
| Multi-hop | Iterative retrieval | Complex reasoning |

## Reranking
Cross-encoder scores top-K results (cohere.rerank, bge-reranker).
Reciprocal Rank Fusion for hybrid results merging.

## Quality Metrics
- Recall@K: relevant_retrieved / total_relevant
- MRR: mean(1 / rank_of_first_relevant)
- NDCG@K: DCG / IDCG (graded relevance)

## Evaluation
- Auto-eval: LLM-as-Judge with rubric dimensions
- Retrieval eval: RAGAS (faithfulness, relevance, context precision)
- Human review: 10% sample for calibration
