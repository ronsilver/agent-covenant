# Multi-Agent Orchestration Patterns

## Pattern Taxonomy (Anthropic)

### Workflows (fixed orchestration)
1. **Prompt Chaining**: A -> B -> C. Sequential steps with gates.
2. **Routing**: Classifier -> Handler. Separate concerns by type.
3. **Parallelization**: Sectioning (split work) + Voting (consensus).
4. **Orchestrator-Workers**: Central LLM decomposes, delegates, synthesizes.
5. **Evaluator-Optimizer**: Generator + Evaluator feedback loop.

### Agents (dynamic orchestration)
- **Supervisor**: routes to specialists, reviews outputs, retries on failure
- **Plan-and-Execute**: planner creates steps, executor runs them, feedback loop
- **Swarm**: agents hand off dynamically based on context need
- **Pipeline**: fixed sequence: IntakeAgent -> ValidationAgent -> EnrichmentAgent -> ApprovalAgent (generic 4-stage sequential pipeline)

## When to Use Each
| Pattern | Complexity | Predictability | Use Case |
|---|---|---|---|
| Prompt Chain | Low | High | Sequential subtasks |
| Routing | Low | High | Classification-based |
| Orchr-Workers | Medium | Medium | Unknown subtask count |
| Supervisor | Medium | Low | Multi-domain delegation |
| Autonomous Agent | High | Low | Open-ended tasks |

## Anti-Patterns
- Nano-services: 1 function = 1 agent (overhead >> value)
- Context sharing: passing raw orchestrator state to subagents (isolate!)
- No feedback loop: agent acts but never validates (add eval step)
- Infinite loop: no max_iterations or stopping conditions

## LangGraph Implementation
```python
from langgraph.graph import StateGraph, END
graph = StateGraph(TypedDict)
graph.add_node("supervisor", supervisor_fn)
graph.add_node("worker_a", worker_a_fn)
graph.add_node("worker_b", worker_b_fn)
graph.add_conditional_edges("supervisor", route_fn, {"a": "worker_a", "b": "worker_b"})
graph.add_edge("worker_a", "supervisor")  # return to supervisor
graph.add_edge("worker_b", END)
```
