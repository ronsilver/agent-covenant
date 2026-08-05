# MCP Server Governance Lifecycle (PROCESS)

## Scope - CRITICAL

This file owns the MCP-server REVIEW PROCESS (fulfilling SC-15 mandate from
engineering-standards/references/supply-chain.md). It defines WHO does WHAT
at each lifecycle stage. It does NOT define WHAT controls to check (CRITERIA)
- those live in engineering-standards/references/mcp-review-criteria.md.
This separation is mandated by SC-15:
"governance skill owns the MCP-review PROCESS; engineering-standards owns
ingestion CRITERIA."

## Lifecycle (5 stages)

| Stage | WHO acts | WHAT happens | Gate (pass to proceed) |
|---|---|---|---|
| 1. Proposal | Proposing agent | Submits MCP tool definition with criteria checklist (see engineering-standards/mcp-review-criteria.md) | Checklist attached; no T3+ tool exposed |
| 2. Review | Human reviewer + governance skill | Governance review: verify criteria checklist complete; confirm no T3+ operations; record reviewer identity | All criteria PASS; reviewer recorded; [GOVERNANCE VIOLATION] if T3+ |
| 3. Activation | governance skill | Pin MCP config in VCS; record first activation as trust event in CHANGELOG (SHA256 + reviewer + date) | Trust event logged; config pinned; deny activation otherwise |
| 4. Drift | compliance-audit.md gate (quarterly) | Config hash vs VCS pinned version; tool schema vs manifest | Flag [WARN]; auto-disable on drift |
| 5. Deprecation | governance skill | Remove from config + archive manifest entry + CHANGELOG entry | Archive complete; re-activation blocked without new proposal |

## Trust Event Recording (stage 3)

First-time MCP activation is a trust event (Anthropic Claude Code security
docs, accessed 2026-07-02). MUST record in CHANGELOG.md:

```
## [Unreleased]
### Added (MCP Governance)
- <mcp-server-name> activated | SHA256: <hash> | reviewer: <name> | date: <YYYY-MM-DD>
```

Without this entry, activation is DENIED. No exceptions.

## Process Rules

- MCP configs MUST be pinned in VCS (no runtime-fetched server URLs).
- Fail-closed default: unmatched/unknown MCP behavior denies + escalates.
- Deprecation archives the manifest entry; it does NOT delete history.
- Re-activation after deprecation requires a NEW proposal (stage 1).

## Boundary - CRITICAL

- WHAT controls to check (7 mandatory controls, T0-T4 binding, AgentShield
  scan integration, spec-kit install-allowed/discovery-only policy,
  Anthropic security patterns): -> engineering-standards/references/mcp-review-criteria.md
- Ingestion CRITERIA (SC-09 to SC-19 threat rows): -> engineering-standards/references/supply-chain.md
- Runtime injection defense: -> operating-protocol/references/untrusted-content.md
- Prompt-design injection defense: -> prompt-expert/references/injection-defense.md
- This file = REVIEW PROCESS (WHO/WHAT/WHEN) only. Never duplicates CRITERIA.
