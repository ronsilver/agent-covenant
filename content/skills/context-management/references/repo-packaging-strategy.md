# Repo-Packaging Strategy -- When to Pack vs JIT

## Scope

Decision tree for when to pack a whole repo (or subtree) into a single context blob vs JIT loading. WHEN to pack for correctness is owned HERE. COMPRESSION of packed output is owned by `token-efficiency`.

## Decision Tree

```
Pack whole repo (or subtree) when:
  (a) Repo <50 files AND
  (b) Task is architectural overview OR impact radius unknown OR sub-agent needs self-contained blob
JIT load when:
  (a) Repo >50 files OR
  (b) Targeted edit (single file/feature) OR
  (c) Single-file investigation
```

## Per-File Inclusion Levels (3-tier)

When packing, assign each file an inclusion level (first matching pattern wins):

| Level | Content | Use for |
|---|---|---|
| Full content | complete file | files central to the task |
| Compressed | signatures only (tree-sitter) | supporting files (need structure, not body) |
| Directory-structure-only | listed, content omitted | peripheral files (need to know they exist) |

`directory-structure-only` takes precedence over `compressed` when both match.

Source: yamadashy/repomix per-file inclusion levels. [V: https://github.com/yamadashy/repomix, accessed 2026-06-30]

## Split Output (large repos)

For repos exceeding a size threshold: split into multiple numbered files, grouped by top-level directory (maintain context cohesion). NEVER split a single file/directory across outputs.

Source: repomix split output. [V]

## Secret Scan Before Packaging (REQUIRED)

ALWAYS run secret scanning before packaging. Respect `.gitignore` + `.ignore` + `.repomixignore`. NEVER package files matching secret patterns (API keys, passwords, private keys, `.env`).

Cross-ref: `security-expert` skill owns the secret-scan implementation. `token-efficiency` owns the token-budget guard (`--token-budget`).

Source: repomix Secretlint integration. [V]

## Boundary

- COMPRESSION of packed output (tree-sitter signatures, token reduction): -> `token-efficiency`.
- WHEN to pack vs JIT for correctness: owned HERE.
- SECRET SCANNING of packed output: -> `security-expert`.
- Token-budget guard: -> `token-efficiency`.
