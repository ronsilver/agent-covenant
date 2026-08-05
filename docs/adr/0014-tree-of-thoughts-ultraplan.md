# ADR-0014 -- Tree of Thoughts light in ultraplan (B1)

**Status**: Accepted · **Date**: 2026-06-24

## Context
`ultraplan` (L82-100) genera **un** plan via CoT lineal. Objetivos ambiguos/High-risk se benefician de ToT (arXiv:2305.10601 `[I]`): 2-3 descomposiciones candidatas, evaluacion, elegir mejor. DAG actual ya es Least-to-Most de facto (no nombrado).

## Decision
Anadir ToT branch **solo** para objectives complexity=High o ambiguos. Generar k=2-3 descomposiciones, evaluar con rubrica, elegir mejor. Nombrar Least-to-Most explicito en DAG. Coste Opus 4.8 justifica gate.

## Alternatives rejected
- ToT en todo plan: coste Opus excesivo en planes rutinarios. Rechazado.
- k>=5 candidatas: coste sin beneficio marginal. k=2-3 suffit. Rechazado.

## Consequences
- (+) Mejor calidad en objetivos ambiguos/High-risk.
- (+) Nombrado explicito Least-to-Most documenta el isomorfismo DAG.
- (-) +coste Opus en High. Gate acota.

## Edit spec
See stdout deliverable from ultraplan 2026-06-24: REPLACE Methodology step 2 in `content/subagents/ultraplan.md`.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
