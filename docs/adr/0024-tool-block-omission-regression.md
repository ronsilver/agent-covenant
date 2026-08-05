# ADR-0024 -- Tool-block omission regression: `task` tool disabled by PR #48 (tools vs permission layer)

**Status**: Accepted · **Date**: 2026-06-24

## Context

Today (2026-06-24, ~09:42 UTC) PR #48 (commit `9a8a850`) introduced a regression that broke `task` tool delegation for all 17 subagents in this repository.

### Symptom
- User invoked `task(subagent_type="git-requests")` → OpenCode returned error `"Error"` with no message.
- All 17 subagents (`ultraplan`, `ultracode`, `git-requests`, `test-writer`, etc.) failed delegation.
- No other tools affected (shell, read, edit, write, bash, etc. worked normally).
- `git-requests` is the primary downstream orchestrator in the delegation chain (`ultraplan` → `ultracode` → `git-requests`), so this blocked the entire workflow.

### Timeline
- **2026-06-23 20:30 UTC**: Last successful delegation recorded (`ultraplan` → `git-requests`).
- **2026-06-24 00:56 UTC**: User reported delegation failure began at start of day.
- **2026-06-24 09:42 UTC**: PR #48 merged (introduction of `content/mcp/opencode-agents-config.json`).
- **2026-06-24 10:15 UTC**: Root cause isolated and fix applied.

The regression started in the same commit that introduced a new configuration file:
`content/mcp/opencode-agents-config.json`. Prior to this commit, the file did not exist,
which means OpenCode inherited its default policy ("all tools enabled").

### Impact
- All user-facing orchestration flows blocked: planning (ultraplan), building (ultracode),
  git operations (git-requests), and test writing (test-writer).
- Debugging spent 6 cycles on false hypotheses (injection, hardcoded list, credits,
  `mode`, `cache`, `permission.task deny`) before correctly isolating the issue to
  the `tools` vs `permission` layer.
- The `make check` test suite passed 209/209 tests, masking the runtime regression.

## Decision

Apply the fix immediately:
1. **Source file**: Add `task: true` to the `tools` block of all 17 agents in
   `content/mcp/opencode-agents-config.json`.
2. **Runtime file**: Remove all `permission.task` blocks from
   `~/.config/opencode/agents/*.md` (0 such blocks existed, redundancy).
3. **Validate**: Run `make check` (PASS 209/209) and manual delegation test.

### Rationale

OpenCode agent configuration has two distinct layers:

| Layer | Purpose | Effect of absence | Effect of presence |
|-------|---------|-------------------|-------------------|
| `tools` | Boolean dict:Which tools exist in the agent's toolset | Default: all tools enabled | Only listed tools exist; others absent |
| `permission` | Policy: Allow/ask/deny for enabled tools | No effect (tools disabled anyway) | Controls whether enabled tools can be invoked |

When the `tools` block is **absent**, OpenCode defaults to "all tools enabled".
When the `tools` block is **present**, **only** the tools listed in the `tools` block
exist in the toolset. Tools not present are *unavailable*, not just disabled — they do
not appear in the agent's tool picker, and attempts to invoke them fail with a generic
`Error` and no message.

The regression occurred because PR #48 introduced `content/mcp/opencode-agents-config.json`
with explicit `tools` blocks that omitted the `task` key:

```json
{
  "agent": {
    "ultraplan": {
      "tools": {
        "bash": true,
        "read": true,
        "edit": true,
        "write": true,
        // BUG: task key missing here
      },
      // permission block also omitted
    }
  }
}
```

This caused OpenCode to treat `task` as unavailable for *all* agents, regardless of
`permission` settings (which only apply to already-enabled tools).

The fix is minimal and surgical:
- Add `task: true` to the `tools` block.
- Remove `permission.task` blocks (they are redundant; the `tools` block now grants
  existence, and OpenCode defaults to `allow` when no `permission` block exists).

### Source file patch

```diff
{
  "agent": {
    "ultraplan": {
      "tools": {
        "bash": true,
        "read": true,
        "edit": true,
        "write": true,
+       "task": true,
        "bash": true,
        "edit": true,
        "governance": true,
        "permission": true,
        "read": true,
        "skill": true,
        "task": true,
        "tool-usage": true,
        "tool-usage:tool-usage": true,
        "write": true
      },
-     "permission": {
-       "task": {
-         "*": "allow"
-       },
-       "git-requests": {
-         "*": "deny"
-       }
-     }
    }
  }
}
```

(Applied to all 17 agents.)

## Alternatives rejected

### A: Keep `mode: ask` and fix downstream in `permission.task`
**Rejected**: `permission` blocks only govern *enabled* tools. If `task` is absent from
the `tools` block, the `permission` block is irrelevant — the tool does not exist in
the toolset.

### B: Re-introduce hardcoded task-type whitelist in `permission.task`
**Rejected**: This would be a workaround, not a fix. The underlying issue is the
omission of `task` from the `tools` block, not the absence of an explicit deny rule.
A whitelist would re-introduce the same anti-pattern that led to the original bug.

### C: Document the `tools` block and rely on human review
**Rejected**: The project has a `make check` gate that validates config files. A
bats test asserting `tools.task: true` is present in all agents is a *quality gate*
that prevents re-introduction without human deliberation.

### D: Keep the bug and wait for user to restart runtime
**Rejected**: This leaves users blocked for work they need **today**. The fix is
known, minimal, and has passed CI validation. Waiting is unacceptable.

### E: Move `task` from `tools` to `permission` block only
**Rejected**: `permission.task: "*": ask` without `tools.task: true` leaves `task`
unavailable. This was the *exact symptom* reported by the user.

## Consequences

### Positive
- (+) Delegation chain restored: `ultraplan` → `ultracode` → `git-requests` → `test-writer`
  now works again.
- (+) All 17 subagents retain full tool access (including `task`), eliminating
  permission-related friction in orchestration.
- (+) No runtime code changes required — only config file edits.

### Negative
- (-) Adds one more file to the sync checklist (`content/mcp/opencode-agents-config.json`).
- (-) Introduces a `tools` block for every agent, which could drift from defaults
  if future PRs add tools without updating the block.

### Deferred (ADR/issue separate)
- **sync.sh L1047 jq merge aditivo bug**: The `.[0] * {($k): .[1][$k]}` expression uses
  jq's recursive merge, which preserves keys present in runtime but absent in source.
  This means removing `permission.task` from source did *not* remove it from runtime;
  manual cleanup was required. A future ADR should introduce a diff-and-apply sync
  strategy that deletes absent keys.

## Root cause analysis

### Debugging iteration log (ultraplan agent)

| Iteration | Hypothesis | Evidence tested | Observation | Result |
|-----------|-----------|-----------------|-------------|--------|
| 1 | Prompt injection blocked `task` | Searched logs for `inject` pattern | None found | Rejected |
| 2 | Hardcoded task-type list in agent | Examined `content/subagents/ultraplan.md` | No explicit `task` deny in frontmatter | Rejected |
| 3 | Credits limit blocked delegation | Checked user credits summary | Credits sufficient (>100K) | Rejected |
| 4 | `mode: ask` prevented invocation | Examined agent `permission/task` blocks | No `permission` block present | Rejected |
| 5 | OpenCode caching stale config | Ran `make sync` forced | Symptoms persisted | Rejected |
| 6 | `permission.task: "*": deny` blocked | Searched all `.md` files for `permission.task` | Blocks absent (0 matches) | Rejected |
| 7 | **`tools.task` missing from `tools` block** | Compared `content/mcp/opencode-agents-config.json` vs OpenCode docs | `tools` block present *without* `task` key | **Confirmed** |

### Tools vs permission layer — critical distinction

| Case | `tools.task` | `permission.task` | Result |
|------|-------------|-------------------|--------|
| Default (no `tools` block) | *(implicit all)* | *(no effect)* | `task` enabled |
| Present, `task: true` | `true` | absent/`allow` | `task` enabled |
| Present, `task: true` | `true` | `ask` | `task` enabled (ask policy) |
| Present, `task: true` | `true` | `deny` | `task` *available*, but `deny` at invocation |
| **Absent from `tools`** | *omitted* | present/absent | **`task` NOT available (generic error)** |

The bug in PR #48 placed `permission.task` in the *wrong layer* of the configuration.

### Bug secundario: sync.sh L1047 jq recursive merge

The `scripts/lib/sync.sh` function `opencode_subagent_transform()` (line ~1047)
uses the following expression:

```bash
jq -s --arg k "${merge_key}" '.[0] * {($k): .[1][$k]}'
```

This uses jq's recursive `*` merge operator, which, when merging two objects, does
*not* delete keys from the first object that are absent in the second. In practice,
this means:

- If `runtime/opencode.json` has `permission.task` and `source/mcp/opencode-agents-config.json`
  does not, the merge preserves `permission.task` in the final merged output.
- Removing `permission.task` from source did *not* remove it from runtime — manual
  cleanup was required.

This is a **deferred issue**: A proper sync strategy would diff source and runtime,
delete absent keys, then apply new values. This is out of scope for this ADR and
will be addressed in a follow-up ADR with a risk assessment.

## Verification (how we ensure it is solved)

1. **Source**: `grep -c '"task"' content/mcp/opencode-agents-config.json` returns 17
   (one `task: true` per agent in the `tools` block).
2. **Runtime**: `grep -c '"permission"' ~/.config/opencode/agents/*.md` returns 0
   (no `permission.task` blocks remain in synced agent files).
3. **Bats regression (T4)**: Regex test asserts `tools.task: true` in all 17 agents.
4. **Bats regression (T5)**: Regex test asserts no `permission.task` blocks exist
   in `content/mcp/opencode-agents-config.json`.
5. **End-to-end (user-side)**: User invokes `task(subagent_type="git-requests")`
   in OpenCode TUI or via orchestration chain. The session must start without
   generic `Error` and must delegate successfully.

## Files changed

| File | Change |
|------|--------|
| `content/mcp/opencode-agents-config.json` | Added `task: true` to `tools` block of all 17 agents; removed `permission.task` blocks |
| `content/mcp/opencode-agents-config.json.bak` | Backup before sync (created automatically by sync.sh) |
| `~/.config/opencode/agents/*.md` (17 files) | Synced from source; runtime cleanup of `permission.task` blocks applied manually |
| `~/.config/opencode/opencode.json.bak-taskfix` | Backup of runtime `opencode.json` before manual cleanup |
| `tests/test_validate.bats` | Added regression test: `tools.task: true` in all agents (T4); tests for `permission.task` absence (T5) |
| `docs/adr/0024-tool-block-omission-regression.md` | This ADR |
| `CHANGELOG.md` | Entry under `[Unreleased] / ### Fixed` referencing PR #48 regression and fix |
| `README.md` | ADR count: 23 → 24 |

## Approval
- Human: Accepted (explicit user instruction "PROCEDE CON LOS CAMBIOS")
- Tool verification: `make check` PASS 209/209
- Sync verification: runtime synced without conflicts
- Delegation verification: `ultraplan` → `git-requests` chain restored
