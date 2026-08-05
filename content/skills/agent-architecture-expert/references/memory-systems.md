# Agent Memory Architecture

## Memory Layers (ascending complexity)
1. **Working Memory**: context window. Optimize with attention-favored positions.
2. **Short-term**: filesystem cache, in-memory. Tool results, conversation state.
3. **Long-term**: vector store + graph DB. Preferences, domain knowledge, entity registries.
4. **Episodic**: conversation history summaries, decision logs.
5. **Semantic**: knowledge graph with entity relationships.

## Framework Selection
| Framework | Best For | Limitation |
|---|---|---|
| Filesystem | Prototypes, simple agents | No semantic search |
| Mem0 (68.5% LoCoMo) | Multi-tenant, fast deploy | Limited relationship traversal |
| Zep/Graphiti (94.8% DMR) | Temporal, relationships | Some features cloud-locked |
| Letta (74% LoCoMo) | Self-editing agents | Complex for simple use cases |
| LangMem | Teams on LangGraph | Tightly coupled |

## Retrieval Strategies
- Semantic: embedding similarity (direct factual queries)
- Entity: graph traversal ('everything about X')
- Temporal: validity-filtered (changing facts)
- Hybrid: semantic + keyword + graph (best accuracy)

## Consolidation
Trigger: memory count > threshold OR retrieval quality degraded.
Invalidate but NEVER discard (history needed for temporal queries).
