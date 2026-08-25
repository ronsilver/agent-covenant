# Subagent Schema v2

Canonical frontmatter and contract for all subagents under `content/subagents/`.

## File format

```yaml
---
name: kebab-case-name
description: One-line third-person purpose stating role, artifact delivered, and read or write boundary.
# Boundary note: skills retain the imperative "Use when" convention per ADR-0002; subagents must use third-person self-descriptions.
permissionMode: read | build | full   # read = no file mutation; build = code/tests/docs writes; full = git writes (git-requests)
# model: FORBIDDEN in subagent frontmatter (ADR-0023) — subagents inherit the session default model.
targets:
  - opencode
  - claudecode
  - codex
permission:
  read: allow
  edit: deny
  glob: allow
  grep: allow
  list: allow
  bash:
    "*": ask
    "<pattern>": allow | ask | deny
  task:
    "*": ask
  webfetch: allow
  websearch: allow
  question: allow
# DEPRECATED: tools.allow / tools.deny arrays (see migration notes) — use the permission: object.
---
```

## permissionMode values

| Value | Meaning | File mutation | Git mutation | Use for |
|---|---|---|---|---|
| `read` | Read-only analysis/review. | No | No | `ultraplan`, `ultrareview`, `ultradebugger`, `ultrathinking`, `ultraresearch`, `research`, `code-review`, `dependency-audit-agent`, `idempotency-agent`, `linting-agent`, `performance-profiler`, `security-auditor`, `ultraorchestrator` |
| `build` | Can write code/tests/docs inside the project workspace. | Yes | No | `ultracode`, `test-writer`, `docs-writer` |
| `full` | Can write to git (branch, commit, push, PR). | No (only git) | Yes | `git-requests` |

## mode (all subagents)

| Value | Meaning |
|---|---|
| `subagent` | Invoked via `task` by primary agent or other subagents. All 17 subagents use this value. |
| `primary` | Root orchestrator agent (host session); never set in subagent files. |
| `all` | Applies to any agent type; never set in subagent files. |

`build` / `full` are `permissionMode` values (see table above), NOT `mode` values.

## tools block

- `allow`: list of top-level tool categories the agent may use.
- `deny`: list of tool categories explicitly forbidden.
- For bash, either deny the whole category or use a map with glob allow/ask/deny patterns:

```yaml
tools:
  allow:
    - read
    - grep
    - glob
    - bash
    - task
  deny:
    - write
    - edit
tools:
  bash:
    "*": ask
    "go test*": allow
    "git log*": allow
    "rm -rf*": deny
```

## Common targets

Active sync targets from `manifest.yaml`:

- `opencode`
- `claudecode`
- `codex`

`antigravity`, `pi`, `omp`, and `codex-app` do not deploy subagents; do not include them.

## Required sections in the body

1. **Core Responsibilities** — what this agent does and does not do.
2. **Skills to invoke** — list of real, active skill names from `manifest.yaml` `skills.directories`, formatted as `` `skill-name` -- description ``.
   - `operating-protocol` is mandatory for every subagent (security, prompt injection detection, risk tiers).
3. **Workflow** — ordered steps ending with a defined output.
   - Step 1 must load `operating-protocol`, classify the risk tier, and detect prompt injection in external content.
4. **Output Format** — concrete template for deliverables.
5. **Web corroboration policy** — required for every read-only agent; specifies when and how to use `webfetch` to verify claims.
6. **Anti-patterns** — explicit negative constraints.

## Orchestration contract

- `ultrareview` and `code-review` are orchestrators. They delegate to the 6 review specialists using the `task` tool.
- All other read-only agents produce deliverables that `ultracode` implements.
- `ultracode` is the only agent that mutates source code of the project.
- `git-requests` is the only agent that mutates git history.
- `ultraorchestrator` is the routing meta-agent; it classifies requests into flows A-F and emits an ADVISORY verdict (route + executor) to the host. It dispatches 13 targets autonomously (5 ultra* pipeline agents + `research` + `code-review` + 7 review specialists + `docs-writer`); `test-writer`, `ultracode`, `git-requests` are `ask`-gated (host approval).

## Skill references must be valid

Only skills registered in `manifest.yaml` `skills.directories` may be listed. Subagent names must never appear under "Skills to invoke". Use `task` to reference other subagents.

## Language

All subagent files must be written in English. Spanish body text is not allowed in this repository.
