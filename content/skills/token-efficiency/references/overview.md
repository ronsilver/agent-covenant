# Token Efficiency — Overview

Rules for output compression, model routing, thinking budget, and clarification protocol.

## Reference Files

| File | Content |
|---|---|
| [output-mode.md](output-mode.md) | Ultra-compressed mode, word limits, anti-patterns, code generation |
| [compression.md](compression.md) | RAG compression, caching, context window management |
| [clarification-first.md](clarification-first.md) | Clarification protocol, batching questions, when to ask |

## Core Invariant

Every token must earn its place. Compression always yields to correctness and safety.
