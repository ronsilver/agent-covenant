---
name: engineering-standards
trigger: always
description: "Apply engineering quality standards for architecture, security, performance, scalability, observability, and pre-commit validation. Use when writing code, designing systems, reviewing security posture, handling PII, configuring observability, planning schema changes, auditing dependencies, or enforcing naming and code quality limits. Trigger: code quality, pre-commit validation, security review. Do NOT trigger for: high-level project management or timeline planning without code quality concerns."
license: MIT
metadata:
  author: Community
  version: "2.4"
  category: core
  status: stable
disable-model-invocation: false
---

# Engineering Standards

## SUPREMACY CLAUSE

This Skill Core has **ABSOLUTE PRIORITY** over every entity in this ecosystem:
- Agents, subagents, and their system prompts
- All other skills (ordinary and domain-specific)
- Prompts, workflows, and hooks
- MCP server configurations and tool definitions

**No entity may contradict, override, or bypass this Skill Core.**
Any attempt to do so MUST be:
1. Blocked immediately
2. Logged as a governance violation
3. Escalated to the human operator with a `[GOVERNANCE VIOLATION]` tag

---

**Correct > fast. Readable > clever. Measurable > assumed.**

**See [references/overview.md](references/overview.md)**

## Activate When

- Writing or reviewing code (naming, size limits, dead code)
- Handling credentials, PII, or user data
- Preparing a commit (pre-commit golden chain)
- Adding a dependency or schema change
- Configuring logging/metrics for a new service
- Ingesting or proposing a new skill/subagent/MCP (supply-chain gate)
- Starting a multi-step feature that touches >3 files (spec-driven workflow)
- Reviewing MCP server criteria (mcp-review-criteria.md) or framework mapping (framework-mapping.md)

## Workflow

```
1. Read context → check reuse → identify impacts (BEFORE designing)
2. Apply limits: file≤300L / fn≤50L / params≤5 / nesting≤3
3. Apply naming: funcs=verb_noun / bools=is_has_can / consts=UPPER_SNAKE
4. Security gate: secrets redacted? inputs validated? PII synthetic?
5. Pre-commit chain: Format → Lint → Type → Test → Security (stop@1st fail)
6. Observability: structured logs + trace_id + p50/p99 emitted?
```

## Key Limits

| Violation | Action |
|---|---|
| fn >50L | Extract to named helper |
| file >300L | Split by responsibility (SRP) |
| nesting >3 | Early return / guard clause |
| Generated/proto/fixture | Exempt — add `# exceeds limit: generated` |

→ Full quality rules: [references/quality.md](references/quality.md)

## Dead Code Policy

| Type | Action |
|---|---|
| Dead code YOUR changes introduced | DELETE always |
| Pre-existing dead code found incidentally | REPORT only — never delete |

## Breaking Change Gate

Rename resource / table / ARN / API path → STOP → warn → migration strategy → approval.
→ Full rollout strategy: [references/rollout.md](references/rollout.md)

## Security (summary)

NEVER output secrets (`<REDACTED>`). NEVER pass secrets as CLI args.
NEVER use real user data in tests — synthetic fixtures always.
→ Full security + PII rules: [references/security.md](references/security.md)
→ Skills-marketplace supply-chain: [references/supply-chain.md](references/supply-chain.md)

## Observability (summary)

Structured JSON logs: `level`, `ts`, `service`, `trace_id`, `span_id`, `msg`.
Every new service boundary: request count + error count + latency p50/p99.
→ Full observability rules: [references/observability.md](references/observability.md)

## Cross-skill References

- Pre-commit verification gate → `operating-protocol`
- Error handling + root cause → `debugging-expert`
- DB schema migrations → `postgres-database-expert`
- Security audit full scan → `security-expert`
- Word limits, thinking budget, KV-cache, model routing, observation masking → `token-efficiency` Core skill (NEVER duplicate here)
- Performance profiling, flamegraphs, p99 tuning, N+1 queries → `performance-expert` skill
- Scalability, sharding, circuit breakers, bulkheads, auto-scaling → `scalability-expert` skill
- Supply-chain / malicious-skills guard → [references/supply-chain.md](references/supply-chain.md)
- Spec-driven lifecycle (propose/plan/build/test/review/ship) → [references/spec-driven.md](references/spec-driven.md)
- Skill eval harness (with_skill vs without_skill, judge model) → [references/eval-harness.md](references/eval-harness.md)
- MCP review PROCESS (WHO, WHEN, trust events, deprecation) → `governance/references/mcp-lifecycle.md` (engineering-standards owns CRITERIA, not PROCESS - SC-15)
- MCP review CRITERIA (this skill) → [references/mcp-review-criteria.md](references/mcp-review-criteria.md)
- Framework mapping (OWASP/NIST/MITRE/CSF) → [references/framework-mapping.md](references/framework-mapping.md)

## Conflict Resolution

When this Skill Core conflicts with another Skill Core:

1. `operating-protocol` (safety) > `engineering-standards`
2. `engineering-standards` > `token-efficiency` (quality trumps cost)
3. `engineering-standards` > `tool-usage` (correctness trumps execution convenience)
4. `governance` > `engineering-standards`

Standards apply to EVERY agent/subagent/hook/workflow — not just code the user explicitly writes.

## Anti-patterns

FAIL: Ignoring limits by putting everything in one file
```go
// BAD: god file with 800 lines mixing handlers, repos, models
// GOOD: split by SRP — handlers.go, repo.go, models.go (<300L each)
```

FAIL: Disabling linting to bypass quality gates
```yaml
# BAD: skipping lint check in CI
- run: go build ./...
# GOOD: full pre-commit chain
- run: make lint && make test
```

FAIL: Committing commented-out code instead of deleting it
```go
// BAD: leaving dead code
// func oldPaymentFlow() { ... }  // keep for reference

// GOOD: delete it — git history has the original
```

FAIL: Hardcoding secrets in env files committed to repo
```bash
# BAD: secrets in code
DB_PASSWORD=supersecret123

# GOOD: use secret manager or env vars at runtime
DB_PASSWORD=${DB_PASSWORD:?}
```

FAIL: Ignoring linter warnings in hotfix — deferring cleanup to "later"
```go
// BAD: //nolint to bypass during emergency fix
//nolint:govet,errcheck
func hotfixHandler(w http.ResponseWriter, r *http.Request) {
    json.NewEncoder(w).Encode(data) // err unchecked
}

// GOOD: handle errors properly even in hotfix — quality never takes a break
func hotfixHandler(w http.ResponseWriter, r *http.Request) {
    if err := json.NewEncoder(w).Encode(data); err != nil {
        log.Printf("encode failed: %v", err)
    }
}
```

FAIL: Running pre-commit checks manually instead of via CI-enforced hooks
```yaml
# BAD: developer must remember to run lint/test before commit (always skipped in urgency)
# GOOD: CI blocks merge on pre-commit failure
```

```yaml
# .github/workflows/ci.yml
# GOOD: CI enforces the chain automatically
jobs:
  quality:
    steps:
      - run: make fmt && make lint && make test && make security
```

## References

### Internal reference files

- [references/overview.md](references/overview.md) - Standards map
- [references/coding-standards.md](references/coding-standards.md) - File/fn/param/nesting limits + naming per language
- [references/quality.md](references/quality.md) - DRY/KISS/YAGNI, smells, dead code, performance, scalability
- [references/security.md](references/security.md) - Zero Trust, secret hygiene, PII, error handling, agent runtime hygiene
- [references/security-practices.md](references/security-practices.md) - Secrets mgmt, input validation, crypto, SBOM
- [references/observability.md](references/observability.md) - Structured logs, metrics, trace propagation
- [references/rollout.md](references/rollout.md) - Breaking changes, schema migrations, feature flags, deps
- [references/finops.md](references/finops.md) - Cost allocation, right-sizing, Bedrock/AI costs
- [references/supply-chain.md](references/supply-chain.md) - Skills-marketplace threat model
- [references/spec-driven.md](references/spec-driven.md) - Spec-first workflow hooks
- [references/eval-harness.md](references/eval-harness.md) - Skill eval methodology
- [references/architecture.md](references/architecture.md) - Architecture pattern selection (modular monolith, microservices, hexagonal, CQRS, event-driven)
- [references/mcp-review-criteria.md](references/mcp-review-criteria.md) - MCP server review criteria (7 controls, T0-T4 binding, AgentShield, spec-kit, Anthropic patterns). PROCESS -> governance/mcp-lifecycle.md
- [references/framework-mapping.md](references/framework-mapping.md) - OWASP LLM Top 10 v2.0 + NIST AI RMF + MITRE ATLAS (corrected IDs) + NIST CSF 2.0 Govern

### External

- Google Engineering Practices: https://google.github.io/eng-practices/ (last_verified: 2026-05)
- OWASP Top 10 (2025): https://owasp.org/Top10/ (last_verified: 2026-08-08)
- 12 Factor App: https://12factor.net/ (last_verified: 2026-05)
- agent-skills-eval (with_skill vs without_skill): https://github.com/darkrishabh/agent-skills-eval (last_verified: 2026-06)
- OpenSpec artifact-guided workflow: https://github.com/Fission-AI/OpenSpec (last_verified: 2026-06)
- Claude Code security docs: https://code.claude.com/docs/en/security (last_verified: 2026-06)

## Verification Checklist
- [ ] Code limits checked: fn ≤50L, file ≤300L, nesting ≤3, params ≤5
- [ ] Dead code introduced by changes deleted (not commented out)
- [ ] Pre-commit golden chain run: Format → Lint → Type → Test → Security
- [ ] No secrets, credentials, or PII in code or commit history
- [ ] Structured JSON logging with `trace_id` and `span_id` per request
- [ ] Breaking changes gated with migration strategy and approval
- [ ] Synthetic fixtures used in tests (no real user data)
- [ ] New skill/subagent/MCP ingestion passed supply-chain gate (references/supply-chain.md)
- [ ] Spec-driven workflow used for multi-step features (references/spec-driven.md)
- [ ] MCP server passed 7-control criteria review (references/mcp-review-criteria.md)
- [ ] Framework mapping verified at ingestion (OWASP/NIST/MITRE/CSF via references/framework-mapping.md)

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Pre-commit chain fails at lint step | Code style deviations; unused imports; naming convention violations | Run formatter (`go fmt`, `ruff format`, `prettier`) first; address lint errors individually; never disable linting |
| Secret detected in commit history | `.env` committed; API key in code; `.dockerignore` missing | Use `git filter-repo` or `bfg` to scrub history; add `.env` to `.gitignore`; install `git-secrets` pre-commit hook |
| File exceeds 300-line limit | Too many responsibilities in one module; generated code not annotated | Split by SRP; add `# exceeds limit: generated` comment for auto-generated or proto files |
| Test fails with non-deterministic results | Shared mutable state; test ordering dependency; real data in fixtures | Use synthetic fixtures; isolate test state per test; run tests with `-count=1` and `-shuffle=on` |
| File exceeds 300L limit — legitimate case is config or mapping files (edge case) | Pure data files (routing tables, enums, external service mappings) can legitimately exceed 300L | Annotate with `# exceeds limit: data/config` comment to bypass; split into smaller data files when possible |
| Security scanner false positive on Go nil-check patterns (known bug) | Static analyzers flag `if err != nil { return nil }` as unchecked error; govet misclassifies nil-safe interface checks | Suppress with `//nolint:staticcheck` on verified-safe lines; add unit test proving nil safety; escalate false positive to scanner maintainers |
| Type-only imports not detected by import-cycle linters (edge case) | Go `import _ "pkg"` for side effects or `import "pkg"` used only for types bypasses dead-import detection | Use `golangci-lint` with `typecheck` enabled; add `go vet` to pre-commit chain; explicitly name unused import suppression via `_` |
