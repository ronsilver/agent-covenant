# ADR 0001: Hybrid Rules Architecture

**Date:** 2026-04-23
**Status:** Accepted
**Branch:** feature/optimization-general

## Context

The previous architecture merged all core rule files (`context-management`, `tool-usage`, `token-efficiency`, `operating-protocol`, `engineering-standards`, `governance`) plus agent-specific files into a single large deployed file per agent. This caused:

- Token overhead: every session loaded ~5k+ tokens of rules regardless of relevance.
- Context bloat: agents like Windsurf and Claude Code received rules designed for other agents.
- Maintenance friction: updating a core rule required re-syncing all agents.

## Decision

Adopt a **hybrid architecture** with two layers:

### Layer 1: Kernel files (always-on, ultra-compressed)
Each agent gets a dedicated kernel file (`windsurf-global.md`, `claude-code-global.md`, `copilot-global.md`) containing a compressed summary of all core rules. These deploy standalone via `source_files` override in `manifest.yaml`, bypassing the full merge.

### Layer 2: Core rule skills (on-demand, full detail)
The 6 core rule files are also published as skills (`engineering-standards`, `operating-protocol`, `context-management`, `tool-usage`, `token-efficiency`, `governance`). Agents load them on-demand when task complexity warrants full detail.

### Sync mechanism
`sync.sh` `get_merged_source_files()` reads `source_files[]` from target config. If present, uses those files directly. If absent, falls back to standard merge (backward compatible for non-kernel agents: gemini, opencode, antigravity, etc.).

## Consequences

- **Windsurf / Claude Code / Copilot**: deploy kernel only (~5k chars vs ~15k+). Full rules available as skills.
- **Gemini / OpenCode / Antigravity / Cursor**: unchanged — continue full merge.
- **Rollback**: remove `source_files` from affected targets in `manifest.yaml` → reverts to full merge.
- **Baseline snapshot**: `content/rules/baseline/pre-hybrid/` contains copies of agent files and manifest before this change.

## Tradeoffs

| | Before | After |
|---|---|---|
| Always-on token cost | High (full merge) | Low (kernel only) |
| Full rule access | Always loaded | On-demand via skill |
| Agent specificity | Same file for all | Per-agent kernel |
| Rollback complexity | N/A | Remove source_files |

## Validation

See `docs/validation/skill-invocation-matrix.md` for empirical recall tracking (F2.8/2.9).
Gate F1.7: 48h observation window after first kernel deploy before removing fallback files.
