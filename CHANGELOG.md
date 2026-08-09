# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `security-expert/references/owasp-agent-attacks.md` — new MITRE ATLAS agent and MCP tool poisoning attack reference (AML.T0110 family, AML.T0053)
- `security-expert/references/owasp-llm-top10.md` — new OWASP LLM Top 10 reference covering 2025 v2.0 primary and 2023-24 v1.1 delta tables
- `docs/adr/0028-owasp-scanner-adoption.md` — ADR proposing SBOM scanner tooling adoption (Status: Proposed)
- `docs/adr/0029-atlas-canonicalization.md` — ADR canonicalizing MITRE ATLAS threat IDs across Core skills (AML.T0053 = AI Agent Tool Invocation, AML.T0110 = AI Agent Tool Poisoning, AML.T0010 = AI Supply Chain Compromise, AML.TA0000 = AI Model Access); ATLAS 2026.07 (178 techniques); resolves ADR-0028 follow-ups #1-#3 (Status: Approved)
- `docs/adr/0030-agentic-runtime-injection-controls.md` — ADR adding runtime agentic injection controls: operating-protocol Tool-Call Validation R1-R6, untrusted-content.md MCP Tool Allowlist + Validation Gates 5-6 + Zero Trust extension; operating-protocol 2.2 -> 2.3 (Status: Approved)
- `docs/adr/0031-tool-boundary-argument-validation.md` — ADR adding tool-boundary argument validation: security-practices.md Tool-Boundary Argument Validation, supply-chain.md SC-10 dangling-ref fix, tool-usage ACI arg-validation checkbox; engineering-standards 2.2 -> 2.3 (Status: Approved)
- `docs/adr/0032-governance-8-domain-audit.md` — ADR migrating the compliance audit from 7 to 8 domains (ATLAS canonicalization gate); governance 2.1 -> 2.2 (Status: Approved)

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

### Fixed

- Fixed stale OWASP Top 10 category codes in audit and review references (injection corrected to A05, A03 re-mapped to supply chain)

## [0.0.1] - 2026-07-27

### Added

### Changed

### Fixed
