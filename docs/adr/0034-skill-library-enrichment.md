# ADR-0034: Skill-Library Enrichment from Master-Catalog Skill Repos

**Date:** 2026-08-10
**Status:** Accepted

## Context

The master catalog maps additional tool and domain repos to existing skills that can absorb them as sections or references rather than new standalone skills. Without an ADR these edits would look like ungoverned drift; the Core-skill edit (engineering-standards) additionally requires the ADR -> human approval -> manifest -> CHANGELOG chain. ADR-0033 already covers the token-efficiency refresh; this ADR covers the remaining skill-library enrichment (D9-D13).

## Decision

Enrich the skill library from master-catalog skill repos:

1. D9: add new skill `spec-driven-development` (OpenSpec and spec-kit lifecycle; category: process, status: stable) with manifest registration (T15a).
2. D10: fold LLM red-team guidance (garak, PyRIT) into `penetration-testing-expert` as new sections; no separate skill (T15b).
3. D11: no new subagents; the repo precedent (53 -> 15 consolidation) holds (T15 scope note).
4. D12: IaC stance: Terraform with modules only; CDK (AWS or CDKTF) out of scope — operator decision 2026-08-12.
5. D13: I-level optional enrichments are recorded only in the refresh matrix (T15m).
6. Strengthened skills: planning-expert, reviewer-expert, security-expert, engineering-standards, prompt-expert, agent-expert, agent-architecture-expert, finops-cost-optimization, research-expert, aws-cloud-expert.
7. Core edit: `engineering-standards/references/supply-chain.md` gains skillspector ingestion patterns and optional gate exit codes; engineering-standards version 2.3 -> 2.4. This plan's approval constitutes the human approval; T11 records the CHANGELOG entries.

No sensitive authentication data is persisted; this change is documentation-only.

## Alternatives Considered

1. One new skill per catalog repo: rejected — the domains are covered by existing skills; new skills would duplicate boundaries.
2. No ADR for non-Core edits: rejected — governance requires a single audit record for the whole enrichment.
3. Flip the IaC default: rejected (D12) — Terraform with modules is the single IaC stance.

## Consequences

- The skill library grows by one new skill (spec-driven-development) and gains depth in ten existing skills.
- engineering-standards (Core) version bump is recorded in CHANGELOG (T11) and this ADR.
- Future master-catalog updates must re-verify content against the READMEs cited in each edit.

## Evidence

- OpenSpec (Fission-AI) and GitHub spec-kit: https://github.com/Fission-AI/OpenSpec and https://github.com/github/spec-kit (accessed 2026-08-10).
- OWASP LLM Top 10 v2.0 (2025) and MITRE ATLAS (accessed 2026-08-10).
- skillspector 68-pattern / 17-category agent-attack catalog and the MCP vetting 5-step process (master catalog #97, #64).
- AWS AgentCore (Code Interpreter, Browser, Gateway) documentation (master catalog #23).
- Master catalog item references: #4, #17, #20, #23, #39, #40, #42, #46, #47, #49, #57, #59, #60, #64, #66, #93, #96, #97, #98, #102, #148, #152. (mis-cited #12 removed — #12 is pgcheck; #23 stays via AgentCore/cost-ops, T15i/T15j; T15o-3)
