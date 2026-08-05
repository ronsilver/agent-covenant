# Token Efficiency Baselines -- Measured Savings

Two tiers: directional (best-case, single-project) vs minimal (rules-only, broadly applicable). Quote directional ONLY as directional. Quote minimal for broad claims.

## Benchmark Table

| Source | Saving | Methodology | methodology_caveat |
|--------|--------|-------------|-------------------|
| drona23/claude-token-efficient | 63% (directional) | Single-project, full discipline stack | Directional only; not independently reproduced |
| drona23/claude-token-efficient | 4-12% (minimal) | Rules-only subset (word limits, abbreviations) | Floor; applies broadly without tooling |
| drona23/claude-token-efficient | -17.4% (independent) | Third-party reproduction attempt | Negative = regression; discipline overhead exceeded savings |
| rtk-ai/rtk | 60-90% per command | CLI proxy filters command output pre-entry (4 strategies: filter/group/truncate/dedupe) | Varies by command type; [V: README, accessed 2026-06-30] |
| nadimtuhin/claude-token-optimizer | 88% (11K -> 1.3K) | Doc restructure: 4 essential files at startup, rest 0-token until asked | [unverified self-reported]; single RedwoodJS project; not independently measured |
| mksglu/context-mode | ~98% | Sandbox + FTS5/BM25 indexing, strict-compression formula pct=(1-With/Without)*100 | [unverified]; ADR-0004 corrected from ~56% to ~95.4% -- verify formulas, NEVER trust dashboards |
| Vercel case study (agent-skills-context-engineering) | 37% fewer tokens | -80% tool count reduction; fewer tool definitions in context | Academic-cited; tool count itself costs tokens |
| Medium article #155 | "up to 90%" | MAX across 10 repos, not typical | [unverified blog-only]; generic author; surfaced 3 blind spots but 30% miss rate |

## Break-Even Condition

Discipline pays off when: tokens_saved > tokens_overhead_discipline.
- Minimal rules (4-12%): near-zero overhead -> almost always net positive.
- Full stack (63% directional): non-trivial overhead -> measure per-project.
- Tooling (rtk 60-90%): <10ms overhead -> net positive for high-frequency commands.

## Cross-Cutting: Tool Count Costs Tokens

Token Savior v3.0 cut 94 -> 61 tools. Vercel -80% tools -> +37% tokens freed. Fewer tool definitions in context = more budget for actual task. Cross-reference: tool-usage skill.

## Quality Mandate

Every saving figure above MUST preserve correctness. Compression that degrades quality is a failure, not a win. Verify with evals (see evals/evals.json) before claiming savings in production.
