# ADR-0018 -- linting-agent pre-commit routing (override of informe discernimiento C)

**Status**: Accepted · **Date**: 2026-06-24

## Context
The research report `plans/estrategias_subagentes.md` (lines 866-870,
discernimiento C) explicitly excludes `linting-agent` from reasoning-based
improvements: "linting-agent y git-requests deben seguir deterministicos.
Anadir razonamiento generativo introduciria no-determinismo y empeoraria su
fiabilidad. Menos LLM es mejor aqui."

This ADR **respects** that constraint. It does NOT add generative reasoning.
It adds a **deterministic routing improvement** that is fully compatible with
the "less LLM is better" principle: when the repo has a `.pre-commit-config.yaml`,
run `pre-commit run --all-files` FIRST as the single source of truth. Only fall
back to running individual linters when no pre-commit config exists. This is
routing, not judgment.

## Decision
Add a pre-commit routing step at the START of the lint workflow:
1. Detect `.pre-commit-config.yaml` at repo root.
2. If present: run `pre-commit run --all-files` (single deterministic pass that
   already encodes the project's lint order). Report its output verbatim with
   `file:line` anchors. Skip the per-language tool matrix (it is redundant when
   pre-commit exists).
3. If absent: keep the existing per-language tool matrix workflow unchanged.

## Alternatives rejected
- Add generative reasoning to "judge" style: EXPLICITLY REJECTED per informe C.
  Generative judgment would introduce non-determinism and degrade reliability.
- Always run both pre-commit AND per-language matrix: redundant, +cost, +noise.
  Rejected.
- Ignore pre-commit config when present: wastes the project's declared lint
  contract. Rejected.

## Consequences
- (+) Respects the project's own lint contract when declared (pre-commit).
- (+) Less noise: no duplicate findings from pre-commit + per-tool runs.
- (+) Stays deterministic -- routing only, no generative judgment.
- (-) If pre-commit config is misconfigured, inherits its gaps. Mitigation:
  the report flags missing tools so ultracode can propose pre-commit fixes.

## Risk note (override disclosure)
This is an explicit override of the report's discernimiento C for
`linting-agent`. The override is NARROW: it adds deterministic routing only,
NOT generative reasoning. The core principle "less LLM is better here" is
preserved -- the LLM role remains routing + report normalization, not
judgment.

## Edit spec
See Edit below: INSERT pre-commit routing step at Workflow step 4 (before
running formatters) in `content/subagents/linting-agent.md`.

## Approval
- Human: Accepted (explicit user approval 2026-06-24, override requested with justification).
