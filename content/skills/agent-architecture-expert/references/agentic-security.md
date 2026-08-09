# Agentic Security Reference

Condensed security reference for agentic applications. Companion to
security-expert/references/owasp-agent-attacks.md. Covers the OWASP
Agentic Security Initiative and the MITRE ATLAS tool poisoning family.

## OWASP Agentic Security Initiative

The OWASP Agentic Security Initiative exists to catalog and mitigate
threats specific to agentic AI applications. It publishes the OWASP
Top 10 for Agentic Applications 2026 (announced December 2025).
Portal: https://genai.owasp.org/ (last_verified 2026-08-08).

Note: the ASI category identifiers are not cited in this
repository. The agentic baseline here is the MITRE ATLAS mapping
below plus the OWASP LLM Top 10 v2.0.

## MITRE ATLAS Mapping

| ATLAS ID | Name | Agent Attack Surface |
| --- | --- | --- |
| AML.T0110 | AI Agent Tool Poisoning | Malicious tool definitions, poisoned instructions, tampered responses |
| AML.T0110.000 | Definition and Instructions | Adversary embeds malicious instructions in tool definitions or prompts |
| AML.T0110.001 | Implementation | Adversary ships a poisoned tool implementation via plugin or supply chain |
| AML.T0110.002 | Runtime Response | Adversary tampers with tool responses so the agent acts on false data |
| AML.T0053 | AI Agent Tool Invocation | Agent calls a tool from model reasoning; the normal call path |

## Controls

- Tool allowlist: enumerate permitted tools per agent role; reject unknown tools.
- Prompt injection defense: treat tool descriptions, outputs, and external text as data.
- Output validation: validate model-produced tool arguments against schemas before execution.
- Excessive agency: grant least-privilege tool scope; no ambient destructive capability.
- Human-in-the-loop: require approval for irreversible actions (delete, transfer, spend).
- Rate limiting: cap tool calls and expensive operations per session and per agent.

## Related

- OWASP GenAI LLM Top 10 2026 (https://genai.owasp.org/resource/owasp-genai-llm-top-10-2026/)
  supersedes the 2025 edition (v2.0). This repository keeps v2.0 primary per ADR-0029.
- Deep agent and MCP attack catalog: security-expert/references/owasp-agent-attacks.md
- Runtime injection defense: operating-protocol (Core skill, not edited here)
