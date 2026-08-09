# ADR-0029: MITRE ATLAS Canonicalization and Framework Mapping Correction

**Date:** 2026-08-08
**Status:** Approved

## Context

Core skills reference MITRE ATLAS threat IDs with stale or wrong names
(verified 2026-08-08 against mitre-atlas/atlas-data, release 2026.07, format
v6.0.0): AML.T0053 labeled "LLM Plugin Compromise", AML.T0010 labeled "ML
Supply Chain Compromise", AML.T0000 labeled "ML Model Access", and ATLAS
version cited as v5.4 / 84 techniques. This ADR canonicalizes every in-scope
occurrence and resolves ADR-0028 Follow-up items #1, #2, #3. The OWASP LLM
Top 10 2026 edition (published 2026-08-04) is recorded as a source note +
drift warning only; full taxonomy swap is deferred to a separate ADR.

## Decision

Canonical names (used by ADR-0030/0031/0032):

| ID | Canonical name | Replaces |
|----|----------------|----------|
| AML.T0053 | AI Agent Tool Invocation | "LLM Plugin Compromise" |
| AML.T0110 | AI Agent Tool Poisoning (.000 Definition and Instructions, .001 Implementation, .002 Runtime Response) | (missing) |
| AML.T0010 | AI Supply Chain Compromise | "ML Supply Chain Compromise" |
| AML.TA0000 | AI Model Access (tactic) | "ML Model Access" (wrong ID/name) |
| AML.T0000 | Search Open Technical Databases | (correct technique, retained) |

Also: framework-mapping ATLAS section header v5.4 → release 2026.07 (178
techniques, not 84); OWASP Top 10 URL → https://owasp.org/Top10/ in
engineering-standards/SKILL.md:207 and docs/SKILL_QUALITY_STANDARD.md:180.
NO version bump in this ADR — co-bumps live in ADR-0030 (op 2.3) and
ADR-0031 (eng-std 2.3), atomic co-merge (F7).

## Alternatives Considered

1. Keep v5.4 and only fix names: rejected — mapping claims a live-verified
   release; a false technique count while claiming verification is
   self-contradictory.
2. Swap to 5.4.0 / 155 techniques: rejected — target is current release
   2026.07 (178).
3. Full LLM Top 10 2026 swap now: rejected (decision preserved) — source
   note only.
4. Leave evals.json:174 stale: rejected — eval would grade the pre-2025 name
   as correct.

## Consequences

- One canonical ID set across framework-mapping.md, untrusted-content.md,
  risk-framework.md, evals.json.
- ADR-0028 follow-ups #1-#3 closed.
- ADR-0032 domain 8 can grep stale names with deterministic exit code.
- Atomic co-merge with ADR-0030 + ADR-0031 required (F7).

## Follow-up (out of scope, requires separate ADR)

1. OWASP LLM Top 10 2026 full taxonomy swap.
2. Verify AML.T0054 ("LLM Jailbreak" vs "AI Jailbreak") canonical rename.
3. Re-verify ATLAS technique count on each version bump.

## Evidence

- mitre-atlas/atlas-data (release 2026.07, format v6.0.0), accessed 2026-08-08.
- ADR-0028 Evidence: AML.T0110 AI Agent Tool Poisoning; AML.T0053 AI Agent
  Tool Invocation.
- Repo scan 2026-08-08: stale names at the lines listed in Appendix A.

## Appendix A — Applied Edits

| ID | File | oldText | newText |
|----|------|---------|---------|
| E1 | engineering-standards/references/framework-mapping.md:51-53 | `## MITRE ATLAS v5.4 -- Agentic AI Threat Governance (CORRECTED IDs)\n\nATLAS v5.4 covers 16 tactics, 84 techniques including agentic AI vectors.` | `## MITRE ATLAS 2026.07 -- Agentic AI Threat Governance (CORRECTED IDs)\n\nATLAS release 2026.07 (format v6.0.0) covers 16 tactics, 178 techniques including agentic AI vectors.` |
| E2 | framework-mapping.md:13 | `Source: MITRE ATLAS v5.4 https://atlas.mitre.org (accessed 2026-07-02).` | `Source: MITRE ATLAS release 2026.07 (format v6.0.0) https://atlas.mitre.org (accessed 2026-08-08).` |
| E3 | framework-mapping.md:60 | `\| AML.T0010 \| ML Supply Chain Compromise \| mcp-review-criteria.md stage 2 review gate (provenance + license + signature) \|` | `\| AML.T0010 \| AI Supply Chain Compromise \| mcp-review-criteria.md stage 2 review gate (provenance + license + signature) \|` |
| E4 | framework-mapping.md (after row 60, add row) | `\| AML.T0010 \| AI Supply Chain Compromise \| mcp-review-criteria.md stage 2 review gate (provenance + license + signature) \|` | `\| AML.T0010 \| AI Supply Chain Compromise \| mcp-review-criteria.md stage 2 review gate (provenance + license + signature) \|\n\| AML.T0110 \| AI Agent Tool Poisoning \| Reject skill-defined tool descriptions/implementations with embedded instructions; tool args validated at boundary (ADR-0030) \|` |
| E5 | framework-mapping.md:63 | `\| AML.T0000 \| ML Model Access \| Scoped credentials (mcp-review-criteria.md control 3) \|` | `\| AML.TA0000 \| AI Model Access \| Scoped credentials (mcp-review-criteria.md control 3) \|` |
| E6 | framework-mapping.md:65-68 (NOTE) | `NOTE: AML.T0051 is "LLM Prompt Injection" (not "context poisoning" -- that is\nAML.T0080). AML.T0010 is "ML Supply Chain Compromise" (not "MCP compromise").\nAML.T0057 is "LLM Data Leakage" (not "malicious agent"). These corrections\nare based on MITRE ATLAS official technique names.` | `NOTE: AML.T0051 is "LLM Prompt Injection" (not "context poisoning" -- that is AML.T0080). AML.T0053 is "AI Agent Tool Invocation" (not "LLM Plugin Compromise"); tool poisoning is AML.T0110. AML.T0010 is "AI Supply Chain Compromise" (renamed ML to AI in 2025). AML.TA0000 is "AI Model Access" (not "ML Model Access"). AML.T0057 is "LLM Data Leakage" (not "malicious agent"). These corrections are based on MITRE ATLAS official technique names (release 2026.07).` |
| E7 | engineering-standards/evals/evals.json:174 | `        "identifies AML.T0010 as ML Supply Chain Compromise (NOT 'MCP compromise')",` | `        "identifies AML.T0010 as AI Supply Chain Compromise (NOT 'MCP compromise')",` |
| E8 | operating-protocol/references/untrusted-content.md:42-43 | `\| AML.T0053 \| LLM Plugin Compromise (tool/MCP poisoning) \|\n\| AML.T0010 \| ML Supply Chain Compromise (malicious MCP server) \|` | `\| AML.T0053 \| AI Agent Tool Invocation (tool call execution) \|\n\| AML.T0110 \| AI Agent Tool Poisoning (family: .000/.001/.002) \|\n\| AML.T0110.000 \| Tool Poisoning: Definition and Instructions \|\n\| AML.T0110.001 \| Tool Poisoning: Implementation \|\n\| AML.T0110.002 \| Tool Poisoning: Runtime Response \|\n\| AML.T0010 \| AI Supply Chain Compromise (malicious MCP server) \|` |
| E9 | operating-protocol/references/risk-framework.md:71-72 | `\| AML.T0053 \| LLM Plugin Compromise \| Tool/MCP poisoning \|\n\| AML.T0010 \| ML Supply Chain Compromise \| Malicious MCP server \|` | `\| AML.T0053 \| AI Agent Tool Invocation \| Tool call execution surface \|\n\| AML.T0110 \| AI Agent Tool Poisoning \| Tool/MCP poisoning (.000/.001/.002) \|\n\| AML.T0010 \| AI Supply Chain Compromise \| Malicious MCP server \|` |
| E10 | engineering-standards/SKILL.md:207 | `- OWASP Top 10: https://owasp.org/www-project-top-ten/ (last_verified: 2026-05)` | `- OWASP Top 10 (2025): https://owasp.org/Top10/ (last_verified: 2026-08-08)` |
| E11 | docs/SKILL_QUALITY_STANDARD.md:180 | `\| Official OWASP Top 10 \| https://owasp.org/www-project-top-ten/ \| 2026-05-25 \|` | `\| Official OWASP Top 10 (2025) \| https://owasp.org/Top10/ \| 2026-08-08 \|` |
