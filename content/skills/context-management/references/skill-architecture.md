# HashiCorp-Inspired Skill Architecture

## Knowledge Unit Pattern

Folder-based organization where each directory is a self-contained knowledge unit:

```
skill-name/
+-- SKILL.md                 # Entry point: metadata + core workflow
+-- references/              # Knowledge units (loaded on-demand)
|   +-- overview.md          # Architecture + when to use
|   +-- patterns.md          # Common patterns
|   +-- api-reference.md     # API signatures + examples
|   \-- troubleshooting.md   # Error patterns + resolution
+-- scripts/                 # Executable helpers (optional)
\-- assets/                  # Templates, diagrams (optional)
```

**Principle**: SKILL.md = compressed entry point. `references/` = expanded knowledge, loaded JIT.

## Review Evals vs Task Evals

| Eval Type | Purpose | Example |
|---|---|---|
| **Review** | Assess quality of agent output | "Does this Terraform module follow naming conventions?" |
| **Task** | Verify agent executed correctly | "Did the agent create the PR with correct title and description?" |

**Design rule**: reviews test the agent (quality). Tasks test the environment (correctness). Keep separate.

## Knowledge vs Data Access Separation

```
KNOWLEDGE layer (references/*.md)
  -> Patterns, best practices, API docs
  -> STATIC -- read once, cached indefinitely
  -> Updated via PR to skill repo

DATA layer (MCP tools, APIs, databases)
  -> Live state: metrics, logs, transactions
  -> DYNAMIC -- re-read on every use
  -> Accessed via MCP tools, never embedded in references
```

**Anti-pattern**: embedding live data (today's metrics, current deploy status) in skill references.
**Correct**: skill references teach the agent *how* to fetch data; MCP tools provide the data.

## Skill Composition (not Inheritance)

Skills reference each other, never extend:
```yaml
---
skills:
  - tool-design              # Composes, not inherits
  - agent-prompt-engineering
---
```

Each skill remains self-contained. Cross-references are advisory ("see also X for Y"), not contractual ("X must be loaded first").

## this project Skill Architecture Decision Record

**Decision**: Hybrid architecture -- Kernel (F1, always-on, <6000 chars) + Skills (F2, on-demand via Skill tool).
**Rationale**: F1 kernels provide identity, safety, and tool discipline regardless of agent type. F2 skills load domain knowledge when tasks match. Keeps baseline context small while enabling deep specialization.
**Tradeoff**: Agent must correctly route tasks to skills. Mitigated by `skill-router` with keyword triggers and domain categories.

## Skill Loading Strategy

```
Session start: load F1 (kernel) + universal baseline skills
Task detected: match domain via skill-router -> Skill(domain_skill)
Skill loaded: SKILL.md in context, references available JIT
Task complete: domain skill context recycled (not persisted)
```

Never pre-load all skills -- load only when >=2 keyword triggers match or task domain is unambiguous.

## Boundary

- Skill CREATION / codification (skillify pattern): -> `skill-creator`.
- Orchestration patterns: -> `agent-expert`.
- This file = the SKILL-FILE ARCHITECTURE pattern (knowledge-unit, F1/F2 loading), not the context-loading technique.
