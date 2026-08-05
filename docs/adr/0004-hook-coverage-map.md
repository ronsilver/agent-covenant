# ADR 0004: Claude Code Hook Coverage Map

**Date:** 2026-04-27
**Status:** Accepted

## Context

Claude Code supports deterministic hooks (`PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SessionStart`, `Notification`, `PreCompact`). These are more reliable than CLAUDE.md instructions because they execute unconditionally. We need a documented policy on what each hook covers and what's left to CLAUDE.md.

## Decision

### Active hooks (as of 2026-04-27)

| Hook event | Script | Purpose | Blocking? |
|---|---|---|---|
| `PreToolUse` (Edit/Write) | `require-read.sh` | Blocks edits to files not read in current session | Yes (exit 2) |
| `PostToolUse` (.*) | `word-budget.sh` | Warns when inter-tool text exceeds word limits | No (exit 0, stderr) |
| `UserPromptSubmit` (.*) | `injection-scan.sh` | Blocks high-confidence injection; warns on suspicious | Conditional (exit 2 / exit 0) |
| `Stop` (.*) | `done-gate.sh` | Warns when done-claim lacks evidence labels | No (exit 0, stderr) |

### Intentionally NOT hooked

| Event | Rationale |
|---|---|
| `SessionStart` | Context bootstrap belongs in CLAUDE.md (declarative); a hook would run every session unconditionally |
| `PreToolUse` Bash | Covered by `permissions.deny` / `permissions.ask` in `settings.json` (cleaner, no script needed) |
| `PreCompact` | Compaction policy is model/UX concern; no script intervention needed |
| `Notification` | Notification delivery is ambient; no agent-safety concern |

### Distribution

Hooks are distributed via `content/hooks/claude-code/` → `manifest.yaml` hooks target → `~/.claude/hooks/` (copied by `sync.sh`). The `settings.fragment.json` in the same directory is merged into `~/.claude/settings.json`.

## Consequences

- New hooks should be added to this ADR and to `settings.fragment.json`
- Windsurf and Copilot do not have a native hook mechanism; safety is enforced via rule pack content only
- `injection-scan.sh` pattern list must be reviewed when new injection vectors are published
