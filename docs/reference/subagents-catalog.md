# Subagents Catalog (15)

Active subagents for discrete workflows. Each subagent is a focused AI persona with specialized system prompt, deployed across OpenCode, Claude Code, Cursor, Codex, and Gemini.

For operational details, permission policies, workflow steps, and orchestration graph — see [`content/subagents/README.md`](../../content/subagents/README.md).

---

## Synced Locations

| Agent | Path |
|-------|------|
| **Windsurf** | `~/.codeium/windsurf/agents/` |
| **Windsurf JetBrains** | `~/.codeium/agents/` |
| **Claude Code** | `~/.claude/agents/` |
| **OpenCode** | `~/.config/opencode/agents/` |

---

## Propósito por subagente

### Meta / Thinking & Analysis

| Subagent | Purpose | Mode | Output |
|----------|---------|------|--------|
| **`ultrathinking`** | Deep reasoning for High-complexity, ambiguous, or irreversible decisions. Explores k=2-3 candidate approaches, stress-tests each, emits a Reasoning Dossier with Decision. For use BEFORE `ultraplan`. | read-only | Reasoning Dossier → `ultraplan` (settled design) |
| **`ultraplan`** | Converts goals into deterministic, zero-reasoning execution plans. DAG of atomic sub-tasks, binary success criteria, pre-mortem risk analysis. Implementer needs NO reasoning. | read-only | Plan (stdout) → host persists → `ultracode` |
| **`ultrareview`** | Elite code audit: security, performance, maintainability, style. Orchestrates 5 specialist subagents in parallel; emits single verdict. | read-only | Verdict + to-do list → `ultracode` |
| **`ultradebugger`** | Root-cause debugger (scientific method). Reproduces failure, isolates, hypothesizes, tests with evidence. Delivers: cause, minimum fix proposal, regression test spec. | read-only | Debug Report + to-do → `ultracode` |
| **`ultraresearch`** | External-facts specialist. Surveys and cross-verifies vendor/library/API/standard before integration decision. Emits Research Dossier (facts, no winner declared). | read-only | Research Dossier → `ultrathinking` (decide) or `ultraplan` (fact-grounding) |
| **`research`** | Investigates codebase and technical topics. Produces findings document with citations and trade-offs. Read-only. | read-only | Findings (with options) → host or `ultraplan` |

### Review Specialists (read-only)

These agents run per-domain reviews on PR diffs or code sections. Orchestrated by `ultrareview` and `code-review` in parallel.

| Subagent | Purpose | Mode | Output |
|----------|---------|------|--------|
| **`code-review`** | PR-focused reviewer. Reads diff, launches 5 specialist subagents (below) in parallel, synthesizes findings, emits structured verdict with file:line. | read-only | PR Review verdict → host (inline comments or approval) |
| **`dependency-audit-agent`** | Scans CVEs, version drift, licenses, supply-chain risks across polyglot stack (Go, Python, TS, Ruby, Java, Scala). Proposes upgrade plan. | read-only | Audit Report + upgrade plan → `ultracode` |
| **`idempotency-agent`** | Verifies idempotency design in critical write operations. Checks idempotency keys, storage backend, state machine, concurrent race handling. | read-only | Assessment + remediation spec → `ultracode` |
| **`linting-agent`** | Multi-language formatting & linting. Runs formatters, linters, type-checkers, security scanners in pre-commit order; reports violations (read-only mode). | read-only | Lint Report + manual-fix to-do list → `ultracode` |
| **`performance-profiler`** | Profiles hot paths, N+1 queries, memory leaks, GC pressure, algorithmic complexity. Delivers profile report with optimization plan & before/after targets. | read-only | Profile Report + optimization to-do → `ultracode` |
| **`security-auditor`** | SAST, OWASP Top 10, secret scanning, IAM review, input validation, AI safety audits. Emits findings and remediation plan. | read-only | Security Audit Report + remediation → `ultracode` |

### Write Agents

Only these agents mutate files. Single mutation point per type.

| Subagent | Purpose | Mode | Constraint |
|----------|---------|------|------------|
| **`ultracode`** | Implementation agent. Takes plan from `ultraplan`, to-do from `ultrareview`, or debug report from `ultradebugger`. Executes task by task, runs tests, delegates git to `git-requests`. Only agent that mutates project source code. | build | Cannot call `ultracode` or `git-requests` via `task`; must call `git-requests` directly for staging/commit/push |
| **`test-writer`** | Writes unit, integration, and E2E tests. Explicit write exception for test files ONLY; does not modify production source code. | build | Cannot mutate non-test files; cannot call `ultracode` or `git-requests` via `task` |
| **`git-requests`** | Git workflow: create branch, stage changes, split logical commits (conventional format), push, open PR. Only agent that mutates git history. | full | Cannot force-push or hard-reset without confirmation; cannot call `ultracode` or `test-writer` via `task` |

---

## Orchestration Flow

```
user/orchestrator -> ultrathinking (if High-complexity/irreversible decision)
                         |
                         v
              ultraplan (deterministic plan)
                         |
          +----+----+----+
          |             |
          v             v
      ultrareview    research (if background needed)
        |
        v (delegates to 5 specialists in parallel)
    dependency-audit-agent
    idempotency-agent
    linting-agent
    performance-profiler
    security-auditor
        |
        v (collates findings)
    to-do list + verdict
        |
        v
    ultracode (implements)
        |
        v
    git-requests (branch, commits, push, PR)
        |
        v
    (if root-cause needed mid-implementation)
    ultradebugger -> debug report -> back to ultracode
```

**Key principles:**

- Only `ultracode` mutates project source code.
- Only `git-requests` mutates git history.
- `test-writer` is the explicit write exception for test files.
- All read-only agents feed their findings/plans into this pipeline; they never fix directly.
- Parallelization: `ultrareview` and `code-review` launch their 5 specialists in parallel (no ordering); other transitions are sequential.

---

## How to Use

1. **In your editor** (Claude Code, OpenCode, Cursor, Codex, Gemini): invoke a subagent via `task` when its purpose matches your need.
2. **Composition**: subagents reference each other via `task` for orchestration (e.g., `ultrareview` launches 5 specialists).
3. **Handoff**: each agent hands off its output to the next in the pipeline or to the host for human decision.
4. **Sync**: deployed via `./scripts/sync.sh` per agent target.

---

## Adding a New Subagent

1. Create new `<name>.md` in `content/subagents/` with YAML frontmatter (`name`, `description`, `permissionMode`, `mode`, `targets`, `permission` block).
2. Add entry to `manifest.yaml` under `subagents.files`.
3. Run `make sync` to deploy to all targets.
4. Document sécções obligatorias: "Session start — load boot skills", "Scope restriction", "Skill-router fallback", "Clarify-first", "Anti-patterns" (see [`content/subagents/README.md`](../../content/subagents/README.md) for full list and examples).

See [content/subagents/_TEMPLATE](../../content/subagents/_TEMPLATE) for the frontmatter structure.

---

## Maintenance

- **Editing**: modify the `.md` file directly in `content/subagents/`.
- **Versioning**: track changes in `CHANGELOG.md` at repo root.
- **Deprecation**: mark in `content/subagents/README.md` deprecated section; remove from `manifest.yaml` if fully decommissioned.
- **Testing**: run the project's test suite after adding/modifying subagents to verify no circular dependencies or permission conflicts.

---

## Related Documentation

- **Operational detail**: [`content/subagents/README.md`](../../content/subagents/README.md) — taxonomy, permission.task delegation graph, mandatory body sections, role profiles, schema reference.
- **Historical consolidation**: ibid., "Deprecated subagents" section — lists the 38 agents (from the original 53-agent catalog) that were consolidated into skills.
- **ADR**: `docs/adr/0001-hybrid-rules-architecture.md` — design rationale for the hybrid rules + skills + subagents ecosystem.
