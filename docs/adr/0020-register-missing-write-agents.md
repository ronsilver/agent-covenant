# ADR-0020 -- Register git-requests, ultracode, test-writer as invocable subagents

**Status**: Accepted · **Date**: 2026-06-24

## Context
`make sync` merges `content/mcp/opencode-agents-config.json` into
`~/.config/opencode/opencode.json` under the `agent` key. The runtime
exposes subagents registered in that key as `subagent_type` values
invocable via the `task` tool. Discovered bug: the source file lists 14
agents (11 read-only `subagent` + 3 read-only `all`), but the repo
defines 17 subagent `.md` files. The 3 missing entries are exactly the
write-agents: `ultracode` (permissionMode: build), `test-writer`
(permissionMode: build), `git-requests` (permissionMode: full).

Effect: other agents cannot delegate to these 3 via `task(subagent_type=...)`.
The `ultraplan -> ultracode -> git-requests` orchestration documented in
AGENTS.md was broken at the last link. Direct `@git-requests` TUI dispatch
worked because OpenCode scans the `agents/` directory for that path, but
the runtime `task` tool only uses the `agent` block of `opencode.json`.

## Decision
Add the 3 missing entries to `content/mcp/opencode-agents-config.json`
with `mode: all` per explicit user decision (uniform override of the
`.md` frontmatter `mode`). The `mode: all` change for `test-writer` and
`git-requests` (originally `subagent`) allows them to be used as
primary agents, not only as delegates. `ultracode` already was `all` in
its `.md`; the decision aligns all three.

Permission consolidation follows the existing source-file convention
(mode/tools booleans + permission allow/deny map), not the granular
subagent frontmatter.

## Alternatives rejected
- Touch `~/.config/opencode/opencode.json` directly: bypasses `make sync`
  contract; changes lost on next sync. Rejected.
- Generate the `agent` block dynamically from `content/subagents/*.md` in
  `sync.sh`: larger refactor; would change how the 14 existing entries are
  generated. Out of scope for this ADR. Rejected (future ADR candidate).
- Keep `mode: subagent` for test-writer and git-requests: contradicts user
  decision. Rejected.

## Consequences
- (+) All 17 subagents invocable via `task`.
- (+) `ultraplan -> ultracode -> git-requests` orchestration restored.
- (+) `test-writer` and `git-requests` become usable as primary agents
  (mode: all) if desired.
- (-) Source file grows by ~80 lines (3 entries).
- (-) Future sync additions require manual entry in the source file; not
  auto-discovered. Mitigation: test in T9 catches drift.

## Audit

| # | Subagent `.md` | In source file before | In source file after | mode after |
|---|-----------------|-----------------------|----------------------|------------|
| 1 | ultraplan | yes | yes | all |
| 2 | ultracode | **no** | yes | **all** (was `subagent` per .md, override) |
| 3 | ultradebugger | yes | yes | all |
| 4 | ultrareview | yes | yes | all |
| 5 | research | yes | yes | subagent |
| 6 | code-review | yes | yes | subagent |
| 7 | dependency-audit-agent | yes | yes | subagent |
| 8 | idempotency-agent | yes | yes | subagent |
| 9 | linting-agent | yes | yes | subagent |
| 10 | performance-profiler | yes | yes | subagent |
| 11 | security-auditor | yes | yes | subagent |
| 12 | test-writer | **no** | yes | **all** (override from `subagent`) |
| 13 | git-requests | **no** | yes | **all** (override from `subagent`) |
| 14 | athia-agent | yes | yes | subagent |
| 16 | psp-integration-agent | yes | yes | subagent |
| 17 | prompt-engineer-agent | yes | yes | subagent |

## Approval
- Human: Accepted (explicit user instruction 2026-06-24, "procede con todos los cambios").
