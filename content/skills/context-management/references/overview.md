# Context Management -- Overview

Rules for loading, invalidating, and managing context efficiently across a session.

## Reference Files

| File | Content |
|---|---|
| [analysis-protocol.md](analysis-protocol.md) | Read order, source-of-truth hierarchy, JIT loading |
| [sub-agent-contract.md](sub-agent-contract.md) | Orchestrator-worker pattern, contract, deduplication |
| [state-management.md](state-management.md) | State across turns, context discipline, invalidation |

## Core Invariant

Context = finite attention budget. Goal: smallest set of high-signal information that enables correct execution.

## Boundary

- Token compression of loaded content: -> `token-efficiency`.
- Tool selection: -> `tool-usage`.
- Orchestration patterns + subagent permissions: -> `agent-expert`.
- Anti-hallucination labels + risk tiers: -> `operating-protocol`.
- This file = index + core invariant for context-management.
