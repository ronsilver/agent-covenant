---
name: agent-expert
description: "Multi-agent system orchestration based on Anthropic patterns (prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer, autonomous agents): analysis of individual agents (capabilities, limitations, MCP configuration, skills, hooks), subagent design with restricted permissionMode, agent runner catalogs (Claude Code, OpenCode, Cursor, Windsurf, Gemini, Copilot, Codex), agent security (injection defense, tool restrictions, output validation), and model routing (cost-performance optimization). Use when coordinating multiple AI agents, implementing agent handoffs, analyzing agent capabilities across platforms, designing subagent permission boundaries, choosing orchestration patterns, or implementing agent safety guardrails. Trigger: multi-agent orchestration, subagent permissions, agent safety. Do NOT trigger for: single-agent tasks without coordination or handoff needs, agent architecture design without multi-agent coordination (use agent-architecture-expert). See also: agent-architecture-expert for Anthropic pattern deep-dive."
license: MIT
metadata:
  author: Community
  version: "1.2"
  category: ai-agents
  status: stable
---

# Agent Expert

**Multi-agent orchestration, agent safety, model routing and runner analysis.**

## Orchestration Patterns
→ Full guide with LangGraph code: [references/multi-agent-orchestration.md](references/multi-agent-orchestration.md)

| Pattern | Use When |
|---|---|
| Supervisor | Multi-domain delegation |
| Plan-and-Execute | Sequential phases |
| Swarm | Dynamic handoffs |
| Pipeline | Generic 4-stage sequential pipeline (Intake → Validation → Enrichment → Approval) |

## Agent Safety
→ Full defense-in-depth guide: [references/agent-safety.md](references/agent-safety.md)

6 safety layers: Input Validation, System Prompt Hardening, Tool Restrictions, Output Validation, Runtime Guardrails, Human-in-the-Loop.

## Model Routing
→ Cost optimization guide: [references/model-routing.md](references/model-routing.md)

| Task | Model |
|---|---|
| Simple (extraction, classification) | Claude Haiku |
| Medium (code review, analysis) | Claude Sonnet |
| Complex (architecture, audit) | Claude Opus |

## Core Rules
- NEVER use default/inherited permissionMode (always explicit)
- NEVER skip tool allowlist/denylist definition
- ALWAYS isolate subagent context (never pass raw orchestrator state)
- NEVER trust subagent output without re-verification on critical claims
- Start with simplest orchestration pattern; add complexity only when needed

## Overview

Multi-agent orchestration using Anthropic patterns (prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer, autonomous agents). Covers agent runner capabilities across Claude Code, OpenCode, Cursor, Windsurf, Gemini, Copilot, and Codex; subagent permission design with explicit allow/denylists; agent safety with 6-layer defense-in-depth; and model routing for cost-performance optimization (Haiku/Sonnet/Opus).

## Quick Reference

| Scenario | Pattern / Action |
|---|---|
| Multi-domain delegation (analytics + code + infra) | Supervisor pattern — one orchestrator delegates to domain specialists |
| Sequential phases (spec → implement → test) | Plan-and-Execute — ordered pipeline |
| Dynamic handoffs between unknown number of workers | Swarm pattern — agents join/leave dynamically |
| Generic sequential document processing (Intake → Validation → Enrichment → Approval) | Pipeline pattern — fixed sequential stages |
| Cost-sensitive task routing | Model routing: Haiku for simple, Sonnet for medium, Opus for complex |

## Workflow

1. Define task scope and required capabilities (code, infra, data, etc.)
2. Identify agent runners with matching capabilities (Claude Code, OpenCode, etc.)
3. Choose orchestration pattern (supervisor, pipeline, swarm, plan-and-execute)
4. Design subagent permissions: explicit allowlist/denylist (never default)
5. Configure MCP servers and skills for each agent
6. Implement safety layers: input validation → prompt hardening → tool restrictions → output validation → runtime guardrails → human-in-the-loop
7. Route by complexity: Haiku (simple), Sonnet (medium), Opus (complex)
8. Isolate subagent context — never pass raw orchestrator state
9. Verify critical subagent outputs before acting on them

## Anti-patterns

FAIL: Using default/inherited permissionMode for subagents
```yaml
permissionMode: default  # inherited — unclear what's allowed
```

PASS: Always set explicit permissionMode with allowlist
```yaml
permissionMode: restricted
toolAllowlist: ["read", "grep", "glob"]
```

FAIL: Passing raw orchestrator context to sub-agents
```
"Here's everything — figure it out"
```

PASS: Extract only relevant subset for sub-agent task
```
{task_id, instructions, relevant_context, required_tools}
```

FAIL: Trusting subagent output without verification on critical claims
```
Subagent: "Deployment is safe to proceed"
Orchestrator: proceeds without checking
```

PASS: Always re-verify critical claims from subagents
```
Orchestrator: verify deployment safety with independent check
```

FAIL: Starting with complex orchestration when simpler suffices
```
Full autonomous swarm for a simple data extraction task
```

PASS: Start with simplest pattern, add complexity only when needed
```
Extraction → prompt chaining. Multi-stage document processing → pipeline. Multi-domain → supervisor.
```

FAIL: No tool restriction on subagents (open-ended access)
```
Subagent can access all tools, all files, all network
```

PASS: Always define tool allowlist per subagent role
```
Code-review agent: {read, grep, glob} only — no write, no network
```

## Subagent-Driven Development

Split implementation into subagent tasks (master catalog #20) and review in two stages:
1. Spec-compliance review: does the subagent deliver exactly the agreed scope?
2. Code-quality review: is the code correct, tested, and idiomatic?
Stage 1 before stage 2; a spec miss invalidates the quality pass.

## Think / Act / Prove

For any non-trivial subagent action, require the trio (master catalog #152):
- Think: state the intended action and its expected effect
- Act: perform the action
- Prove: show the observable evidence it worked
An intent gate forces an artifact: the subagent must produce the proof (a file, log line, or result) before the orchestrator accepts the step.

## Frozen Checks and Typed-Evidence Watchdog

Freeze the checks a task must pass before it can finish (master catalog #4). A typed-evidence watchdog verifies each completion claim against its evidence type:
- Claim type: file written -> evidence: file exists with expected content
- Claim type: command ran -> evidence: captured exit code and output
- Claim type: state changed -> evidence: observable before/after diff
A completion claim without matching typed evidence is treated as not done.

## References

| Resource | URL | Last verified |
|---|---|---|
| Anthropic — multi-agent patterns | https://docs.anthropic.com/en/docs/build-with-claude/multi-agent | 2026-04 |
| Anthropic — tool use design (ACI) | https://docs.anthropic.com/en/docs/build-with-claude/tool-use | 2026-04 |
| MCP specification | https://spec.modelcontextprotocol.io/ | 2026-04 |
| OpenCode subagent configuration | https://opencode.ai/docs/agents | 2026-05 |

- [references/runner-matrix.md](references/runner-matrix.md)

## Verification Checklist
- [ ] Subagent `permissionMode` set explicitly (not inherited default)
- [ ] Tool allowlist/denylist defined for every subagent (no open-ended access)
- [ ] Subagent context isolated — no raw orchestrator state passed
- [ ] Critical subagent outputs re-verified by orchestrator before acting
- [ ] Safety layers implemented: input validation → prompt hardening → output validation
- [ ] Model routing matches complexity: Haiku for simple, Sonnet for medium, Opus for complex

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Subagent fails silently without reporting error | Worker contract not followed; orchestrator missing task timeout | Implement structured worker response: `{task_id, status, output, errors}`; set max_iteration limit |
| Subagent accesses unauthorized files or tools | `permissionMode` left as `default`; no tool allowlist defined | Set `permissionMode: restricted` with explicit `toolAllowlist` per role |
| Orchestrator context overflows after subagent delegation | Subagent returns raw output exceeding token budget | Enforce ≤1-2k token return; orchestrator compresses before next delegation |
| Model cost higher than expected | Complex tasks routed to Opus when Sonnet would suffice; no Haiku for simple extraction | Implement model routing by task complexity; log token cost per task for audit |
| Subagent tool execution hangs when MCP server crashes mid-request (known bug) | Worker has no timeout for tool execution; orchestrator waits indefinitely | Add tool execution timeout per subagent call; implement health check before delegating |
