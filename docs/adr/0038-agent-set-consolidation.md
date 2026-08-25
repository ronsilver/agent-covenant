# ADR-0038: Agent-Set Consolidation (18 to 7)

**Date:** 2026-08-24
**Status:** Accepted

> Approval record: Accepted by repository owner via explicit session directive
> (2026-08-24) after read-only corroboration (see plan
> docs/plans/cleanup-agent-set-2026-08-24.md). Implementation delegated to ultracode.

## Context

The agent set grew to 18 supported agents, many of which (Windsurf, Cursor, GitHub
Copilot variants, Claude Desktop, Gemini CLI, local-project) are no longer actively
used. Supporting a large, partly-stale agent set spreads validation, documentation,
and skill-invocation taxonomy across many per-agent files, increasing drift and
maintenance cost.

Findings from the 2026-08-24 audit:

1. The kernels directory contains exactly 4 files (claude-code, opencode, antigravity,
   copilot-global.md); no gemini-global.md exists.
2. The validator arrays in scripts/validate-kernel-skill-coherence.sh list
   TOOL_AGENTS=(claude-code windsurf opencode) and FILE_AGENTS=(copilot cursor gemini);
   antigravity is in NO list, leaving its kernel unchecked.
3. manifest.yaml has 6 agent blocks; manifest.example.yaml has 15, and its antigravity
   block references agents/gemini-global.md (a nonexistent kernel) with Spanish header
   and comments.
4. Skill-invocation taxonomy conflates TOOL agents (native skill() tool: claude-code,
   opencode) with FILE agents (no skill tool: antigravity, codex-cli, pi, omp).
   Codex CLI, Pi, and OMP have no kernel yet; codex-global.md would be silently
   unchecked because the validator derives the agent from the filename and "codex" is
   not in FILE_AGENTS.
5. All 17 subagent bodies plus the template hardcode `skill({name:"..."})` Step-0 lists,
   which is valid for TOOL agents but broken for FILE agents (codex-cli) once subagents
   deploy to ~/.codex/agents.

## Decision

Consolidate to a 7-agent set and unify the skill-invocation taxonomy.

1. **Final agent set (7):** antigravity, claude-code, codex-app, codex-cli, omp,
   opencode, pi. Remove all others: windsurf, windsurf-jetbrains, cursor, cursor-cli,
   copilot-cli, copilot-app, copilot-vscode, copilot-intellij, claude-desktop,
   gemini-cli, local-project.
2. **manifest.example.yaml:** prune to the 7 accepted agents (not kept as a full
   reference).
3. **Kernels + validator:** extend FILE_AGENTS to (antigravity codex-cli pi omp) and
   TOOL_AGENTS to (claude-code opencode). Create three new kernels
   (codex-cli-global.md, pi-global.md, omp-global.md) modeled verbatim on
   antigravity-global.md with the 9 substitution rows from the plan. Name the Codex
   kernel codex-cli-global.md so the filename-derived agent matches the manifest key.
   Delete copilot-global.md.
4. **Skill-invocation taxonomy (TOOL vs FILE):** kernels and skill loading follow the
   settled design — claude-code and opencode use the native skill() tool; antigravity
   (via `@`), codex-cli (by file path), pi (via `read`), and omp (via `read` against
   skill://) load SKILL.md by file read.
5. **Subagent neutral phrasing (binding decision a):** subagent bodies name the 7 boot
   skills only; the loading mechanism is governed by each host kernel's <SKILLS> clause.
   Zero per-agent variants, no path coupling. Valid in all 3 deploy targets (opencode,
   claude-code, codex-cli).
6. **Core-skill mechanism neutralization:** skill-router and governance SKILL.md no
   longer prescribe `skill()` as the only load mechanism; version bumps
   skill-router 3.1 -> 3.2 and governance 2.4 -> 2.5 (Core modification rule).
7. **Docs and manifests:** prune all removed-agent references across README.md,
   AGENTS.md, CONTRIBUTING.md, content/rules/README.md, content/mcp/README.md,
   docs/reference/*, docs/canonical-paths.yaml, docs/validation/*, scripts, and tests.
   Translate all Spanish documentation to English. Delete
   docs/validation/path-validation.md and copilot-global.md. ADR-0036 per-agent truth
   table applied throughout.

## Alternatives Considered

1. Keep all 18 agents: rejected — stale entries spread drift and validation gaps.
2. Keep a full-reference manifest.example.yaml: rejected — single source of truth
   should match the active set (binding decision).
3. Name the Codex kernel codex-global.md: rejected — the validator derives the agent
   from the filename, so "codex" would fall outside FILE_AGENTS and be silently
   unchecked.
4. Per-agent Step-0 variants in subagents: rejected — multiplies files and couples to
   per-agent skill directory paths; the kernel <SKILLS> clause is the single mechanism
   authority.

## Consequences

- Only the 7 supported agents are validated, synced, and documented; removed agents are
  unsupported.
- The validator now covers antigravity (gap closed) and the three new FILE kernels.
- Subagents deploy correctly to OpenCode, Claude Code, and Codex CLI with
  mechanism-neutral Step-0 boot-skill lists.
- Core-skill loading language is mechanism-neutral across all agents.
- Removed-agent references are pruned from the working tree (git history is immutable;
  historical references in commits are accepted and excluded from the gate).

## Migration

Implemented by the cleanup plan docs/plans/cleanup-agent-set-2026-08-24.md (P1-P5),
executed by ultracode. `make sync` is HOST-executed last. Host checklist T37 handles
host-side deployed-remnant deletion (~/.copilot, ~/.github-copilot, ~/.gemini/config +
~/.gemini/settings.json) with host confirmation.

## Evidence

- Kernels dir exactly 4 files; no gemini-global.md (Glob content/rules/agents/*.md).
- Validator arrays L20/L22 (read scripts/validate-kernel-skill-coherence.sh).
- manifest.yaml 6 agent blocks; manifest.example.yaml 15 blocks (yq keys length).
- ADR 0036 + 0037 exist, no 0038 (Glob docs/adr).
- Subagent Step-0 `skill({name:"..."})` present in 18 files (grep count).
- Git HEAD a3b1363a927289909ea727d9b862ffd3c4af8813.
