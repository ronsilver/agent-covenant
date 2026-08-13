# ADR-0033: Token-Efficiency Master-Catalog Refresh

**Date:** 2026-08-10
**Status:** Accepted

## Context

The master catalog (`links-maestro-2026-06-25.md`) maps the token-optimization cluster (headroom, codegraph, claude-token-efficient, prompt-master, stop-slop, humanizer, caveman, token-savior, token-optimizer, ccusage, aislop, i-have-adhd, repomix) to the existing `token-efficiency` Core skill and `llm-expert`. The current references contain stale numbers (7-compressor taxonomy vs the 10-compressor headroom set; token-savior 94 -> 61 vs v3.0 profiles; an unverified 6-engine aislop claim) and miss techniques from the catalog.

Core skills are immutable without ADR -> human approval -> manifest -> CHANGELOG. This plan's approval constitutes the human approval; this ADR is the governance record; T11 Edit 1/2 adds the CHANGELOG entries.

## Decision

Refresh `token-efficiency` references and `llm-expert` with master-catalog-verified content:

1. compression-algorithms.md: adopt the 10-compressor taxonomy (SmartCrusher, CodeAwareCompressor, SearchCompressor, LogCompressor, DiffCompressor, HTMLExtractor, TabularCompressor, ConfigCompressor, TextCrusher, Kompress) with the CacheAligner -> ContentRouter -> CCR pipeline, plus output shaping (verbosity steering, effort routing, `headroom learn --verbosity`).
2. retrieval-economics.md: adopt the re-measured codegraph benchmark (88% fewer tool calls, 53% faster, 62% fewer tokens, 44% cheaper, 0 file reads; VS Code arm 2 vs 28 calls) with the residual-context caveat.
3. ai-slop-patterns.md: adopt the README-verified aislop scoring (5 categories, failBelow example 80, `--strict` 85, inline suppression flags) and append the stop-slop banned-phrase list.
4. baselines.md: adopt token-savior v3.0 profiles, the drona23 6-rule minimal set with the chat-vs-file cost note, and caveman honest baselines (directional only).
5. observability-loop.md: adopt the 15-CLI source list, `--instances`/`--project` attribution, and the 5-hour billing-window definition.
6. optimization.md: add prompt-cache keep-warm and the PreToolUse vs PostToolUse output-reduction distinction with manifest minimization.
7. action-first-output.md: new reference with the 10-rule action-first output structure (i-have-adhd).
8. llm-expert: add the prompt token audit (9 dimensions), humanized-output quality gate, and multi-source usage monitoring.
9. Version bumps: token-efficiency 2.1 -> 2.2; llm-expert 1.1 -> 1.2.

No sensitive authentication data is persisted; this change is documentation-only.

## Alternatives Considered

1. Leave the stale numbers in place: rejected — the plan goal is master-catalog-aligned truth.
2. Create separate new skills per tool (headroom, ccusage, aislop): rejected — the domain is already covered by token-efficiency and llm-expert; new skills would duplicate boundaries.
3. Update the kernel file (content/rules/core/token-efficiency.md): rejected — the kernel carries no compressor or baseline numbers (verified STATIC 2026-08-10); the refresh targets reference depth only.

## Consequences

- token-efficiency references match the master catalog; stale figures (7-compressor, 94 -> 61, 6-engine aislop) are removed.
- Core version bump is recorded in CHANGELOG (T11) and the skills catalog (T14j).
- Future master-catalog updates to these tools must re-verify numbers against the READMEs cited in each reference.

## Evidence

- headroom compression docs: https://headroom-docs.vercel.app/docs/how-compression-works (accessed 2026-08-10).
- codegraph README benchmark (re-measured 2026-08-05, Opus 4.8).
- aislop README (5 categories; thresholds 80/85).
- token-savior v3.0 profiles; drona23/claude-token-efficient; caveman README (directional).
- ccusage README (15 CLI sources; repo moved to apps/ccusage).
- stop-slop banned-phrase list; i-have-adhd action-first structure.
```
