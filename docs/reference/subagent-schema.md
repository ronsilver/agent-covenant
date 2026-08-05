# Subagent Schema v2

Canonical frontmatter and contract for all subagents under `content/subagents/`.

## File format

```yaml
---
name: kebab-case-name
description: "One-line purpose. Use when ..."
permissionMode: read | build | full
model: provider/model-id     # optional; required when deviating from default
                              # example: anthropic/claude-sonnet-4
targets:
  - opencode
  - claudecode
  - cursor
  - codex
  - gemini
tools:
  allow:
    - read
    - grep
    - glob
    - webfetch     # optional; required for read-only agents that corroborate via web
    - task          # needed to delegate to other subagents
  deny:
    - write
    - edit
    - bash          # or a bash allow/deny map if bash is needed
---
```

## permissionMode values

| Value | Meaning | File mutation | Git mutation | Use for |
|---|---|---|---|---|
| `read` | Read-only analysis/review. | No | No | `ultraplan`, `ultrareview`, `ultradebugger`, `ultrathinking`, `ultraresearch`, `research`, `code-review`, `dependency-audit-agent`, `idempotency-agent`, `linting-agent`, `performance-profiler`, `security-auditor` |

## mode (all subagents)

| Value | Meaning |
|---|---|
| `subagent` | Invoked via `task` by primary agent or other subagents. All 15 subagents use this value. |
| `build` | Can write code/tests inside the project workspace. | Yes | No | `ultracode`, `test-writer` |
| `full` | Can write to git (branch, commit, push, PR). | No (only git) | Yes | `git-requests` |

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
- `cursor`
- `codex`
- `gemini`

`windsurf` is disabled in `manifest.yaml`; do not include it.

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

## Skill references must be valid

Only skills registered in `manifest.yaml` `skills.directories` may be listed. Subagent names must never appear under "Skills to invoke". Use `task` to reference other subagents.

## Language

All subagent files must be written in English. Spanish body text is not allowed in this repository.
