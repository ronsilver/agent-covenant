# Rules Reference

Rules define **agent identity and principles** — loaded on every interaction via the kernel file.

## How Rules Work

Rules use a **hybrid architecture**: each agent loads an ultra-compressed kernel (~6000 chars max) on every turn. The kernel inlines summaries of all **6 core rule pillars** plus a `<GOVERN>` section and ends each section with a pointer to the corresponding skill for full detail.

### Loading Chain

```
Every turn  →  kernel file  (identity + compressed rules + <GOVERN> enforcement)
On-demand   →  core skills  (full rule detail, invoked when relevant)
```

## Kernel Files (one per agent)

| Agent | Kernel File | Deployed to |
|-------|-------------|-------------|
| **Claude Code** | `rules/agents/claude-code-global.md` | `~/.claude/CLAUDE.md` |
| **Antigravity** | `rules/agents/antigravity-global.md` | `~/.gemini/GEMINI.md` |
| **Codex CLI** | `rules/agents/codex-cli-global.md` | `~/.codex/AGENTS.md` |
| **Pi** | `rules/agents/pi-global.md` | `~/.pi/agent/AGENTS.md` |
| **OMP** | `rules/agents/omp-global.md` | `~/.omp/agent/AGENTS.md` |
| **OpenCode** | `rules/agents/opencode-global.md` | `~/.config/opencode/AGENTS.md` |

All kernels are `*-global.md` files; the full-merge variants were removed in ADR-0038.

## Core Rule Files (6 pillars)

Each file lives in `content/rules/core/`. Inlined into each kernel for quick reference; available as standalone skills for full detail on-demand.

| File | Skill | Covers |
|------|-------|--------|
| `core/engineering-standards.md` | `engineering-standards` | Code quality limits (file ≤300L, fn ≤50L, params ≤5, nesting ≤3), SOLID/CUPID, Zero-Trust, PII handling, secret hygiene, structured observability, pre-commit validation chain |
| `core/operating-protocol.md` | `operating-protocol` | Risk tiers T0-T4, irreversible action gates, anti-hallucination rules, scope discipline, autonomy levels, error retry limits |
| `core/context-management.md` | `context-management` | File read order, source-of-truth hierarchy (Skills Core > Code > Tests > Comments > Docs > Memory > Assumptions), sub-agent contracts, JIT context loading, stale-context invalidation |
| `core/tool-usage.md` | `tool-usage` | Tool selection priority (dedicated > MCP > Bash), ACI checklist, parallel vs sequential calls, MCP namespacing, tool response limits |
| `core/token-efficiency.md` | `token-efficiency` | Thinking budgets, ≤25w inter-tool / ≤50w done word limits, model routing, KV-cache ordering, observation masking, clarification-first protocol |
| `core/governance.md` | `governance` | Skills Core supremacy, mandatory binding (subagents must load 6 Cores), modification protocol (ADR + human approval), Core Compliance Gate for T2+ operations, violation escalation ([GOVERNANCE VIOLATION], [SCOPE VIOLATION], [CORE CONFLICT], [CORE COMPLIANCE FAILURE]) |

## Frontmatter Format

Rules use `trigger: always` to ensure they are loaded on every interaction:

```markdown
---
trigger: always
---

<MEMORY[rule-name]>
---
trigger: always
---
...rule content...
</MEMORY[rule-name]>
```

## Agent-Specific Rules

Beyond the kernel and core rules, each agent can receive rules via the `agents` filter in `manifest.yaml`:

```yaml
rules:
  files:
    - path: content/rules/my-rule.md
      agents: [antigravity, claude-code]   # Only synced to these agents
```

## Adding a New Rule

1. Create `content/rules/<category>/<name>.md` with `trigger: always` frontmatter.
2. Add it to `manifest.yaml` under `rules.files`.
3. For agent-specific rules, add `agents: [<agent>, ...]` in the manifest entry.
4. Run `make sync`.
