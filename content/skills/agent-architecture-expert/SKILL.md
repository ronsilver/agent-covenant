---
name: agent-architecture-expert
description: "Agentic system architecture: Anthropic patterns (prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer, autonomous agents), RAG pipelines (chunking, embeddings, hybrid search, reranking, grounding), tool design (ACI principles, poka-yoke), AWS Bedrock Agents (action groups, knowledge bases, guardrails, AgentCore), memory systems (working, short-term, long-term, episodic, semantic), and framework selection (LangGraph, CrewAI, AutoGen). Use when designing agent systems, building RAG pipelines, creating Bedrock Agents, designing tool interfaces, implementing agent memory, or choosing agentic architectures. Trigger: agent systems, RAG pipelines, Bedrock Agents, agentic security, tool poisoning, prompt injection. Do NOT trigger for: simple single-LLM tasks without tool use or memory requirements, subagent permissions, agent safety (use agent-expert). See also: agent-expert for multi-agent coordination patterns."
license: MIT
metadata:
  author: Community
  version: "1.3"
  category: ai-agents
  status: stable
---

# Agent Architecture Expert

**Agentic systems: workflows, agents, RAG, tools, memory and AWS Bedrock Agents.**

## Agentic Patterns (Anthropic)

### Simple Patterns
| Pattern | When | Reference |
|---|---|---|
| Prompt Chaining | Sequential subtasks | [references/agentic-patterns.md](references/agentic-patterns.md) |
| Routing | Classification-based | [references/agentic-patterns.md](references/agentic-patterns.md) |
| Parallelization | Independent subtasks | [references/agentic-patterns.md](references/agentic-patterns.md) |

### Complex Patterns
| Pattern | When | Reference |
|---|---|---|
| Orchestrator-Workers | Unknown subtask count | [references/agentic-patterns.md](references/agentic-patterns.md) |
| Evaluator-Optimizer | Iterative refinement | [references/agentic-patterns.md](references/agentic-patterns.md) |
| Autonomous Agent | Open-ended tasks | [references/agentic-patterns.md](references/agentic-patterns.md) |

Rule: start simple. Only add agentic complexity when simpler approaches demonstrably fail.

## AWS Bedrock Agents

Create agents with FM + instructions + action groups + knowledge bases.
→ Full guide: [references/bedrock-agents.md](references/bedrock-agents.md)

AgentCore services: Gateway (MCP), Runtime (sandbox), Memory, Identity, Observability.
Guardrails: content filters, PII regex, topic denial, word filters.

AgentCore code interpreter (master catalog #23): enable for sandboxed code execution inside the Runtime; scope compute limits and file access per agent.
AgentCore browser (master catalog #23): enable for sandboxed web navigation; restrict to allowlisted domains and read-only interactions unless the task requires more.
AgentCore gateway (master catalog #23): expose a REST endpoint over the agent's MCP tools (REST to MCP bridging); put auth, rate limits, and request validation in front of the gateway.

## Agentic Security

Apply defense-in-depth to the architecture (master catalog #42, #39, #97):
- RAG poisoning: validate the corpus source, sanitize ingested documents, and ground answers back to retrieval.
- MCP abuse: treat tool definitions and responses as untrusted; allowlist tools and validate every tool argument at the boundary.
- Excessive agency: scope tools and permissions per task; require human approval for destructive actions; add iteration and cost ceilings.

## RAG Pipeline

Documents -> Ingestion -> Chunking -> Embedding -> Indexing -> Retrieval -> Reranking -> Generation
→ Full patterns: [references/rag-patterns.md](references/rag-patterns.md)

## Tool Design (ACI)

| Principle | Implementation | Poka-yoke |
|-----------|---------------|-----------|
| Clear names | `verify_result` not `vr` | Name must describe action + target |
| Typed params | `result_id: str, value: Decimal` | Type hint every parameter |
| Descriptive docs | Tells LLM when to use AND when NOT to | Include anti-trigger in tool doc |
| Validation | Validate all inputs before acting | Reject invalid args with clear error |
| Confirm gate | Require confirmation for destructive ops | `confirm_required=True` on delete/update |

→ Full guide with edge cases: [references/tool-design-aci.md](references/tool-design-aci.md)

## Memory Systems

| Type | Storage | Scope | Use Case |
|------|---------|-------|----------|
| Working | In-context (LLM window) | Per-turn | Immediate task state |
| Short-term | Agent session store | Session (1-N turns) | Accumulating context across turns |
| Long-term | Vector DB / KV store | Cross-session | Persistent knowledge |
| Episodic | Event log | Full timeline | Audit trail, replay |
| Semantic | Embedding index | Global | Facts, patterns, learnings |

→ Full patterns: [references/memory-systems.md](references/memory-systems.md)

## Pattern Selection Decision Table

| Situation | Pattern | Frameworks | Complexity |
|-----------|---------|------------|------------|
| Sequential deterministic steps, known count | Prompt Chaining | Any | Low |
| Classification-based branching (route to handler) | Routing | LangGraph | Low |
| Independent parallel work (no shared state) | Parallelization | LangGraph, Task | Low |
| Unknown subtask count, shared memory needed | Orchestrator-Workers | LangGraph, CrewAI | Medium |
| Iterative refinement (generate, evaluate, improve) | Evaluator-Optimizer | LangGraph | Medium |
| Open-ended multi-step, full autonomy | Autonomous Agent | LangGraph, AutoGen | High |

## Core Rules
- Start simple, add complexity only when needed
- ALWAYS evaluate with multi-dimensional rubrics before deploying agents
- NEVER use agents for tasks solvable with single LLM call + retrieval
- ALWAYS implement guardrails + human-in-the-loop for production agents
- NEVER skip tool testing with real input examples before deployment

## Overview

Provides guidance on designing agentic systems using Anthropic patterns (prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer, autonomous agents), RAG pipelines, tool design (ACI principles), memory systems, and AWS Bedrock Agents for cloud-native AI workloads.

## Quick Reference

| Pattern | Use Case | Framework |
|---|---|---|
| Prompt Chaining | Sequential deterministic subtasks | LangGraph, AutoGen |
| Orchestrator-Workers | Unknown number of subtasks | LangGraph, CrewAI |
| Evaluator-Optimizer | Iterative quality refinement | LangGraph |
| Autonomous Agent | Open-ended multi-step tasks | LangGraph, AutoGen |
| RAG | Knowledge grounding at inference | LangChain, Bedrock KB |

## Workflow

1. Define task requirements and assess complexity level
2. Choose simplest pattern that fits (start with prompt chaining)
3. Design tool interfaces following ACI principles
4. Implement RAG pipeline if external knowledge is needed
5. Add guardrails, human-in-the-loop, and observability
6. Evaluate with multi-dimensional rubric before deploying

## Anti-patterns

FAIL: Adding agentic complexity for simple deterministic tasks
```python
# BAD: wrapping a 3-step logic in an autonomous agent
agent = AutonomousAgent(tools=[tool_a, tool_b, tool_c])
result = agent.run("step1, then step2, then step3")

# GOOD: prompt chaining
result_c = chain([step_a, step_b, step_c], input_data)
```

FAIL: Unrestricted tool access without validation
```python
# BAD: agent can call any tool with any arguments
agent.add_tool(delete_workflow_tool)

# GOOD: tool has input validation + confirmation gate
@tool(confirm_required=True)
def delete_workflow(workflow_id: str) -> bool:
    validate_workflow_id(workflow_id)
    return workflow_service.delete(workflow_id)
```

FAIL: Using LLM output as ground truth without verification
```python
# BAD: trusting agent summary directly
summary = agent.run("summarize this operation")

# GOOD: verify against source data
summary = agent.run("summarize this operation")
verified = cross_reference(summary, operation_data)
```

## References

- Anthropic agent patterns: https://docs.anthropic.com/en/docs/build-with-claude/agent-patterns (last_verified: 2026-05)
- LangGraph documentation: https://langchain-ai.github.io/langgraph/ (last_verified: 2026-05)
- AWS Bedrock Agents guide: https://docs.aws.amazon.com/bedrock/latest/userguide/agents.html (last_verified: 2026-05)

## Verification Checklist
- [ ] Simplest viable pattern chosen (prompt chaining > agent) for the task complexity
- [ ] Tool interfaces follow ACI principles: clear names, typed params, descriptive descriptions
- [ ] Guardrails configured: content filters, topic denial, or PII regex as applicable
- [ ] Evaluation rubric defined with multi-dimensional criteria before agent deployment
- [ ] Human-in-the-loop gate implemented for production agent actions
- [ ] RAG pipeline validated: chunking strategy, embedding model, retrieval quality metrics

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Agent produces incorrect or hallucinated answers | RAG retrieval returning irrelevant chunks; no grounding verification | Add reranking step; verify LLM output against source data; reduce chunk size |
| Tool called with invalid arguments | Tool schema lacks validation; description ambiguous | Add input validation with poka-yoke defaults; clarify parameter descriptions |
| Agent stuck in loop or exceeds max iterations | Task too open-ended for chosen pattern | Add sub-task decomposition or switch to orchestrator-workers pattern |
| High latency per agent invocation | Model too powerful for task; unnecessary context in prompt | Route to cheaper model (Haiku); trim context to essentials |
| Agent loops when LLM returns tool calls for non-existent tools (known bug) | LLM hallucinates tool names or parameters not in schema | Validate all tool calls against registered schema before execution; add strict_tools mode if available |
