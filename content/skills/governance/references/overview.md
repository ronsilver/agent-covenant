# Governance -- Overview

Meta-governance: guards the other 5 Skills Core. Defines modification rules, mandatory binding, compliance audit, violation escalation, MCP lifecycle (PROCESS), and ADR lifecycle.

## Reference Files

| File | Content |
|---|---|
| [mcp-lifecycle.md](mcp-lifecycle.md) | MCP server governance PROCESS (5 stages: proposal, review, activation, drift, deprecation) + trust event recording. Criteria -> engineering-standards/mcp-review-criteria.md |
| [adr-lifecycle.md](adr-lifecycle.md) | ADR proposal to archive lifecycle + OpenSpec /opsx binding + spec-kit constitution pattern |
| [compliance-audit.md](compliance-audit.md) | Deterministic 7-domain compliance audit + drift detection + exit-code gate (audits by reference) |
| [violation-escalation.md](violation-escalation.md) | 4-severity escalation catalog + 6-tag catalog + 5-layer observer guard |

## Glossary

- GOVERNANCE VIOLATION: any entity bypasses a Skills Core rule
- SCOPE VIOLATION: subagent executes without loading all 6 Core skills
- CORE CONFLICT: deadlock between Skills Core not resolved by precedence hierarchy
- DISCOVERABILITY VIOLATION: subagent sets hidden: true (invariant #8)
- HITL: human-in-the-loop approval required for irreversible changes
- ADR: architecture decision record (docs/adr/)
- SC-15: engineering-standards supply-chain threat row mandating governance owns MCP-review PROCESS
