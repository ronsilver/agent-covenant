# Compression Algorithms -- 7-Compressor Taxonomy

Source: chopratejas/headroom + https://headroom-docs.vercel.app/docs/how-compression-works (accessed 2026-06-30).

## Quality Mandate

Every compressor preserves: keys, signatures, types, error messages, and structurally significant tokens. Compression that corrupts search/source/code is a FAILURE, not a win.

## CRITICAL RULE: grep/code = 0% intentional

SmartCrusher passes grep output and source code at 0% compression INTENTIONALLY. Compressing these corrupts search results and source semantics. NEVER compress grep output or code with any compressor.

## 7-Compressor Taxonomy

| # | Name | content_type | detection_signal | savings | latency | preserved | compressed |
|---|------|-------------|------------------|---------|---------|-----------|------------|
| 1 | SmartCrusher | mixed | structural analysis | 0-66% | low | keys, signatures, types, errors | filler, whitespace, comments |
| 2 | CodeAwareCompressor | source code | AST parsing | 20-40% | medium | function signatures, types, logic | docstrings, comments, blank lines |
| 3 | SearchCompressor | search results (non-grep) | match grouping | 50-70% | low | match lines, file paths, match context | duplicates, boilerplate headers |
| 4 | LogCompressor | log output | pattern detection | 60-80% | low | error lines, stack traces, timestamps | repeated lines, INFO/DEBUG noise |
| 5 | DiffCompressor | git diff | hunk analysis | 40-60% | low | added/removed lines, file names | context lines, metadata |
| 6 | HTMLCompressor | HTML/markup | tag analysis | 30-50% | low | text content, links, structure | whitespace, redundant tags |
| 7 | TextCompressor | prose/text | NLP summarization | 40-60% | medium | key sentences, entities, facts | filler, repetition, examples |

## Decision Tree

```

Is content grep output or source code?
YES -> SmartCrusher at 0% (DO NOT COMPRESS)
NO -> match content_type to compressor above
-> apply compressor
-> verify preserved tokens intact (keys, errors, types)
-> if any preserved token missing -> rollback, use verbatim

```

## Total Savings (headroom aggregate)

66.1% total across all compressors in headroom benchmarks. Your mileage varies by content mix.
