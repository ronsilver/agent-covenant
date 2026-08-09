# OWASP LLM Top 10

The OWASP Top 10 for Large Language Model Applications. This reference keeps
both published editions: the current 2025 edition (v2.0) as the primary
table and the 2023-24 edition (v1.1) as a delta table. Use the 2025 edition
for new audits; consult the 2023-24 edition for legacy review notes.

## 2025 Edition (v2.0) - Primary

Source: OWASP Top 10 for Large Language Model Applications v2.0 (2025),
https://github.com/OWASP/www-project-top-10-for-large-language-model-applications/tree/main/2_0_vulns
(accessed 2026-08-08, CC BY-SA 4.0). Matches
engineering-standards/references/framework-mapping.md.

| ID | Category | Core Defense |
| --- | --- | --- |
| LLM01 | Prompt Injection | Treat untrusted content as data; isolate prompts; validate tool arguments |
| LLM02 | Sensitive Information Disclosure | Redact PII at boundaries; least-privilege data access; no secrets in output |
| LLM03 | Supply Chain | Pin models and packages; verify provenance; SBOM for the model stack |
| LLM04 | Data and Model Poisoning | Validate training data lineage; detect drift; sandbox model updates |
| LLM05 | Improper Output Handling | Encode and validate model output before downstream use |
| LLM06 | Excessive Agency | Least-privilege tool grants; require confirmation for sensitive actions |
| LLM07 | System Prompt Leakage | Do not embed secrets in prompts; treat prompts as application logic |
| LLM08 | Vector and Embedding Weaknesses | Protect embeddings; filter retrieval; monitor index tampering |
| LLM09 | Misinformation | Ground outputs; add citations; verify claims before high-stakes use |
| LLM10 | Unbounded Consumption | Rate limit tokens and requests; budget per session and per user |

## 2023-24 Edition (v1.1) - Delta

Source: OWASP Top 10 for LLM Applications 2023-24 (v1.1),
https://owasp.org/www-project-top-10-for-large-language-model-applications/
(accessed 2026-08-08). Superseded by v2.0; kept for historical context.

| ID | Category |
| --- | --- |
| LLM01 | Prompt Injection |
| LLM02 | Insecure Output Handling |
| LLM03 | Training Data Poisoning |
| LLM04 | Model Denial of Service |
| LLM05 | Supply Chain Vulnerabilities |
| LLM06 | Sensitive Information Disclosure |
| LLM07 | Insecure Plugin Design |
| LLM08 | Excessive Agency |
| LLM09 | Overreliance |
| LLM10 | Model Theft |

## Edition Mapping Note

2025 LLM06 Excessive Agency maps to AI Agent Tool Invocation (AML.T0053) and
to the AI Agent Tool Poisoning family when a tool is maliciously modified.
The 2023-24 LLM06 Sensitive Information Disclosure maps to 2025 LLM02. Other
renames: Insecure Output Handling to Improper Output Handling, Training Data
Poisoning to Data and Model Poisoning; Model Theft is not a standalone
category in the 2025 edition.

## Related OWASP Resources

| Resource | Edition | URL |
| --- | --- | --- |
| OWASP GenAI LLM Top 10 2026 | 2026 (latest announced) | https://genai.owasp.org/resource/owasp-genai-llm-top-10-2026/ |
| OWASP Top 10 for Agentic Applications | In development | https://genai.owasp.org/initiatives/agentic-security-initiative/ |
| OWASP AI Exchange | Ongoing (300+ pages) | https://owaspai.org/ |

Note: the 2025 (v2.0) category table above is the verified baseline. The 2026
edition categories and the Agentic Applications ASI01-ASI10 list are not yet
verified by this audit; confirm contents against the linked URLs before
extending the tables.
