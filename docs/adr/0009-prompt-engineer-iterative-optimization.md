# ADR-0009 — Pilot: prompt-engineer-agent Iterative Optimization Mode

**Status**: Accepted · **Date**: 2026-06-24 · **Supersedes**: none

## Context
`prompt-engineer-agent` (read mode, 366L) opera single-pass manual (workflow L141-169). Ya tiene eval set de 20+ casos (L204-211) sin usarlo como reward signal. APE (arXiv:2211.01910 `[V]`), OPRO (arXiv:2309.03409 `[V]`), EvoPrompt (arXiv:2309.08532 `[V]`), Self-Refine (arXiv:2303.17651 `[V]`) son fit directo. Read-only → bajo riesgo.

## Decision
Anadir **modo iterativo opcional** (no reemplaza single-pass). Genera candidatos (APE) -> scorea contra eval set existente -> OPRO trajectory + EvoPrompt crossover -> Self-Refine anti-injection final. No runtime LangGraph (especulativo). Reutiliza eval set L204-211 sin nuevo fixture.

## Alternatives rejected
- Reemplazar single-pass: rompe flujo existente, +riesgo. Rechazado.
- Runtime LangGraph state machine: no existe runtime en repo -> deuda especulativa. Rechazado.
- APE-only sin eval: sin reward signal = no optimizacion, solo generacion. Rechazado.

## Consequences
- (+) Cierra loop eval->reward (A4) donde hoy eval es solo entregable.
- (+) Medible con eval set existente -> piloto cuantificable (T7 GO/NO-GO).
- (-) +tokens en modo iterativo -> mantener opcional, default off.
- (-) Requiere eval set ejecutable; si L204-211 es solo framework no implementado, T4 debe implementar runner primero.

## Edit spec
See stdout deliverable from ultraplan 2026-06-24: REPLACE workflow steps 9-11 + ADD "Iterative Optimization Mode -- reward signal" section in `content/subagents/prompt-engineer-agent.md`.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
- Governance gate passed: ADR drafted before edit; human approval logged.
