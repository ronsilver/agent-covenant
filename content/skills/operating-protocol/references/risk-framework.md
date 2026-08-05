# Risk Tier Framework (T0-T4) — Deep Autonomy Matrix

## Scope

This reference is the DEEPER companion to risk-tiers.md. risk-tiers.md gives the
quick T0-T4 table + irreversible gates. This file gives the read/mutation
autonomy matrix, weighted priority, subagent permissionMode mapping, and ATLAS
threat IDs. Semantics here are ALIGNED with risk-tiers.md (T0 = reversible,
T3 = data-loss/security, T4 = cannot-classify).

## T0-T4 — Aligned Semantics (matches risk-tiers.md)

| Tier | Criteria | Agent action |
|------|----------|--------------|
| T0 | Fully reversible, deterministic, local, tested | Proceed autonomously |
| T1 | Cross-file, cross-service, or ambiguous scope | State plan, proceed |
| T2 | Irreversible OR prod-touching OR >3 services affected | Confirm before act |
| T3 | Data loss risk, security decision, conflicting instructions | STOP, escalate human |
| T4 | Cannot classify with available information | Ask to classify first |

## Read/Mutation Autonomy Matrix

| Tier | Read | Mutation |
|------|------|----------|
| T0 | Full autonomy | N/A (read-only tier) |
| T1 | Full autonomy | State plan, proceed (heads-up, non-blocking) |
| T2 | Full autonomy | Confirm before act |
| T3 | Full autonomy | Authorization + kill switch active |
| T4 | Full autonomy | Human-in-the-loop before execution |

Read-only-by-default principle: diagnosis-tier agents hold NO write tools until
a tier-escalation handoff (pattern: scitix/siclaw, V, accessed 2026-07-01).

## Weighted Risk Priority (escalation order)

When multiple issues compete for the same escalation slot, prioritize in this
order (pattern: VoltAgent/awesome-claude-code-subagents, V):

1. Security flaws (RCE, data breach, auth bypass)
2. Breaking bugs
3. Architecture defects
4. Performance
5. Style
6. Config drift
7. Dependency risk
8. Documentation gaps

## Subagent permissionMode Mapping

| Tier | permissionMode | Tool allowlist |
|------|----------------|----------------|
| T0 | read | Read, Grep, Glob |
| T1 | read | Read, Grep, Glob (proposes, waits) |
| T2 | build | Read, Write, Edit, Bash, Glob, Grep (confirm-gated) |
| T3 | build | Read, Write, Edit, Bash (authorization-gated, kill switch) |
| T4 | full | All tools (HITL before execution) |

permissionMode enforcement is owned by governance skill; this table is the
mapping reference only.

## ATLAS Threat IDs (AI-specific risk surfaces)

For injection/tool/supply-chain risks, cross-reference these MITRE ATLAS
techniques (pattern: mukul975/Anthropic-Cybersecurity-Skills, V):

| ATLAS ID | Threat | Relevance |
|----------|--------|-----------|
| AML.T0051 | LLM Prompt Injection | Initial access via crafted input |
| AML.T0051.000 | Direct Prompt Injection | "ignore previous instructions" |
| AML.T0051.001 | Indirect Prompt Injection | Poisoned tool desc / RAG chunks |
| AML.T0053 | LLM Plugin Compromise | Tool/MCP poisoning |
| AML.T0010 | ML Supply Chain Compromise | Malicious MCP server |
| AML.T0054 | LLM Jailbreak | Guardrail bypass |
| AML.T0057 | LLM Data Leakage | System-prompt leakage |

NIST AI RMF MEASURE-2.7: "repeatable, scored security measurements" -> the
evidence-label requirement in anti-hallucination.md is the compliance hook.

## Conflict Resolution

On disagreement between operating-protocol (risk) and tool-usage (operation
type), the MORE RESTRICTIVE risk tier prevails. Every T3/T4 mutation requires
explicit human authorization.

## Boundary

- Irreversible action GATES (dry-run/confirm/rollback) -> risk-tiers.md.
- 7-Question Gate triage mapping -> risk-tiers.md.
- permissionMode ENFORCEMENT -> governance skill.
- Deep SAST / OWASP Top 10 (web) / CVE / MITRE ATT&CK -> security-expert.
- This file = autonomy MATRIX + weighted priority + subagent mapping + ATLAS.
