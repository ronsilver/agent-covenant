# Engineering Standards — Overview

Core engineering rules for code quality, security, performance, scalability, observability, and compatibility.

## Reference Files

| File | Content |
|---|---|
| [quality.md](quality.md) | Code quality limits, naming, DRY/KISS/YAGNI, Boy Scout |
| [security.md](security.md) | Zero Trust, secret hygiene, PII, error handling |
| [observability.md](observability.md) | Structured logging, metrics, trace propagation |
| [rollout.md](rollout.md) | Breaking changes, schema migrations, feature flags, deps |

## Quick Reference

**Limits:** file≤300L | fn≤50L | params≤5 | nesting≤3 | complexity≤10
**Naming:** funcs=verb_noun | classes=NounProcessor | bools=is_has_can | consts=UPPER_SNAKE
**Pre-commit chain:** Format → Lint → Type → Test → Security (stop@1st fail)
**Security non-negotiables:** no secrets in output | no secrets as CLI args | no real PII in tests
