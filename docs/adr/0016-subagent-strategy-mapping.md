# ADR-0016 -- Subagent strategy mapping reference doc (non-normative)

**Status**: Accepted · **Date**: 2026-06-24

## Context
El informe `plans/estrategias_subagentes.md` mapea 17 subagentes x estrategias cientificas con pseudo-codigo LangGraph **especulativo** (sin runtime en repo). Promoverlo a contrato normativo = deuda especulativa + 17 ADRs.

## Decision
Crear `docs/reference/subagent-strategy-mapping.md` consolidando el mapeo (tabla + 17 secciones + bibliografia + etiquetas V/I) como **doc de investigacion no-normativo**. Sin pseudo-codigo LangGraph como contrato. Adopcion real = futuros ADRs puntuales (0009-0015 ya cubren las 10 recs accionables).

## Alternatives rejected
- Editar 17 prompts con todas las estrategias: 17 ADRs + deuda especulativa. Rechazado.
- Dejar el informe solo en `plans/`: no indexado en `docs/reference/`, no discoverable. Rechazado.

## Consequences
- (+) Mapeo discoverable + indexado.
- (+) Separacion clara: doc investigacion vs contrato normativo (subagent .md).
- (-) Mantenimiento: debe sync si subagents cambian. Nota en doc.

## Edit spec
See stdout deliverable from ultraplan 2026-06-24: CREATE `docs/reference/subagent-strategy-mapping.md` + UPDATE README counts + ADD CHANGELOG entry.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
