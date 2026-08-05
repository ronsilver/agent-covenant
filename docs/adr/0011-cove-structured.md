# ADR-0011 -- Chain-of-Verification structured (A2)

**Status**: Accepted · **Date**: 2026-06-24 · **Affects**: research, security-auditor, dependency-audit-agent

## Context
`research` exige ">=2 fuentes" (L121-127) y `security`/`dependency` razonan sobre explotabilidad/severidad como **texto libre**. CoVe (arXiv:2309.11495 `[V]`) convierte eso en paso estructurado: draft -> generar verification questions -> responderlas independientes -> revisar. Reduce alucinacion y falsos positivos SAST/CVE.

## Decision
Anadir paso CoVe estructurado a los 3 agentes. En security/dependency: CoVe **antes** de elevar severidad alta (filtro de falsos positivos).

## Alternatives rejected
- CoVe en todo el reporte (no solo severidad alta): +coste tokens sin beneficio en LOW findings. Rechazado.
- Dejar ">=2 fuentes" como regla pasiva: status quo, alucinacion no mitigada. Rechazado.

## Consequences
- (+) Reduce falsos positivos SAST/CVE que erosionan confianza.
- (+) Formaliza ">=2 fuentes" de research con loop activo.
- (-) +1 paso por finding high -> +latencia. Gate a severidad alta lo acota.

## Edit spec
See stdout deliverable from ultraplan 2026-06-24: 3 APPEND operations with verbatim anchors in `research.md`, `security-auditor.md`, `dependency-audit-agent.md`.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
