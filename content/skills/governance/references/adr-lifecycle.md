# ADR Lifecycle -- OpenSpec Binding

## Scope

Documents the ADR (Architecture Decision Record) lifecycle bound to OpenSpec
MCP tools (openspec_create_proposal, openspec_archive_change) and the spec-kit
constitution pattern. Governance Council (SKILL.md) defines the rules; this
file documents the binding + artifact flow.

Source: https://github.com/Fission-AI/OpenSpec (accessed 2026-07-02) -- /opsx:propose, /opsx:apply, /opsx:archive, artifact-guided workflow.
Source: https://github.com/github/spec-kit (accessed 2026-07-02) -- /speckit.constitution creates governing principles referenced by all subsequent phases.

## 6-Step Lifecycle

| Step | OpenSpec command | Artifact | Governance gate |
|------|------------------|----------|-----------------|
| 1. Propose | openspec_create_proposal (/opsx:propose) | docs/adr/00NN-title.md + openspec/changes/<id>/proposal.md | Rationale + impact + migration plan present |
| 2. Review | (human) | PR comment / approval log | Human approval recorded with audit trail |
| 3. Version | (edit frontmatter) | metadata.version bump (MAJOR.break / MINOR.add-fix) | semver compliant |
| 4. Register | (edit manifest) | docs/skills-core-definition.md + manifest.yaml | make validate passes; cross-refs intact |
| 5. Changelog | (edit CHANGELOG) | ## [Unreleased] ### Changed (Core Governance) | Header present + entry describes change |
| 6. Archive | openspec_archive_change (/opsx:archive) | docs/adr/archived/00NN-title.md (deprecation date) | Spec deltas merged into main specs |

## spec-kit Constitution Pattern

spec-kit's /speckit.constitution creates .specify/memory/constitution.md --
governing principles referenced by specify, plan, and implement phases. This
ensures consistent decision-making throughout development.

Governance binding: docs/skills-core-definition.md is the constitution
equivalent for this repo. Every ADR MUST reference it. The Supremacy Clause
(SKILL.md) is the immutable constitution layer -- ADRs may extend but never
override it.

## Deprecation Archive

Superseded ADRs move to docs/adr/archived/ with:
- Original filename preserved
- Deprecation date appended to frontmatter
- "Superseded by ADR-00MM" pointer
- Reason for deprecation

Archive is NOT deletion. ADRs are immutable history. Direct edit to an
Accepted ADR = [GOVERNANCE VIOLATION] Critical severity (rollback + new ADR).

## Anti-pattern

- Editing an Accepted ADR in place (no archive, no supersession pointer) =>
  BLOCK. History must be append-only.
- ADR without migration plan => reject at step 1.
- Version bump without CHANGELOG entry => reject at step 5 (CI gate).

## Boundary

- Detailed planning methodology: planning-expert
- OpenSpec artifact schema: Fission-AI/OpenSpec docs
- This file = ADR LIFECYCLE + OpenSpec binding + constitution reference only.
