# Security Rules

## Zero Trust — CRITICAL

NEVER output secrets → use `<REDACTED>`.
ALWAYS validate inputs + HTTPS/TLS + least_privilege.

## Secret Hygiene — CRITICAL

NEVER pass secrets as inline CLI args:
```bash
# BAD — lands in shell history
cmd --token=abc
TF_VAR_x="secret" cmd

# GOOD
export VAR=secret   # separate step
cmd
```

NEVER suggest copying a real token into a command in chat.

## Cloud APIs — CRITICAL

Services with non-obvious constraints (regex patterns, ARN formats, IAM evaluation logic) → read official docs BEFORE first attempt. NEVER assume behavior matches intuition.

## Error Handling — MANDATORY

NEVER silent_catch. Specific exceptions. Check return values.
Generic messages → users. Detailed messages → logs only.

## PII & Sensitive Data — CRITICAL

- NEVER use real user data (emails, phones, IDs, names) in tests, fixtures, prompts, or logs.
- Synthetic fixtures always. Real data in tests = security violation.
- Log redaction: PII fields must be redacted before logging. Log `user_id` only, never `email` or `name`.
- Anonymize before analysis: if prod data required, request anonymized export first.
- NEVER cache or store sensitive data beyond minimum required for the task.

## Documentation

Comments: WHY NOT HOW/WHAT.
Comment: non-obvious + tradeoffs + workarounds + security-critical logic.
NOT: obvious + outdated + apologies.

Security-critical logic and non-obvious tradeoffs MAY include a WHY comment without explicit request.
All other comments: only on request.

## Agent Runtime Hygiene

From Anthropic Claude Code security docs (https://code.claude.com/docs/en/security,
accessed 2026-06-30):

- Monitor agent usage via OpenTelemetry metrics [V]
- Audit or block settings changes mid-session via ConfigChange hooks [V]
- Use dev containers for additional isolation with sensitive code [V]
- Windows: NEVER enable WebDAV or allow `\\*` paths - deprecated, bypasses
  permission system [V]
- Credential storage: prefer OS keychain (macOS Keychain) or file-perm-protected
  storage on Win/Linux [V] (restates secret hygiene for agent-runtime context)
