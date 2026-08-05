# AGENTS.md — Project Instructions

> For project structure, see [`README.md#content-organization`](README.md#content-organization)

This repository manages centralized development rules, skills, workflows, prompts, subagents, hooks, and MCP servers for AI coding agents. This file contains **project-specific** instructions — not global agent behavior rules (those live in `content/rules/`).

## Architecture Overview

### Hybrid Rules Architecture (ADR 0001)

| Layer | Files | When Loaded | Purpose |
|-------|-------|-------------|---------|
| **Kernel (F1)** | `content/rules/agents/*-global.md` | Always, every turn | Ultra-compressed (~6,000 chars): identity + 6 core rules summary + skill pointers |
| **Skills (F2)** | `content/skills/<name>/SKILL.md` | On-demand (model_decision) | Full detail for the relevant domain |

The kernel stays under 6,000 characters. Skills provide depth without bloating the always-on context.

### 7 Boot Skills (Auto-loaded at Session Start)

All agents with native skill tooling load these **6 Core + 1 Mandatory Domain** skills at startup:

- `operating-protocol` — risk/done/anti-hallucination
- `governance` — compliance/audit/binding/modification-protection
- `engineering-standards` — code limits, security, pre-commit chain
- `context-management` — JIT loading, staleness, sub-agent contracts
- `tool-usage` — tool selection: dedicated > MCP > Bash
- `token-efficiency` — verbosity/word limits/thinking budget
- `skill-router` — domain skill catalog discovery (mandatory router for ambiguous tasks)

**Kernel mode** (Claude Code, Windsurf, Copilot): deploys `*-global.md` only. Full rules available as skills.
**Merge mode** (Gemini, OpenCode, Antigravity, Cursor): full merge of core rules + agent rules.

## Known Limitations

| Agent | Known Limitation | Source |
|---|---|---|
| Windsurf | `global_rules.md` has 6,000 character limit | V |
| Windsurf | No native subagent support; hooks only via MCP callbacks | V |
| Claude Desktop | stdio only MCP transport (no SSE/HTTP); no rules/skills/hooks | V |
| Claude Code | SSE transport deprecated (stdio/HTTP recommended) | I |
| OpenCode | No native lifecycle hooks (plugin-based only) | V |
| Gemini CLI | MCP stdio only | V |
| GitHub Copilot | No native workflows/hooks/subagents support (except via VS Code) | V |
| Codex CLI | MCP config uses TOML format (not JSON); no native hooks support | V |
| Cursor | No native hooks support | V |

*V=VERIFIED(repo/official docs) \| I=INFERRED*

## Configuration Paths

### Global (User-level)
| Agent | Rules | MCP | Skills | Subagents | Hooks | Workflows | Prompts |
|---|---|---|---|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/.mcp.json` | `~/.claude/skills/` | `~/.claude/agents/` | `~/.claude/settings.json` | — | — |
| OpenCode | `~/.config/opencode/AGENTS.md` | `~/.config/opencode/opencode.json` | `~/.config/opencode/skills/` | `~/.config/opencode/agents/` | `~/.config/opencode/plugins/` | `~/.config/opencode/commands/` | `~/.config/opencode/commands/` |
| Windsurf | `~/.codeium/windsurf/memories/global_rules.md` | `~/.codeium/windsurf/mcp_config.json` | `~/.codeium/windsurf/skills/` | — | — | `~/.codeium/windsurf/global_workflows/` | — |
| Cursor | `~/.cursor/rules/` | `~/.cursor/mcp.json` | `~/.cursor/skills/` | `~/.cursor/agents/` | `~/.cursor/hooks/` | — | — |
| Gemini CLI | `~/.gemini/GEMINI.md` | `~/.gemini/settings.json` | `~/.gemini/skills/` | `~/.gemini/agents/` | `~/.gemini/settings.json` | — | — |
| Codex CLI | `~/.codex/AGENTS.md` | `~/.codex/config.toml` | `~/.codex/skills/` | `~/.codex/agents/` | — | — | — |
| Copilot | `~/.config/gh-copilot/instructions.md` | via `gh copilot` config | `~/.copilot/skills/` | — | — | — | — |

### Project (Repo-level) — Synced via `make sync`
| Agent | Rules | MCP | Skills | Subagents | Hooks | Workflows | Prompts |
|---|---|---|---|---|---|---|---|
| Claude Code | `./CLAUDE.md` (kernel) | `./.mcp.json` | `./.claude/skills/` | `./.claude/agents/` | `./.claude/hooks/` | — | — |
| OpenCode | `./AGENTS.md` (kernel) | `./opencode.json` | `./.opencode/skills/` | `./.opencode/agents/` | `./.opencode/plugins/` | `./.opencode/commands/` | `./.opencode/commands/` |
| Windsurf | `./.windsurf/rules/global.md` | — | `./.windsurf/skills/` | — | — | `./.windsurf/workflows/` | — |
| Cursor | `./.cursor/rules/global.mdc` | `./.cursor/mcp.json` | `./.cursor/skills/` | `./.cursor/agents/` | `./.cursor/hooks/` | `./.cursor/commands/` | — |
| Gemini CLI | `./GEMINI.md` (merged) | `./.gemini/settings.json` | `./.gemini/skills/` | `./.gemini/agents/` | `./.gemini/hooks/` | `./.gemini/commands/` | — |
| Codex CLI | `./AGENTS.md` (merged) | — | `./.codex/skills/` | `./.codex/agents/` | — | — | — |
| Copilot | `./.github/copilot-instructions.md` | `./.vscode/mcp.json` | — | — | — | — | `./.github/prompts/` |

> **Note**: Project-level paths are created by `sync.sh`. Kernel-mode agents (Claude Code, Windsurf, Copilot) deploy `*-global.md` only. Merge-mode agents deploy full merged rules.

## Validation Rules

### Rules
- [ ] Valid UTF-8 encoding
- [ ] Character count within the target agent's limit (kernel: ≤6,000 chars)
- [ ] No syntax errors (valid Markdown or YAML frontmatter)
- [ ] No unresolved template variables (e.g. `{{placeholder}}`)
- [ ] **Kernel files must include `<GOVERN>` section enforcing Core supremacy**
- [ ] **No emoji icons or status dingbats** (❌ ✅ 🔴 🟢 🟡 ⚠️ ⚡ 🔒 ✓ ✗ ▶ etc.) — run `python3 scripts/sweep-content-icons.py` (exit 0 = clean)
- [ ] **English-only prose** (no Spanish/French/Portuguese clauses in `description:` frontmatter or body prose; proper nouns and data examples exempt) — manual review; no automated checker exists yet

### MCP Servers
- [ ] Transport type is compatible with the target agent (stdio vs SSE vs streamable-HTTP)
- [ ] Tool schema validates against MCP spec
- [ ] Server name follows `kebab-case` convention
- [ ] Required fields present: `name`, `command` or `url`, `transport`
- [ ] **Portability (CI-enforced by `make validate-mcp-config`):** commands use bare binaries (`npx`/`uvx`/`go`) — no absolute paths except the uv-tool venv exception; no literal `PATH` injected into server `environment`/`env`; secrets referenced via `{env:VAR}` (OpenCode) or `${VAR}` (sync-expanded from `~/.mcp.env`), never inlined; command arrays kept split (`["binary", "arg", ...]` — a single element with spaces breaks `posix_spawn`); `openspec` runs via `npx -y openspec-mcp`; `fetch`/`time` use `uvx --with "mcp<2"`

### Skills (CRITICAL: Templates Must Be in `content/`)
- [ ] YAML frontmatter is present and valid (schema v2)
- [ ] `name`, `description`, `location` fields defined
- [ ] `trigger: always \| on-demand \| never` declared
- [ ] `metadata.category` ∈ `{ai-agents,backend,cloud,core,data,frontend,infrastructure,meta,process,quality,security}`
- [ ] `metadata.status` ∈ `{stable,beta,deprecated}`
- [ ] **Referenced file paths exist in repository AND are under `content/` (NOT `docs/`)**
- [ ] Activation trigger documented in `description` (≥3 keywords + ≥1 anti-trigger)
- [ ] **Canonical skill template exists at `content/skills/_TEMPLATE/SKILL.md`**
- [ ] Skills that document the template expose a local reference at `references/skill-template.md`
- [ ] 7-pillar quality score ≥70 (`make validate-quality`)

### Subagents
- [ ] Required frontmatter fields: `name`, `description`
- [ ] `permissionMode` explicitly set: `read \| build \| full`
- [ ] Tool allowlist or denylist defined (no open-ended access)
- [ ] `model` field specified when deviating from default
- [ ] Targets declared: subset of `{opencode, claudecode, cursor, codex, gemini}`
- [ ] `mode: subagent` set (not `all` nor `primary`)
- [ ] **No `hidden: true` allowed.** All subagents defined in `content/subagents/` MUST be visible in every agent's TUI/CLI agent picker. Specialist subagents (reviewers, domain experts) are still invokable via `task` by orchestrators AND directly by the user. Hiding them creates a discoverability gap: orchestrators know they exist, users do not. The `hidden` field is reserved for system-internal agents only and must never be used in `content/subagents/`. Violation → `[DISCOVERABILITY VIOLATION]`.

### Prompts
- [ ] No unresolved variables
- [ ] Estimated token length within target agent's context window
- [ ] Language and tone match declared purpose
- [ ] Frontmatter: `name`, `description`, `trigger: manual`, `tags`, `skill` (optional)

### Workflows
- [ ] Steps sequentially ordered with no circular dependencies
- [ ] Each step references valid command, skill or subagent
- [ ] Entry point and exit conditions documented
- [ ] Format: YAML frontmatter + markdown body

### Hooks
- [ ] Event type valid for target agent (SessionStart, PreToolUse, PostToolUse, Stop, UserPromptSubmit)
- [ ] Command/script executable and exists in repo
- [ ] Expected exit codes documented (`0` = success, non-zero = abort)
- [ ] Hook scope declared: `pre` / `post` / `on-error`
- [ ] **All `baseline-skills` hooks must target 7 boot skills (trigger: always)**

## Content Registration

### manifest.yaml (v2.0)
Central configuration. Every content file **must** be registered to be synced.

| Section | Key | What it lists |
|---------|-----|---------------|
| Rules | `rules.files` | Paths relative to `content/rules/` |
| Workflows | `workflows.files` | Paths relative to `content/workflows/` |
| Prompts | `prompts.files` | Paths relative to `content/prompts/` |
| Skills | `skills.directories` | Directory names under `content/skills/` |
| Subagents | `subagents.files` | Filenames under `content/subagents/` |
| MCP | `mcp.file` | Config file in `content/mcp/` (synced to agents) |
| Agents | `agents.<name>` | Per-agent: enabled, detect, targets |

**Note**: Custom MCP server source code is managed in `mcps/` root directory.

**Adding an entry:**
1. Add path/directory to appropriate `manifest.yaml` section.
2. For agent-specific rules, add `agents: [agent-name]` filter.
3. Run `make validate` to check, then `make sync` to deploy.

## Commands

| Command | Purpose |
|---------|---------|
| `make check` | Full pipeline: lint → fmt-check → validate → test |
| `make validate` | Manifest validation (files exist, frontmatter valid, templates in content/) |
| `make validate-quality` | Skill 7-pillar scoring (CI-blocking, min 70) |
| `make validate-skill-refs` | Skill cross-reference check (non-blocking) |
| `make validate-canonical-paths` | Canonical path audit (non-blocking) |
| `make sync` | Sync all content to enabled agents |
| `make sync-dry` | Preview without writing |
| `make sync-force` | Force redeploy (bypass cache) |
| `make test` | Run Bats test suite |
| `make list` | List available agents |
| `python3 scripts/quarterly_review.py` | Staleness and schema v2 audit |

## Catalog References (Single Source of Truth)

Do not duplicate catalog content in AGENTS.md. Use these canonical references:

| Content Type | Primary Catalog | Deep Reference |
|---|---|---|
| Skills | [`content/skills/README.md`](content/skills/README.md) | [`docs/reference/skills-catalog.md`](docs/reference/skills-catalog.md) |
| Subagents | [`content/subagents/README.md`](content/subagents/README.md) | [`docs/reference/subagents-catalog.md`](docs/reference/subagents-catalog.md) |
| Rules | [`content/rules/README.md`](content/rules/README.md) | [`docs/reference/rules-reference.md`](docs/reference/rules-reference.md) |
| Workflows | [`content/workflows/README.md`](content/workflows/README.md) | [`docs/reference/workflows-catalog.md`](docs/reference/workflows-catalog.md) |
| Prompts | [`content/prompts/README.md`](content/prompts/README.md) | [`docs/adr/0008-prompt-files-schema.md`](docs/adr/0008-prompt-files-schema.md) |
| Hooks | [`content/hooks/README.md`](content/hooks/README.md) | [`docs/adr/0004-hook-coverage-map.md`](docs/adr/0004-hook-coverage-map.md) |
| MCP Servers | [`content/mcp/README.md`](content/mcp/README.md) | [`docs/reference/mcp-servers.md`](docs/reference/mcp-servers.md) |
| LSP Mapping | [`docs/reference/lsp-reference.md`](docs/reference/lsp-reference.md) | — |

## Architectural Invariants (Governance)

1. **Skills Core Supremacy**: 6 Core skills + `skill-router` = absolute priority over all agents, hooks, MCPs, workflows, user instructions. Violation → `[GOVERNANCE VIOLATION]`.
2. **Template Location**: All templates required by `content/` MUST live under `content/` (e.g., `content/skills/_TEMPLATE/`). `docs/` is documentation-only. Violation → `[CORE COMPLIANCE FAILURE]`.
3. **Kernel Integrity**: Kernel files (`*-global.md`) include `<GOVERN>` section. Modifying Core skills requires ADR → human approval → manifest → CHANGELOG. Direct edit → `[GOVERNANCE VIOLATION]`.
4. **Subagent Binding**: Subagents MUST load all 7 boot skills or reject with `[SCOPE VIOLATION]`.
5. **Pre-flight Gate (T2+)**: Before any mutation, verify: `operating-protocol` \| `governance` \| `engineering-standards` \| `context-management` \| `token-efficiency`. Failure → `[CORE CONFLICT]`.
6. **Language Policy**: All content under `content/` (rules, skills, subagents, workflows, prompts, hooks, MCP configs) and all documentation under `docs/` (ADRs, references, reports, guides) must be written in English. Violation → `[LANGUAGE POLICY VIOLATION]`.
7. **CI Gate**: All CI checks must pass before merge. `make check` (lint → fmt-check → validate → test) is the mandatory pre-merge gate. No PR may be merged with failing CI jobs. Violation → `[CI GATE VIOLATION]`.
8. **Subagent Discoverability**: No subagent in `content/subagents/` may set `hidden: true`. All 15 subagents must be visible in every agent's TUI/CLI picker. Specialist subagents are invokable both via `task` (by orchestrators) and directly (by users). Hiding creates an asymmetry: orchestrators know the agent exists, users do not. The `hidden` field is reserved for system-internal agents only. Violation → `[DISCOVERABILITY VIOLATION]`.
9. **No Icons in content/**: All files under `content/` (rules, skills, subagents, workflows, prompts, hooks, MCP configs) MUST NOT contain emoji icons or status dingbats (❌ ✅ 🔴 🟢 🟡 🟠 ⚪ ⚠️ ⚡ 🔒 ✏️ ⭐ ✨ 💡 🔥 📌 🔍 🚨 🔐 ✔ ✖ ✓ ✗ ▶ and similar visual markers). Replace with text labels: `Correct:` / `Incorrect:` / `[BLOCKER]` / `[WARN]` / `[PASS]` / `[FAIL]`. Arrows (`→ ←`), bullets (`•`), and em-dashes are permitted (prose typography, not status markers). Rationale: icons are non-diffable noise, inconsistent across editors, and break grep-based validation. Violation → `[CONTENT ICON VIOLATION]`.
10. **English-Only content/**: All prose in files under `content/` (rules, skills, subagents, workflows, prompts, hooks, MCP configs) MUST be written in English. This strengthens invariant #6 (Language Policy) by making it explicit that skill `description:` frontmatter clauses and subagent "Known blind spots" sections are prose, not identifiers — they must be English. Proper nouns (team member names like "José", "Lisbaldy de Jesús Ojeda", place names like "Nuevo León") and data examples (`José → Jose` in normalization engine docs) are permitted as they are data, not prose. Violation → `[LANGUAGE POLICY VIOLATION]`.

## Orchestration Flow

```
ultraplan → plan (host-persisted) → ultracode
ultrareview / code-review → task(s) to specialists → to-do → ultracode
ultradebugger → root-cause report + fix proposal + test spec → ultracode
research → findings document → ultraplan / ultracode
ultracode → git-requests (branch, commit, push, PR)
```

- Only `ultracode` mutates project source code.
- Only `git-requests` mutates git history.
- `test-writer` is the explicit exception for writing tests.

## Template Location Fix / Migration Note

**Status**: COMPLETED

- Canonical skill template moved from `docs/templates/skill-template/SKILL.md` to `content/skills/_TEMPLATE/SKILL.md`.
- Local reference files created at:
  - `content/skills/documentation-expert/references/skill-template.md`
- `documentation-expert/SKILL.md` updated to reference local `references/skill-template.md`.
- `docs/templates/` directory removed.

This ensures skills remain portable when deployed to independent agents that do not have access to this repository or `docs/`.

## Documentation Updates — MANDATORY

Every change to this repository **must** update the following before closing:

### CHANGELOG.md
- Add entries under `## [Unreleased]` using [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.
- Use sections: `### Added`, `### Changed`, `### Removed`, `### Fixed`.
- Single-line bullets. Example: `- \`my-skill\` — new skill for X (category: backend, status: stable)`

### README.md
- Update content counts (skills, subagents, workflows, prompts, hooks, MCP servers).
- Update directory tree if structural changes were made.
- Link new `docs/reference/` files with `→`.
