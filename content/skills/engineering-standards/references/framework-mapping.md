# Framework Mapping -- Ingestion/Audit-Time Governance Controls

## Scope - CRITICAL

Maps governance controls to 4 industry frameworks at INGESTION TIME (skill/
MCP/subagent onboarding) and AUDIT TIME (compliance-audit.md gate). Does NOT
cover runtime defense (owned by operating-protocol) or prompt-design defense
(owned by prompt-expert). Does NOT hunt MITRE ATT&CK techniques (owned by
security-expert). The review PROCESS is owned by governance/mcp-lifecycle.md.

Source: OWASP LLM Top 10 v2.0 (2025) https://github.com/OWASP/www-project-top-10-for-large-language-model-applications/tree/main/2_0_vulns (accessed 2026-07-02, CC BY-SA 4.0).
Source: NIST AI RMF 1.0 + GenAI Profile (AI 600-1, July 2024) https://airc.nist.gov/AI_RMF (accessed 2026-07-02).
Source: MITRE ATLAS release 2026.07 (format v6.0.0) https://atlas.mitre.org (accessed 2026-08-08).
Source: NIST CSF 2.0 (Feb 2024) https://www.nist.gov/cyberframework (accessed 2026-07-02).

## OWASP LLM Top 10 v2.0 -- Ingestion Controls

| OWASP ID | Risk | Ingestion control (this file) | Runtime owner |
|----------|------|-------------------------------|---------------|
| LLM01 (direct) | Prompt injection in skill content | Scan skill text for embedded instructions; reject supremacy-override patterns | operating-protocol |
| LLM01 (indirect) | Skill fetches external data without isolation | Require isolation boundary declaration | operating-protocol |
| LLM02 | Sensitive info disclosure | gitleaks + PII synthetic-fixture scan | engineering-standards |
| LLM03 | Supply chain | Provenance, license, signature, SC-15 MCP review | engineering-standards/supply-chain.md + governance/mcp-lifecycle.md (PROCESS) |
| LLM04 | Data/model poisoning | Scan reference docs for poisoned examples | engineering-standards |
| LLM05 | Improper output handling | Reject exec/eval on model output without validate-then-execute | operating-protocol |
| LLM06 | Excessive agency | permissionMode declared; reject trigger:always + destructive tools | operating-protocol T2 gate |
| LLM07 | System prompt leakage | Reject instruction-hierarchy violations | prompt-expert |
| LLM08 | Vector/embedding weaknesses | Out of scope (no RAG in marketplace) | vector-databases |
| LLM09 | Misinformation | Out of scope (runtime accuracy) | evaluation-expert |
| LLM10 | Unbounded consumption | Require max_token_budget + max_tool_calls declaration | token-efficiency |

## NIST AI RMF 1.0 -- Govern Function Alignment

NIST AI RMF defines 4 functions: Govern (GV), Map (MP), Measure (MS), Manage
(MG). This file maps the GOVERN function (72 subcategories total; Govern has
30+ in cybersecurity-skills mapping).

| NIST AI RMF (Govern) | Ingestion/audit control |
|----------------------|------------------------|
| GV.AT-01 (roles/responsibilities) | ADR lifecycle assigns ownership (governance/adr-lifecycle.md) |
| GV.RR-01 (resources) | Manifest registration enforced (make validate) |
| GV.RM-01 (risk monitored) | governance/compliance-audit.md quarterly gate |
| GV.PO-01 (policy) | Supremacy clause + Mandatory Binding |
| GV.OE-01 (organizational ethics) | Discoverability invariant #8 (no hidden subagents) |

NOTE: Colorado AI Act (effective February 2026) provides legal safe harbor
for organizations complying with NIST AI RMF. This mapping is directly
relevant to regulatory compliance for this project AI features (the AI service).
Source: Colorado AI Act (SB 24-205), not NIST AI RMF itself.

## MITRE ATLAS 2026.07 -- Agentic AI Threat Governance (CORRECTED IDs)

ATLAS release 2026.07 (format v6.0.0) covers 16 tactics, 178 techniques including agentic AI vectors.
IDs below use official MITRE ATLAS names (verified against cybersecurity-skills
repo mappings, accessed 2026-07-02).

| ATLAS ID | Official name | Ingestion control |
|----------|---------------|-------------------|
| AML.T0051 | LLM Prompt Injection | Reject skills that fetch external data without isolation boundary |
| AML.T0010 | AI Supply Chain Compromise | mcp-review-criteria.md stage 2 review gate (provenance + license + signature) |
| AML.T0110 | AI Agent Tool Poisoning | Reject skill-defined tool descriptions/implementations with embedded instructions; tool args validated at boundary (ADR-0030) |
| AML.T0057 | LLM Data Leakage | Discoverability invariant #8 + subagent mandatory binding |
| AML.T0080 | AI Agent Context Poisoning | Reject skills with supremacy-override patterns; require isolation boundary |
| AML.TA0000 | AI Model Access | Scoped credentials (mcp-review-criteria.md control 3) |

NOTE: AML.T0051 is "LLM Prompt Injection" (not "context poisoning" -- that is
AML.T0080). AML.T0053 is "AI Agent Tool Invocation"; tool poisoning is
AML.T0110. AML.T0010 is "AI Supply Chain Compromise" (renamed ML to AI in
2025). AML.TA0000 is "AI Model Access"; AML.T0000 is "Search Open Technical
Databases". AML.T0057 is "LLM Data Leakage" (not "malicious agent"). These
corrections are based on MITRE ATLAS official technique names (release 2026.07).

## NIST CSF 2.0 -- Govern Function (new in v2.0)

NIST CSF 2.0 (Feb 2024) added the GOVERN function, expanding scope from
critical infrastructure to all organizations. 22 categories, 106 subcategories.

| CSF 2.0 (Govern) | Ingestion/audit control |
|------------------|------------------------|
| GV.OC (organizational context) | skills-core-definition.md defines scope |
| GV.RM (risk management strategy) | governance/violation-escalation.md severity tiers |
| GV.RR (roles/responsibilities) | ADR lifecycle ownership |
| GV.PO (policy) | Supremacy clause + Mandatory Binding |
| GV.OV (oversight) | governance/compliance-audit.md quarterly gate |
| GV.SC (supply chain) | mcp-review-criteria.md + supply-chain.md SC-15 |

## Cross-references (boundary)

- REVIEW PROCESS (WHO, WHEN, trust events): -> governance/references/mcp-lifecycle.md
- Runtime injection defense (LLM01/LLM05 at runtime): -> operating-protocol/references/untrusted-content.md
- Prompt-design injection defense (LLM01/LLM07 design): -> prompt-expert/references/injection-defense.md
- Deep SAST / OWASP Top 10 (web) / CVE / MITRE ATT&CK technique hunting: -> security-expert
- PCI DSS / CDE / PAN tokenization: -> security-expert
- This file = INGESTION-TIME + AUDIT-TIME criteria only.

## Version drift warning

OWASP LLM Top 10 may release v2.1+; NIST AI RMF may update; MITRE ATLAS updates
quarterly. Re-verify framework versions via scripts/quarterly_review.py.
last_verified: 2026-07-02.
