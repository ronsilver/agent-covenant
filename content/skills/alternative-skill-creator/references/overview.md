# Skill Creator Overview

## Skill Purpose

Guide the creation of effective skills that extend Claude's capabilities with specialized knowledge, workflows, and tool integrations.

## What Is a Skill?

A skill is a structured knowledge package stored as a directory in `content/skills/`. When invoked, it gives the AI agent:

1. **Domain context**: deep knowledge of a specific technical area
2. **Opinionated defaults**: "use this, not that" for common decisions
3. **Actionable patterns**: copy-paste code examples and workflows
4. **Reference navigation**: links to detailed sub-topics

## Skill Directory Structure

```
content/skills/<skill-name>/
├── SKILL.md           # Entry point — concise, high-value, ≤300 lines
└── references/        # Detailed sub-topics, linked from SKILL.md
    ├── overview.md    # Purpose and navigation (this pattern)
    ├── *.md           # Domain-specific reference files
    └── ...
```

## Good vs. Bad Skills

| Characteristic | Good Skill | Bad Skill |
|---------------|-----------|----------|
| Scope | One domain, one technology stack | "Everything about backend" |
| SKILL.md | Concise, navigable, actionable | Wall of text with everything |
| References | Detailed, code-heavy, specific | Placeholder boilerplate |
| Opinionation | Clear preferences with reasons | "Both X and Y are valid" |
| Code examples | Real, runnable snippets | Pseudocode with TODO |

## Reference Navigation

| Topic | File | When to Use |
|-------|------|-------------|
| What skills provide | `what-skills-provide.md` | Understanding the skill system |
| Creating a skill | (SKILL.md) | Step-by-step creation guide |

## Skill Quality Checklist

Before finalizing a skill:
- [ ] `SKILL.md` is ≤ 500 lines
- [ ] No placeholder content (`See SKILL.md for usage context`)
- [ ] All reference files have real content with code examples
- [ ] Skill has a clear "when to use this" trigger
- [ ] Opinionated defaults are stated with reasoning
- [ ] At least 3 concrete code examples in references
