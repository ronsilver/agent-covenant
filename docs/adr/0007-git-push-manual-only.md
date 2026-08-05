# ADR 0007: Git Push Manual-Only Policy

**Date:** 2026-04-28
**Status:** Accepted
**Branch:** feat/skills-strengthening-and-audit-2026-04

## Context

AI agents (Windsurf/Cascade, Claude Code, Gemini CLI, GitHub Copilot, Antigravity) can execute shell commands autonomously. Without an explicit policy, an agent may execute `git push` as part of a multi-step workflow, bypassing:

- Human review of the changeset before it leaves the local machine
- Pre-push hook execution (e.g., secret scanning, lint gate)
- Branch protection rules review step (PR creation is separate from push)
- Auth confirmation — agents often inherit cached credentials silently

Observed risk: an agent that commits and immediately pushes removes the human checkpoint between "staged, reviewed commit" and "remote branch updated". In monorepos with CI that triggers on push, this can start pipelines without human intent.

## Decision

**All AI agents MUST NOT execute `git push` autonomously.**

### Rule

```
NEVER execute `git push` or any variant.
When a push is needed, output the command as a copy-pasteable instruction to the user.
```

### Scope

Applies to all agents configured via this repository:
- Windsurf (Cascade)
- Claude Code
- Gemini CLI
- Antigravity
- GitHub Copilot (CLI, VS Code, IntelliJ)
- Any future agent added to `manifest.yaml`

### Allowed git operations (agents may execute)

```
git add <specific-files>
git commit -m "..."
git checkout -b <branch>
git checkout <branch>
git status
git log [options]
git diff [options]
git merge <branch>
git stash [push|pop]
git branch [options]
git fetch [options]
git pull [--rebase]
git tag [options]
```

### Prohibited operations (agents MUST NOT execute)

```
git push
git push origin <branch>
git push --force
git push --force-with-lease
git push -u origin <branch>
git push --tags
git push --all
```

### Output format when push is required

When the user's intent requires a push, the agent outputs:

```
Ready to push. Run:
  git push origin <branch-name>
```

The agent MUST NOT execute this command.

## Implementation

The policy is enforced via four complementary layers:

### Layer 1: Kernel rules (agent-global files)

Each agent kernel file (`*-global.md`) contains a `<GIT>` section with:

```
NEVER execute `git push` — output the command as text for the user to run manually.
```

Files updated: `windsurf-global.md`, `claude-code-global.md`, `copilot-global.md`, `gemini-global.md`.

### Layer 2: `git-protocol` skill

The `SKILL.md` Safety Protocol section adds rule 8:

```
8. NEVER execute `git push` — print as copy-pasteable command for user to run manually.
```

### Layer 3: `operating-protocol` core rule

The Autonomy & Risk Policy section notes that `git push` is T2 (confirm) minimum and delegates to `git-protocol`.

### Layer 4: Pre-push hook awareness

Agents are aware that pre-push hooks exist and that bypassing push preserves their execution under user control.

## Rationale

| Option | Considered | Rejected reason |
|---|---|---|
| Allow push with confirm dialog | Yes | Agents may auto-confirm in non-interactive mode |
| Allow push only on non-main branches | Yes | Still bypasses review; harder to enforce |
| Prohibit push in hooks (`pre-push` block) | Yes (complementary) | Hooks are not always installed; not agent-portable |
| Manual-only policy in all kernel files | **Selected** | Simple, portable, no tooling dependency |

## Consequences

- Agents never push to remote without explicit user action
- CI pipelines are only triggered by human-initiated push
- Pre-push hooks always run under user control
- Human remains the final checkpoint before code reaches remote
- Slight UX friction: user must run one extra command after agent commits
- Policy survives agent updates (kernel files are agent-version-independent)

## Review trigger

Re-evaluate if Windsurf or Claude Code adds a native "push with confirmation" feature that satisfies the human-in-the-loop requirement.
