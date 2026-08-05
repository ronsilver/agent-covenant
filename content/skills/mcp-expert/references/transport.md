# MCP Transport Selection

| Transport | Best For | Auth |
|---|---|---|
| stdio | Local CLI tools | Process isolation |
| SSE | Remote tools, multi-client | Bearer token |
| Streamable HTTP | Modern bidirectional | API key / OAuth |

## SSE Configuration
```python
from mcp.server.sse import SseServerTransport
transport = SseServerTransport("/messages/")
```

## Security
- API Key: header validation, rotation policy
- mTLS: service-to-service only
- Rate limiting: 100 req/min per client
- Input validation: server-side ALWAYS (never trust agent)
