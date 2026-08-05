# PR Review Report Template

```
## PR Review: <title> (#<number>)
**Author**: @<author> | **Base**: <base> <- <head>
**CI**: PASS | FAIL | PENDING
**Files Changed**: N (+X -Y lines)

### Summary
<2-3 sentence overview>

### Strengths
- <praise specific things done well>

### Issues
- [BLOCKER] <file>:<line> — <description> (CWE-XXX)
- [MAJOR] <file>:<line> — <description>
- [LOW] <description>

### Security
CLEAN | N findings (CRITICAL/HIGH/MEDIUM)
<findings with CWE + fix>

### Verdict
APPROVE | COMMENT | REQUEST CHANGES
<one-line rationale>
```

## Speed Guidelines
- Optimal: 200-400 LOC/hour
- >500 LOC: flag for scope split
- >1000 LOC: request 2+ PRs

## Tone Rules
- Questions, not commands: "What happens if X?" not "Fix this"
- ALWAYS include at least one praise
- NEVER comment on formatting (linters handle that)
