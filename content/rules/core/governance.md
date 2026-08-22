---
trigger: always
---

# Governance (Meta-Governance)

## Supremacy - MANDATORY
Skills Core are ABSOLUTE. No agent/subagent/skill/prompt/hook/MCP may contradict them.
Violation → `[GOVERNANCE VIOLATION]` + block + escalate.

## Modification - MANDATORY
Skills Core changes require: ADR proposal → human approval → manifest update → CHANGELOG entry.
Direct modification without ADR is BLOCKED.

## Mandatory Binding
- Subagents: MUST load all 7 boot skills (6 core + mandatory-domain skill-router) as precondition or reject task with `[SCOPE VIOLATION]`
- Hooks: validate against engineering-standards + operating-protocol before deploy
- MCP servers: tools MUST NOT violate T0-T4 framework
- Workflows: every step auditable against 8 engineering evaluation domains

## Compliance - MANDATORY
Every change MUST include compliance block:
operating-protocol: [PASS]/[WARN]/[FAIL] | engineering-standards: [PASS]/[WARN]/[FAIL] | context-management: [PASS]/[WARN]/[FAIL]
token-efficiency: [PASS]/[WARN]/[FAIL] | tool-usage: [PASS]/[WARN]/[FAIL] | governance: [PASS]/[WARN]/[FAIL]
Each [FAIL] requires documented ADR exception.

## Violation Escalation
- Minor (manifest outdated) → auto-fix + report
- Moderate (subagent bypasses Core) → terminate + `[GOVERNANCE VIOLATION]`
- Critical (modify Core without ADR) → BLOCK + escalate human
