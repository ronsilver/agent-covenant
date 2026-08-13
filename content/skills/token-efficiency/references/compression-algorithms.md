# Compression Algorithms -- 10-Compressor Taxonomy

Source: chopratejas/headroom + https://headroom-docs.vercel.app/docs/how-compression-works (accessed 2026-08-10, V-verified) -- master catalog #11 headroom.

## Quality Mandate

Every compressor preserves: keys, signatures, types, error messages, and structurally significant tokens. Compression that corrupts search/source/code is a FAILURE, not a win.

## CRITICAL RULE: grep/code = 0% intentional

SmartCrusher passes grep output and source code at 0% compression INTENTIONALLY. Compressing these corrupts search results and source semantics. NEVER compress grep output or code with any compressor.

## 10-Compressor Taxonomy (V-verified from headroom docs, accessed 2026-08-10)

| # | Name | content_type | savings | notes |
|---|------|-------------|---------|-------|
| 1 | SmartCrusher | JSON | 70-90% | structural analysis; grep output passes at 0% INTENTIONALLY |
| 2 | CodeAwareCompressor | source code | 40-70% | OPT-IN, disabled by default (AST-aware; preserves signatures and logic) |
| 3 | SearchCompressor | search results | 80-95% | non-grep search; match grouping |
| 4 | LogCompressor | logs | 85-95% | pattern detection; preserves error lines and stack traces |
| 5 | DiffCompressor | diffs | 60-80% | hunk analysis; preserves added/removed lines |
| 6 | HTMLExtractor | HTML | 50-70% | tag analysis; preserves text content and links |
| 7 | TabularCompressor | tabular data | 60-90% | row/column structure preserved |
| 8 | ConfigCompressor | config files | 40-70% | key/value structure preserved |
| 9 | TextCrusher | prose/text | 30-60% | NLP summarization; preserves key sentences and facts |
| 10 | Kompress | ML fallback | varies | fallback for unclassified content |

Pipeline: CacheAligner (detector-only, OFF by default; guards dynamic-prefix drift) -> ContentRouter (routes content_type to the best compressor) -> CCR (reversible compression, originals cached for rollback).

## Decision Tree

```

Is content grep output?
YES -> pass at 0% (DO NOT COMPRESS — corrupts search semantics)
Is content source code?
YES -> CodeAwareCompressor (opt-in) OR pass at 0% when not enabled
NO -> match content_type to compressor above (via ContentRouter)
-> apply compressor
-> verify preserved tokens intact (keys, errors, types)
-> if any preserved token missing -> rollback, use verbatim (CCR cache holds the original)

```

## Total Savings (headroom aggregate)

66.1% total across all compressors in headroom benchmarks. Your mileage varies by content mix.

## Output Shaping (HEADROOM_OUTPUT_SHAPER — master catalog #11 headroom)

Verbosity steering: append a terse directive such as "be terse, don't restate context" to the END of the system prompt (cache-safe: the stable prefix before it stays untouched).

Effort routing: dial `reasoning_effort` (OpenAI) or `thinking.budget_tokens` (Anthropic) DOWN on resumption turns after tool results; keep FULL effort on new questions and error recovery.

Self-calibration: `headroom learn --verbosity` records per-task verbosity preferences for future sessions.
