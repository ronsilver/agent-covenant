# MCP Tool Design

## Schema Template
```json
{
  "name": "service_resource_action",
  "description": "Single-sentence purpose. Use when [trigger].",
  "inputSchema": {
    "type": "object",
    "properties": {
      "param_name": {
        "type": "string",
        "description": "What this parameter does, valid values, constraints"
      }
    },
    "required": ["param_name"]
  }
}
```

## Namespacing
```
shipments_records_search
warehouse_query_execute
infrastructure_cluster_status
```
Pattern: `{domain}_{resource}_{action}`

## Response Limits
- ALWAYS paginate (cursor-based)
- maxLimit enforced server-side
- Error format: `{error: "what", fix: "how"}`
