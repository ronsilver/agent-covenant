---
name: spec-driven-development
description: "Specification-driven development with OpenSpec and spec-kit: artifact-guided change lifecycle (proposal.md, specs/ REQUIREMENTS + WHEN/THEN, design.md, tasks.md), constitution-to-converge pipeline, analyze/checklist validation, brownfield application, and `openspec validate` gates. Use when starting a feature from a spec, converting requirements into executable tasks, validating change proposals, running spec checklists, or planning a brownfield refactor spec-first. Trigger: OpenSpec, spec-kit, spec-driven, proposal.md, design.md, tasks.md, REQUIREMENTS, WHEN/THEN, openspec validate, spec checklist. Do NOT trigger for: roadmap and milestone planning without spec artifacts (use planning-expert); ADR-only decision records (use planning-expert); implementation without a spec (use engineering-standards)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: process
  status: stable
trigger: on-demand
---

# Spec-Driven Development Expert

**Artifact-guided development: propose, apply, archive. Requirements become executable tasks through checkable specs.**

## Overview

Spec-driven development treats the spec as the executable contract for a change. OpenSpec and spec-kit define a deterministic lifecycle where each artifact has a fixed shape, each transition has a gate, and the final state is the archived change. This skill covers the full lifecycle and the boundary with plain planning.

**What this skill covers:**
- Change lifecycle: propose -> apply -> archive
- Artifact shapes: proposal.md, specs/ (REQUIREMENTS + WHEN/THEN), design.md, tasks.md
- Pipeline: constitution -> specify -> plan -> tasks -> implement -> converge
- Validation: `openspec validate` and the spec checklist (analyze / checklist)
- Brownfield application: spec-first retrofits on existing systems

**What this skill does NOT cover:**
- Roadmaps, milestones, and ADR-only decisions (use `planning-expert`)
- Implementation detail without a spec (use `engineering-standards`)
- Agent orchestration or subagent design (use `agent-expert`)

**Limitation:** `openspec validate` only proves artifact shape; it does not prove the spec is correct or complete. Pair shape checks with the checklist and design review.

## Quick Reference

| If you need to | Do this | See section |
|---|---|---|
| Start a feature from a requirement | Write proposal.md, then the delta spec | Lifecycle |
| Turn requirements into tests | Add REQUIREMENTS blocks and WHEN/THEN statements | Specs |
| Break a spec into work | Generate tasks.md from the spec | Pipeline |
| Check a proposal before apply | Run the analyze / checklist pass and `openspec validate` | Validation |
| Retrofit an existing system | Scope the delta spec to the brownfield boundary | Brownfield |

## Lifecycle

```
propose -> apply -> archive
```

1. Propose: write proposal.md (problem, solution, scope, affected specs) and the delta spec under specs/.
2. Apply: implement the tasks.md deliverables and update specs/ to the new intended behavior.
3. Archive: record the change, sync revisions into design.md, and merge delta specs into the main specs.

## Specs

A spec change is a delta describing intended behavior. Each requirement is a REQUIREMENTS block with WHEN/THEN statements:

```markdown
## REQUIREMENTS

### REQ-1: Feature exists
WHEN a user requests the feature
THEN the system returns a result
AND the result is cached
```

Rules:
- Write WHEN/THEN as executable assertions, not prose paragraphs.
- Keep each requirement single-behavior; split compound requirements.
- Update the spec delta BEFORE implementation so code has a target.

## Pipeline

```
constitution -> specify -> plan -> tasks -> implement -> converge
```

1. Constitution: confirm the spec-kit constitution and repo conventions are loaded.
2. Specify: write the delta spec (specs/) with REQUIREMENTS and WHEN/THEN.
3. Plan: write design.md for architecturally-significant decisions.
4. Tasks: derive tasks.md from the spec; each task maps to a requirement.
5. Implement: execute tasks.md; keep code in lockstep with the spec.
6. Converge: run `openspec validate`, run the checklist, and archive the change.

## Validation

### analyze / checklist

- Analyze: read the proposal and specs to confirm scope, affected specs, and open questions before apply.
- Checklist: run the spec checklist pass against proposal.md, specs/, design.md, and tasks.md; every item must be complete or explicitly deferred.

### openspec validate

`openspec validate` checks artifact shape and cross-references:
- Every requirement in specs/ maps to a task in tasks.md.
- Every task has an owner of the implementation (test, code, or doc).
- No dangling references between proposal, design, and specs.

Shape-pass is necessary, not sufficient. Treat a green `openspec validate` as the entry gate, then apply the checklist.

## Brownfield

For existing systems, apply spec-first in bounded slices:
- Scope the delta spec to one bounded context; do not rewrite the world in one proposal.
- Record the current behavior as the baseline spec, then specify the delta.
- Flag legacy behavior that violates the new WHEN/THEN as an explicit debt task.

## Constraints

- NEVER skip the proposal step for a change that touches a spec
- NEVER implement from a spec that fails `openspec validate`
- NEVER treat a green shape check as proof the spec is correct
- ALWAYS write WHEN/THEN as testable assertions
- ALWAYS archive a change after converge (append-only history)

## Anti-patterns

FAIL: Implementing before specifying
```
Spec: none. Code: feature shipped. Review: cannot verify intent.
```
PASS: Specify first, then implement
```
1. proposal.md approved
2. specs/ delta with REQUIREMENTS
3. tasks.md derived
4. implement
5. openspec validate + checklist + archive
```

FAIL: Prose requirements instead of WHEN/THEN
```markdown
The feature should let users see their history when they log in.
```
PASS: Executable assertion
```markdown
WHEN an authenticated user opens the history page
THEN the last 30 sessions are listed
```

FAIL: Unbounded brownfield scope
```
One proposal that rewrites six services and their specs.
```
PASS: Bounded slice
```
Delta spec scoped to one service; legacy violations recorded as debt tasks.
```

## References

| Resource | URL | Last verified |
|---|---|---|
| OpenSpec (Fission-AI) | https://github.com/Fission-AI/OpenSpec | 2026-08-10 |
| GitHub spec-kit | https://github.com/github/spec-kit | 2026-08-10 |
| Master catalog items: #46, #47 | see docs/reference/master-catalog-mapping.md | - |

## Verification Checklist

- [ ] proposal.md written with problem, solution, scope, and affected specs
- [ ] specs/ delta contains REQUIREMENTS with WHEN/THEN assertions
- [ ] design.md records architecturally-significant decisions
- [ ] tasks.md derived from specs; every requirement maps to a task
- [ ] `openspec validate` exits 0 on the change
- [ ] checklist pass completed (analyze / checklist)
- [ ] change archived after converge

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `openspec validate` fails | Spec artifact shape or cross-reference broken | Fix the delta spec or tasks.md reference; re-run validate |
| Requirements not testable | WHEN/THEN written as prose | Rewrite each as a single-behavior assertion |
| Implementation drifts from spec | Code written before the spec delta landed | Rebase the tasks to the accepted spec; update the delta first |
| Scope creep in a brownfield change | Delta spec not bounded to one context | Re-scope to one bounded context; defer the rest as debt tasks |
