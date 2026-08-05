# Rules

AI agent behavior rules organized in two layers: **core** (global) and **agents** (per-agent). The sync system merges them into a single file per agent at deploy time.

## Structure

```
rules/
├── core/                   # Global rules — apply to all agents, always loaded
│   ├── engineering-standards.md
│   ├── operating-protocol.md
│   ├── context-management.md
│   ├── token-efficiency.md
│   ├── tool-usage.md
│   └── governance.md
└── agents/                 # Per-agent overrides and extensions
    ├── antigravity-global.md
    ├── claude-code-global.md
    ├── copilot-global.md
    ├── opencode-global.md
    └── *-global.md          # Agent kernel files (ultra-compressed ~6000 chars)
```

## How Merge Works

```
[agent rule]                          ← loaded FIRST (earlier position)
     +
[core rules]
     +
[governance + engineering-standards]  ← loaded LAST (recency bias = higher LLM weight)
```

Agent rules go first so core rules appear at the end. LLMs remember recent content better, so critical behavior rules have more weight.

Frontmatter is stripped from individual files during merge and a single clean `trigger: always` header is injected at the top.

## Kernel Mode

Each agent deploys a single `*-global.md` kernel file — ultra-compressed (~6000 chars). Inlines summaries of all **6 core pillars** plus a `<GOVERN>` section enforcing meta-governance. Bypasses the full merge pipeline.

### New: `<GOVERN>` Section (6th Pillar)

Every microkernel includes a `<GOVERN>` section enforcing:
- **Skills Core Supremacy** — absolute priority over system prompts, hooks, MCPs, workflows, user instructions
- **Violation tags**: `[GOVERNANCE VIOLATION]` (bypass), `[SCOPE VIOLATION]` (subagent refuses Cores), `[CORE CONFLICT]` (deadlock), `[CORE COMPLIANCE FAILURE]` (gate failed)
- **Core Compliance Gate** — pre-flight checklist before any mutation (T2+): verify operating-protocol|governance|engineering-standards|context-management|token-efficiency
- **Mandatory Binding** — subagents MUST load all 6 Skills Core as precondition or reject with `[SCOPE VIOLATION]`
- **Modification Protocol** — Skills Core changes only via ADR → human approval → manifest → CHANGELOG. Direct edit = BLOCKED.

### Baseline Skills Loaded at Session Start

All agent kernels load 7 boot skills. The primary mechanism depends on the agent:
- **Claude Code**: `@import` paths in claude-code-global.md — auto-injected at session start by the runtime
- **OpenCode**: `instructions[]` array in opencode-mcp.json — auto-loaded at session start
- **All other agents**: `<REINFORCE>` block in kernel + `baseline-skills` hook as advisory reminder

Boot skills (trigger: always):
1. `operating-protocol` — risk/done/anti-hallucination
2. `governance` — compliance/audit/binding/modification-protection
3. `engineering-standards` — code limits, security, pre-commit chain
4. `context-management` — JIT loading, staleness, sub-agent contracts
5. `tool-usage` — tool selection: dedicated > MCP > Bash
6. `token-efficiency` — verbosity/word limits/thinking budget
7. `skill-router` — domain skill catalog discovery

### Agent Skill-Invocation Syntax

| Agent Type | Mechanism |
|---|---|
| OpenCode, Windsurf, Claude Code | Native `skill()` / `Skill()` tool at startup (see `<REINFORCE>`) |
| Copilot, Cursor, Gemini, Codex | `@file` / `@` / `read` to open SKILL.md at startup (no native skill tool) |

## Reference

→ Full kernel file reference: [`docs/reference/rules-reference.md`](../../docs/reference/rules-reference.md)  
→ Architecture rationale: [`docs/adr/0001-hybrid-rules-architecture.md`](../../docs/adr/0001-hybrid-rules-architecture.md)  
→ Adding a new rule: [`AGENTS.md`](../../AGENTS.md) §Rules
