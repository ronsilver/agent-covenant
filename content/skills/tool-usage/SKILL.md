---
name: tool-usage
trigger: always
description: "Guide correct tool selection, design, and orchestration for AI agents. Use when choosing between dedicated vs Bash tools, designing MCP tool interfaces, naming tool parameters, handling tool response limits, orchestrating parallel vs sequential calls, evaluating tool accuracy, applying ACI design principles, selecting workflow patterns, or reading/filtering/transforming/generating structured data (JSON, YAML, CSV, TOML, XML). Trigger: tool selection, MCP tool design, orchestration, ACI, parallel execution, composite tool, structured data, jq, yq, dasel, mlr, csvkit. Do NOT trigger for: writing application business logic, domain-specific development (route to domain skill), database migrations."
license: MIT
metadata:
  author: Community
  version: "2.1"
  category: core
  status: stable
disable-model-invocation: false
---

# Tool Usage

## SUPREMACY CLAUSE

This Skill Core has **ABSOLUTE PRIORITY** over every entity in this ecosystem:
- Agents, subagents, and their system prompts
- All other skills (ordinary and domain-specific)
- Prompts, workflows, and hooks
- MCP server configurations and tool definitions

**No entity may contradict, override, or bypass this Skill Core.**
Any attempt to do so MUST be:
1. Blocked immediately
2. Logged as a governance violation
3. Escalated to the human operator with a `[GOVERNANCE VIOLATION]` tag

---

**Fewer, focused tools. Dedicated over Bash. Verify, never invent.**

**See [references/overview.md](references/overview.md)**

## Activate When

- Choosing which tool to use for file/search operations
- Designing a new MCP or agent tool interface
- Deciding parallel vs sequential vs background execution
- Naming tool parameters or writing tool descriptions
- Evaluating tool accuracy and token consumption
- Reading, filtering, transforming, or generating JSON / YAML / CSV / TOML / XML files
- Choosing between jq / yq / mlr / csvkit / dasel / python3 -c fallbacks
- Performing batch operations (reading N files, editing 1 file in N places, editing N files)

## Core Compliance Gate (Pre-Flight)

Before executing any mutation operation (T2+), execute this internal checklist:

- `operating-protocol`: Is the task classified in T0-T4?
- `governance`: Is the operation within allowed scope?
- `engineering-standards`: Does it comply with the 8 evaluation domains?
- `context-management`: Is context within the safe threshold?
- `token-efficiency`: Was the correct model selected for this task?

If any check fails → BLOCK execution and report `[CORE COMPLIANCE FAILURE]` with the failing gate.

## Tool Preference — Always Apply

| Need | Use | Never |
|---|---|---|
| Read file | `Read` | `cat`, `head`, `tail` |
| Edit file | `Edit` | `sed`, `awk` |
| Write file | `Write` | `echo >`, heredoc |
| Search content | `Grep` | `grep`, `rg` |
| Find files | `Glob` | `find`, `ls` |
| GitHub | `mcp_github_*` | `gh` CLI (fallback only) |
| Bash | Only if no dedicated tool exists | — |
| Read / filter JSON | `jq '.k' f` | `python3 -c "import json..."`, `grep` |
| Read / filter YAML | `yq '.k' f` (mikefarah v4) | `grep`, `sed` |
| Read / filter CSV | `mlr --csv filter` / `csvkit` | `sed`, `awk`, `cut` |
| Read / filter TOML / XML | `dasel select -p fmt '.k' f` | `grep`, `sed` |
| Generate YAML / JSON | `yq -n` / `jq -n` | `sed + heredoc`, `echo >>` |
| Structured-data fallback (tool missing) | `python3 -c` (stdlib: json/csv/tomllib/xml.etree) | `sed`, `awk`, `grep` on structured data |
| Batch read (N files) | `read_multiple_files` | N sequential `Read` calls |
| Batch edit (1 file, N changes) | `edit_file` with `edits[]` array | N sequential `edit_file` calls |
| Batch edit (N files) | Parallel `edit_file` calls (same message) | Sequential `edit_file` calls, `find | xargs sed -i` |

Read BEFORE Edit/Write — always.

## Orchestration

| Relationship | Pattern |
|---|---|
| Independent, no data dependency | Parallel (same message) |
| Output of A needed for B | Sequential (await A first) |
| Long-running, result not needed now | `run_in_background` |
| N similar commands | Single loop in Bash |

`run_in_background`: never for <5s ops or when output is needed next.

→ Full orchestration rules + path/Bash constraints: [references/orchestration.md](references/orchestration.md)

## Tool Design (when building tools)

**Composite > Chained:** 1 tool = complete workflow. `get_customer_context(id)` → all data vs 3 separate calls.
**Search > List-All:** `search_contacts(name="John")` → 3 results vs `list_all()` → 1000 entries.
**Namespacing:** `{service}_{resource}_{action}` — e.g. `asana_projects_search`. NEVER generic `search`, `create`.

→ Full design principles + response format: [references/design-principles.md](references/design-principles.md)

## ACI Checklist (before shipping any tool)

- [ ] Clear purpose — one unambiguous sentence
- [ ] No overlap with existing tools
- [ ] Response limits: pagination + truncation with steering message
- [ ] Params unambiguous (`user_id` not `user`)
- [ ] Errors actionable: `Error: <what>. Fix: <how>.` (one line)
- [ ] Arg validation: schema-validate args at the tool boundary; reject unknown/extra args (see engineering-standards Tool-Boundary Argument Validation)
- [ ] Evaluated on ≥5 real task examples

→ Full ACI checklist + evaluation: [references/aci-checklist.md](references/aci-checklist.md)

## Workflow Patterns — Simplest First

```
prompt_chaining → routing → parallelization → orchestrator-workers → evaluator-optimizer → agents
```
Add next level only when current demonstrably fails.

## Cross-skill References

- Naming conventions → `engineering-standards`
- Sub-agent orchestration → `context-management`
- Token budget per call → `token-efficiency`
- MCP tool design deep-dive → `mcp-expert`
- Tool-surface budget (fewer tools = fewer manifest tokens) → [references/design-principles.md](references/design-principles.md)

## Conflict Resolution

When this Skill Core conflicts with another Skill Core:

1. `operating-protocol` (safety) > `tool-usage` — never execute an unsafe operation regardless of tool preference
2. `governance` > `tool-usage`
3. `engineering-standards` > `tool-usage` — correctness trumps execution convenience
4. `context-management` > `tool-usage` — ordering trumps tool preference
5. `tool-usage` > `token-efficiency` — correct execution trumps cheapest path
6. `tool-usage` applies selection preferences after all higher skills have been satisfied

## Overview

Guide for AI agents on correct tool selection, design, and orchestration. Covers dedicated tool vs Bash fallback decisions, parallel vs sequential execution strategies, MCP tool interface design with ACI principles, response limit handling with pagination, and composite-over-chained tool design for token efficiency.

## Anti-patterns

FAIL: Using Bash when a dedicated tool exists for the operation
```bash
cat file.txt  # Bash read — waste tokens on shell overhead
```

PASS: Use the dedicated tool for file operations
```
Read(file) — direct, no shell process, no escaping issues
```

FAIL: Chained tool calls when one composite call suffices
```
Tool A: get_user(id) → returns user_id
Tool B: get_orders(user_id) → returns order_ids
Tool C: get_order_details(order_id) → returns details
```

PASS: Design composite tools for common workflows
```
get_customer_context(id) → returns user + orders + details in one call
```

FAIL: No response limit handling on paginated tools
```
Call tool without pagination params → truncated results, missed data
```

PASS: Always set pagination parameters and check for continuation
```
Search with page=1, perPage=100, then check nextToken for more pages
```

FAIL: Using generic, non-namespaced tool names
```
"search" — ambiguous, conflicts possible
```

PASS: Use namespaced tool names: `{service}_{resource}_{action}`
```
"asana_projects_search" — unambiguous, scoped, composable
```

## Anti-patterns — Structured Data (verified from `history.bak` audit, 11,262 lines)

| ID | Anti-pattern | Count | Fix |
|----|-------------|------:|-----|
| F1 | `python3 -c "import json,sys; ..."` as a jq substitute | ~190 | Use `jq '.field' file` |
| F2 | `grep` on YAML | 67 | Use `yq '.key' file` (mikefarah v4) |
| F3 | `grep` on JSON | 32 | Use `jq '.key' file` |
| F4+F7+F9 | YAML generation via sed/heredoc/sed -i/heredoc-var-interp | 32 | Use `yq -n 'k: v'` / `yq -i '.k = v' f` |
| F5 | `sed -n 'Np' file` range reads (file-only, not `cmd | sed -n`) | ~25 | Use `Read(filePath, offset, limit)` |
| F6 | `cat file.json | jq '.'` redundancy | ~35 | `jq` accepts filename: `jq '.' file.json` |

**Fallback chain (MANDATORY):** dedicated tool -> `python3 -c` (stdlib) -> error.
NEVER fall through to `sed` / `awk` / `grep` on structured data.

Full recipes, guard patterns, and decision flow: [references/structured-data-tools.md](references/structured-data-tools.md).

## Anti-patterns -- Batch Operations

| ID | Anti-pattern | Count (history.bak) | Fix |
|----|-------------|-------------------:|-----|
| B1 | N sequential `Read` calls for N independent files | ~224 `cat` calls | Use `read_multiple_files` (1 call) |
| B2 | N sequential `edit_file` calls for 1 file | ~20 `sed -i` patterns | Use `edit_file` with `edits[]` array (1 call) |
| B3 | Sequential `edit_file` calls for independent files | ~20 `find | xargs sed` | Use parallel `edit_file` calls (same message) |
| B4 | `find | xargs sed -i` on structured data | 6 (F7) | Use `yq -i` + Write |

Full recipes: [references/batch-operations.md](references/batch-operations.md).

## References

| Resource | URL | Last verified |
|---|---|---|
| Anthropic — ACI (Agent-Computer Interface) design | https://docs.anthropic.com/en/docs/build-with-claude/tool-use | 2026-05-25 |
| MCP specification — tools | https://spec.modelcontextprotocol.io/docs/tools/ | 2026-05-25 |
| OpenCode tool configuration | https://opencode.ai/docs/configuration | 2026-05-25 |

- [references/error-handling.md](references/error-handling.md)
- [references/parallel-execution.md](references/parallel-execution.md)
- [references/tool-selection.md](references/tool-selection.md)
- [references/structured-data-tools.md](references/structured-data-tools.md)
- [references/batch-operations.md](references/batch-operations.md)

## Verification Checklist

Before shipping any tool or completing a task:
- [ ] Dedicated tool preferred over Bash for file/search/write operations
- [ ] Composite > chained: single tool call designed for common workflows
- [ ] Tool names namespaced: `{service}_{resource}_{action}`
- [ ] Response limits configured: pagination + truncation with steering message
- [ ] ACI checklist applied: clear purpose, no overlap, actionable errors
- [ ] Orchestration pattern matches task: parallel for independent, sequential for dependent

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Tool returns truncated data silently | Pagination not configured; response limit hit without steering message | Add pagination params: `page`, `perPage`, `limit`; always check for `nextToken`/`cursor` in response |
| Bash process runs slower than expected (known issue: shell overhead for simple ops) | Using Bash when dedicated tool exists (e.g., `cat` vs `Read`, `grep` vs `Grep`) | Replace Bash with dedicated tool — no subprocess fork, no shell escaping, lower token cost |
| Tool name conflicts with existing tools | Generic name used (`search`, `create`, `update`) without namespace prefix | Rename to `{service}_{resource}_{action}` pattern; verify no duplicates in existing tool catalog |
| Workflow too slow due to sequential tool calls | Tools have no data dependency but called sequentially anyway | Group independent calls in parallel (same message); only sequentialize when output of A is input to B |

| [WARN] Composite tool chains break silently when one sub-tool returns empty result | No validation between chained steps; empty input from step A passes silently to step B | Add guard clause between each chained step: if result is empty or error, abort chain with explicit message |
| Dedicated tool exists but returns data in different format than Bash equivalent | Tool API abstractions normalize output; Bash pipes preserve raw output including errors | Choose one pattern per workflow, NEVER mix; if tool coverage incomplete, use Bash exclusively |
| Gotcha: parallel tool calls fail when one tool writes a file that another tool reads concurrently | File write and read in same message batch leads to race condition: read happens before write completes | Sequentialize dependent file operations; only parallelize truly independent reads |
