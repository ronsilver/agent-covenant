# Violation Escalation -- Severity Catalog

## Scope

Defines the 4-severity escalation taxonomy, the tag catalog, and the 5-layer
observer guard (adopted from affaan-m/ECC). Expands the Violation Escalation
table in SKILL.md with detection triggers + audit log requirements.

Source: https://github.com/affaan-m/ECC (accessed 2026-07-02, [unverified] adoption; pattern from README) -- observer loop prevention 5-layer guard.

## 4-Severity Catalog

| Severity | Condition | Detection trigger | Action | Audit log |
|----------|-----------|-------------------|--------|-----------|
| Minor | Skill Core reference outdated in manifest | make validate warning | Auto-fix + report | CHANGELOG ### Fixed |
| Moderate | Subagent/hook bypasses Core without justification | subagent executes without loading 6 Core skills; hook deploys without safety validation | Terminate + log [GOVERNANCE VIOLATION] | Incident report |
| Critical | Attempt to modify a Skill Core without ADR | direct edit to Core SKILL.md; version bump without CHANGELOG; no human approval | BLOCK + escalate to human | ADR required to proceed |
| Catastrophic | MCP server exposes unsafe operations (T3+) | MCP tool exposes delete/secret-rotation; hidden subagent; supremacy override | Remove from config + report + [BLOCKER] | Security incident + root-cause |

## Tag Catalog

| Tag | Meaning | Severity |
|-----|---------|----------|
| [GOVERNANCE VIOLATION] | Any entity bypasses a Skills Core rule | Moderate+ |
| [SCOPE VIOLATION] | Subagent executes without loading all 6 Core skills | Moderate |
| [CORE CONFLICT] | Cross-core deadlock not resolved by precedence hierarchy | Critical |
| [DISCOVERABILITY VIOLATION] | Subagent sets hidden: true (invariant #8) | Catastrophic |
| [CORE COMPLIANCE FAILURE] | Pre-flight gate (T2+ mutation) fails | Critical |
| [CI GATE VIOLATION] | PR merged with failing CI jobs (invariant #7) | Critical |
| [LANGUAGE POLICY VIOLATION] | Content not in English in content/ or docs/ | Moderate+ (BLOCK) |

## 5-Layer Observer Guard (ECC pattern)

ECC prevents observer loops with a 5-layer guard. Governance binding: any
automated compliance-audit loop MUST include these 5 layers to prevent
infinite escalation cycles:

1. **Re-entrancy guard**: audit cannot trigger itself (audit-of-audit loop).
2. **Tail sampling**: limit audit log entries per cycle (prevent memory explosion).
3. **Throttling**: rate-limit audit runs (prevent CPU burn).
4. **Lazy-start**: audit only runs on signal, not continuously.
5. **Observer-loop detection**: if audit triggers the same violation >2 times,
   escalate to human (not auto-fix again).

Without these layers, an automated governance loop can cascade into resource
exhaustion or infinite violation logging.

## Audit Log Requirements

Every violation (Minor+) MUST record:
- Timestamp (UTC)
- Violating entity (skill/subagent/hook/MCP name)
- Severity
- Detection trigger (which check fired)
- Action taken
- Reviewer (human, if escalated)

Catastrophic violations additionally require a blameless post-mortem within
48h (see debugging-expert/references/postmortem-template.md).

## Boundary

- Runtime error handling: operating-protocol
- Incident response / post-mortem authoring: debugging-expert
- This file = ESCALATION TAXONOMY + tag catalog + observer guard only.
