# Hooks

Deterministic shell hooks triggered by agent lifecycle events (SessionStart, PreToolUse, PostToolUse, Stop, UserPromptSubmit). Unlike rules/skills (model-interpreted), hooks are always executed by the agent harness — enforcing behavior the model might forget.

## Agents

| Agent dir | Hooks |
|---|---|
| `claude-code/` | 7 hooks: baseline-skills, require-read, word-budget, injection-scan, done-gate, memory-persist, git-guardrails |
| `opencode/` | baseline-skills (shell + ESM plugin) |

> **Note:** All `baseline-skills` hooks now target 7 boot skills with `trigger: always` frontmatter (was 4 prior to v2.6.0). See `content/rules/core/boot-manifest.yaml` for the full specification. For Claude Code, primary enforcement is `@import` in CLAUDE.md; for OpenCode, `instructions[]` in `opencode-mcp.json`. Hooks are secondary (redundant) enforcement for all agents.

## Sync

Hooks are deployed via `make sync`. Scripts are copied with `chmod 755` and settings fragments are merged into each agent's config via `jq`.

## Reference

→ Hook coverage map and design rationale: [`docs/adr/0004-hook-coverage-map.md`](../../docs/adr/0004-hook-coverage-map.md)  
→ Adding a new hook: [`AGENTS.md`](../../AGENTS.md) §Hooks  
→ Rule kernel files that reference hooks: [`docs/reference/rules-reference.md`](../../docs/reference/rules-reference.md)
