# MCP Server Implementation

## Python (FastMCP)
```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("records")

@mcp.tool()
def search_records(entity_id: str, from_date: str, limit: int = 50) -> dict:
    """Search records by entity and date range. Returns paginated results."""
    if limit > 100: limit = 100  # server-side enforcement
    results = db.query(entity_id, from_date, limit)
    return {"data": results, "count": len(results)}
```

## Node.js (MCP SDK)
```javascript
const { Server } = require("@modelcontextprotocol/sdk/server/index.js");
const { StdioServerTransport } = require("@modelcontextprotocol/sdk/server/stdio.js");

const server = new Server({
  name: "records-mcp",
  version: "1.0.0",
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{ name: "search_shipments", description: "...", inputSchema: {...} }]
}));

server.setRequestHandler("tools/call", async (request) => {
  const { name, arguments: args } = request.params;
  if (name === "search_shipments") return await handleSearch(args);
});
```

## Publishing
```bash
# npm
npm publish --access public

# Python (uvx)
uv tool install records-mcp

# Verify
npx records-mcp --help
```

## Testing
```python
import pytest
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

@pytest.mark.anyio
async def test_search_shipments():
    async with stdio_client(StdioServerParameters(command="records-mcp")) as (read, write):
        async with ClientSession(read, write) as session:
            await session.initialize()
            result = await session.call_tool("search_records", {"entity_id": "test"})
            assert len(result.data) > 0
```
