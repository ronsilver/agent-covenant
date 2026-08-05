# LangGraph / the AI service Patterns (Python)

## the AI service Orchestrator Layout

```
src/multi_agents/orchestrator/
  branches/
    <stimulus>/
      <version>/
        graph.py        # StateGraph definition
        nodes.py        # node functions — pure: state → state patch
        edges.py        # conditional routing
  stimuli_registry.py   # maps stimulus → branch/version
  state.py              # shared TypedDict state
```

## Core Pattern

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
from langchain_aws import ChatBedrockConverse

class State(TypedDict):
    messages: Annotated[list, operator.add]
    analysis: dict
    next: str

def analyze_node(state: State) -> dict:
    # NEVER mutate state directly → return patches only
    return {"analysis": {"result": "ready"}, "next": "respond"}

graph = StateGraph(State)
graph.add_node("analyze", analyze_node)
graph.add_conditional_edges("analyze", lambda s: s["next"], {
    "respond": "respond",
    "end": END,
})
app = graph.compile()
```

## Adding a Stimulus

1. Create `branches/<stimulus>/<version>/` with graph.py, nodes.py, edges.py
2. Register in `stimuli_registry.py`:
   ```python
   STIMULI["payment_analysis"] = {"branch": "payment_analysis", "version": "v1"}
   ```
3. Wire Bedrock model via `ChatBedrockConverse(model_id=...)`
4. Stream: `app.astream(input, config={"run_name": "payment_analysis"})`

## LangSmith Tracing

```python
app.astream(
    input,
    config={
        "run_name": "payment_analysis",
        "tags": ["production", "ai-service"],
        "metadata": {"stimulus": "payment_analysis", "version": "v1"},
    }
)
```
