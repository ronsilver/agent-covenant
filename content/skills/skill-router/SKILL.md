---
name: skill-router
trigger: always
description: "Select the right skill for a task when the best match is unclear. Use when facing an unfamiliar task domain, when multiple skills could apply, when unsure whether a skill exists for the current work, when the agent needs to decide between overlapping skills, or when a user asks what is the best approach or how to handle a specialized domain. Trigger: which skill should I use, what skill handles, multiple skills apply, is there a skill for, choose between skills, skill selection, ambiguous task routing, disambiguation. Do NOT trigger for: clearly defined tasks with one obvious skill match, pure code implementation."
license: MIT
metadata:
  author: Community
  version: "3.0"
  category: ai-agents
  status: stable
disable-model-invocation: false
---

# Skill Router

**When to invoke a skill. Progressive disclosure: system prompt `<available_skills>` = catalog. This = decision guide.**

## Usage

System prompt already lists all available skills with `name`, `description`, `location`. Use that catalog directly.

| Situation | Action |
|---|---|
| Task fits one skill | Invoke `skill(name)` to load L2 instructions |
| ≥2 skills could match | Pick most specific category: api > backend > process |
| No skill matches | Proceed without — system prompt has enough general knowledge |
| Need depth | Load `references/disambiguation.md` |

## Disambiguation — Common Pairs

| Pair | Rule |
|---|---|
| `kubernetes-expert` vs `helm-expert` | Raw K8s YAML → `kubernetes`. Helm chart pkg → `helm` |
| `postgres-database-expert` vs similar | Queries/schema → `postgres`. Migrations → `postgres` also covers schema changes |
| `terraform-expert` vs `aws-cloud-expert` | IaC/.tf → `terraform`. AWS svc cfg → `aws-cloud` |

| `evaluation-expert` vs `reasoning-expert` | Quality measurement → `evaluation`. Fallacy detection → `reasoning` |
| `prompt-expert` vs `llm-expert` | Prompt design/injection → `prompt`. LLM ops/cost → `llm` |

## Boot Skills (NEVER invoke via `skill()`)

`operating-protocol` `governance` `engineering-standards` `context-management` `tool-usage` `token-efficiency` `skill-router`

Declared in `content/rules/core/boot-manifest.yaml` with `trigger: always`. Auto-loaded at session start.

## Anti-patterns

### Loading multiple skills when one suffices
```
// WRONG: task is a DB migration — loads both DB + migration skills
skill(postgres-database-expert)
skill(mysql-expert)
```
```
// CORRECT: pick the most specific — postgres-database-expert covers migrations + schema
skill(postgres-database-expert)
```
**Why:** Each skill load costs context budget. Load only what the immediate task needs.

### Routing by single loose keyword
```
// WRONG: task mentions "database" for caching question
skill(postgres-database-expert)  // should be redis-cache-expert
```
```
// CORRECT: require >=2 trigger keyword matches from system prompt
keywords: {"redis", "cache", "TTL"} >= 2 → redis-cache-expert
```
**Why:** Single-keyword routing causes false positives and wastes context.

### Invoking skill for trivial tasks
```
// WRONG: loading a skill for a grep or rename
skill(git-expert)  // for renaming a variable
```
```
// CORRECT: system prompt knowledge suffices — skip skill load
proceed without skill()
```
**Why:** Skills are for specialized domain knowledge, not general-purpose tasks.

### Falling back to no skill without broader category search
```
// WRONG: searched "ETL" → no match → gave up
```
```
// CORRECT: search broader category "data" or "pipeline" first
system prompt categories → data → scala-expert
```
**Why:** Skills use consistent category labels; broader search finds cross-domain matches.

## Verification Checklist

- [ ] Task domain classified before scanning skills
- [ ] System prompt `<available_skills>` consulted first (catalog always in context)
- [ ] >=2 trigger keywords matched before invoking skill
- [ ] Most specific skill selected when multiple candidates match
- [ ] No skill invoked for trivial edits (grep, rename, single-line fix)
- [ ] Boot skills (7) never invoked via `skill()` — always available

## Known Limitations

- **System prompt skill list may be stale**: `<available_skills>` reflects the system prompt snapshot; new/deleted skills take effect on agent restart. Always verify with `references/disambiguation.md` for edge cases.
- **Category assignment is subjective**: Some skills could fit multiple categories (e.g., `evaluation-expert` as process vs quality). When categories conflict, skill-router prefers the most narrowly scoped category.
- **Trigger keyword collision**: Similar domain skills (`golang-expert` vs `java-expert`) may share keywords like "gRPC" or "REST". Use language-specific keywords for disambiguation.

## References

| Resource | URL | Last verified |
|---|---|---|
| AgentSkills.io Specification | https://agentskills.io/specification | 2026-05-30 |
| Anthropic Skills Repository | https://github.com/anthropics/skills | 2026-05-30 |
