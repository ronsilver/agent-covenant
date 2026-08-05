# ADR 0008: Prompt Files Schema

**Date:** 2026-05-04
**Status:** Accepted
**Branch:** feat/copilot-inspired-skill-enhancements

## Context

The project has 10 prompt files (`content/prompts/*.prompt.md`) deployed by `sync.sh` and registered in `manifest.yaml`. Their frontmatter schema was consistent but undocumented. This ADR formalizes the existing convention.

## Decision

### Prompt File Schema

```yaml
---
name: <Title Case name>          # Display name (e.g. "Review", "Security")
description: <one-line summary>  # What the prompt does
trigger: manual                  # Reserved for future auto-trigger support
tags: [<kebab-case categories>]  # Taxonomy tags for search/filtering
skill: <skill-name>              # Primary skill this prompt delegates to
# OR:
workflow: <category/workflow>    # Workflow this prompt delegates to (instead of skill)
---
```

### Fields

| Field | Required | Notes |
|---|---|---|
| `name` | Yes | Title Case, display name |
| `description` | Yes | One-line summary |
| `trigger` | Yes | Always `manual` currently; reserved for future auto-trigger |
| `tags` | Yes | YAML list of kebab-case category tags |
| `skill` | No* | Delegates to a named skill. Mutually exclusive with `workflow`. |
| `workflow` | No* | Delegates to a named workflow. Mutually exclusive with `skill`. |

*One of `skill` or `workflow` should be present unless the prompt is self-contained.

### Relationship to Skills

Prompt files are thin wrappers — they delegate to skills for domain expertise. A prompt file without a `skill:` or `workflow:` is self-contained (e.g., `explain.prompt.md` has no skill dependency).

### Current Inventory (10 prompts)

| Prompt | Delegates To |
|---|---|
| `commit` | `git-protocol` |
| `debug` | `systematic-debugging` |
| `document` | `documentation-generator` |
| `explain` | (self-contained) |
| `optimize` | `performance-optimization` |
| `refactor` | `refactoring` |
| `review` | `code-review` |
| `security` | `security-audit` |
| `test` | `test-driven-development` |
| `validate` | `validation/validate` (workflow) |

## Consequences

- Prompt files are documented as first-class content alongside skills and workflows
- Frontmatter normalization is a one-time task (already consistent)
- New prompts must follow this schema
- `explain.prompt.md` intentionally has no `skill:` — self-contained prompts are valid
