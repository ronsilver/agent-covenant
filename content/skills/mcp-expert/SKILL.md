---
name: mcp-expert
description: "Model Context Protocol (MCP): server design and implementation (stdio/SSE/streamable-HTTP), tool and resource definition with namespacing, full protocol (requests, responses, notifications, errors, sampling), auth (API Key, OAuth, mTLS), observability (logging, tracing, metrics), testing with MCP clients, publishing via npm/uvx, and security (rate limiting, input validation, secret handling). Use when designing MCP servers, defining tools/resources, configuring transports (stdio/SSE/HTTP), implementing MCP auth, or testing MCP integrations. Trigger: MCP server, MCP tool, MCP resource, stdio transport, SSE transport, Streamable HTTP, FastMCP, MCP SDK. Do NOT trigger for: general REST API design, generic tool creation without MCP protocol, Claude API direct usage without MCP."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: ai-agents
  status: stable
---

# MCP Expert

**Model Context Protocol: servers, tools, resources, transports and security.**

## Protocol Reference
→ Full message types + capabilities: [references/protocol-reference.md](references/protocol-reference.md)

## Server Implementation
→ Python (FastMCP) + Node.js (SDK) examples: [references/server-implementation.md](references/server-implementation.md)

## Quick Transport Selection
| Transport | Best For | Constraint |
|---|---|---|
| stdio | Local tools, CLI agents | Single process |
| SSE | Remote, web apps | HTTP |
| Streamable HTTP | Modern, cloud-native | Bidirectional |

## Server Capabilities
- **Tools**: model-invoked functions (tools/list, tools/call)
- **Resources**: data exposure to clients (resources/list, resources/read)
- **Prompts**: pre-configured templates (prompts/list, prompts/get)
- **Sampling**: server requests LLM from client

## Core Rules
- NEVER expose raw database access without validation layer
- NEVER return unbounded results (always paginate, server-side limit enforcement)
- ALWAYS include rate limiting and timeout on MCP tools
- ALWAYS validate inputs server-side (never trust the agent client)
- NEVER output secrets or PII in tool responses

## Overview

The Model Context Protocol (MCP) standardizes how AI agents interact with external tools, data sources, and services. This skill covers MCP server design across three transports (stdio, SSE, Streamable HTTP), tool/resource schema definition with proper namespacing, authentication (API Key, OAuth, mTLS), observability (logging, tracing, metrics), testing against MCP clients, and security hardening (rate limiting, input validation, secret handling). MCP is the primary integration layer for agent-tool interactions.

## Quick Reference

| Concern | Standard | Implementation |
|---|---|---|
| Transport | stdio / SSE / Streamable HTTP | Python FastMCP, Node.js SDK |
| Tool schema | JSON Schema (tools/list → tools/call) | `@mcp.py/tool` decorator |
| Resources | URI-based (resources/list → resources/read) | File or API-backed URIs |
| Auth | API Key / OAuth 2.0 / mTLS | Server capability negotiation |
| Sampling | Server → Client LLM request | `sampling/create` notification |
| Rate limiting | Per-tool token bucket | Middleware in server |
| Observability | OTel spans per tool call | Wrapped in server handler |
| Publishing | npm / uvx / GitHub | Package with entry point |

## Workflow

1. **Choose transport** — stdio for local agent-tool interaction (single process). SSE for remote web-accessible servers. Streamable HTTP for cloud-native bidirectional streaming.
2. **Design tool schemas** — Define each tool with JSON Schema: `name` (kebab-case, namespaced), `description` (purpose + when to use), `inputSchema` (typed parameters), and optional `output` contract.
3. **Implement server** — Use FastMCP (Python) or MCP SDK (Node.js). Register tools via decorators. Add rate limiting and timeout middleware. Add OTel instrumentation.
4. **Define resources** — Expose data as URI-based resources with MIME types. Use URI template pattern for parameterized resources: `example://resources/{resource_id}/status`.
5. **Add auth** — Configure API Key for internal services, OAuth 2.0 for partner-facing servers, mTLS for sensitive-data-scoped tools.
6. **Test with clients** — Use MCP Inspector or `mcp-cli` to test tool calls, resource reads, and error handling. Verify rate limiting, timeout, and validation behavior.
7. **Publish** — Package for npm (`npx`) or uvx (`uvx`). Include README with tool list, auth setup, and example usage.

## Anti-patterns

FAIL: Raw database access exposed as an MCP tool without validation.
```python
# BAD: Direct SQL execution tool — SQL injection vector
@server.tool()
def query_db(sql: str) -> str:
    return str(db.execute(sql))  # agent can run DROP TABLE
```
```python
# GOOD: Specific read-only query with parameter binding
@server.tool()
def get_resource(resource_id: str) -> dict:
    return resource_repo.find_by_id(resource_id)
```

FAIL: Returning unbounded results from a search tool.
```python
# BAD: No pagination — 100K results in one response
@server.tool()
def search_items(q: str) -> list: ...
```
```python
# GOOD: Paginated with server-side limit
@server.tool()
def search_items(q: str, limit: int = 20, cursor: str = None) -> SearchResult: ...
```

FAIL: Leaking secrets or PII in tool error messages.
```python
# BAD: API key in error response
raise McpError(f"Auth failed: token={api_key}")
```
```python
# GOOD: Safe error message
raise McpError("Authentication failed: invalid credentials")
```

## References

| Resource | URL | Last verified |
|---|---|---|
| MCP Specification — Official Docs | https://spec.modelcontextprotocol.io/ | 2026-05-25 |
| MCP Python SDK — GitHub | https://github.com/modelcontextprotocol/python-sdk | 2026-05-25 |
| Anthropic — MCP Guide | https://docs.anthropic.com/en/docs/agents-and-tools/mcp | 2026-05-25 |

- [references/tool-design.md](references/tool-design.md)
- [references/transport.md](references/transport.md)

## Verification Checklist

- [ ] Transport chosen appropriately for deployment context (stdio vs SSE vs Streamable HTTP)
- [ ] Tool input schemas use JSON Schema with typed parameters and descriptions
- [ ] Rate limiting and timeout middleware configured on all tools
- [ ] Server-side input validation enforced (never trust the agent client)
- [ ] No raw database access exposed as tools (validated query layer only)
- [ ] All tool results paginated with server-side limit enforcement
- [ ] Auth configured (API Key / OAuth / mTLS) per deployment requirements

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Client receives `MethodNotFound` | Tool name mismatch or capability not declared | Verify tool name in `tools/list` response matches client call; check `capabilities.tools` in server config |
| `Error: Transport closed unexpectedly` | Stdio process exited or SSE connection timed out | Check server logs for unhandled exceptions; increase heartbeat/keep-alive interval |
| Rate limiting blocks legitimate calls | Token bucket too small for burst traffic | Increase burst capacity; add per-client rate limit tiers for different consumers |
| Known issue: SSE transport reconnection drops in-flight tool calls | Client reconnects after connection loss, but server-side tool execution continues orphaned | Implement idempotency keys for tool calls; add timeout on server-side execution; use Streamable HTTP for workloads requiring reliable delivery |

| [WARN] MCP server with stdio transport leaks child processes on crash | Parent process exits without killing spawned child; orphan processes accumulate | Register process group (`setpgid`) and use `SIGKILL` on cleanup for the entire group |
| FastMCP server with SSE transport drops connection when behind AWS ALB with idle timeout | ALB idle timeout (default 60s) closes SSE connection; FastMCP does not auto-reconnect | Increase ALB idle timeout to 3600s; enable MCP heartbeat pings every 30s to keep connection alive |
| Gotcha: Stdio MCP server deadlocks when client does not drain stdout before writing stdin | Bidirectional pipe deadlock: stdout buffer full, process blocks on write, cannot read stdin | Use line-buffered output; ensure client reads stdout continuously before sending next request |
