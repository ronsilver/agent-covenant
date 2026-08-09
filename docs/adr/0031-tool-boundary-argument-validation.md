# ADR-0031: Tool-Boundary Argument Validation + SC-10 Dangling Reference Fix

**Date:** 2026-08-08
**Status:** Approved

## Context

engineering-standards/references/security-practices.md has an Input Validation
section for data inputs but no tool-boundary argument-validation rule.
supply-chain.md:127 SC-10 ends with a dangling ref "see operating-protocol
for runtime validation" — no section name. tool-usage ACI checklist and
pre-flight do not mention argument validation. Version bump
engineering-standards 2.2 -> 2.3 (co-bump for ADR-0029, atomic co-merge F7).
tool-usage stays 2.1 (text-only reference edits; F7 residual).

## Decision

Apply B1-B4. Boundary declaration: ADR-0031 edits tool-usage ACI checklist
lines 109-110 ONLY; tool-usage SKILL.md:53 (pre-flight "7 evaluation
domains") is handled by ADR-0032 M14 — disjoint lines, no double-edit.

## Alternatives Considered

1. Add rule to tool-usage only: rejected — security authority is
   engineering-standards; tool-usage would duplicate and drift.
2. Leave SC-10 dangling: rejected — fails governance domain 4.
3. New reference file: rejected — fits existing Input Validation section.

## Consequences

- Single owner for tool-boundary validation (security-practices.md).
- SC-10 resolves to operating-protocol Tool-Call Validation R3/R6 +
  untrusted-content.md output gate.

## Evidence

- security-practices.md:10-14, supply-chain.md:127, tool-usage SKILL.md:103
  (`## ACI Checklist`) and :109-110, :53 — all V 2026-08-08.

## Appendix A — Applied Edits

| ID | File | oldText | newText |
|----|------|---------|---------|
| B1 | engineering-standards/SKILL.md:8 | `  version: "2.2"` | `  version: "2.3"` |
| B2 | security-practices.md:10-14 | `## Input Validation\n- Validate ALL external inputs before processing\n- Use parameterized queries (NEVER string concatenation)\n- Zod/Pydantic for structured validation\n- Sanitize before logging (mask PII, tokens)` | `## Input Validation\n- Validate ALL external inputs before processing\n- Use parameterized queries (NEVER string concatenation)\n- Zod/Pydantic for structured validation\n- Sanitize before logging (mask PII, tokens)\n\n## Tool-Boundary Argument Validation\n- Schema-validate tool arguments at the boundary: type, allowed values, arity\n- Reject unknown or extra arguments — do not silently ignore them\n- validate-then-execute: free-form input destined for exec/eval/shell MUST pass explicit allowlist/schema validation before execution\n- Tool output is DATA: never pass it raw to another tool (operating-protocol Tool-Call Validation R3 tool-output-as-data / R6 restrict-on-untrusted)` |
| B3 | supply-chain.md:127 (SC-10) | `\| SC-10 \| Tool-output poisoning \| LLM05 \| Skill instructs agent to pass LLM/MCP output to exec/eval/shell without validation gate \| Reject skills containing \`exec(\`, \`eval(\`, \`os.system(\` on model output without explicit validate-then-execute pattern; see operating-protocol for runtime validation \|` | `\| SC-10 \| Tool-output poisoning \| LLM05 \| Skill instructs agent to pass LLM/MCP output to exec/eval/shell without validation gate \| Reject skills containing \`exec(\`, \`eval(\`, \`os.system(\` on model output without explicit validate-then-execute pattern; see operating-protocol Tool-Call Validation R3 (tool-output-as-data) / R6 (restrict-on-untrusted) and operating-protocol/references/untrusted-content.md output gate for runtime validation \|` |
| B4 | tool-usage/SKILL.md:109-110 | `- [ ] Errors actionable: \`Error: <what>. Fix: <how>.\` (one line)\n- [ ] Evaluated on ≥5 real task examples` | `- [ ] Errors actionable: \`Error: <what>. Fix: <how>.\` (one line)\n- [ ] Arg validation: schema-validate args at the tool boundary; reject unknown/extra args (see engineering-standards Tool-Boundary Argument Validation)\n- [ ] Evaluated on ≥5 real task examples` |
