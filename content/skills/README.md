# Agent Skills

63 active skills following the [Agent Skills](https://agentskills.io) open standard (schema v2). Skills are loaded on-demand via progressive disclosure when the agent detects relevance. Every skill except `graphify` (exempt) carries `evals/evals.json`, validated by `make validate-evals` (Schema B canonical, Schema A legacy).

No deprecated skills in active rotation. All retired skills are documented in `manifest.yaml` under `retired:`.

> **Note (2026-06-30):** The `context-sculpting` technique was evaluated for inclusion in the `token-efficiency` v2.1 plan and **retired before publication**. V-grade evidence from the perceptiontheory demos showed 14x-70x cost blowup, no demonstrated quality benefit, and 10 additional negative effects beyond cost (over-intervention, latency 12-13x, inner-agent opacity, in-memory-only limitation). The technique is excluded from the final scope (plan archive removed).

## Architecture — Progressive Disclosure

| Level | Content | When Loaded | Tokens |
|---|---|---|---|
| **L1: Metadata** | `name` + `description` | Always (startup) | ~100/skill |
| **L2: Instructions** | Full `SKILL.md` body | When agent detects relevance | <5000 recommended |
| **L3: Resources** | `references/`, `evals/` | Only when referenced | Variable |

## Skill Structure

```
content/skills/<name>/
├── SKILL.md           # Required — YAML frontmatter (schema v2) + instructions
├── references/        # Required — deep knowledge loaded on demand
├── evals/             # Required — eval test cases (evals.json)
└── scripts/           # Optional — executable utilities
```

## Frontmatter (Schema v2)

```yaml
---
name: my-skill
description: "What this skill does. Use when ..."
trigger: on-demand          # always | on-demand | never (v2.6+)
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend
  status: stable
---
```

**Categories:** `ai-agents` · `backend` · `cloud` · `core` · `data` · `frontend` · `infrastructure` · `meta` · `process` · `quality` · `security`

**Statuses:** `stable` · `beta` · `deprecated`

## Core Rule Skills (6) + skill-router = 7 Boot Skills

**Main sessions** load all 7 skills always-on (`governance`, `operating-protocol`, `engineering-standards`, `context-management`, `token-efficiency`, `tool-usage`, `skill-router`) — see `content/rules/core/boot-manifest.yaml`.

**Subagents** (content/subagents/) load ALL 7 unconditionally at their Step 0, before any task (AGENTS.md Architectural Invariant #4).

**Core (immutable):** `engineering-standards` · `operating-protocol` · `context-management` · `tool-usage` · `token-efficiency` · `governance`

**Mandatory domain:** `skill-router`

See `content/rules/core/boot-manifest.yaml` for the full specification.

## Reference

→ Full catalog with descriptions: [`docs/reference/skills-catalog.md`](../../docs/reference/skills-catalog.md)
→ Schema design: [`docs/adr/0006-skill-metadata-schema.md`](../../docs/adr/0006-skill-metadata-schema.md)
→ Adding a new skill: [`AGENTS.md`](../../AGENTS.md) §Skills

## TO-DO — Open Governance Questions

- [x] **SC-15 MCP review ownership** (from engineering-standards v2.1 plan, 2026-06-30): Confirm that the `governance` Core skill owns the MCP-server review *process* (mandatory binding, approval workflow). The `engineering-standards/references/supply-chain.md` file (Paso 4c, OWASP LLM Top 10 v2.0 alignment) only lists *ingestion criteria* for MCP configs — it must NOT redefine the review process. If `governance` does NOT own MCP review, escalate as `[CORE CONFLICT]` before merging supply-chain.md. Tracking issue: engineering-standards v2.1 plan §Pre-mortem SC-15 (plan archive removed).

**RESOLVED (2026-06-30):** `governance` Core skill owns MCP review PROCESS. Evidence: `governance/SKILL.md:66-68` (MCP configs must pass governance review), `:96` (Catastrophic escalation), `:121` (Quick Reference), `:203` (Verification Checklist), `:214` (Troubleshooting). supply-chain.md SC-15 correctly scoped to ingestion CRITERIA only.

## TO-DO -- Deferred Decisions

- **Universal Memory Protocol (UMP)**: UMP (https://universalmemoryprotocol.io/) proposes a 6-operation memory interoperability layer (MCP for tools / A2A for talk / UMP for memory) with bi-temporal supersede-never-delete + injection-resistance mandate. DEFERRED: not adopted as a standard because there is no platform service or infrastructure focused on cross-vendor memory interoperability yet. Techniques extracted (bi-temporal, injection-resistance) are recorded in context-management/references/staleness-protocol.md as patterns. If a memory service is later built, revisit UMP adoption -> requires a new ADR. Tracked: 2026-07-01.

## TO-DO -- Deferred Investigation (removed from tool-usage v2.1 plan)

- **codegraph (colbymchenry/codegraph)**: Removed from the tool-usage v2.1 plan (archive removed) after 5-subagent review flagged composite case study as unverifiable (self-run, no repro harness). The `codegraph_explore` composite tool concept was originally in T3 (design-principles.md) and T4 (tool-selection.md). To add later: requires a new plan with third-party reproduction or a public harness. Tracked: 2026-07-01.

- **architect-loop (DanMcInerney/architect-loop)**: Removed from the tool-usage v2.1 plan (archive removed) after 5-subagent review flagged "Fable 5" model name discrepancy (README says "Claude Fable"/"Fable", no "5" suffix). Cross-vendor handoff pattern was originally in T5 (orchestration.md). To add later: requires a new plan with corrected model attribution. Tracked: 2026-07-01.
