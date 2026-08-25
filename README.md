# Agent Covenant

Centralized development rules for AI coding agents (GitHub Copilot, Cursor, Claude Code, Codex CLI, Gemini CLI, Antigravity, OpenCode).

> **AI agents**: see [`AGENTS.md`](AGENTS.md) for project-specific instructions (where to create content, validation commands, schema formats).

## Table of Contents
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Requirements](#requirements)
- [Content Organization](#content-organization)
- [Docs](#docs)
- [Supported Agents](#supported-agents)
- [Usage](#usage)
- [Hooks](#hooks)
- [MCP Servers](#mcp-servers)
- [Subagents](#subagents)
- [LSP (Code Intelligence)](#lsp-code-intelligence)
- [Scripts](#scripts)
- [Development](#development)
- [Quarterly Review](#quarterly-review)
- [License](#license)

## Architecture


**Hybrid rules architecture** — two complementary layers:

| Layer | What | When loaded | Purpose |
|-------|------|-------------|---------|
| **Kernel** (F1) | `rules/agents/*-global.md` | Always, every turn | Ultra-compressed identity + per-section skill pointers |
| **Skills** (F2) | `skills/<name>/SKILL.md` | On-demand, agent-detected | Full detail for the relevant domain |

The kernel stays under 6,000 chars. Skills provide depth without bloating the always-on context.

**Core rule skills** (6 pillars): `engineering-standards` · `operating-protocol` · `context-management` · `tool-usage` · `token-efficiency` · `governance`

## Quick Start

```bash
make check       # Full pipeline: lint → fmt-check → validate → test
make sync        # Deploy to all enabled agents
make sync-dry    # Preview without writing
make list        # List available agents
```

## Requirements

```bash
brew install yq shellcheck shfmt bats-core node uv docker
```

## Content Organization

```
agent-covenant/
├── manifest.example.yaml      # Source of truth template (copy to manifest.yaml for local config)
├── content/
│   ├── rules/                 # Agent behavior rules (kernel + core) → README
│   ├── skills/                # 71 active skills (on-demand, progressive disclosure, schema v2; evals CI-validated via `make validate-evals`) → README
│   ├── workflows/             # 10 slash-command workflows → README
│   ├── prompts/               # 1 reusable prompt → README
│   ├── subagents/             # 17 active sub-agents + README → README
│   ├── hooks/                 # Deterministic lifecycle hooks (2 agent dirs) → README
│   └── mcp/                   # MCP server configuration (12 servers) + agent config → README
├── docs/                      # Architecture documentation → below
├── scripts/                   # Sync, validate, quarterly review
├── tests/                     # Bats test suite
├── tests/benchmark/           # Benchmark harness (context vs baseline)
├── Makefile                   # lint, fmt, test, validate, sync targets
└── mcps/                      # Custom MCP server source
```

Each `content/` subdirectory has its own `README.md` with purpose, format, and links to deep-dive docs.

## Docs

| Directory | Contents |
|---|---|
| `docs/adr/` | 31 Architecture Decision Records (0001–0032; 0026 missing) |
| `docs/architecture/` | Architecture diagram |
| `docs/grafana/` | Importable skill usage dashboard (JSON) |
| `docs/plans/` | Active revision plans: [refactor-05-aug-2026.md](docs/plans/processed/refactor-05-aug-2026.md) (fintech-bias removal) |
| `docs/reference/` | Detailed catalogs: [skills](docs/reference/skills-catalog.md), [MCP](docs/reference/mcp-servers.md), [subagents](docs/reference/subagents-catalog.md), [workflows](docs/reference/workflows-catalog.md), [rules](docs/reference/rules-reference.md), [LSP](docs/reference/lsp-reference.md), [issue-as-prompt](docs/reference/issue-as-prompt.md), [subagent-strategy-mapping](docs/reference/subagent-strategy-mapping.md), [master-catalog-mapping](docs/reference/master-catalog-mapping.md) |
| `docs/SKILL_QUALITY_STANDARD.md` | 7-pillar quality standard for skills (scoring, examples, CI) |
| `docs/reports/` | Repository reports and audits |
| `docs/validation/` | Canonical paths, skill invocation matrix |

> **Template location rule:** all templates required by `content/` live under `content/skills/_TEMPLATE/` (not `docs/`). See [`AGENTS.md`](AGENTS.md) §Validation Rules → Skills.

## Supported Agents

| Agent | Status | Skills | Subagents | MCP | Hooks | Workflows | Prompts |
|-------|--------|--------|-----------|-----|-------|-----------|---------|
| **claude-desktop** | Enabled | — | — | Yes | — | — | — |
| **claude-code** | Enabled | Yes | Yes | Yes | Yes | Yes | — |
| **copilot-cli** | Enabled | Yes | — | — | — | — | — |
| **copilot-app** | Enabled | Yes | — | — | — | — | — |
| **antigravity** | Enabled | Yes | — | Yes | — | Yes | — |
| **opencode** | Enabled | Yes | Yes | Yes | Yes | — | — |

## Usage

```bash
make sync              # Sync to all enabled agents
make sync-dry          # Dry run
make sync-force        # Force redeploy (bypass cache)

# Single agent
./scripts/sync.sh --agent windsurf
./scripts/sync.sh --agent claude-code

# Extra flags
./scripts/sync.sh --backup --debug
```

```bash
make validate                      # Check manifest, files, and frontmatter
make validate-mcp-config           # MCP portability: bare binaries, no PATH env, no secrets
make validate-skill-refs           # Skill coherence check (non-blocking)
make validate-canonical-paths      # Canonical path audit (non-blocking)
make test                          # Run bats tests
```

## Hooks

Deterministic shell hooks triggered by agent lifecycle events (SessionStart, PreToolUse, PostToolUse, Stop). 2 agent dirs configured (claude-code, opencode), 7 hooks for Claude Code. Enforce behavior the model might forget.

→ Full hook catalog: [`content/hooks/README.md`](content/hooks/README.md)  
→ Coverage map: [`docs/adr/0004-hook-coverage-map.md`](docs/adr/0004-hook-coverage-map.md)

## MCP Servers

12 MCP servers configured in `content/mcp/mcp.json` — GitHub, AWS, Context7, OpenSpec, and more. Synced automatically per agent.

→ Server catalog: [`content/mcp/README.md`](content/mcp/README.md)  
→ Token configuration: [`docs/reference/mcp-servers.md`](docs/reference/mcp-servers.md)

## Subagents

17 active AI sub-agents — organized as read-only analysis + routing (7), review specialists (6), and write agents (4).

→ Full catalog: [`content/subagents/README.md`](content/subagents/README.md) · [`docs/reference/subagent-schema.md`](docs/reference/subagent-schema.md)

## LSP (Code Intelligence)

11 LSP servers mapped to supported tech stacks. OpenCode: native `auto_lsp`. Claude Code: plugin-based.

```bash
./scripts/setup-lsp.sh            # Install + verify
./scripts/setup-lsp.sh --check-only
```

→ Full mapping: [`docs/reference/lsp-reference.md`](docs/reference/lsp-reference.md)

## Scripts

| Script | Purpose |
|---|---|
| `sync.sh` | Reads manifest.yaml, deploys rules/skills/workflows/subagents/MCP/hooks to agents |
| `validate.sh` | Manifest syntax, file references, frontmatter consistency |
| `validate-skill-references.sh` | Skill cross-reference check (non-blocking) |
| `validate-canonical-paths.sh` | Canonical path audit (non-blocking) |
| `validate-skill-quality.py` | Score all skills against 7-pillar standard (CI-blocking) |
| `quarterly_review.py` | Staleness, schema v2 scan, category distribution |
| `validate-router-delegation.sh` | Router dispatch gate: REFUSAL PROTOCOL + Dispatch mandate + MCP write-root check |
| `setup-lsp.sh` | Bootstrap LSP plugins + binary verification |
| `seed-memory.sh` | Pre-seed MCP memory with core directives |
| `tests/benchmark/benchmark.py` | Deterministic context-vs-baseline harness for `opencode run` (probe, dry-run, HOME-isolation smoke, reports) |

## Development

### Code Style

| Rule | Value |
|------|-------|
| **Shell indent** | 4 spaces |
| **Shell header** | `set -euo pipefail` |
| **Formatter** | `shfmt -i 4 -ci` |
| **Linter** | `shellcheck -x` |
| **Test framework** | `bats-core` |

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(rules): add rust best practices
fix(sync): handle empty glob paths
docs(readme): update agent table
```

## Quarterly Review

```bash
python3 scripts/quarterly_review.py --stale-days 90 --output docs/review-$(date +%Y-%m).md
```

Outputs: staleness report, schema issues, category distribution, quality opportunities.

## License

MIT
