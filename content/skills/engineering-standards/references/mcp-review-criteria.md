# MCP Server Review Criteria

## Scope - CRITICAL

This file defines WHAT controls to check when reviewing an MCP server for
activation (ingestion CRITERIA). It does NOT define the review PROCESS (WHO
reviews, WHEN, trust event logging, deprecation) -- that is owned by
governance/references/mcp-lifecycle.md. This separation is mandated by SC-15:
"governance skill owns the MCP-review PROCESS; engineering-standards owns
ingestion CRITERIA."

## 7 Mandatory Controls (stage 2 review gate)

Before any MCP server passes governance review (governance/mcp-lifecycle.md
stage 2), ALL 7 controls MUST pass:

- [ ] **Input validation**: every tool parameter validated (no raw passthrough).
       Reject if any parameter accepts arbitrary input without validation.
- [ ] **Rate limiting**: per-tool and per-server rate limits declared.
       Reject if no rate limit mechanism documented.
- [ ] **Scoped credentials**: short-lived, least-privilege, blast-radius limited.
       Reject if credentials have broad scope or no expiry.
- [ ] **VCS-pinned config**: MCP config pinned in VCS under the skill repo.
       Reject if server URL is runtime-fetched or not in VCS.
- [ ] **Fail-closed default**: unmatched/unknown behavior defaults to deny +
       human review. Reject if default is allow.
- [ ] **Sandbox/VM validation**: install + validation run inside isolated
       container or VM before host-context trust. Reject if no isolation plan.
- [ ] **Ingestion audit log**: SHA256 + reviewer + date recorded in CHANGELOG.md.
       Reject if no audit log entry.

Failure of ANY control = reject at stage 2. No exceptions for "trusted" sources.

## T0-T4 Framework Binding

MCP tool definitions cannot expose operations violating the T0-T4 risk tier
framework (operating-protocol). Mapping:

| Tier | MCP tool allowed? | Example | Review action |
|---|---|---|---|
| T0 (reversible, local) | Yes, auto-approve | read-only file list | Pass stage 2 automatically |
| T1 (cross-file) | Yes, state plan | multi-file search | Pass with plan declaration |
| T2 (irreversible OR prod) | Yes, CONFIRM before | write, deploy | Require human confirmation |
| T3 (data loss, security) | NO -- reject | delete, secret rotation | BLOCK + [GOVERNANCE VIOLATION] |
| T4 (unclassifiable) | NO -- ask to classify | ambiguous tool | BLOCK + ask human to classify |

Any MCP tool exposing T3+ operations = Catastrophic severity (see
governance/violation-escalation.md). Remove from config + report.

## AgentShield Scan Integration

Source: https://github.com/affaan-m/ECC (accessed 2026-07-02, [unverified]
adoption metrics; pattern extracted from README).

AgentShield scans MCP configs across 5 categories:
1. Secrets detection (14 patterns)
2. Permission auditing
3. Hook injection analysis
4. MCP server risk profiling
5. Agent config review

102 static analysis rules. Exit code 2 on critical findings for build gates.

Governance binding: stage 2 review MUST run an AgentShield-equivalent scan
(secrets + permissions + injection + MCP risk + config) before activation.
Exit code != 0 = BLOCK activation.

Optional deep mode: 3-agent red-team/blue-team/auditor pipeline (attacker
finds exploit chains, defender evaluates protections, auditor synthesizes
prioritized risk). Recommended for any MCP server exposing T2+ tools.

## spec-kit Install Policy Pattern

Source: https://github.com/github/spec-kit (accessed 2026-07-02).

spec-kit catalogs carry an install policy:
- `install-allowed`: full review gate (stage 2) passed, eligible for activation
- `discovery-only`: visible in catalog but activation BLOCKED until review
  passes. No MCP server activates from a discovery-only source.

This prevents "list-and-trust" attacks where directory presence implies safety.

## Anthropic Security Patterns

Source: https://code.claude.com/docs/en/security (accessed 2026-07-02, V-graded):

- "Anthropic does not security-audit or manage any MCP server" => Directory
  presence is NOT a security signal. The review gate is the only enforcement.
- First-time activation = trust event (governance/mcp-lifecycle.md stage 3).
- MCP configs MUST be pinned in VCS (control 4).
- Fail-closed default (control 5).
- Sandbox/VM validation (control 6).
- Scoped credentials (control 3).

## Boundary

- REVIEW PROCESS (WHO, WHEN, trust events, deprecation): -> governance/references/mcp-lifecycle.md
- Ingestion CRITERIA (SC-09 to SC-19 threat rows): -> references/supply-chain.md
- Runtime injection defense: -> operating-protocol/references/untrusted-content.md
- Prompt-design injection defense: -> prompt-expert/references/injection-defense.md
- This file = INGESTION CRITERIA only. Never duplicates PROCESS.
