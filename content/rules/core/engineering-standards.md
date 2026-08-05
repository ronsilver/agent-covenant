---
trigger: always
---

# Engineering Standards

## Architecture - MANDATORY
Read context + check reuse + identify impacts before designing.
Apply SOLID/CUPID. Skip: scripts, prototypes, hot paths.

## Quality - MANDATORY
DRY: abstract on 3rd repetition. KISS: if junior>5min→REFACTOR. YAGNI: current requirements only.

Limits - MANDATORY: `file≤300L`, `func≤50L`, `params≤5`, `nesting≤3`, `complexity≤10`
Limits are heuristics, not invariants. Exceptions allowed for: generated/auto-formatted files (proto, migration, fixture) | hot paths where extraction requires interface indirection | stdlib pattern implementations. Exception requires inline comment: `# exceeds limit: <reason>`
Naming - MANDATORY: `funcs=verb_noun`, `classes=NounProcessor`, `bools=is_has_can`, `consts=UPPER_SNAKE`, `private=lang_specific`
Smells: >50L→extract | >3nest→early_return | magic#→const | >300L→SRP
Dead code policy: dead code YOUR changes introduced → DELETE. Pre-existing dead code → REPORT only, never delete unless asked (see operating-protocol for full policy).
Boy Scout - MANDATORY: Do=indent+rename+types+rm_unused+extract_const. NOT: >100L refactor+arch_change+rewrite.

## Performance - MANDATORY
Measure first. O(n)>O(n²). DB=bottleneck. 80/20.
Anti-patterns: premature_opt, N+1, `SELECT *`, O(n²)loops, missing cache_TTL, missing connection_pool.

## Scalability - MANDATORY
Stateless services. Idempotent writes + idempotency keys for external calls. Async I/O. Rate limits+payload caps+timeout budgets at every boundary.
Anti-patterns: shared mutable globals, sync blocking in hot paths, unbounded queues, missing backpressure.

## Security - CRITICAL
Zero Trust - CRITICAL: NEVER output secrets(`<REDACTED>`). ALWAYS validate inputs + HTTPS/TLS + least_privilege.
Secret hygiene - CRITICAL: NEVER pass secrets as inline CLI args (`cmd --token=abc`, `TF_VAR_x="secret" cmd`). Secrets in terminal args → shell history → leaked. Correct: `export VAR=secret` (separate step, not shown) → `cmd`. NEVER suggest copying a real token into a command in chat.
Cloud APIs - CRITICAL: services with non-obvious constraints (regex patterns, ARN formats, IAM evaluation logic) → read official docs BEFORE first attempt. NEVER assume behavior matches intuition.
Error - MANDATORY: NEVER silent_catch. Specific exceptions. Check returns. Generic→users, detailed→logs.

PII & sensitive data - CRITICAL:
- NEVER use real user data (emails, phones, IDs, names) in tests, fixtures, prompts, or logs.
- Use synthetic fixtures always. Real data in tests = security violation.
- Log redaction: PII fields must be redacted before logging. Log `user_id` only, never `email` or `name`.
- Anonymize before analysis: if prod data analysis required, request anonymized export first.
- NEVER cache or store sensitive data beyond the minimum required for the task.

## Documentation - MANDATORY
Comments: WHY NOT HOW/WHAT. Comment: non-obvious+tradeoffs+workarounds+security+complexity. NOT: obvious+outdated+apologies.
Comment exception: security-critical logic, non-obvious tradeoffs, and workarounds MAY include a WHY comment without explicit request. All other comments: only on request.

## Pre-Commit Checklist - MANDATORY
Golden Chain: Format→Lint→Type→Test→Security. Stop@1st_fail. NEVER claim done without running.

## Compatibility & Rollout - MANDATORY
Breaking changes: STOP → warn → propose migration strategy → get approval.
Expand-contract for schema changes: add column → backfill → switch reads → remove old.
Feature flags: new behavior behind flag when rollout risk is non-zero.
Canary / dark launch: required for changes affecting >1% prod traffic or >1 service boundary.
Data migrations: always reversible, always idempotent, always tested on a copy first.
NEVER deploy breaking API change without versioning (/v2) or a deprecation window.

## Dependency Policy - MANDATORY
Pin exact versions in lockfiles. Audit license+CVE before adding. Upgrade one at a time + full test suite after each.
Vendored deps: include checksum/provenance. Use stdlib or existing deps before adding new ones.

## Observability - MANDATORY
Structured logging: JSON with fields: `level`, `ts`, `service`, `trace_id`, `span_id`, `msg`.
Log levels: ERROR=needs human action | WARN=degraded/self-recoverable | INFO=business events | DEBUG=removed before PR.
Correlation IDs: propagate `trace_id` / `request_id` across all service calls and logs.
Metrics: every new service boundary must emit: request count, error count, latency p50/p99.
Debug cleanup: remove all debug print statements before closing task.
NEVER log secrets, tokens, passwords, or PII fields.
