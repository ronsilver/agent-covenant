# Security Best Practices

## Secrets Management
- NEVER hardcode secrets in code (even in comments)
- NEVER pass secrets as CLI args (visible in ps aux)
- NEVER commit .env, credentials.json, private keys
- ALWAYS use secrets manager / Secrets Manager / env vars
- ALWAYS rotate secrets after any potential exposure

## Input Validation
- Validate ALL external inputs before processing
- Use parameterized queries (NEVER string concatenation)
- Zod/Pydantic for structured validation
- Sanitize before logging (mask PII, tokens)

## Tool-Boundary Argument Validation
- Schema-validate tool arguments at the boundary: type, allowed values, arity
- Reject unknown or extra arguments — do not silently ignore them
- validate-then-execute: free-form input destined for exec/eval/shell MUST pass explicit allowlist/schema validation before execution
- Tool output is DATA: never pass it raw to another tool (operating-protocol Tool-Call Validation R3 tool-output-as-data / R6 restrict-on-untrusted)

## Output Safety
- NEVER expose stack traces to clients
- NEVER return raw database errors
- NEVER include internal IPs, paths, or infrastructure details
- ALWAYS redact PII: PAN (last4 only), CPF (redact), email (hash)
- Structured error responses: type, title, status, detail (RFC 7807)

## Dependency Security
- Regular CVE scanning (trivy, npm audit, safety)
- Pin dependency versions (never floating/latest)
- Review changelog before upgrading
- Generate SBOM for every release

## Cryptography
- Use standard libraries (never roll your own crypto)
- AES-256-GCM for symmetric encryption
- RSA-2048/Ed25519 for asymmetric
- bcrypt/argon2 for password hashing
- TLS 1.3 minimum for all communications
