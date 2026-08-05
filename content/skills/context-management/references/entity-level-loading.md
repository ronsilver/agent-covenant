# Entity-Level Loading -- Per-Symbol Context Loading

## Scope

Load at SYMBOL granularity (function/method/class), not file granularity. Escalate from signature to body on signal. Token savings are owned by `token-efficiency` `retrieval-economics.md` G12. This file owns the LOADING ESCALATION decision for correctness.

## 3-Layer Progressive Disclosure

3-layer progressive disclosure (signature -> +docstring -> full body; token costs per `token-efficiency/retrieval-economics.md` G12). Escalate one layer on signal: explicit request | error | complexity | type mismatch.

## Escalation Signals

- Explicit request: user/agent asks for implementation.
- Error: signature suggests one behavior, runtime shows another -> load body to find bug.
- Complexity: signature simple but call site shows complex usage -> load body.
- Type mismatch: expected type differs from actual -> load body to find coercion.

## Adaptive Skeletonization

For files with many functions: load the FLOW SPINE fully (functions on the critical path), skeletonize polymorphic siblings (off-spine, same interface). 4-condition gate to skeletonize:
1. Spine exists (a critical path is identified).
2. File is OFF the spine.
3. Function is a polymorphic sibling (same interface, different impl).
4. Function is NOT spared (explicitly requested).

Source: colbymchenry/codegraph adaptive explore sizing. [V: https://github.com/colbymchenry/codegraph, accessed 2026-06-30]

## Symbol Body Retrieval (without reading surrounding file)

Load just the body of method M without reading the surrounding file. Use LSP-based semantic retrieval. For cross-file refactors, retrieve all affected symbols atomically.

Source: oraios/serena symbol body retrieval. [V: https://github.com/oraios/serena, accessed 2026-06-30]
Source: claude-mem smart_outline / smart_unfold (symbol-level progressive disclosure). [V: https://github.com/thedotmack/claude-mem, accessed 2026-06-30]

## QUALITY CLAUSE -- MANDATORY (inline highlights)

Entity-level diff MUST include word-level inline highlights for modified entities. NEVER hide a 1-line fix inside a 50-line function block. If an entity is modified, the diff shows the changed line with +/- inline markers even in entity-level context. Hiding inline changes = the agent misses the actual change = quality failure.

(This clause originated in `token-efficiency/retrieval-economics.md` G12 for token concerns; context-management owns it here for CORRECTNESS -- agent missing the change is a correctness failure.)

## Boundary

- Token SAVINGS from entity-level window: -> `token-efficiency` `retrieval-economics.md` G12.
- LOADING ESCALATION for correctness (when to go signature -> body): owned HERE.
- Tool selection (LSP vs Read): -> `tool-usage`.
