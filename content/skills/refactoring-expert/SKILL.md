---
name: refactoring-expert
description: "Disciplined application of Fowler refactoring catalog: function/class extraction, collection encapsulation, conditional decomposition, primitive-to-object replacement, split-phase, and post-implementation simplification (DRY/SOLID, Boy Scout rule). Use when eliminating code smells, extracting functions or modules, splitting god classes, reducing cyclomatic complexity, simplifying code while preserving behavior, or cleaning up after feature implementation. Trigger: refactoring, code smell, DRY, SOLID, extract function, god class, cyclomatic complexity, Boy Scout rule. Do NOT trigger for: adding new features, debugging runtime errors, performance optimization (use performance-expert)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Refactoring Expert

**Code refactoring + simplification: Fowler catalog and DRY/SOLID.**

## Pre-Refactor Gate

1. Tests exist and pass (add characterization tests if missing)
2. Understand current behavior (NOT assumed behavior)
3. Identify specific smells with measurable criteria
4. Plan incremental steps (one refactor at a time)

## Code Smells -> Solutions

| Smell | Refactoring |
|---|---|
| Long Method (>50L) | Extract Function |
| Deep Nesting (>3) | Early Return / Guard Clause |
| Magic Numbers/Strings | Named Constants |
| Duplicated Code (>3 lines) | Extract Function / Parameterize |
| Conditional Complexity | Replace Conditional with Polymorphism |
| Primitive Obsession | Replace Primitive with Object |
| Boolean Flag Params | Split into two explicit functions |
| God Class (>300L) | Extract Class by SRP |

## Post-Implementation Simplification

After feature implementation, scan changed files for:

```
Duplication
- Identical blocks >3 lines -> extract function
- Similar logic with minor variation -> parameterize

Complexity
- Cyclomatic complexity >10 -> decompose conditions
- Unused imports/variables -> remove
- Large if/else chains -> map/strategy pattern

Naming
- Abbreviations (usr, tmp, d) -> full names
- Misleading names -> rename to intent

Efficiency
- Repeated lookups inside loop -> hoist outside
- Unnecessary allocations -> reuse
```

## Language-Specific Patterns

| Language | Patterns |
|---|---|
| Go | error wrapping over sentinel errors, named returns for defer |
| Python | dataclasses over raw dicts, context managers for resources |
| TypeScript | type guards over `any`, discriminated unions over if/else |

## Constraints

- ALWAYS same inputs -> same outputs (behavior preserving)
- ALWAYS tests pass after each step (never batch changes)
- ALWAYS stable public API (no signature changes without migration)
- ONE refactor at a time (NEVER batch unrelated changes)
- NEVER new dependencies unless strictly necessary
- NEVER premature optimization (measure first, then optimize)
- NEVER refactor pre-existing code outside the changed scope (report only)

## Overview

Refactoring improves code structure without changing observable behavior. This skill applies Fowler's refactoring catalog systematically: extract function/class, encapsulate collections, decompose conditionals, replace primitives with objects, split phases, and simplify post-implementation. Every refactoring step is gated by characterization tests to preserve behavior — one refactor at a time, never batched.

## Quick Reference

| Smell | Refactoring | Risk |
|---|---|---|
| Long method (>50L) | Extract Function | Low — mechanical extraction |
| Deep nesting (>3 levels) | Early Return / Guard Clause | Low — preserve all branches |
| Duplicated code (>3 lines) | Extract Function / Parameterize | Medium — verify all call sites |
| Primitive obsession | Replace Primitive with Object | Medium — new type adoption |
| God class (>300L) | Extract Class by SRP | High — may break consumers |
| Boolean flags in params | Split into explicit functions | Low — clearer API |
| Large conditional chains | Strategy / Polymorphism | Medium — behavioral equivalence |
| Data clumps | Parameter Object | Low — mechanical extraction |

## Workflow

1. **Gate check** — Verify tests exist and pass. If no tests, write characterization tests that capture current behavior (inputs → outputs). Never refactor untested code.
2. **Identify specific smell** — Pick one measurable code smell (method >50L, nesting >3, duplicated block >3 lines). NEVER mix concerns.
3. **Apply refactoring** — Execute one refactoring from Fowler's catalog. Run tests after every individual step. Fix any failure before proceeding.
4. **Commit atomic change** — Each refactoring is a standalone commit. Message format: `refactor: extract <method> from <class>` or `refactor: replace <pattern> with <pattern>`.
5. **Simplify post-implementation** — After feature code is merged, scan the changed files for duplication, dead imports, complex conditions, and poor naming. Apply Boy Scout rule: leave it cleaner than you found it.
6. **Report only for out-of-scope code** — If pre-existing code outside the change scope needs refactoring, file a tech-debt ticket. NEVER modify it during feature work.

## Anti-patterns

FAIL: Refactoring and adding features in a single commit (mixes behavior change with structure change).
```go
// BAD: Renaming + logic change in same commit
// Commit message: "refactor and add retry logic"
func processRecord(p Record) Result {   // renamed from handleRecord
    if p.Value > 0 {                     // new logic — mixed!
        ...
```
```go
// GOOD: One commit per refactor, separate commits for features
// Commit 1: refactor: rename handleRecord → processRecord
// Commit 2: feat: add value validation to processRecord
```

FAIL: Refactoring without tests (unknown behavior — guaranteed regression).
```
BAD: Refactoring a critical path function with no test coverage.
→ Regression detected in production, no characterization test exists.
GOOD: Write characterization test first (capture current output for given input),
then refactor, then verify test still passes.
```

FAIL: Changing public API signature without migration path.
```go
// BAD: Breaking change — forces all callers to update simultaneously
func ProcessRecord(value int64, kind string, recordID string) error
// becomes:
func ProcessRecord(request RecordRequest) error  // all callers break
```
```go
// GOOD: Keep old signature, add new one, deprecate old
func ProcessRecord(value int64, kind string, recordID string) error {
    return ProcessRecordV2(RecordRequest{Value: value, Kind: kind, RecordID: recordID})
}
```

## References

| Resource | URL | Last verified |
|---|---|---|
| Martin Fowler — Refactoring 2nd Edition | https://martinfowler.com/books/refactoring.html | 2026-05-25 |
| Refactoring Guru — Code Smells Catalog | https://refactoring.guru/refactoring/smells | 2026-05-25 |
| SourceMaking — Refactoring Patterns | https://sourcemaking.com/refactoring/ | 2026-05-25 |

- [references/catalog.md](references/catalog.md)
- [references/micro-refactorings.md](references/micro-refactorings.md)
- [references/safety-checklist.md](references/safety-checklist.md)

## Verification Checklist

- [ ] Tests exist and pass before any refactoring begins
- [ ] Only one refactoring applied per commit (no batched changes)
- [ ] Characterization tests written if no test coverage existed
- [ ] Public API unchanged (no breaking signature changes without migration path)
- [ ] Cyclomatic complexity reduced or maintained (never increased)
- [ ] No new dependencies introduced unless strictly necessary
- [ ] Pre-existing dead code outside scope only reported, not modified

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Test fails after refactoring | Behavior changed or missed edge case | Revert the refactoring step; verify characterization test captured all branches; re-apply |
| Duplicated code reappears after extraction | Parameterization missed variant differences | Compare all call sites; add parameter for the varying behavior |
| Refactoring causes cascade of broken consumers | Public API signature changed without deprecation path | Add deprecated overload; keep old signature delegating to new one |
| Refactored code is more complex than original | Wrong refactoring chosen for the smell | Revert; re-evaluate the specific smell; apply a different refactoring from Fowler's catalog |
| Extract Function introduces performance regression on hot path (edge case: function call overhead) | Inlined code performed better than function call in tight loop | Inline the extracted function back; use compiler-optimized inline or macro instead of manual extraction |
| [WARN] Known limitation: automated refactoring tools may break in the presence of dynamic features | Metaclasses, eval, or runtime code generation confuse static analysis | Add characterization tests before any automated refactoring; verify behavior equivalence post-refactoring with property-based tests |
