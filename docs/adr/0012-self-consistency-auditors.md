# ADR-0012 -- Self-Consistency voting (A1) -- CRITICAL/BLOCKER only

**Status**: Accepted · **Date**: 2026-06-24 · **Affects**: code-review, security-auditor, dependency-audit-agent, idempotency-agent

## Context
Los 4 auditores emiten hallazgos en un solo pase -> falsos positivos/negativos. Self-Consistency (arXiv:2203.11171 `[I]`) muestrea k juicios y vota por mayoria. Trade-off: +tokens -> gate a severidad alta solamente.

## Decision
Anadir Self-Consistency voting **solo** a hallazgos de severidad maxima (`[BLOCKER]` en code-review/idempotency; `[CRITICAL]` en security; `Critical CVSS` en dependency). N>=3 samples, majority vote. Orden: CoVe-filtro primero (donde aplique ADR-0011), Self-Consistency sobre sobrevivientes.

## Alternatives rejected
- Self-Consistency en todo el reporte: +coste Opus sin beneficio en LOW. Rechazado.
- N>=10: coste excesivo. N>=3 suffit para reduccion de varianza. Rechazado N>=10.

## Consequences
- (+) Reduce falsos positivos en hallazgos que bloquean merge/deploy.
- (+) Combinable con CoVe (filtro + voto) sin conflicto si se respeta orden.
- (-) +latencia y +tokens en hallazgos high. Gate acota el impacto.

## Edit spec
See stdout deliverable from ultraplan 2026-06-24: 4 APPEND operations (code-review.md, security-auditor.md, dependency-audit-agent.md, idempotency-agent.md) with verbatim anchors.

## Approval
- Human: Accepted (explicit user approval 2026-06-24).
