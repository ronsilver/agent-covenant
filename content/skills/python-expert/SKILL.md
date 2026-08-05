---
name: python-expert
description: "Complete Python stack for cloud-native projects: async backend with FastAPI and Pydantic v2, agent flow orchestration with LangGraph/LangChain on AWS Bedrock, data science (pandas, scikit-learn, numpy), Jupyter notebooks, testing with pytest, and code quality with ruff/black/mypy/bandit. Use when building AI services (api, context-layer), writing FastAPI route handlers, implementing LangGraph StateGraph nodes/edges, doing data science/ML work, working with Jupyter notebooks, or running Python linting/type checks. Trigger: Python, FastAPI, Pydantic, LangGraph, pytest, ruff. Do NOT trigger for: frontend development, mobile development, DevOps/CI scripting in Bash. For AI architecture questions (RAG, model selection, evaluation), use agent-architecture-expert or evaluation-expert instead."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend
  status: stable
---
# Python Expert

**Python Stack: FastAPI, LangGraph/LangChain, data science, testing and linting.**

## Core Stack

- API: FastAPI 0.110+ (routers, Depends, lifespan, middleware)
- Validation: Pydantic v2 (`model_config = ConfigDict(from_attributes=True)`)
- Async: `asyncio`, httpx, SQLAlchemy 2.0 async, asyncpg
- AI: LangGraph (StateGraph, nodes, conditional edges) + LangChain (chains, tools)
- AI Runtime: AWS Bedrock (`ChatBedrockConverse`)
- Data Science: pandas, scikit-learn, numpy, joblib
- Notebooks: Jupyter (jupytext, nbconvert, papermill, kernels)
- Testing: pytest + fixtures + parametrize + httpx `AsyncClient`
- Linting: `ruff format` -> `ruff check` -> `mypy` -> `bandit`
- Packaging: pyproject.toml / uv / poetry

## Project Structure

```
src/
  api/routers/          # route handlers (thin)
  core/                 # config, dependencies, lifespan
  models/               # Pydantic schemas (request/response)
  services/             # business logic
  repositories/         # data access
  multi_agents/
    orchestrator/
      branches/<stimulus>/<version>/
        graph.py        # StateGraph definition
        nodes.py        # node functions
        edges.py        # conditional routing
      stimuli_registry.py
      state.py          # shared TypedDict state
tests/
```

## Architecture

```
Router -> Service -> Repository (NEVER skip layers)
```

- Routers: parse -> call service -> return Pydantic model
- Service: business logic only (no HTTP concerns)
- Repository: async data access
- NEVER business logic in routers | NEVER sync blocking in `async def`

## Rules

- `source .venv/bin/activate` before `pytest`/`python` — ALWAYS
- Docstrings: Google style (Args/Returns/Raises)
- `ensure_ascii=False` only in `json.dumps`, never in LLM system prompts
- ASCII-only in LLM system prompts (no em-dash, smart quotes)
- NEVER log PII (tokens, government IDs)

## LangGraph / AI Patterns

```python
from langgraph.graph import StateGraph, END
from typing import TypedDict

class State(TypedDict):
    messages: list
    next: str

graph = StateGraph(State)
graph.add_node("analyze", analyze_node)
graph.add_conditional_edges("analyze", route_fn, {"a": "nodeA", "b": END})
app = graph.compile()
```

- NEVER mutate state directly -> return patches only
- NEVER hardcode model IDs -> use config/env
- ALWAYS version branches (`v1/`, `v2/`) — never overwrite
- ALWAYS register new stimuli in `stimuli_registry.py`
- ALWAYS use `astream`/`ainvoke` for async execution
- Wire to Bedrock via `ChatBedrockConverse`

## Data Science

- pandas: vectorized ops over loops (100x perf)
- scikit-learn: pipelines, ColumnTransformer, cross-validation
- numpy: broadcasting, masking, avoid Python-level loops
- joblib: model persistence (`dump`/`load`), parallel processing
- Notebooks: jupytext for .py sync, nbconvert for automation, NEVER secrets in notebooks

## Testing

```python
import pytest
from httpx import AsyncClient, ASGITransport
from myapp.main import app

@pytest.mark.anyio
async def test_create_item():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/items", json={"value": 1000})
        assert response.status_code == 201
```

- Fixtures over setup/teardown. Parametrize over loops.
- `httpx.AsyncClient` with `ASGITransport` for FastAPI testing
- NEVER global client — always `async with`

## Linting (Golden Chain)

```
ruff format -> ruff check -> mypy -> bandit
```
Stop on first failure. Never `|| true` in CI.

## Constraints

- NEVER business logic in routers -> service layer only
- NEVER sync blocking in `async def` -> `run_in_executor` or async libs
- NEVER `import *` — explicit imports only
- NEVER mutate LangGraph state directly — return patches
- NEVER hardcode model IDs or secrets in notebooks
- ALWAYS type-annotate all function signatures
- ALWAYS `raise HTTPException` with explicit `status_code`
- ALWAYS propagate `request_id` via `contextvars`
- NEVER `from langchain_community import *` — pin exact imports

## Overview

Python services in this project use FastAPI for async APIs, LangGraph on AWS Bedrock for agent orchestration, and pandas/scikit-learn for data science. This skill covers the full stack from route handlers to LangGraph state machines to linting.

## Quick Reference

| Layer | Library | Responsibility |
|---|---|---|
| API | FastAPI + Pydantic v2 | Route handlers, request/response validation |
| AI Workflows | LangGraph + Bedrock | Agent state machines, LLM invocation |
| Data | pandas, scikit-learn, numpy | Analytics, ML pipelines |
| Testing | pytest + httpx AsyncClient | Unit + integration tests |
| Linting | ruff → mypy → bandit | Format, type-check, security scan |

## Workflow

1. Define Pydantic v2 models with `ConfigDict(from_attributes=True)` for request/response schemas
2. Implement FastAPI router with thin handlers: parse → call service → return model
3. Write async service layer with business logic and `contextvars` for `request_id`
4. For AI workflows: define LangGraph `StateGraph` with typed `State`, nodes, and conditional edges
5. Register new agent branches in `stimuli_registry.py` with versioned directories
6. Write pytest fixtures + parametrized tests using `httpx.AsyncClient` with `ASGITransport`
7. Run golden chain: `ruff format` → `ruff check` → `mypy` → `bandit`

## Anti-patterns

FAIL: Business logic in FastAPI route handlers
PASS: Route handlers only parse input and delegate to service layer

```python
# FAIL:
@app.post("/items")
async def create_item(req: ItemRequest):
    if req.value <= 0:
        raise HTTPException(400)
    result = await db.execute("INSERT ...")
    return {"status": "ok"}

# PASS:
@app.post("/items")
async def create_item(req: ItemRequest):
    return await item_service.create(req)
```

FAIL: Synchronous blocking calls inside `async def`
PASS: Use async libraries or `run_in_executor` for CPU-bound work

```python
# FAIL:
async def process():
    time.sleep(2)  # blocks event loop
    result = pd.DataFrame(...).apply(slow_fn)  # CPU-bound blocks event loop

# PASS:
async def process():
    await asyncio.sleep(2)
    result = await asyncio.to_thread(lambda: pd.DataFrame(...).apply(slow_fn))
```

FAIL: Mutating LangGraph state directly inside nodes
PASS: Always return patches from node functions

```python
# FAIL:
def analyze_node(state: State) -> dict:
    state["messages"].append({"role": "assistant", "content": "done"})
    return state

# PASS:
def analyze_node(state: State) -> dict:
    return {"messages": [{"role": "assistant", "content": "done"}]}
```

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/) (last_verified: 2025-02)
- [LangGraph Tutorial](https://langchain-ai.github.io/langgraph/tutorials/) (last_verified: 2025-01)
- [AWS Bedrock Converse API](https://docs.aws.amazon.com/bedrock/latest/userguide/converse-api.html) (last_verified: 2024-12)

- [references/async-patterns.md](references/async-patterns.md)
- [references/datascience.md](references/datascience.md)
- [references/langgraph-patterns.md](references/langgraph-patterns.md)
- [references/testing-patterns.md](references/testing-patterns.md)

## Verification Checklist

- [ ] Business logic separated into service layer (never in routers)
- [ ] All `async def` functions use async libraries only (no sync blocking calls)
- [ ] LangGraph nodes return state patches (never mutate state directly)
- [ ] Pydantic v2 models use `ConfigDict(from_attributes=True)` for ORM mode
- [ ] Golden chain passed: `ruff format` → `ruff check` → `mypy` → `bandit`
- [ ] `request_id` propagated via `contextvars` throughout request lifecycle
- [ ] No PII logged (tokens, government IDs)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Event loop blocked during request | Sync `time.sleep()` or CPU-bound operation in `async def` | Replace with `asyncio.sleep()` or `await asyncio.to_thread()` for CPU work |
| FastAPI returns 422 on valid input | Pydantic v2 model uses v1-style config or `ConfigDict` missing | Verify `model_config = ConfigDict(from_attributes=True)` on model |
| LangGraph node state not updating | Node mutates state directly instead of returning patch | Change node to return dict of only changed keys (never mutate `state` arg) |
| Pydantic v2 JSON serialization fails for custom types (edge case: non-serializable types) | Custom type lacks `__get_pydantic_core_schema__` or serializer | Add `model_serializer` or use `field_serializer` decorator on the field; register type adapter |

| [WARN] FastAPI `Depends()` evaluates DB session outside request context on error path | Exception handler may try to access request-scoped dependency after request cleaned up | Create DB session in middleware/lifespan, not Depends(); use `try/finally` for cleanup |
| pytest --cov shows 100% coverage but critical exception path was never tested | Coverage tracks line execution, not logic branches; uncovered except blocks hidden from metric | Use --cov-branch to measure branch coverage; enforce if/except path coverage in CI gate |
| Limitation: LangGraph checkpoint created during node execution is rolled back if node later fails | Checkpointing at node start commits state that node may not fully validate until end | Checkpoint only at end of node execution; use conditional edge to skip checkpoint on partial failure |
