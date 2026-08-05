# MCP Protocol Reference

## Core Concepts
- **Server**: exposes tools, resources, prompts
- **Client**: consumes capabilities from servers
- **Transport**: stdio, SSE, or streamable HTTP

## Messages
| Type | Direction | Purpose |
|---|---|---|
| Request | C->S | Ask server to do something |
| Response | S->C | Result of request |
| Notification | Both | One-way message (no response) |
| Error | S->C | Request failed |

## Server Capabilities
### Tools
Model-invoked functions. Server exposes list_tools, client calls tool via call_tool.
```json
{ "method": "tools/list", "params": {} }
{ "method": "tools/call", "params": {"name": "...", "arguments": {...}} }
```

### Resources
Data exposed to clients. Server exposes list_resources, client reads via read_resource.
```json
{ "method": "resources/list" }
{ "method": "resources/read", "params": {"uri": "file:///..."} }
```

### Prompts
Pre-configured prompt templates. Server exposes list_prompts, client gets via get_prompt.
```json
{ "method": "prompts/list" }
{ "method": "prompts/get", "params": {"name": "...", "arguments": {...}} }
```

### Sampling
Server requests LLM completion from client.
```json
{ "method": "sampling/createMessage", "params": {"messages": [...], "maxTokens": 1000} }
```

## Transport Details
### stdio
- Process spawns server as child process
- Messages via stdin/stdout (newline-delimited JSON)
- Best for: local tools, CLI agents

### SSE (Server-Sent Events)
- HTTP POST for client->server, SSE stream for server->client
- Endpoint: POST /messages, GET /sse
- Best for: remote tools, web apps

### Streamable HTTP
- Bidirectional streaming over HTTP
- Server: POST /mcp with Accept: text/event-stream
- Best for: modern cloud-native setups

## Security
- API Key: X-API-Key header validation
- OAuth 2.0: Bearer token authorization
- mTLS: certificate-based for service-to-service
- Rate limiting: 100 req/min per client (minimum)
- Input validation: ALWAYS server-side (never trust agent)
