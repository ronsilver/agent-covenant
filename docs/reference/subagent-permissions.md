# Subagent Permissions Reference

Central reference for tool permissions, permission modes, and agent modes used by AI coding subagents.

## Tool Reference

| Tool | Description |
|------|-------------|
| `Default` | Wildcard fallback. Defines default behavior (`allow`, `ask`, or `deny`) for any tool not explicitly listed in the subagent's permission block. |
| `apply_patch` | Apply structured patch files (.patch or diffs) directly to source code instead of rewriting entire files. |
| `bash` | Execute arbitrary commands in the system terminal (Mac/Linux). The most security-critical tool. |
| `codesearch` | INERT in OpenCode 1.18.21 — UI/config-visible but never runtime-evaluated (zero binary hits). Kept only for UI parity. |
| `doom_loop` | Internal safety mechanism. Monitors and detects infinite loops or redundant repetitive calls to stop the agent if it gets "stuck." |
| `edit` | Directly edit and modify specific sections of text or lines within an existing file. |
| `external_directory` | Interact with, read, or write files in directories outside the configured workspace root. |
| `glob` | Find files using path matching patterns (e.g., `**/*.go`). |
| `grep` | Plain-text or regex search within project file contents (fast string search). |
| `list` | List files and directories at a given path (equivalent to `ls`). |
| `lsp` | Interact with the Language Server Protocol for autocomplete, go-to-definition, find references, and real-time syntax error analysis. |
| `plan_enter` | Formally start a high-level planning or task-structuring phase. |
| `plan_exit` | Conclude the current planning phase and transition to task execution. |
| `question` | Pause technical execution to ask the user an interactive question (in the UI or terminal), awaiting clarification. |
| `read` | Read files within the workspace. Open and view the full content of any file. |
| `skill` | Invoke or reuse pre-built, reusable code blocks or custom functions ("skills"). |
| `task` | Invoke another subagent by type (dispatched subagent runs in a fresh session; used for delegation/fan-out). Permission patterns match the target subagent name. |
| `todoread` | INERT in OpenCode 1.18.21 — UI/config-visible but never runtime-evaluated (zero binary hits). Kept only for UI parity. |
| `todowrite` | Write, check off, or add items to the internal pending task list. |
| `webfetch` | Download raw content (HTML, JSON, or text) from a specific internet URL (like curl or an HTTP GET request). |
| `websearch` | Run queries on external web search engines to gather documentation or up-to-date information from the internet. |

## Permission Modes

| Mode | Behavior |
|------|----------|
| `allow` | Direct execution. The subagent uses the tool immediately. |
| `ask` | Interactive mode. The system freezes the subagent's execution and requests explicit user approval before proceeding. |
| `deny` | Absolute block. If the subagent attempts to use the tool, the system returns an error simulating that the tool does not exist or has no privileges. |

## Agent Mode

| Mode | Behavior |
|------|----------|
| `primary` | Root orchestrator agent. Interacts directly with the user in the main interface. Can delegate complex tasks by creating subagents. Inherits global permission rules. Controls the main problem-solving flow. |
| `subagent` | Secondary specialized executor, subordinate to a `primary` agent. Permissions are restricted by default to protect the system. Does not interact directly with the user unless requesting permission via `ask` mode. Reports results back to the invoking primary agent. |
| `all` | Universal mode. Applies configuration, rules, or permissions to any agent type running in the environment. Used in global configuration files or meta-rules as a baseline security or behavior layer. Affects both `primary` and all `subagent` instances. Also enables direct GUI invocation in addition to `task`-based invocation. |

**Current usage:** All 17 subagents use `mode: subagent`. They are invoked via `task` by the primary agent or by other subagents. The main build agent operates in `primary` mode.

## Role Profiles

### Planner (`ultraplan`)
- `edit: deny`
- `bash: ask` + safe read-only commands
- `apply_patch: deny`
- `plan_enter/plan_exit/todowrite: allow`
- `question: allow`
- `mode: subagent`

### Builder (`ultracode`, `test-writer`, `docs-writer`)
- `edit: allow`
- `bash: ask` + build/test/lint commands
- `apply_patch: deny` (use `edit` instead)
- `plan_enter/plan_exit/todowrite: allow`
- `question: allow`
- `mode: subagent`

### Reviewer (`ultrareview`, `code-review`)
- `edit: deny`
- `bash: ask` + safe read-only commands
- `apply_patch: deny`
- `plan_enter/plan_exit: deny`
- `todowrite: allow`
- `question: allow`
- `mode: subagent`

### Debugger (`ultradebugger`)
- `edit: deny`
- `bash: ask` + debug/test commands
- `apply_patch: deny`
- `plan_enter/plan_exit: deny`
- `todowrite: allow`
- `question: allow`
- `mode: subagent`

### Investigator (`research`)
- `edit: deny`
- `bash: ask` + safe read-only commands + `gh search/repo/api`
- `apply_patch: deny`
- `plan_enter/plan_exit/todowrite: deny`
- `question: allow`
- `mode: subagent`

### Router (`ultraorchestrator`)
- `edit: deny` with scoped write exception `docs/plans/**`: allow
- `bash: ask` + read-only git/jq (find/cat/jq ask; universal denies)
- `task: "*": ask`; allow 13 targets (5 ultra* + `research` + `code-review` + 7 specialists + `docs-writer`); ask `ultracode`/`git-requests`/`test-writer`
- `question/webfetch/websearch/skill/lsp/plan_enter/plan_exit/external_directory/todowrite: allow`
- `doom_loop: ask`; `apply_patch: deny`
- `mode: subagent`

### Domain experts and specialists (read-only, autonomous)
- `edit: deny`
- `bash: ask` + domain-specific commands
- `apply_patch: deny`
- `plan_enter/plan_exit/todowrite: deny`
- `question: allow` (S8: can corroborate info and resolve doubts)
- `task: "*": deny` (S2: leaves; no delegation)
- `hidden: false` — `hidden: true` is FORBIDDEN for subagents (governance invariant #8, ADR-0021): all subagents must be visible in the agent picker
- `mode: subagent`

### Full (git workflow — `git-requests`)
- `edit: deny` (git-requests writes only to git, not app code)
- `bash: ask` + git/gh commands
- `apply_patch: deny`
- `plan_enter/plan_exit/todowrite: deny`
- `question: deny`
- `mode: subagent`

## Per-Agent Permission Matrix

| Agent | Role | read | edit | glob | grep | list | bash | task | webfetch | websearch | question | apply_patch | codesearch | doom_loop | external_directory | lsp | plan_enter | plan_exit | skill | todoread | todowrite | mode | hidden |
|-------|------|------|------|------|------|------|------|------|----------|-----------|----------|-------------|------------|-----------|-------------------|-----|------------|-----------|-------|----------|-----------|------|--------|
| code-review | review | allow | deny | allow | allow | allow | safe | specialists only | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | allow | allow | subagent | false |
| dependency-audit-agent | audit | allow | deny | allow | allow | allow | audit | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| idempotency-agent | domain | allow | deny | allow | allow | allow | safe | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| linting-agent | specialist | allow | deny | allow | allow | allow | lint | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| performance-profiler | specialist | allow | deny | allow | allow | allow | perf | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| research | investigation | allow | deny | allow | allow | allow | research | `"*": allow`; deny ultracode/test-writer/git-requests/docs-writer | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| security-auditor | audit | allow | deny | allow | allow | allow | audit | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| ultradebugger | debug | allow | deny | allow | allow | allow | debug | `"*": allow`; deny ultracode/test-writer/git-requests/docs-writer | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | allow | allow | subagent | false |
| ultraplan | plan | allow | deny | allow | allow | allow | safe | `"*": allow`; deny ultracode/test-writer/git-requests/docs-writer | allow | allow | allow | deny | allow | ask | deny | allow | allow | allow | allow | allow | allow | subagent | false |
| ultraresearch | investigation | allow | deny | allow | allow | allow | safe | `"*": allow`; deny ultracode/test-writer/git-requests/docs-writer | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| ultrareview | review | allow | deny | allow | allow | allow | safe | `"*": allow`; deny ultracode/test-writer/git-requests/docs-writer | allow | allow | allow | deny | allow | ask | deny | allow | deny | deny | allow | allow | allow | subagent | false |
| ultrathinking | decision | allow | deny | allow | allow | allow | safe | `"*": allow`; deny ultracode/test-writer/git-requests/docs-writer | allow | allow | allow | deny | allow | ask | deny | allow | allow | allow | allow | allow | allow | subagent | false |
| ultraorchestrator | routing | allow | deny (docs/plans/** allow) | allow | allow | allow | read-only git/jq (find/cat/jq ask) | `"*": ask`; allow ultraplan/ultrathinking/ultrareview/ultraresearch/ultradebugger/research/code-review/dependency-audit-agent/idempotency-agent/linting-agent/performance-profiler/security-auditor/docs-writer; ask ultracode/git-requests/test-writer | allow | allow | allow | deny | allow(inert) | ask | allow | allow | allow | allow | allow(inert) | allow | subagent | false |
| git-requests | git | allow | deny | allow | allow | allow | git | `"*": deny` | allow | allow | deny | deny | allow | ask | deny | allow | deny | deny | allow | deny | deny | subagent | false |
| test-writer | build | allow | allow | allow | allow | allow | build | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | allow | allow | allow | allow | allow | subagent | false |
| docs-writer | build | allow | allow | allow | allow | allow | read-only git (no build cmds) | `"*": deny` | allow | allow | allow | deny | allow | ask | deny | allow | allow | allow | allow | allow | allow | subagent | false |
| ultracode | build | allow | allow | allow | allow | allow | build | allow only git-requests/test-writer/docs-writer; deny rest | allow | allow | allow | deny | allow | ask | deny | allow | allow | allow | allow | allow | allow | subagent | false |

### Bash Allow-Lists

| Profile | `*` default | Allowed patterns |
|---------|-------------|------------------|
| safe | ask | `git status`, `git log*`, `git diff*`, `git blame*`, `grep*`, `find*`, `ls*`, `cat*`, `kubectl get*`, `kubectl logs*`, `kubectl describe*`, `kubectl top*`, `curl*` |
| audit | ask | safe + `gitleaks*`, `gosec*`, `bandit*`, `eslint-plugin-security*`, `brakeman*`, `spotbugs*`, `trufflehog*`, `trivy*`, `checkov*`, `govulncheck*`, `npm audit*`, `pnpm audit*`, `pip-audit*`, `safety*`, `bundler-audit*`, `dependency-check*`, `grype*`, `osv-scanner*` |
| debug | ask | safe + `go test*`, `pytest*`, `npm test*`, `git bisect*` |
| research | ask | safe + `gh search*`, `gh repo*`, `gh api*` |
| lint | ask | safe + `gofmt*`, `golangci-lint*`, `eslint*`, `prettier*`, `tsc*`, `ruff*`, `mypy*`, `rubocop*`, `checkstyle*`, `spotless*`, `scalafix*`, `scalafmt*`, `swiftlint*`, `swiftformat*`, `ktlint*`, `detekt*`, `tflint*`, `checkov*`, `trivy*`, `terraform fmt*`, `shellcheck*`, `shfmt*`, `sqlfluff*`, `yamllint*`, `markdownlint*` |
| perf | ask | safe + `go test* -bench*`, `pprof*`, `py-spy*`, `cProfile*`, `memory_profiler*`, `async-profiler*`, `clinic*`, `stackprof*`, `rbtrace*` |
| build | ask | safe + `go test*`, `go build*`, `go vet*`, `pytest*`, `npm test*`, `npm run build*`, `vitest*`, `jest*`, `tsc*`, `mypy*`, `terraform plan*`, `terraform validate*`, `tflint*`, `checkov*`, `playwright*` |
| git | ask | `git status`, `git diff*`, `git log*`, `git branch*`, `git show*`, `git stash*`, `git checkout*` (ask), `git switch*` (ask), `git add*`, `git commit*`, `git push*`, `gh pr create*`, `gh pr edit*`, `gh pr view*`, `gh pr checks*`, `gh release*` (ask) |

### Universal Denies

Denied for all agents:

- `rm -rf*`
- `git push --force*`, `git push -f*`
- `git reset --hard*`
- `git rebase*` (except `git-requests`: ask)
- `kubectl delete*`
- `kubectl apply*` (ask for `ultracode`, `test-writer`, `docs-writer`)
- `terraform apply*` (ask for `ultracode`, `test-writer`, `docs-writer`)

## Known divergences (JSON mirror vs frontmatter)

The OpenCode JSON mirror (`content/mcp/opencode-agents-config.json`) is a partial, hand-maintained subset. Status per ratified fix plan (`docs/plans/ultraorchestrator-pipeline-fix-2026-08-22.md`):

- **Mirror parity is being enforced, not tolerated**: the plan (S3 + validator checks d/f) requires the mirror's `permission` map (task/edit/write/question/bash + all retained keys) to deep-equal the md frontmatter. Bash `"*"` default and task allowlist divergences are fixed by lockstep updates; drift is CI-blocking.
- **C2 ask-gate becomes runtime-enforced**: after S3 adds `permission.task` to the mirror, the `ultracode`/`git-requests`/`test-writer` ask gates are enforced by tooling, not prose-only.
- **Runtime keys verified 1.18.21**: real keys = read/edit/glob/grep/list/bash/task/external_directory/todowrite/question/webfetch/websearch/lsp/doom_loop/skill/plan_enter/plan_exit/apply_patch. `codesearch`/`todoread` are inert (UI-visible only).

## Migration Notes

- Use the `permission:` object in YAML frontmatter.
- Deprecated `tools.allow`/`tools.deny` arrays should be removed.
- All subagents use `mode: subagent`. No `mode: all` or `mode: primary` in subagent files.
- Global `external_directory` permissions are inherited; explicitly deny in subagents unless required.
- See [`content/subagents/README.md`](../../content/subagents/README.md) for the agent catalog and orchestration flow.
