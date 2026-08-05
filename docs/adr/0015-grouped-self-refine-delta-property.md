# ADR-0015 -- Grouped: B4 Self-Refine pre-done (ultracode) + B5 Delta Debugging (ultradebugger) + B6 property/metamorphic (test-writer) + A4 residual guidance

**Status**: Accepted · **Date**: 2026-06-24

## Context
- B4: `ultracode` (L196-201) implementa -> valida. Falta auto-critica pre-suite (Self-Refine arXiv:2303.17651 `[V]`).
- B5: `ultradebugger` "trigger minimo" (L125) cualitativo. Delta Debugging ddmin (Zeller & Hildebrandt 2002 `[I]`) lo vuelve algoritmico.
- B6: `test-writer` (L66-72) AAA+table-driven. Falta property-based (QuickCheck) + metamorphic (oracle-free) para logica pagos.
- A4: `performance-profiler` YA cierra before/after (L150, L230-233). A4 residual = guidance doc-only.

## Decision
4 edits agrupados (misma familia Self-Refine/measurement-loop). B4/B5/B6 edits + A4 guidance note en test-writer (coverage loop ya es Self-Refine-adjacent).

## Edit spec
See stdout deliverable from ultraplan 2026-06-24:
- `content/subagents/ultracode.md` REPLACE workflow step 6 with self-critique insert + step 6.
- `content/subagents/ultradebugger.md` APPEND Delta Debugging ddmin block.
- `content/subagents/test-writer.md` APPEND property-based + metamorphic to Test philosophy + Core responsibilities.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
