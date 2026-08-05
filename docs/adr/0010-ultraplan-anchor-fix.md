# ADR-0010 -- Fix staleness anchors in ultraplan (B2)

**Status**: Accepted · **Date**: 2026-06-24

## Context
`ultraplan` (read mode, 343L) emite planes a stdout para `ultracode`. "Zero-reasoning output standard" (L271-299) exige `oldText`/line-range **exactos**. Pero cualquier edicion previa entre emision y ejecucion corre los numeros de linea -> handoff roto. Hallazgo de fragilidad real, no solo mejora.

## Decision
Anclar specs por **string literal estable** (nombre de funcion/constante/bloque verbatim) + comando de verificacion. Prohibir numeros de linea absolutos como anchor primario. Line-range permitido solo como confirmacion secundaria.

## Alternatives rejected
- Mantener line-range: fragilidad confirmada. Rechazado.
- Solo comando de verificacion sin anchor textual: ultracode no ubica el sitio. Rechazado.

## Consequences
- (+) Handoff robusto a edits previos.
- (+) Contrato ultraplan->ultracode menos propenso a fallos silenciosos.
- (-) ultraplan debe citar strings literales mas largos -> +tokens en output. Justificado.

## Edit spec
See stdout deliverable from ultraplan 2026-06-24: REPLACE item 2 of "Zero-reasoning output standard" + REPLACE compliant example anchor in `content/subagents/ultraplan.md`.

## Contract update note
`ultracode` should treat literal-string anchors as authoritative and fall back to symbol search if a literal drifts.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
