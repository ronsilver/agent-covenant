# Code Quality Rules

## Architecture
Read context + check reuse + identify impacts before designing.
Apply SOLID/CUPID. Skip: scripts, prototypes, hot paths.

## DRY / KISS / YAGNI
- DRY: abstract on 3rd repetition
- KISS: if junior >5min to understand → REFACTOR
- YAGNI: current requirements only, no speculative abstractions

## Limits — MANDATORY

`file≤300L` | `func≤50L` | `params≤5` | `nesting≤3` | `complexity≤10`

Limits are heuristics, not invariants. Exceptions:
- Generated/auto-formatted files (proto, migration, fixture)
- Hot paths where extraction requires interface indirection
- Stdlib pattern implementations

Exception requires inline comment: `# exceeds limit: <reason>`

## Naming — MANDATORY

| Type | Convention | Example |
|---|---|---|
| Functions | `verb_noun` | `parsePayload`, `validateToken` |
| Classes | `NounProcessor` | `PaymentHandler`, `UserValidator` |
| Booleans | `is_has_can` | `isRetry`, `hasPermission` |
| Constants | `UPPER_SNAKE` | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Private | Language-specific | `_internal` (Python), unexported (Go) |

## Code Smells → Actions

| Smell | Action |
|---|---|
| Function >50L | Extract to named helper |
| Nesting >3 | Early return / guard clause |
| Magic number | Extract to named const |
| File >300L | Split by responsibility (SRP) |

## Dead Code Policy

| Type | Action |
|---|---|
| Dead code YOUR changes introduced | DELETE always |
| Pre-existing dead code found incidentally | REPORT only — never delete unless asked |
| Pre-existing dead code explicitly in scope | Delete only if task scope says so |

## Boy Scout Rule — MANDATORY

Do: indentation fixes | rename unclear vars | add types | remove unused imports | extract constants.
NOT: >100L refactors | architecture changes | rewrites.

## Performance

Measure first. O(n) > O(n²). DB = bottleneck. 80/20 rule.
Anti-patterns: premature_opt | N+1 queries | `SELECT *` | O(n²) loops | missing cache_TTL | missing connection_pool.

## Scalability

Stateless services. Idempotent writes + idempotency keys for external calls. Async I/O.
Rate limits + payload caps + timeout budgets at every boundary.
Anti-patterns: shared mutable globals | sync blocking in hot paths | unbounded queues | missing backpressure.
