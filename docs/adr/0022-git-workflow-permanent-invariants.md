# ADR-0022 -- Git workflow permanent invariants (no re-prompt required)

**Status**: Accepted · **Date**: 2026-06-24

## Context
The `git-requests` subagent and the `git-expert` skill exist to handle the
branch / commit / push / PR flow end-to-end using git best practices. In
practice, however, the user had to re-paste the SAME four rules at every
`@git-requests` invocation:

1. Create a branch for the changes (if it does not already exist) with a name
   distinct from `main`, `master`, `develop`, `development`, `staging`, and
   `sandbox`.
2. Create commits -- minimum 2, as segmented as possible (the more commits,
   the better).
3. Ask before running `git push`.
4. Create a pull request using the project's PR template, falling back to a
   default template if none exists.

Rule 4 was already satisfied by the existing "PR/MR template detection" +
"Default PR/MR template" sections of `git-requests.md`. Rules 1, 2, and 3 were
absent or weak: push was `allow`-gated, no protected-branch list was enforced,
and the commit-splitting rule emphasized the minimum but not the preference
for maximum segmentation. The result: the agent existed but did not encode
the user's standing expectations, forcing the user to act as a prompt
repeater.

## Decision
Embed the four rules as PERMANENT invariants in two source-of-truth files so
the user never has to re-prompt them:

1. **`content/subagents/git-requests.md`** -- the executable agent contract:
   - Frontmatter: `"git push*": allow` -> `"git push*": ask` (rule 3 enforced
     at the permission gate, not just prose).
   - Workflow step 4: protected-branch guard listing all six names (rule 1).
   - Commit splitting strategy: add max-segmentation preference (rule 2).
   - Workflow step 6: require explicit user confirmation before `git push`
     (rule 3, procedural counterpart of the ask gate).
   - Known blind spots + Anti-patterns: protected-branch + ask-before-push
     entries, both tagged `(ADDRESSED ... ADR-0022)`.

2. **`content/skills/git-expert/SKILL.md`** -- the domain knowledge base:
   - New "Protected branches" subsection under Branching Strategy, centralizing
     the six-name list as the canonical source.
   - Two new Constraints: never create a branch named after a protected
     branch; always ask confirmation before `git push`.

3. **`tests/test_validate.bats`** -- 5 regression tests (ADR-0022) asserting:
   - `git-requests.md` frontmatter gates `git push` as `ask` (not `allow`).
   - `git-requests.md` mentions all six protected branch names.
   - `git-requests.md` step 6 requires explicit confirmation before push.
   - `git-requests.md` prefers max-segmentation commits.
   - `git-expert/SKILL.md` documents the "Protected branches" section.

Rule 4 (PR template + default fallback) required no change; it was already
implemented and is referenced here only for completeness.

## Alternatives rejected
- Keep the rules out of the agent and rely on the user re-pasting them:
  this is the exact pain point being solved. Rejected.
- Encode the rules only in `git-expert` SKILL.md: the subagent is the
  executable contract, and skills are on-demand; the invariants must live in
  the agent that performs the action. Rejected (kept in BOTH for defense in
  depth).
- Make `git push` a hard `deny` instead of `ask`: would prevent legitimate
  pushes; the user wants to be asked, not blocked. Rejected.
- Hard-code the protected-branch list in a single file: spread across
  git-requests step 4 AND git-expert SKILL.md so neither can drift alone;
  git-expert remains the canonical knowledge source. Accepted (dual-site).

## Consequences
- (+) User no longer re-prompts the four rules; they are permanent agent
  behavior.
- (+) Push is ask-gated at the permission layer, so even if the agent skips
  the procedural step 6, the runtime still pauses for confirmation.
- (+) Protected-branch list is centralized in git-expert and enforced in
  git-requests; regression tests prevent silent removal.
- (-) `git push` is now ask-gated on every feature branch push, adding one
  confirmation round per push. Acceptable per user intent ("preguntar al
  hacer git push").
- (-) Six protected names are project-defaults; repos with different protected
  branches must extend the list in both files. Documented limitation.

## Files changed

| File | Change |
|------|--------|
| `content/subagents/git-requests.md` | push gate `allow`->`ask`; step 4 protected-branch guard; commit-splitting max-segmentation; step 6 confirm-before-push; blind spots + anti-patterns |
| `content/skills/git-expert/SKILL.md` | "Protected branches" subsection; 2 new Constraints |
| `tests/test_validate.bats` | 5 regression tests (ADR-0022) |
| `CHANGELOG.md` | entry under `[Unreleased] / ### Changed` |
| `README.md` | ADR count 21 -> 22 |

## Approval
- Human: Accepted (explicit user instruction 2026-06-24, "para que esta el
  subagente y skill si siempre debo entregar el mismo prompt para que
  funcione" + "procede con los cambios").
