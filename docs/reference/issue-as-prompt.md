# Issue-as-Prompt Philosophy

**Treat every issue assigned to an agent as a prompt. Structure determines outcome.**

## Required Elements

Every agent-assignable issue must include:

| Element | Purpose |
|---|---|
| **Clear goal** | One sentence describing the desired outcome |
| **Context** | Relevant files, patterns, constraints the agent needs |
| **Scope boundary** | What NOT to change — prevents overreach |
| **Done criteria** | Observable test/check confirming completion |
| **Risk tier** | T0 (safe auto) through T3 (needs human) per operating-protocol |

## Optional Elements

- **Reference files**: Point to existing implementations, configs, or docs to emulate
- **Checklist**: Break into discrete verifiable steps
- **Constraints**: Explicit limitations (e.g., "no external dependencies", "must work offline")
- **Examples**: Show expected output format

## Anti-Patterns

| Instead of... | Use... |
|---|---|
| "Fix the bug in auth" | "Token expiry check uses `<` not `<=` at auth/middleware.go:42 — change operator and add test" |
| "Improve performance" | "Page load >3s. Profile hotspots in dashboard.tsx, target <1s with memoization" |
| "Add logging" | "Add structured logging (slog) at 3 entry points: login, payment, logout — include user_id, latency_ms" |
| Vague acceptance criteria | "Run `go test ./auth/...` with 100% pass rate" |

## Copilot-Specific Guidance

From GitHub's tutorials: "You should think of the issue you assign to Copilot as a prompt."

- **Prompt files are issues**: The `*.prompt.md` format is essentially a reusable, parameterized issue
- **First 1,000 chars matter most**: Copilot's context window prioritizes issue title + first 1,000 characters
- **Don't overload**: 3-5 clear requirements beat 20 vague suggestions
- **Iterate in PR comments**: Use `@copilot` in PR review comments for targeted refinements rather than new issues
- **Branch per task**: Let the agent work in isolation — avoid multi-issue branches

## Issue Template (for development agents)

```markdown
## Goal
[One sentence outcome]

## Context
- Affected files: [paths]
- Related patterns: [links to similar implementations]
- Constraints: [what NOT to change]

## Done Criteria
- [ ] [Verifiable check 1]
- [ ] [Verifiable check 2]

## Risk Tier
[T0-T3] per operating-protocol
```
