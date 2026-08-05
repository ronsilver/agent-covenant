# ADR 0002: SKILL.md Frontmatter Schema

**Date:** 2026-04-27
**Status:** Accepted

## Context

Skills need a consistent, machine-readable frontmatter schema to enable validation, indexing, and routing. The schema must balance completeness with flexibility — overspecification prevents natural skill growth.

## Decision

**Required fields** (enforced by `scripts/validate.sh`):
- `name`: lowercase-hyphenated string, must match directory name
- `description`: ≥50 chars; must contain "Use when" to guide routing
- `license`: string (default `MIT`)

**Optional fields** (present in ≥95% of skills by convention):
- `metadata.author`: author or org (e.g., `Community`)
- `metadata.version`: semver string (e.g., `"2.0"`)
- `metadata.category`: controlled vocabulary (see taxonomy ADR)
- `disable-model-invocation`: boolean; `false` = skill loaded as context (default)

**Explicitly NOT validated** (see validate.sh comment at L257):
- `metadata.version` presence or any subfield — version is tracked in manifest.yaml; SKILL.md metadata is advisory only and MUST NOT be a CI gate.
- `compatibility`, `allowed-tools` — experimental; optional

## Rationale

- Requiring `metadata.version` in CI would require mass updates to ~80 skills simultaneously
- Skill versioning is the responsibility of the manifest, not SKILL.md frontmatter
- Optional advisory fields (author, category) improve discoverability without creating a merge gate

## Consequences

- New skills should include all optional fields by convention
- `skill-creator` skill enforces this convention when creating new skills
- Validation script must NOT be changed to require `metadata.*` without a migration plan
