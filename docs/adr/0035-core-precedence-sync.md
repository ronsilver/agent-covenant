# ADR-0035: Core Precedence Sync — tool-usage vs token-efficiency

**Date:** 2026-08-17
**Status:** Accepted

## Context

The audit of skills and evals (plan `docs/plans/audit-skills-evals-16-aug-2026.md`, Phase 4) surfaced a contradiction in the Core precedence hierarchy between `tool-usage` and `token-efficiency`.

Two incompatible orderings exist:

1. **`... > context-management > tool-usage > token-efficiency`** — stated in 8 sources:
   - Kernel files (`content/rules/agents/`): `antigravity-global.md:6`, `claude-code-global.md:6`, `copilot-global.md:8`, `opencode-global.md:6`
   - `AGENTS.md` (repo root, Conflict line) and user-level `~/.config/opencode/AGENTS.md:3`
   - `content/skills/operating-protocol/SKILL.md:91-93` (Rule Conflict Resolution items 4-6)
   - `content/skills/token-efficiency/SKILL.md:117-121` (Precedence items 4-6, "token-efficiency applies last")

2. **`... > context-management > token-efficiency > tool-usage`** — stated in 2 sources (outlier):
   - `content/skills/governance/SKILL.md:271` (troubleshooting table, circular-dependency row)
   - `content/skills/governance/evals/evals.json` eval 3 (expected output)

The kernel (top authority per ADR-0001), operating-protocol, and token-efficiency all agree on ordering 1. Governance is the lone dissenter. Governance itself references the fixed hierarchy as its own resolution mechanism, so the mismatch is an internal inconsistency in governance, not a deliberate override.

Rationale supports ordering 1: correct execution (tool-usage) trumps token count (token-efficiency) — a compressed-but-wrong tool call is worse than a verbose correct one. This matches the existing statement in token-efficiency: "Compression always yields to correctness and safety."

## Decision

Adopt **`... > context-management > tool-usage > token-efficiency`** as the single canonical precedence, treating the two skills as **complementary rather than competing**:

- `tool-usage` is the instrument of `token-efficiency`: it tells the LLM how to use tools optimally (correct tool, minimal iterations), which reduces iterations and thereby reduces tokens and cost. It applies **first** — correct, minimal tool execution.
- `token-efficiency` applies **last** — it compresses whatever remains after correct execution, and always yields to correctness and safety.

Because they are complementary (instrument → outcome), the ordering is descriptive, not a conflict: tool-usage runs before token-efficiency in the pipeline, and token-efficiency never overrides correct execution. The kernel order `tool-usage > token-efficiency` already encodes this. Governance is the only source stating the reverse, so the sync is:

1. `content/skills/governance/SKILL.md:271` — change the troubleshooting-row hierarchy from `... > token-efficiency > tool-usage` to `... > tool-usage > token-efficiency`, and add a complementary-relationship note (tool-usage = instrument of token-efficiency; applies first to cut iterations, then token-efficiency compresses the remainder).
2. `content/skills/governance/evals/evals.json` eval 3 — change the expected-output hierarchy to the same ordering.

No changes to kernel files, AGENTS.md, operating-protocol, or token-efficiency — they already state the canonical order. Governance is the only file edited (2 edits + 1 note).

This is a Core-skill edit (governance is one of the 7 boot skills), so it follows the ADR -> human approval -> CHANGELOG chain. Manifest registration is unaffected (no new files; governance is already registered). Version bump: governance frontmatter version 2.x -> 2.(x+1) minor per ADR lifecycle.

## Alternatives Considered

1. **Sync the other 8 sources to governance (`token-efficiency > tool-usage`)**: rejected — requires editing 4 kernel files + 2 AGENTS.md + operating-protocol + token-efficiency to satisfy a 2-source outlier; contradicts the kernel authority.
2. **Leave the contradiction unresolved**: rejected — precedence determines behavior on real tool-vs-compression conflicts; inconsistency makes resolution dependent on which skill is consulted.
3. **Remove the hierarchy from governance's troubleshooting table entirely**: rejected — the row exists to resolve a documented circular-dependency edge case; the fix is to correct the ordering, not drop the guidance.
4. **Keep governance's reverse order with a coexistence note**: rejected — the user decision is that the skills are complementary (tool-usage = instrument of token-efficiency, applies first; token-efficiency compresses the remainder, applies last). This matches the kernel order, so governance must be synced to it rather than vice versa.

## Consequences

- Single canonical precedence: `operating-protocol > governance > engineering-standards > context-management > tool-usage > token-efficiency`, consistent across kernel, AGENTS.md, operating-protocol, token-efficiency, and governance.
- The complementary relationship (tool-usage = instrument of token-efficiency) is documented in governance, so future readers understand the ordering is a pipeline (tool-usage first to cut iterations, token-efficiency last to compress the remainder), not a competition.
- governance's eval 3 remains scorable with an updated expected output; no new evals required.
- CHANGELOG entry under `### Changed` (Core Governance) documenting the sync.

## Evidence

- Kernel orderings: `content/rules/agents/{antigravity,claude-code,copilot,opencode}-global.md` (Conflict lines), `AGENTS.md` root and user-level.
- operating-protocol: `content/skills/operating-protocol/SKILL.md:91-93`.
- token-efficiency: `content/skills/token-efficiency/SKILL.md:117-121`.
- Governance outlier: `content/skills/governance/SKILL.md:271` and `content/skills/governance/evals/evals.json` eval 3.
- All sources read directly (STATIC) on 2026-08-17.
