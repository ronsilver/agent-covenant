# Refactoring Safety Checklist

## Pre-Refactor
- [ ] All existing tests pass
- [ ] Understand current behavior (NOT assumed behavior)
- [ ] Identify specific smell (not "this looks wrong")
- [ ] Plan incremental steps (each independently testable)

## During Refactor
- [ ] ONE change at a time
- [ ] Run tests after EACH step (never batch)
- [ ] Git commit after each successful step
- [ ] Behavior preserved: same inputs -> same outputs

## Post-Refactor
- [ ] All tests pass (including new ones)
- [ ] No new dependencies introduced
- [ ] Public API unchanged (no signature changes)
- [ ] No dead code left from extraction
- [ ] Complexity metrics improved (cyclomatic <10)

## When to STOP
- Tests don't exist and can't be added easily
- Change would affect >3 public consumers
- Pre-existing code outside scope (report, NEVER touch)
- Behavior change needed (that's a rewrite, not a refactor)

## Anti-Patterns
- Refactoring while adding features (separate PRs)
- "While I'm here" changes (scope creep)
- Premature optimization (profile first)
- Refactoring without tests (adding risk)
