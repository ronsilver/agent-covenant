# ADR 0006: Skill Metadata Schema

**Date:** 2026-04-28
**Status:** Accepted
**Branch:** feat/skills-strengthening-and-audit-2026-04
**Supersedes:** ADR 0002 (SKILL.md Frontmatter Schema)

## Context

ADR 0002 defined a minimal schema (required: `name`, `description`, `license`; optional: `metadata.*`, `allowed-tools`). After auditing 103 skills, four gaps were found:

1. No `metadata.status` — impossible to signal `deprecated`, `beta`, or `stable`
2. `allowed-tools` defined but **never used** — no tool-scoping per skill in any skill file
3. `skills:` dep field defined in validator but **never populated** — no declared cross-skill dependency graph
4. `aliases:` defined in validator `ALLOWED_PROPERTIES` but **never populated** — no alternate routing names

Additionally, `metadata.version` and `metadata.category` are present in ~60% of skills with inconsistent values (`ai` vs `ai-agents`, `1.0`/`1.1`/`2.0` without changelog).

## Decision

### Schema v2 — canonical definition

```yaml
# ── REQUIRED ──────────────────────────────────────────────────────────────────
name: <kebab-case-matching-directory-name>
description: >-
  <What the skill does and when to invoke it. Must contain "Use when".
   Min 50 chars. Max 1024 chars.>
license: MIT | Proprietary

# ── REQUIRED (metadata block) ─────────────────────────────────────────────────
metadata:
  author: Community
  version: "<semver>" # e.g. "1.0", "2.0" — bump minor on content add, major on breaking
  category: <enum> # see Category Enum below
  status: stable # stable | beta | deprecated (default: stable)

# ── OPTIONAL ──────────────────────────────────────────────────────────────────
aliases: [] # alternate names for routing (e.g. ["prompt-arch", "agent-prompts"])
allowed-tools: [] # Claude Code tool patterns (e.g. ["Bash(git *)", "Read"])
skills: [] # declared skill dependencies (e.g. ["context-management"])
applyTo: [] # glob patterns for file-based activation (e.g. ["**/*.tf", "**/*.py"])
setup: [] # pre-session init hints (e.g. ["terraform --version"]); declarative, not guaranteed
disable-model-invocation: false # true = always-load without model decision (core skills only)
```

### Required vs optional — enforcement table

| Field                      | v1 status | v2 status    | `--legacy` | `--strict`         |
| -------------------------- | --------- | ------------ | ---------- | ------------------ |
| `name`                     | required  | required     | ERROR      | ERROR              |
| `description`              | required  | required     | ERROR      | ERROR              |
| `license`                  | required  | required     | ERROR      | ERROR              |
| `metadata.author`          | optional  | **required** | WARNING    | ERROR              |
| `metadata.version`         | optional  | **required** | WARNING    | ERROR              |
| `metadata.category`        | optional  | **required** | WARNING    | ERROR              |
| `metadata.status`          | absent    | optional     | skip       | WARNING if missing |
| `aliases`                  | optional  | optional     | skip       | skip               |
| `allowed-tools`            | optional  | optional     | skip       | skip               |
| `skills`                   | optional  | optional     | skip       | skip               |
| `disable-model-invocation` | optional  | optional     | skip       | skip               |
| `applyTo`                  | absent    | optional     | skip       | skip               |
| `setup`                    | absent    | optional     | skip       | skip               |

### Category enum (controlled vocabulary — 12 values)

Extends ADR 0005 with 2 new values (`cloud`, `meta`):

| Value            | Covers                                                                  |
| ---------------- | ----------------------------------------------------------------------- |
| `core`           | 5 always-on protocol skills                                             |
| `ai-agents`      | LLMs, agents, MCP design, RAG, evaluation, memory, prompting, BDI       |
| `cloud`          | AWS services, MCP setup, finops, CDN, serverless                        |
| `infrastructure` | Docker, K8s, Helm, Ansible, Terraform, Terragrunt, IaC, GitOps          |
| `security`       | Security audit, threat hunting, OAuth/JWT, Vault, PCI, compliance       |
| `data`           | Snowflake, Postgres, Redis, Mongo, ETL, time-series, event-sourcing     |
| `backend`        | Go, Python, Node.js, Java, gRPC, messaging, APIs                        |
| `frontend`       | React, Next.js, state management, mobile SDK, design tokens, i18n, a11y |
| `payments`       | payment testing, fraud, compliance                                      |
| `quality`        | TDD, linting, refactoring, code-review, debugging, performance          |
| `process`        | git-protocol, CI/CD, docs, chaos, DR, mobile CI                         |

Values from ADR 0005 that are retired: `observability` (→ `cloud`), `devops` (→ `process`).

### License rule

| Skill type                                                                     | License                                    |
| ------------------------------------------------------------------------------ | ------------------------------------------ |
| Generic / public knowledge (infra, quality, process, generic AI)               | `MIT`                                      |
| Contains proprietary repo structure, PSP names, internals, payment vendor data | `Proprietary`                              |
| `skill-creator`                                                                | `MIT` (tooling, not proprietary knowledge) |

Expected distribution: ~70% MIT, ~30% Proprietary.

### `metadata.status` lifecycle

| Value        | Meaning                                   | Action                                                          |
| ------------ | ----------------------------------------- | --------------------------------------------------------------- |
| `stable`     | Production-ready, fully validated         | Default — omit field or set explicitly                          |
| `beta`       | New skill not yet validated in production | Add `beta` tag in manifest comment                              |
| `deprecated` | Superseded by another skill               | Add deprecation notice in SKILL.md body pointing to replacement |

### Disabled skills disposition

The 2 currently disabled skills (`context-fundamentals`, `context-optimization`) are **permanently retired**:

- Their content was merged into `context-management` and `token-efficiency` respectively
- Directory entries remain commented out in `manifest.yaml` as tombstones
- All 12 cross-references in 9 skills will be replaced in S4

## Validation tooling changes (S2.5)

1. `scripts/validate.sh` — add `--strict` flag; upgrade `metadata.*` fields from warning to error in strict mode
2. `content/skills/skill-creator/scripts/quick_validate.py` — v2: add `--strict`/`--legacy` dual mode, validate all 8 schema fields, semver format check, category enum check
3. `scripts/normalize-skill-metadata.sh` (NEW) — dry-run audit proposing field additions per skill
4. `content/skills/skill-creator/scripts/init_skill.py` — update template to emit full schema v2 frontmatter

## Migration plan

| Phase        | Session | Action                                                                |
| ------------ | ------- | --------------------------------------------------------------------- |
| Define       | S2      | This ADR + audit doc                                                  |
| Tooling      | S2.5    | Update `skill-creator` + 7 scripts                                    |
| New skills   | S3      | 4 new skills born with schema v2 (golden examples)                    |
| Strengthen   | S4      | 8 priority skills updated (includes schema v2)                        |
| Mass migrate | S5      | 103 skills updated (12 commits by cluster; `--legacy` CI gate during) |
| Enforce      | S6      | Switch default to `--strict`; PR gated on 0 errors                    |

## Consequences

- **All new skills** (created after this ADR) MUST use schema v2 in full
- **Existing skills** have until S5 to migrate; `--legacy` mode keeps CI green during transition
- `skill-creator` becomes the canonical schema source — deviations from its template are linting violations
- `validate.sh --strict` becomes the S6+ CI gate replacing current lenient check
- ADR 0002 is superseded; ADR 0005 category taxonomy is extended (not replaced)

## Tradeoffs

|                                | Before (v1)          | After (v2)                                        |
| ------------------------------ | -------------------- | ------------------------------------------------- |
| Required fields                | 3                    | 6                                                 |
| Optional fields                | 4                    | 4 + 1 new (`status`)                              |
| Category vocabulary            | 10 values (ADR 0005) | 12 values (extended)                              |
| Status tracking                | None                 | `stable`/`beta`/`deprecated`                      |
| Dep graph                      | None                 | Declared via `skills:`                            |
| CI strictness during migration | N/A                  | `--legacy` (warnings) → `--strict` (errors) at S6 |
