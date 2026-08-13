---
name: Prompts Catalog
description: Catalog and conventions for reusable agent prompts registered in manifest.yaml.
---

# Prompts

Reusable agent prompts following the schema in ADR-0008. Each prompt is a thin wrapper that delegates to a skill or workflow for domain expertise.

## Inventory

| Prompt | Delegates To |
|---|---|
| `spec-review.prompt.md` | `reviewer-expert` skill |

## Schema

See `docs/adr/0008-prompt-files-schema.md` for the full frontmatter schema: `name`, `description`, `trigger: manual`, `tags`, and one of `skill` or `workflow`.

## Deployment Posture

Prompts are **repo-registered only**: files under `content/prompts/` and the `prompts.files` entries in `manifest.yaml` are registered and validated by `make validate`, but `sync.sh` does NOT deploy them to any agent. No enabled agent declares a `prompts:` target (verified in `manifest.yaml`), so prompts never reach agent environments. This is a deliberate, documented scope decision — if a prompt must be deployed, add a `prompts:` target to the agent in `manifest.yaml` and update this section.

## Adding a Prompt

1. Create `content/prompts/<name>.prompt.md` with valid frontmatter per ADR-0008.
2. Register the file under `prompts.files` in `manifest.yaml`.
3. Run `make validate` and `make sync`.
