# Spec-Driven Workflow Hooks

## Scope

Hooks for spec-first development. This repository ships OpenSpec MCP tools
(openspec_create_proposal, openspec_archive_change, etc.) and orchestrates
ultraplan -> ultracode. This file documents the binding between engineering
standards and the spec lifecycle.

## Workflow Phases

| Phase | Command / MCP | Engineering-standards gate |
|---|---|---|
| Propose | `openspec_create_proposal` (alias /opsx:propose) | Scope defined; <=3 files? if >3 confirm first (context-management) |
| Plan | `ultraplan` (alias /plan) | Plan junior-readable; TDD/YAGNI/DRY applied (quality.md) |
| Build | `ultracode` (alias /build) | Code limits enforced: fn<=50L, file<=300L, nesting<=3 |
| Test | `test-writer` (alias /test) | Tests are proof; synthetic fixtures only (security.md) |
| Review | `ultrareview` / `code-review` | Pre-commit chain run: Format->Lint->Type->Test->Security |
| Archive | `openspec_archive_change` (alias /opsx:archive) | Spec deltas merged; CHANGELOG + README updated |

## Artifact-Guided Discipline (OpenSpec)

Each proposal creates an artifact set under `openspec/changes/<change-id>/`:
- proposal.md - why, what changes
- specs/ - requirements + scenarios
- design.md - technical approach
- tasks.md - implementation checklist

Brownfield-friendly: works on existing codebases, not just greenfield.

Reference: https://github.com/Fission-AI/OpenSpec (last_verified: 2026-06)
- artifact-guided workflow, /opsx:propose /opsx:apply /opsx:archive.

## Autonomous Build Mode

`/build auto` (addyosmani/agent-skills pattern): approve plan once, then
runs autonomously. Pauses on failures or risky steps. Every task still
test-driven and committed individually. Human steps between tasks removed,
NOT verification gates.

Reference: https://github.com/addyosmani/agent-skills (last_verified: 2026-06)
- /spec /plan /build /test /review /ship + /build auto.

## Superpowers Alignment

obra/superpowers: spec-before-code, junior-readable plan, subagent-driven
development, true red/green TDD, YAGNI, DRY. Agent steps back and asks what
you are really trying to do before writing code.

Reference: https://github.com/obra/superpowers (last_verified: 2026-06)

## Boundary

- Detailed planning methodology: -> `planning-expert` skill
- Sub-agent orchestration patterns: -> `agent-expert` skill
- This file only documents the ENGINEERING-STANDARDS gates at each phase.
