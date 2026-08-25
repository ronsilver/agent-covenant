---
name: my-skill-name
description: "A clear description of what this skill does, when to activate (>=3 trigger keywords), and when NOT to activate (>=1 anti-trigger). Trigger: <keyword1>, <keyword2>, <keyword3>. Do NOT trigger for: <anti-trigger>."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: core
  status: beta
  trigger: on-demand
compatibility:
  - claude-code
  - opencode
  - cursor
  - codex
  - gemini
---

# My Skill Name

> **One-liner:** What this skill does in one sentence.

## Overview

2-4 lines describing the domain, core concepts, and the problem this skill solves. Assume the agent knows nothing about this topic.

**What this skill covers:**
- X
- Y
- Z

**What this skill does NOT cover:**
- A (use `other-skill` instead)
- B (use manual configuration)

---

## Quick Reference

Decision table for the most common scenarios. Agent should find what to do in <3s.

| If you need to | Do this | See section |
|---|---|---|
| Common scenario 1 | `<command or action>` | Workflow |
| Common scenario 2 | Follow checklist X | Guidelines |
| Error: symptom Z | Apply fix Y | Troubleshooting |

---

## Workflow

### Primary Path: [Scenario Name]

```
1. [Step 1 - concrete action]
2. [Step 2 - concrete action]
   -> Expected output: [what to observe]
3. [Step 3 - decision point]
   -> If X: go to path A
   -> If Y: go to path B
4. [Verify step]
5. [Final step - confirm done]
```

**Before starting, confirm:**
- [ ] Precondition 1 met
- [ ] Precondition 2 met

**After completing, verify:**
- [ ] Run `<command>` to confirm success
- [ ] Check `<metric or log>`
- [ ] No `<specific error>` in output

### Alternative Path: [Other Scenario]

```
1. [Step 1]
2. [Step 2]
```

---

## Guidelines

### DO

| Rule | Why |
|---|---|
| Do X | [Rationale] |
| Do Y | [Rationale] |

### DO NOT

| Anti-pattern (cross mark) | Correct approach (check mark) | Why |
|---|---|---|
| cross mark `wrong code or bad practice` | check mark `correct code or better practice` | [Explanation of the mistake] |
| cross mark `another wrong pattern` | check mark `another correct pattern` | [Explanation] |

---

## Anti-patterns

### cross mark [Anti-pattern Name]
```[language]
// WRONG
bad-code-example
```
```[language]
// CORRECT
good-code-example
```
**Why:** Explanation of why the wrong version fails and the correct version is better.

### cross mark [Another Anti-pattern Name]
[Same structure with code]

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Error message X | Cause A | `command or checklist to fix` |
| Unexpected output Y | Cause B | Step-by-step recovery |
| Known bug Z | Version X.Y.Z | Workaround or upgrade path |

---

## Verification Checklist

Before claiming "done", confirm ALL:

- [ ] Workflow executed end-to-end
- [ ] Output passes validation (`<command>`)
- [ ] No regressions in connected systems
- [ ] Edge cases handled: empty state, failure state, large input
- [ ] Anti-patterns avoided from section above

---

## References

| Resource | URL | Last verified |
|---|---|---|
| Official docs | `<url>` | YYYY-MM-DD |
| Related skill: `other-skill-name` | `<path>` | - |
| Internal guide | `<url>` | YYYY-MM-DD |

---

## Shell Safety

When including shell commands or special characters, follow these rules to prevent Zsh history expansion errors in any AI agent (OpenCode, Claude Code, Cursor, etc.).

### Dangerous Characters

These characters trigger Zsh history expansion when loaded by any agent:

| Character | Why dangerous | Alternative |
|---|---|---|
| `!` + double quote | Bang + double quote: history expansion | Rewrite without emphatic `!` |
| `!` + single quote | Bang + single quote: history expansion | Use `not` / `avoid` / `never` |
| `!` + backtick | Bang + backtick: shell interprets as command | Place `!` inside fenced code block |
| `!` + star | Bang + star: Zsh expands to all last args | Replace with `any` / `all` / `wildcard` |
| `!` end of sentence | Prose emphasis -> shell finds command | Remove `!` from prose, use period |

### Safe Patterns

Fenced code blocks - `!` inside triple-backtick blocks is safe:
```bash
echo "Done!"  # safe inside fenced block
```

Code language examples - `!` in Rust/Ruby/Swift blocks is safe:
```ruby
record.save!  # safe inside ```ruby block
```

### Unsafe Patterns (NEVER in prose)

`!"` in prose:
- BAD: `Never commit secrets to Git!`
- GOOD: `Never commit secrets to Git.`

`!` + backtick inline code:
- BAD: `` Use `!` to negate ``
- GOOD: `Use a negation operator`

`!*` in prose:
- BAD: `specific actions only (!`*`)`
- GOOD: `specific actions only (avoid wildcard *)`

### Pre-commit Validation

Run the shell safety scanner before committing:
```bash
python3 scripts/validate-shell-safety.py --ci
```

This gate is integrated into `make check`.

## Evals schema (evals/evals.json)

Each skill SHOULD carry an `evals/evals.json`. Two schemas are accepted:

- **Schema B (canonical, preferred for new skills):**
  ```json
  {
    "skill": "<skill-name>",
    "version": "1.0",
    "description": "<what this skill is evaluated on>",
    "rubric": { "score_range": [0, 5], "criteria": ["<observable criteria>"] },
    "test_cases": [
      {
        "id": 1,
        "stratum": "simple | medium | complex",
        "input": "<realistic user prompt that triggers this skill>",
        "expected_behaviors": ["<observable behavior the output must have>"],
        "flags_to_avoid": ["<failure modes the output must not have>"]
      }
    ]
  }
  ```
- **Schema A (legacy, accepted):** top-level `evals` list; each case has `prompt` (str) and `expected_output` (str, >=60 chars).

Validation is enforced by `make validate-evals` (`scripts/validate-evals.py`). New skills MUST use Schema B; existing Schema A skills are not required to migrate.
