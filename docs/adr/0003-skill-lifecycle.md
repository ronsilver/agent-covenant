# ADR 0003: Skill Lifecycle — Creation, Update, Deprecation, Deletion

**Date:** 2026-04-27
**Status:** Accepted

## Context

Skills grow over time. Without a defined lifecycle policy, skills accumulate drift: outdated references, overlapping domains, abandoned stubs. The `content/disabled/skills/` directory was created for deprecated skills but had no formal process.

## Decision

### Creation

1. Use `skill-creator` skill to scaffold
2. Open a PR with `skill-request` issue linked
3. Requires: all required frontmatter + `references/` (if >3 inlined facts) + ≥1 eval test case

### Update

- Bump `metadata.version` on any behavioral change
- Update `manifest.yaml` if version is tracked there
- Cross-refs to other skills should be updated if the paired skill was renamed

### Deprecation (soft delete)

- Move to `content/disabled/skills/<name>/` when a skill is superseded but may be referenced
- Add `deprecated: true` to frontmatter and note the replacement

### Deletion (hard delete)

- Allowed when:
  - Skill has zero inbound cross-refs (verified via `grep -r "<name>" content/skills/`)
  - Skill has been in `disabled/` for ≥1 sprint
  - Manifest references removed
- Process: PR with `git rm -r` + CHANGELOG entry

## Consequences

- `content/disabled/` should be empty or near-empty in healthy repo state
- Deleting `context-*` stubs (ADR 0001 migration leftovers) is safe as they are informational references only
- The 2026-04-27 cleanup deleted all 4 disabled stubs; cross-refs in active skills pointing to `context-fundamentals` / `context-optimization` are now stale annotations (no behavioral impact)
