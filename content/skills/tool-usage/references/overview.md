# Tool Usage -- Overview

Rules for tool selection, design, orchestration, and evaluation for AI agents.
v2.1 adds structured-data tooling discipline (jq/yq/mlr/csvkit/dasel) backed by
verified anti-pattern counts from a `history.bak` audit (11,262 lines, 381
total anti-pattern occurrences across F1-F9).

## Reference Files (8)

| File | Content |
|---|---|
| [orchestration.md](orchestration.md) | Parallel/sequential/background, path/Bash constraints |
| [design-principles.md](design-principles.md) | Composite tools, namespacing, response format, Parse Don't Pattern-Match, YAML Generation Anti-patterns |
| [aci-checklist.md](aci-checklist.md) | ACI design checklist, evaluation, workflow patterns |
| [tool-selection.md](tool-selection.md) | Decision matrix for file, GitHub, shell, and structured-data operations |
| [structured-data-tools.md](structured-data-tools.md) | jq/yq/mlr/csvkit/dasel discipline, fallback chain, guard patterns, F1-F9 anti-pattern table (v2.1) |
| [batch-operations.md](batch-operations.md) | Massive reading strategies, batch edit 1 file (edits[] array), multi-file edit patterns, anti-patterns (v2.1) |
| [error-handling.md](error-handling.md) | Error message format, retry policy, fail-fast rules |
| [parallel-execution.md](parallel-execution.md) | Parallel-call safety, race conditions, batch ordering |

## Core Invariant

Tools are contracts between deterministic systems and non-deterministic agents.
Goal: maximize surface area for agent success, minimize context consumed.

## v2.1 Change Summary

- New reference: `structured-data-tools.md` (jq/yq/mlr/csvkit/dasel recipes +
  F1-F9 verified anti-patterns + mandatory fallback chain)
- New reference: `batch-operations.md` (massive reading strategies, batch edit
  1 file with edits[] array, multi-file edit patterns, B1-B4 anti-patterns)
- `tool-selection.md`: +Structured Data Operations 5-row matrix
- `design-principles.md`: +Parse Don't Pattern-Match + YAML Generation Anti-patterns
- `SKILL.md`: +6 tool-preference rows, +3 batch rows, +structured-data Activate
  When bullets, +batch Activate When bullet, +Anti-patterns -- Structured Data
  section, +Anti-patterns -- Batch Operations section, references block +2 entries
- `evals.json`: v1.0 -> v1.1, +structured_data_tool dimension (weight 0.15),
  +5 test cases (tu-005/006/007/008/009), rebalanced weights sum to 1.00
