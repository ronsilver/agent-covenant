# ADR-0019 -- git-requests build validation gate (override of informe discernimiento C)

**Status**: Accepted · **Date**: 2026-06-24

## Context
The research report `plans/estrategias_subagentes.md` (lines 866-870,
discernimiento C) explicitly excludes `git-requests` from reasoning-based
improvements: deterministic by design, "menos LLM es mejor aqui".

The `git-requests.md` "Known blind spots" section already flags the real gap:
"Puede crear commits sin verificar que el codigo compila; siempre corre
`go build`/`tsc` antes de commitear." This blind-spot note exists but is NOT
enforced as a workflow step. The fix is deterministic, not generative: insert
a build validation gate before `git commit`.

## Decision
Add a build validation gate as Workflow step 5b (between stage and commit):
1. Detect the project language(s) from manifest files.
2. Run the matching build/compile check in read-only mode:
   - Go: `go build ./...`
   - TypeScript/JS: `tsc --noEmit` (or `npm run build --if-present`)
   - Python: `python -m compileall .` (syntax check; no type check)
   - Other languages: skip (no universal build command)
3. If the build fails: STOP, do not commit, report the failure to the caller.
   Never commit code that does not compile.

## Alternatives rejected
- Add generative reasoning to "judge" commit quality: EXPLICITLY REJECTED per
  informe C. Would introduce non-determinism into a deterministic agent.
- Run full test suite before commit: out of scope for git-requests (that is
  ultracode's verification step). Build check is the minimum gate.
- Skip build check on docs-only changes: tempting, but detecting "docs-only"
  reliably is itself non-deterministic. Keep the gate universal; build is
  fast and a docs-only repo typically has no build command to run.

## Consequences
- (+) Closes the documented blind spot (commits that don't compile).
- (+) Stays deterministic -- build is a binary pass/fail command.
- (+) Catches broken commits before they hit CI, saving a CI cycle.
- (-) +latency per commit (build time). Justified by avoiding broken history.
- (-) Some repos have slow builds; mitigation: build check is the project's
  own build command, not a synthetic check.

## Risk note (override disclosure)
This is an explicit override of the report's discernimiento C for
`git-requests`. The override is NARROW: it adds a deterministic build gate,
NOT generative reasoning. The agent remains deterministic; the LLM role is
still routing + structured commit messages, not judgment of code quality.

## Edit spec
See Edit below: INSERT build validation gate as step 5b in the Workflow of
`content/subagents/git-requests.md`, and update the blind-spot note to mark
it as addressed.

## Approval
- Human: Accepted (explicit user approval 2026-06-24, override requested with justification).
