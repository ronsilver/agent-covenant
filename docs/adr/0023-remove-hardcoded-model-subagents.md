# ADR-0023 -- Remove hard-coded `model:` from subagent frontmatter (provider portability)

**Status**: Accepted · **Date**: 2026-06-24

## Context
All 17 subagents in `content/subagents/` hard-coded `model: anthropic/claude-sonnet-4`
(`ultraplan` used `anthropic/claude-opus-4-8`) in their frontmatter. This field is
OpenCode agent metadata preserved by `scripts/lib/sync.sh:opencode_subagent_transform()`
and written to the synced `~/.config/opencode/agents/<name>.md`.

This repository is multi-agent: it deploys the same subagent files to 5 targets
(`opencode`, `claudecode`, `cursor`, `codex`, `gemini`). A provider-specific model
string (`anthropic/*`) is NOT portable:

- On OpenCode runtimes that do not have the `anthropic` provider configured, the
  synced agent declares a model the runtime cannot resolve.
- Symptom: OpenCode creates the subagent session successfully (the dispatch works),
  then fails with `ProviderModelNotFoundError` when it tries to start the model.
  The `task` tool returns a bare `Error` with no message. 14 such errors were
  logged in one day.
- Net effect: `git-requests` (and every other subagent) was un-invocable via
  `task` on OpenCode even though ADR-0020 (registration) and ADR-0021
  (discoverability) had already succeeded. Prior debugging blamed the wrong
  layers (injection, hardcoded task-type list, credits, permission deny rules)
  because the failure is post-dispatch, not at dispatch.

The root cause is a portability violation: provider-specific metadata baked into
a file synced to multiple agents with different default providers.

## Decision
Remove the `model:` field from all 17 subagent frontmatter files. Subagents now
inherit the runtime's default model, which is provider-agnostic and correct for
whatever environment the synced file lands in.

This conforms to the existing schema contract:
- `content/subagents/README.md` L178: `model: <provider/model-id>` is "required
  when deviating from default" -- i.e. OPTIONAL, used only for deliberate
  deviation.
- `docs/reference/subagent-schema.md` L12: `model: provider/model-id` is
  "optional; required when deviating from default".
- `AGENTS.md` L106 validation rule: "`model` field specified when deviating
  from default" -- confirms optional usage.

`sync.sh` already guards the emit: `[[ -n "${model}" ]] && printf 'model: ...'`
(scripts/lib/sync.sh L679). An empty `model` produces no `model:` line in the
synced file, so the runtime falls back to its configured default. No sync logic
change required.

## Alternatives rejected
- **A: Per-target model in sync** -- manifest declares a model per agent target
  (opencode inherits default, claudecode uses anthropic). Rejected: adds
  manifest schema complexity + sync.sh branching for a benefit (tiered models)
  the user did not request now. Reversible later via a follow-up ADR if tiering
  is wanted.
- **C: Override only for opencode** -- force `model: inherit` in the opencode
  sync target while keeping anthropic for claudecode/cursor/codex/gemini.
  Rejected: same portability trap for the other targets that run on non-anthropic
  providers; only fixes the current user's runtime. The bug is generic, so the
  fix is generic.
- **Keep `model:` and configure anthropic on OpenCode** -- rejected: shifts the
  burden to every OpenCode user to provision the Anthropic provider. Violates
  portability invariant of a multi-agent rules repo.

## Consequences
- (+) All 17 subagents dispatch correctly on any provider runtime (OpenCode,
  claude-code, cursor, codex, gemini) because they inherit the local default.
- (+) Eliminates `ProviderModelNotFoundError` as a subagent-dispatch failure
  mode on non-anthropic runtimes.
- (+) Conforms to the documented schema (model optional).
- (-) Loses the deliberate tier split (planner = opus-tier, builder = sonnet-tier)
  introduced in CHANGELOG [Unreleased] L58-59. The runtime default now applies
  uniformly. If tiering is later required across providers, follow-up ADR with
  per-target model mapping (Alternative A) is the path.
- (-) Cannot verify the fix from `ultraplan` (this ADR's authoring agent),
  because `ultraplan` is read-only with `task: git-requests: deny` by design
  (AGENTS.md orchestration: ultraplan -> ultracode -> git-requests). Verification
  is the responsibility of `ultracode` or direct TUI invocation by the user.

## Verification (how we ensure it is solved)
1. `grep -c '^model:' content/subagents/*.md` returns 0 for all 17 files (no
   model field remains in source).
2. After `make sync`, `grep -l anthropic ~/.config/opencode/agents/*.md` returns
   empty (no provider-specific model in synced agents).
3. Regression bats test asserts no subagent in `content/subagents/` declares a
   hard-coded `model:` line, preventing re-introduction.
4. End-to-end (user-side): invoke `@git-requests` directly in the OpenCode TUI
   or via `ultracode` -> `git-requests` delegation. The session must start
   without `ProviderModelNotFoundError`.

## Files changed

| File | Change |
|------|--------|
| `content/subagents/*.md` (17 files, excl README) | removed `model:` frontmatter line |
| `tests/test_validate.bats` | regression test: no subagent hard-codes `model:` |
| `CHANGELOG.md` | entry under `[Unreleased] / ### Fixed` |
| `README.md` | no count change (17 subagents unchanged); no structural change |

## Approval
- Human: Accepted (explicit user instruction 2026-06-24, "B: quitar model de
  subagents" after reviewing AGENTS.md/CHANGELOG/README and the portability
  diagnosis).
