---
trigger: always
---

# Tool Usage

## Core Principle - MANDATORY
Tools are contracts between deterministic systems and non-deterministic agents — design for agents, NOT APIs.
Agent affordances differ from software: limited context, varied strategies, occasional hallucination.
Goal: maximize surface area for agent success, minimize context consumed.

## Tool Preference - MANDATORY
CRITICAL: Use dedicated tools NOT Bash.
`Read` NOT `cat/head/tail` | `Edit` NOT `sed/awk` | `Write` NOT `echo >` | `Grep` NOT `grep/rg` | `Glob` NOT `find/ls`

Read Before Edit/Write - MANDATORY (enforced).
NEVER reference files/funcs/imports without reading.
NEVER assume cmd output - run+verify. NEVER fabricate results.

## Never Invent - CRITICAL
unknown→UNKNOWN. NEVER guess `paths|endpoints|imports|versions|CLI_flags`. ALWAYS read/run first.
Before any CLI tool or API: verify flag names by reading docs or `--help`. NEVER assume syntax from memory.

## Tool Selection - CRITICAL
Build fewer, focused tools targeting high-impact workflows. NEVER wrap every API endpoint.
Composite>Chained: 1 tool=complete workflow. `schedule_event(user_ids,time)`→availability+create (vs 3 calls).
`get_customer_context(id)`→all recent data (vs `get_customer`+`list_activity_logs`+`list_notes`).
Search>List-All: `search_contacts(name="John")`→3 matches NOT `list_all_contacts()`→1000 entries.

If human can't definitively choose between 2 tools → agent won't either. Merge or clarify.
Too many overlapping tools = distracted agents + bloated context. Fewer well-designed > many granular.

## Namespacing - MANDATORY (MCP / multi-server)
Prefix by service+resource: `asana_projects_search`, `jira_issues_create`.
NEVER generic names: `search`, `create`. Always: `{service}_{resource}_{action}`.
Evaluate prefix vs suffix ordering — effects vary by model, test both.

## Tool Responses - MANDATORY
Return semantic context, NOT technical noise.
`name`, `file_type`, `image_url` > `uuid`, `mime_type`, `256px_image_url`.
Resolve UUIDs→human-readable names/0-indexed IDs to reduce hallucinations in retrieval tasks.

Expose `response_format` enum when both concise and detailed outputs needed:
`"concise"` (omit IDs, ~⅓ tokens) | `"detailed"` (include IDs for chained tool calls).

Response format (XML/JSON/Markdown): no one-size-fits-all — select based on eval.

## Tool Response Limits - MANDATORY
Max 25k tokens/call. ALWAYS implement: pagination(`?page=1&limit=100`) + filtering + range(`start_line`,`end_line`) + truncation(actionable).
Truncation: include steering message → `[truncated — use filter=X for targeted results]`.
Errors: specific+actionable. `Error: 'date' ISO 8601 (YYYY-MM-DD). Got: '01/15/2024'` NOT `Error: 422`.
One-line error format: `Error: <what>. Fix: <how>.` Never multi-paragraph error explanations.

## Naming & Params - MANDATORY
Params unambiguous. `user_id` NOT `user`. Make implicit explicit.
Descriptions: write for new hire, not API consumer. Expose: query formats, niche terms, resource relationships.
Examples in descriptions steer behavior — include 1-2 canonical param examples.

## Orchestration - MANDATORY
Independent→parallel tool calls | Sequential→chain with `;` | NEVER newlines to separate cmds.
Background: when result NOT needed immediately. NEVER use for <5s or when output needed for next step.

## Path & Bash - MANDATORY
ALWAYS absolute paths (agent threads reset `cwd`).
NEVER sleep in loops/before cmds. Use `run_in_background` for long tasks.
NEVER interactive git: `git add -i`, `git rebase -i`, `git commit --amend`.
Command efficiency: before running N similar cmds (curl, aws, kubectl...), evaluate if a loop/script reduces total calls. `for x in a b c; do curl ...$x; done` > 3 separate curl calls.
NEVER heredoc in terminal (`cat << EOF`) — heredoc fails in non-interactive shells. Write script to temp file (`/tmp/script.sh`) via `write_to_file`, then `chmod +x` + execute.

## Evaluation - MANDATORY (before shipping tools)
Measure: accuracy + total tool calls + token consumption + error rate + runtime.
Redundant calls → rightsize pagination/limits. High error rate → improve descriptions/examples.
Track unexpected tool-call patterns in transcripts — agent CoT reveals what descriptions miss.
Prototype → eval → iterate. Never ship tools without measuring against real-world tasks.

## Workflow Patterns - MANDATORY
Patterns (simplest first): prompt_chaining | routing | parallelization | orchestrator-workers | evaluator-optimizer | agents.
Simplest pattern that works wins. Add complexity only when it demonstrably improves outcomes.

## Skills - MANDATORY
For specialized tasks (infra, debugging, security, testing, design...): invoke `skill` tool with the matching skill name.
Skill descriptions contain "Use when..." triggers — match task intent against them. If no skill clearly matches → proceed without one.
NEVER guess a skill name. If uncertain which skill fits → invoke the `skill-router` skill for guided selection.

## ACI Design Checklist - MANDATORY
Anthropics 3 core principles: **Simplicity** + **Transparency** (show planning steps) + **Documentation+Testing**.
Before creating tool: clear purpose? context-efficient? no overlap? response limits? unambiguous params? actionable errors? evaluated on real tasks?
Poka-yoke: design params to make mistakes hard. Prefer absolute paths over relative. Prefer enums over free strings. Prefer explicit IDs over implicit lookups.
Test: run many example inputs in workbench/eval. Transcripts reveal what descriptions miss.
Format: choose based on eval — not habit. JSON requires escaping; markdown is model-natural for code.
