---
name: security-expert
description: "Complete security audit: SAST source code analysis, OWASP Top 10 review, dependency CVE scanning, secret scanning in code and commits, IAM and cloud permission audit, proactive threat hunting with Sigma rules and MITRE ATT&CK, and SIEM queries for anomaly detection. Use when performing security reviews, running SAST or OWASP checks, scanning for secrets in code, auditing dependency CVEs, reviewing IAM permissions, hunting for threats in logs, or implementing behavioral anomaly detection. Trigger: security, SAST, OWASP, CVE, IAM audit, threat hunting, gitleaks, MITRE ATT&CK, agent tool poisoning, MCP poisoning, LLM Top 10. Do NOT trigger for: application feature development, authentication/authorization implementation, TLS/encryption configuration, CSRF protection implementation, database schema design, general code review (use reviewer-expert). For application security features (auth, encryption), rely on general programming guidance."
license: MIT
metadata:
  author: Community
  version: "1.2"
  category: security
  status: stable
---
# Security Expert

**Security audit: SAST, OWASP, CVE scanning, secrets, IAM review, threat hunting.**

## Audit Pipeline
```
SAST -> Dependency CVE scan -> Secret scan -> IAM review -> Threat hunting
```

## OWASP Top 10 (2025)

| # | Risk | Check |
|---|---|---|
| A01 | Broken Access Control | Every endpoint enforces auth + authz |
| A02 | Security Misconfiguration | No defaults, hardened configs, CIS benchmarks |
| A03 | Software Supply Chain Failures | Pin deps, verify provenance, SBOM + signature checks |
| A04 | Cryptographic Failures | TLS everywhere, strong algorithms |
| A05 | Injection | Parameterized queries, no `eval` |
| A06 | Insecure Design | Threat modeling, security requirements |
| A07 | Authentication Failures | MFA, no default passwords, session mgmt |
| A08 | Software and Data Integrity Failures | Signed artifacts, verified updates |
| A09 | Security Logging and Alerting Failures | Audit trails, alert on anomalies |
| A10 | Mishandling of Exceptional Conditions | Fail-secure error paths, sanitized error messages |

## Agent and MCP Security

| Attack vector | Mapping | Defense |
|---|---|---|
| MCP Tool Poisoning | AML.T0110 | Treat tool definitions as untrusted; allowlist tools; pin plugin versions |
| HITL Dialog Forging | AML.T0110.002 | Verify dialog against raw tool output; independent confirmation |
| Prompt injection | AML.T0051 | Untrusted text is data; validate model-produced tool arguments |
| Deserialization / XXE / upload / reflection | CWE-502/611/434/470 | Allowlists, no XXE, validated uploads, restricted reflection |
| SSRF | CWE-918 | Block private ranges, validate resolved IPs, allowlist destinations |
| Business logic | CWE-840 | State machine checks, idempotency, numeric bounds |
| LLM Top 10 | references/owasp-llm-top10.md LLM01-LLM10 | Apply 2025 LLM Top 10 defenses per category |

Audit checklist and defense guidance: references/owasp-agent-attacks.md.

## Agent Skill Ingestion and LLM Red-Team

Skill ingestion: apply the condensed attack-pattern catalog (references/agent-attack-patterns.md, master catalog #97) to any new skill; assign a risk score (0-100) and a SAFE / CAUTION / DO_NOT_INSTALL verdict; vet MCP servers with the 5-step process (provenance, code review, permissions, Docker sandbox, monitoring).

LLM red-team tooling: `garak` for automated LLM vulnerability scanning (master catalog #42) and Microsoft PyRIT for agentic red-team workflows (master catalog #39). Run each test inside the written scope of an authorized engagement; use the 7-Question Gate before every attack step.

7-Question Gate (per attack step): who authorized the target? is it in the written inventory? is the action inside the time window? are excluded hosts avoided? is the impact reversible? is evidence capture in place? is a rollback defined? Any NO stops the step.

Evidence hygiene: capture timestamps, tool output, and hashes as the run progresses; keep findings in a password-protected vault; purge test artifacts at closeout.

## Secret Scanning
```bash
# gitleaks — scan git history
gitleaks detect --source . --verbose

# truffleHog — scan commits + current state
trufflehog filesystem .
```

## Threat Hunting
| Framework | Use |
|---|---|
| MITRE ATT&CK | Map activity to adversary tactics |
| Sigma Rules | Convert threat intel to SIEM queries |
| IOC-based | Known-bad hashes, IPs, domains |
| Behavioral | Baseline deviation detection |

## IAM Review Checklist
- [ ] No `*` in actions or resources
- [ ] No wildcard principals (`"Principal": "*"`)
- [ ] MFA enforced for all human users
- [ ] Rotation policy for access keys (90 days max)
- [ ] Least privilege: verify against actual CloudTrail usage

## Constraints
- NEVER output real secrets — `<REDACTED>` always
- NEVER rely solely on automated scanning (manual review required)
- NEVER skip IAM review for any infrastructure change
- ALWAYS include CWE reference in security findings
- ALWAYS check for secrets in git history, not just current state

## Overview

Full security audit methodology covering SAST source analysis, OWASP Top 10 (2025) review, CVE dependency scanning with Trivy, secret scanning with Gitleaks, IAM permission auditing for AWS, proactive threat hunting using MITRE ATT&CK and Sigma rules, and agent and MCP attack review using the OWASP LLM Top 10 and MITRE ATLAS. Designed for pre-deployment security gates and incident response.

## Quick Reference

| Scenario | Tool / Action |
|---|---|
| Audit a new service before deployment | SAST → Dependency scan → Secret scan → IAM review → Threat hunting |
| Scan git history for leaked secrets | `gitleaks detect --source . --verbose` |
| Find vulnerable dependencies | `trivy fs . --scanners vuln` |
| Review AWS IAM for privilege escalation | Check for `*` in actions/resources, wildcard principals |
| Map anomalous behavior to adversary tactics | MITRE ATT&CK framework + Sigma rules |

## Workflow

1. Run SAST (Semgrep/CodeQL) on source code — block CRITICAL/HIGH findings
2. Scan dependencies with Trivy — fail on exploitable CVEs
3. Scan git history + current tree with Gitleaks — fail on any secret
4. Review IAM policies for least privilege (no `*`, no wildcard principals)
5. Review logs for anomalous activity against MITRE ATT&CK techniques
6. Document findings with CWE references and remediation plan
7. Re-scan after fixes to validate closure

## Anti-patterns

FAIL: Relying solely on automated scanning without manual review
```bash
semgrep --ci && echo "All clear"
```

PASS: Automate first pass, then manual review of HIGH/CRITICAL findings
```
SAST catches injection patterns but misses business logic flaws → always pair with human review
```

FAIL: Ignoring git history in secret scanning (only scanning current state)
```bash
gitleaks detect --no-git  # scans only working tree
```

PASS: Scan both current state and full git history
```bash
gitleaks detect --source . --verbose  # full history scan
```

FAIL: Allowing `"Principal": "*"` in IAM policies
```json
{ "Effect": "Allow", "Principal": "*", "Action": "s3:GetObject" }
```

PASS: Restrict to specific principals
```json
{ "Effect": "Allow", "Principal": { "AWS": "arn:aws:iam::123456789012:role/AppRole" } }
```

FAIL: Skipping IAM review for small infrastructure changes
```
"Just adding one SQS queue permission"
```

PASS: Every infrastructure change needs IAM review regardless of size
```
One extra permission can chain into privilege escalation → review all IAM changes
```

## References

| Resource | URL | Last verified |
|---|---|---|
| OWASP Top 10 (2025) | https://owasp.org/Top10/ | 2026-08 |
| Gitleaks documentation | https://github.com/gitleaks/gitleaks | 2026-04 |
| MITRE ATT&CK framework | https://attack.mitre.org/ | 2026-03 |
| Trivy vulnerability scanner | https://trivy.dev/ | 2026-03 |
| OWASP ASVS 5.0.0 | https://owasp.org/www-project-application-security-verification-standard/ | 2026-08 |
| OWASP Web Security Testing Guide v4.2 | https://owasp.org/www-project-web-security-testing-guide/v42/ | 2026-08 |
| OWASP AI Exchange | https://owaspai.org/ | 2026-08 |

- [references/container-security.md](references/container-security.md)
- [references/sast-tools.md](references/sast-tools.md)
- [references/sigma-rules.md](references/sigma-rules.md)
- [references/zero-trust.md](references/zero-trust.md)
- [references/owasp-agent-attacks.md](references/owasp-agent-attacks.md)
- [references/agent-attack-patterns.md](references/agent-attack-patterns.md)
- [references/owasp-llm-top10.md](references/owasp-llm-top10.md)

## Verification Checklist

- [ ] SAST scan completed (Semgrep/CodeQL) with no CRITICAL/HIGH findings
- [ ] Dependency scan (Trivy) passed — no exploitable CVEs
- [ ] Git history scanned with Gitleaks (both current tree and full history)
- [ ] IAM policies reviewed: no `*` in actions/resources, no wildcard principals
- [ ] OWASP Top 10 (2025) checks: access control, misconfig, supply chain, crypto, injection, auth, logging, error handling covered
- [ ] All security findings include CWE reference + concrete remediation
- [ ] Re-scan performed after fixes to validate closure

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Gitleaks false positive on test fixture | Test data contains placeholder secrets | Add path to `.gitleaksignore` or mark as allowlisted in config |
| Trivy reports high-severity CVE in transitive dependency | No direct upgrade path | Check for backported fix in distro package; add suppression with documented risk assessment |
| IAM policy review misses privilege escalation risk | Policy too broad — `"Action": "*"` used | Replace wildcard with explicit action list; use `Condition` block to restrict resources |
| Gitleaks scan passes but secret was still committed (edge case: binary file encoding bypass) | Gitleaks skips binary files; secret hidden in image or compiled artifact | Add `gitleaks detect --no-git` on build artifacts; pre-commit hook must reject binary files with `git lfs` |

| [WARN] SAST tool reports false positive on dynamically constructed SQL query | Static analysis cannot trace dynamic string concatenation; flags all non-parameterized patterns | Mark false positive with inline comment (`// nosemgrep` / `# nosec`); still refactor to parameterized query |
| Trivy scan passes in CI but CVE was fixed in an image layer older than cache TTL | Trivy cache skips scan of layers older than --cache-ttl; stale results reported as no vulns | Set --cache-ttl 24h in CI; use --no-cache on critical scans; add Trivy to nightly full-scan pipeline |
| BUG: gitleaks detect --no-git skips .gitleaksignore pattern matching | gitleaks ignore patterns only work with git mode; no-git mode does not read ignore file | Use --no-git with explicit --path flag; pipe results through custom grep filter as workaround |
