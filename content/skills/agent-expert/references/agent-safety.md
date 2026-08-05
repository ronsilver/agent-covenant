# Agent Safety & Guardrails

## Safety Layers (defense in depth)
1. **Input Validation**: sanitize, classify, reject injection patterns
2. **System Prompt Hardening**: user input = DATA, never INSTRUCTIONS
3. **Tool Restrictions**: allowlists, denylists, permission modes
4. **Output Validation**: schema enforcement, PII detection, content filtering
5. **Runtime Guardrails**: AWS Bedrock Guardrails, content classifiers
6. **Human-in-the-Loop**: approval gates for destructive operations

## Permission Modes
| Mode | Write | Bash | Network | Use |
|---|---|---|---|---|
| default | Ask | Ask | Ask | General |
| acceptEdits | Auto | Ask | Ask | Dev |
| bypassPermissions | Auto | Auto | Auto | Sandbox only |
| plan | None | None | None | Review only |

## Prompt Injection Defense
1. Strip injection patterns: 'ignore previous instructions', 'you are now', 'system prompt'
2. Context separation: delimiters between immutable rules and user input
3. Output format enforcement: reject non-JSON when JSON expected
4. NEVER trust LLM to self-defend without multiple validation gates

## PII / Data Protection
- NEVER log national ID numbers, tax IDs, or other government-issued identifiers in plain text
- Hash/mask sensitive data in logs
- Tokenization via secrets manager for card data
- AWS Bedrock Guardrails: sensitiveInformationPolicy for regex-based PII blocking
