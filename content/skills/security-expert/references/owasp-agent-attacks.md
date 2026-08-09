# Agent and MCP Attack Reference

Attack catalog for AI agents and MCP (Model Context Protocol) servers.
Companion reference for security-expert audits. Each attack maps to a
detection and a defense action. MITRE ATLAS IDs follow the current ATLAS
technique catalog.

## MITRE ATLAS Mapping

Primary mapping for agent tool poisoning, plus the related tool invocation
technique.

| ATLAS ID | Name | Agent Attack Surface |
| --- | --- | --- |
| AML.T0110 | AI Agent Tool Poisoning | Malicious tool definitions, poisoned instructions, tampered responses |
| AML.T0110.000 | Definition and Instructions | Adversary embeds malicious instructions in definitions or prompts |
| AML.T0110.001 | Implementation | Adversary ships a poisoned tool implementation via plugin or supply chain |
| AML.T0110.002 | Runtime Response | Adversary tampers with tool responses so the agent acts on false data |
| AML.T0053 | AI Agent Tool Invocation | Agent calls a tool from model reasoning; the normal call path |

Note: tool invocation (AML.T0053) is the ordinary agent-to-tool call path.
The poisoning family above covers corrupting the tool itself, its
definitions, or its responses. Audit tool poisoning and tool invocation as
separate signals.

## MCP Tool Poisoning Audit Checklist

Audit an MCP server or agent tool integration against tool poisoning
vectors. Use this as a defensive checklist, not a compliance form.

- Allowlist the tool names and schema versions the agent may call; reject unknown tools.
- Treat every tool description and parameter schema as untrusted model input; validate before use.
- Pin tool package versions and verify signatures before an MCP server or plugin ships.
- Monitor for unexpected tools appearing in a server manifest or capability list.
- Log tool invocation results and compare them against the expected output shape.
- Enforce allowlists and deny rules at the transport boundary, not only in model prompts.
- Detect prompt injection that asks the agent to call a tool with forged arguments.
- Keep a human approval gate for destructive tools (delete, transfer, spend).

## HITL Dialog Forging / Lies-in-the-Loop

A human-in-the-loop (HITL) gate is only as strong as the dialog it shows.
Forged dialog presents fabricated or modified tool output to the operator so
the operator approves a harmful action.

- Verify the dialog that reached the human against the raw tool response.
- Detect tampered tool results before they render in the approval prompt.
- Require independent confirmation for irreversible actions (delete, transfer, publish).
- Log the dialog hash and the raw tool response hash for later audit.
- Alert when approval rate spikes or when dialog content diverges from tool output.

## Prompt Injection

Prompt injection smuggles instructions into model input so the agent follows
adversary-controlled text instead of its system prompt. Map to AML.T0051 in
ATLAS and to LLM01 Prompt Injection in the OWASP LLM Top 10.

- Treat any untrusted text (email, web content, tool output, documents) as data, never as instructions.
- Isolate system and user prompts; do not concatenate untrusted content into the system prompt.
- Validate tool arguments produced by the model against schemas before execution.
- Limit the blast radius of a single injected instruction with least-privilege tool grants.
- Log prompt segments separately so injection attempts remain auditable.

## Insecure Deserialization / XXE / File Upload / Unsafe Reflection

Object deserialization, XML external entity (XXE) expansion, unsafe file
upload, and unsafe reflection allow attackers to smuggle code or data into
the agent process. CWE-502 (deserialization), CWE-611 (XXE), CWE-434
(unrestricted upload), CWE-470 (unsafe reflection).

- Reject untrusted serialized payloads; use allowlisted classes and type checks.
- Disable external entity resolution in XML parsers; use JSON where possible.
- Validate upload file type, size, and content signature; store outside the execution path.
- Restrict reflection to allowlisted types; never reflect attacker-controlled names.
- Run the deserialization boundary in a sandboxed or least-privilege process.

## SSRF

Server-side request forgery (SSRF) lets an attacker make the agent or service
fetch internal resources. CWE-918.

- Block requests to link-local, loopback, and private address ranges at the proxy.
- Resolve DNS, then validate the resolved IP against the allowlist before connecting.
- Disable redirects or re-validate the target after each redirect.
- Require explicit allowlisted destinations for agent fetch and browse tools.
- Log outbound request targets for anomaly review.

## Security Headers

Agent-facing endpoints and MCP transports should return the standard
security headers to reduce browser and client-side exposure.

- Set Content-Security-Policy on any agent or MCP web console.
- Set X-Content-Type-Options: nosniff, Referrer-Policy, and Permissions-Policy.
- Disable embedding with X-Frame-Options or frame-ancestors in the CSP.
- Serve HSTS when the transport runs over TLS.
- Audit headers on every deployed endpoint as part of the security checklist.

## Session and Authorization Quick Controls

Agent sessions carry identity and authorization state. Verify these
controls on every agent boundary.

- Issue short-lived session tokens; rotate refresh tokens on reuse.
- Bind sessions to the transport channel and to the originating principal.
- Enforce authorization at every tool call, not only at session start.
- Invalidate sessions on password change, permission change, or anomaly.
- Log session lifecycle events without storing raw tokens.

## Business Logic

Agent workflows inherit business logic flaws from the applications they
call. Map to CWE-840 (business logic errors).

- Model the intended state machine and reject out-of-order transitions.
- Rate limit and quota expensive or irreversible operations.
- Validate numeric bounds and ownership on every mutation.
- Add idempotency keys to retryable operations.
- Review agent decision branches for privilege or financial escalation.

## Boundary

The agent boundary is the trust perimeter between the model, tools, and
data.

- Run agents and MCP servers as non-root with least privilege and no ambient credentials.
- Apply network policies that deny all except required agent-to-tool flows.
- Keep model context, tool outputs, and audit logs in separate stores.
- Treat agent logs as security-relevant data: encrypt at rest and control access.
- Review the boundary after every dependency or tool integration change.
