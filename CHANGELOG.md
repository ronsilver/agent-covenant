# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `scripts/validate-evals.py` — new eval presence/schema/quality validator (Schema A + Schema B, graphify exempt), wired into `make validate-evals` and `make validate`
- `scripts/validate-router-delegation.sh` — router delegation gate (REFUSAL PROTOCOL + Dispatch mandate + MCP write-root check), wired into `make validate`
- `content/skills/spec-driven-development/evals/evals.json` — new evals (canonical Schema B, 3 cases)
- `content/skills/penetration-testing-expert/evals/evals.json` — new evals (canonical Schema B, 3 cases)
- `content/skills/web-browsing-agent-expert/evals/evals.json` — new evals (canonical Schema B, 3 cases)
- `content/skills/token-efficiency/evals/evals.json` — added eval 9 (safety: compression yields to correctness) and eval 10 (measurement loop), removed unverified KV-cache numbers from eval 4, added reference-dependency note
- `tests/benchmark/` — deterministic stdlib-only benchmark harness for `opencode run` with 12 raw + 5 derived metrics, 5 static prompts, context and baseline modes (paired selection runs both), HOME-override baseline isolation with a fail-closed `--smoke` gate, and 13 Bats tests at `tests/test_benchmark.bats`
- `docs/adr/0036-boot-skill-step-zero-enforcement.md` — zero-reasoning execution plan (T1-T6, ADR-0036 draft) for fixing the boot-skill partial-load defect: Step-Zero invocation mandate, per-agent injection truth table, count-drift unification to 7, transitive binding across skill/subagent/rule/hook load paths, CI regression gates

### Changed

- `Makefile` — added `validate-evals` target and wired it into `validate` (inherited by `check` via the `validate` dependency)
- `governance` (Core) — synced precedence to `... > tool-usage > token-efficiency` (ADR-0035): fixed troubleshooting-row hierarchy, updated eval 3 expected output, documented tool-usage/token-efficiency as complementary (tool-usage = instrument of token-efficiency, applies first; token-efficiency compresses the remainder, applies last), version 2.2 -> 2.3
- `content/subagents/ultraorchestrator.md` — router now DISPATCHES routed subagents via `task`: added `## Dispatch` section (dispatch table + rules), DISPATCH workflow step, `## REFUSAL PROTOCOL`; litmus executors updated to "router dispatches via task" (ask-gated rows: `ultracode`/`git-requests`/rollback); scope + negative constraints forbid self-execution
- `content/subagents/README.md` — orchestration flow + restricted delegation graph updated for router direct-dispatch of 9 agents; specialist fan-out documented inside `code-review`/`ultrareview`
- `content/mcp/opencode-mcp.json` — filesystem MCP server root narrowed from `/` to `.` (relative) — closes MCP write gap for read-only agents
- `content/mcp/mcp.json` — filesystem MCP server root narrowed from `/` to `.` (relative) — same MCP write-gap closure for the Claude Code-format config
- `scripts/validate-mcp-config.py` — added dangerous filesystem mount (root `/`) check
- `Makefile` — wired `validate-router-delegation` into `validate`
- `tests/test_validate.bats` — added 4 router-dispatch regression tests
- `.gitignore` — removed `docs/plans` ignore so router-persisted plans become git-visible

### Removed

- `content/skills/.claude/` — removed stale orphan deploy artifact (already gitignored, untracked); dropped the now-dead `lint-md` exclusion from `Makefile`
- `content/skills/alternative-skill-creator/scripts/evaluate_skill.py` — added Schema B (`test_cases`) dual-support with native carry of `expected_behaviors`/`flags_to_avoid`/`expected_tier`/`pass_threshold` onto the case struct
- `content/skills/alternative-skill-creator/scripts/init_skill.py` — `EVALS_TEMPLATE` now defaults to Schema B (canonical) and documents Schema A as legacy
- `content/skills/_TEMPLATE/SKILL.md` — documented evals schema (Schema B canonical, Schema A legacy, graphify exempt)
- `content/skills/engineering-standards/references/eval-harness.md` — added dual-schema note + negative-case (`flags_to_avoid`) guidance

### Fixed

- `content/skills/skill-router/SKILL.md` — removed "NEVER invoke via skill()" boot-skills prohibition; trigger:always clarified as catalog membership; Step 0 now mandates invoking all 7 boot skills (ADR-0036)
- `content/rules/agents/opencode-global.md` — GOVERN pre-flight corrected to "verify all 7 boot skills loaded"; anti-waiver clause added to <SKILLS> (ADR-0036)
- `content/rules/agents/claude-code-global.md` — anti-waiver clause added to <SKILLS>; compensating trims preserve the 6000-byte kernel budget (ADR-0036)
- False blanket auto-injection claims replaced with per-agent truth: boot-manifest.yaml, docs/reference/skills-catalog.md, content/rules/README.md, baseline-skills-plugin.js, AGENTS.md heading (ADR-0036)
- `content/hooks/opencode/baseline-skills.sh` — boot list corrected 4 -> 7; `content/hooks/claude-code/baseline-skills.sh` — verify-first ordering, leading auto-load assertion dropped
- Stale boot-count literals unified to 7: governance SKILL.md (+references, +evals), tool-usage SKILL.md compliance gate, content/rules/core/governance.md, AGENTS.md invariants 1/5 (ADR-0036)

### Changed (Core Governance)

- `skill-router` (Core) — boot-skills section rewritten: Step-Zero invocation mandate + verbatim-body exception; version 3.0 -> 3.1 (ADR-0036)
- `governance` (Core) — subagent binding unified to 7 boot skills; overflow exception scoped to subagents only; version 2.3 -> 2.4 (ADR-0036)
- `tool-usage` (Core) — Core Compliance Gate extended 5 -> 7 skills; version 2.1 -> 2.2 (ADR-0036)

## [0.0.2] - 2026-08-16

### Added

- `security-expert/references/owasp-agent-attacks.md` — new MITRE ATLAS agent and MCP tool poisoning attack reference (AML.T0110 family, AML.T0053)
- `security-expert/references/owasp-llm-top10.md` — new OWASP LLM Top 10 reference covering 2025 v2.0 primary and 2023-24 v1.1 delta tables
- `docs/adr/0028-owasp-scanner-adoption.md` — ADR proposing SBOM scanner tooling adoption (Status: Proposed)
- `docs/adr/0029-atlas-canonicalization.md` — ADR canonicalizing MITRE ATLAS threat IDs across Core skills (AML.T0053 = AI Agent Tool Invocation, AML.T0110 = AI Agent Tool Poisoning, AML.T0010 = AI Supply Chain Compromise, AML.TA0000 = AI Model Access); ATLAS 2026.07 (178 techniques); resolves ADR-0028 follow-ups #1-#3 (Status: Approved)
- `docs/adr/0030-agentic-runtime-injection-controls.md` — ADR adding runtime agentic injection controls: operating-protocol Tool-Call Validation R1-R6, untrusted-content.md MCP Tool Allowlist + Validation Gates 5-6 + Zero Trust extension; operating-protocol 2.2 -> 2.3 (Status: Approved)
- `docs/adr/0031-tool-boundary-argument-validation.md` — ADR adding tool-boundary argument validation: security-practices.md Tool-Boundary Argument Validation, supply-chain.md SC-10 dangling-ref fix, tool-usage ACI arg-validation checkbox; engineering-standards 2.2 -> 2.3 (Status: Approved)
- `docs/adr/0032-governance-8-domain-audit.md` — ADR migrating the compliance audit from 7 to 8 domains (ATLAS canonicalization gate); governance 2.1 -> 2.2 (Status: Approved)
- `penetration-testing-expert` — new skill for authorized penetration testing and offensive security (category: security, status: beta)
- `web-browsing-agent-expert` — new skill for AI web-browsing agents and headless browser tooling (category: ai-agents, status: beta)
- `content/prompts/` — restored minimal prompts feature (`spec-review.prompt.md` + README) per ADR-0008 schema
- `docs/reference/master-catalog-mapping.md` — master catalog wiring doc (source-of-truth mapping and ingestion rule)
- `scripts/validate-kernel-budget.sh` — kernel 6000-byte budget gate wired into `make validate`
- `docs/adr/0033-token-efficiency-refresh.md` — ADR adopting the master-catalog refresh of `token-efficiency` and `llm-expert` (Status: Accepted)
- `content/skills/token-efficiency/references/action-first-output.md` — new reference with the 10-rule action-first output structure (master catalog #155 i-have-adhd)
- `spec-driven-development` — new skill for OpenSpec and spec-kit artifact-guided development (category: process, status: stable)
- `docs/adr/0034-skill-library-enrichment.md` — ADR recording the skill-library enrichment (D9-D13) and the engineering-standards Core edit (Status: Accepted)
- `content/skills/security-expert/references/agent-attack-patterns.md` — new condensed agent-attack-pattern catalog (49 pattern families, risk 0-100, SAFE/CAUTION/DO_NOT_INSTALL)
- `ultraorchestrator` — new read-only routing meta-agent (permissionMode: read, category: ai-agents)
- `docs-writer` — new documentation write-exception agent (permissionMode: build, category: ai-agents)

### Changed

- `content/subagents/*.md` — rewrote all 16 subagent descriptions to single-line, plain-scalar-safe text (no `: `, no leading `#`/`- `, no `Use when/before/after` prefix) for OpenCode and Claude Code sync compatibility.
- `scripts/validate.sh` — added `validate_subagent_descriptions` gate (manifest-driven, quote-tolerant, full folded-value scan) wired into `main()`.
- `tests/test_validate.bats` — added 6 subagent-description validator tests.
- `docs/reference/subagent-schema.md` — documented third-person description convention and ADR-0002 boundary note.
- `security-expert` — OWASP Top 10 updated to 2025 taxonomy; added agent and MCP security section and ASVS/WSTG/AI Exchange reference rows (version 1.1)
- `mcp-expert` — added Tool Poisoning Defense section with cross-reference to the agent attack reference (version 1.2)
- `security-expert/references/sast-tools.md` — OWASP automation table moved to 2025 taxonomy; added Supply Chain and SBOM tooling table
- `security-expert/references/container-security.md` — added SBOM analysis step to the scanning pipeline; Dependency-Track policy for continuous monitoring
- `security-auditor` — OWASP Top 10 checklist rows rewritten to 2025 categories
- `reviewer-expert` — OWASP Top 10 reference updated to 2025 taxonomy
- `ultrareview` — injection A-code corrected to A05 under the 2025 taxonomy
- `agent-architecture-expert` — added agentic-security reference (OWASP Agentic Security Initiative, MITRE ATLAS AML.T0110/AML.T0053) and fixed trigger/DONOT contradiction (version 1.2)
- `openapi-expert` — added Security section with OWASP API Security Top 10 2023, securitySchemes, and 429/Retry-After guidance; extended triggers (version 1.0)
- `architecture-expert` — added STRIDE-lite Threat Modeling section for OWASP A06 Insecure Design with zero-trust and security-practices cross-refs (version 1.2)
- `golang-expert` — added Security section: gosec, govulncheck, SSRF (CWE-918), deserialization (CWE-502), supply chain (version 1.0)
- `python-expert` — added Security section: bandit, pip-audit, CWE-502 safe deserialization, SSRF, SQLi (version 1.0)
- `typescript-expert` — added Security section: helmet CSP/SRI/SameSite/HttpOnly, eslint-plugin-security, npm audit (version 1.0)
- `java-expert` — added Security section and 2025 taxonomy constraint labels (@Valid A05, @ControllerAdvice A10, dependency scan A03) (version 1.1)
- `kotlin-expert` — added Security section with OWASP MASVS v2.1.0 STORAGE/CRYPTO/NETWORK cross-ref and EncryptedSharedPreferences (version 1.0)
- `swift-expert` — added Security section with OWASP MASVS v2.1.0 cross-ref, Keychain, and ATS enforcement (version 1.0)
- `ruby-expert` — added Security section: brakeman, strong parameters, CSRF, mass-assignment (version 1.0)
- `scala-expert` — added Security section: find-sec-bugs + sbt-dependency-check, UDF deserialization (version 1.0)
- `mysql-expert` — added Security section: TLS, least-privilege, parameterized queries (version 1.0)
- `mongodb-expert` — added Security section: NoSQL operator injection, auth, TLS (version 1.0)
- `redis-cache-expert` — added Security section: CWE-502 deserialization, ACL, TLS (version 1.0)
- `dynamodb-expert` — added Security section: IAM least-privilege, KMS, PII in PK/SK (version 1.0)
- `postgres-database-expert` — extended Security section with SQL Injection Prevention Cheat Sheet cross-ref (version 1.1)
- `performance-expert` — added Security section: PII-cache cross-ref to security-practices (version 1.0)
- `scalability-expert` — added Security section: rate limiting as API security (API4/API10), DoS (version 1.0)
- `terraform-expert` — refreshed last_verified dates to 2026-08-08 (version 1.0)
- `content/rules/agents/*-global.md` — aligned all four kernels to 7 always-on boot skills and trimmed under the 6000-byte budget
- `content/skills/_TEMPLATE/SKILL.md` — category `domain` to `core`, status `draft` to `beta`
- `manifest.yaml` — registered 2 new skills, restored `prompts:` section, fixed 11 retired-skill successor references
- `scripts/validate.sh` — added `validate_skill_frontmatter` gate enforcing the metadata.category whitelist and status enum
- `scripts/sweep-content-icons.py` — extended REPLACEMENTS map with the skip-ahead glyph used by validation workflows
- `Makefile` — wired `validate-kernel-budget` and `validate-icons` into the validate chain
- `README.md` and `docs/reference/*` — repaired stale content counts (workflows 10/4, MCP 12, hooks 2 agent dirs, skills 63)
- `content/skills/token-efficiency/` — refreshed 5 references against master-catalog sources (headroom, codegraph, aislop, token-savior, ccusage) and added output-shaping, keep-warm, hook-compaction, stop-slop, and action-first techniques (version 2.1 -> 2.2)
- `content/skills/llm-expert/SKILL.md` — added prompt token audit (9 dimensions), humanized-output quality gate, and multi-source usage monitoring (version 1.1 -> 1.2)
- `docs/reference/skills-catalog.md` — token-efficiency entry updated to v2.2 with the 10-compressor and action-first references
- `planning-expert` — added spec/PRD structure, brainstorming, Three Amigos, and junior-readable plan guidance (version 1.1 -> 1.2)
- `reviewer-expert` — added adversarial verification pass, receiving-review discipline, doubt-driven development, and a 10-class vulnerability table (version 1.0 -> 1.1)
- `security-expert` — added LLM red-team tooling, the 7-Question Gate, evidence hygiene, and the agent-attack-patterns reference (version 1.1 -> 1.2)
- `engineering-standards` — added skillspector ingestion patterns to the supply-chain reference (Core edit, version 2.3 -> 2.4, covered by ADR-0034)
- `prompt-expert` — added malicious-skill injection patterns (version 1.1 -> 1.2)
- `agent-expert` — added subagent-driven development, think/act/prove, and typed-evidence watchdog guidance (version 1.1 -> 1.2)
- `agent-architecture-expert` — added AgentCore code interpreter, browser, gateway, and agentic-security sections (version 1.2 -> 1.3)
- `finops-cost-optimization` — added pre-deploy estimation and anomaly-cadence cost operations (version 1.0 -> 1.1)
- `research-expert` — added claim-verification and fact-check workflow (version 1.0 -> 1.1)
- `aws-cloud-expert` — strengthened IaC stance: Terraform with modules only (version 1.0 -> 1.1)
- `planning-expert` — added the grill-me pre-change interrogation protocol (master catalog #18, version 1.2 -> 1.3)
- `documentation-expert` — added the shared-language CONTEXT.md pattern (master catalog #18, version 1.0 -> 1.1)
- `prompt-expert` — completed the prompt-master pipeline: 7-step routing, framework templates, Universal Fingerprint, tool profiles (master catalog #31, version 1.2)
- `token-efficiency` — added the shared-language cross-reference in references/clarification-first.md (master catalog #18)
- `engineering-standards` — recorded the SkillOpt self-optimization reference in references/eval-harness.md (master catalog #154; Core edit, covered by ADR-0034)
- `docs/reference/master-catalog-mapping.md` — appended the closed 1-190 disposition table (coverage-completion audit trail, T15o)
- `docs/reference/subagent-strategy-mapping.md` — subagent count updated from 15 to 17 in the mapping intro

### Fixed

- Fixed stale OWASP Top 10 category codes in audit and review references (injection corrected to A05, A03 re-mapped to supply chain)
- `content/workflows/validation/lint.md` and `test.md` — replaced the skip-ahead icon with `[SKIPPED]` label and repaired stale references (`test-driven-development` to `testing-expert`, removed dangling `.pre-commit-config.yaml` pointer)
- `README.md` — repointed the refactor plan link to `docs/plans/processed/`

## [0.0.1] - 2026-07-27

### Added

### Changed

### Fixed
