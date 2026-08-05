# Tool Error Handling

## Error Categories
| Type | Action |
|---|---|
| File not found | Verify path, suggest alternatives |
| Permission denied | Request elevated access or suggest alternative |
| Network timeout | Retry with backoff, max 3 attempts |
| Validation error | Fix input, re-run |
| Rate limit | Wait, retry with exponential backoff |
| Unknown error | Log, escalate to human |

## Retry Strategy
```
max_retries = 3
backoff = 1s, 2s, 4s (exponential)
max_backoff = 30s
respect Retry-After header if present
```

## When NOT to Retry
- 400 Bad Request (fix input first)
- 401/403 (auth issue, not transient)
- 404 Not Found (resource doesn't exist)
- 409 Conflict (state conflict, needs resolution)
- File not found on disk (path error)

## Error Reporting
```
Format: "Error: <what happened>. Fix: <suggested action>."
Good: "Error: file not found at src/handler.go. Fix: check if file was moved or renamed."
Bad: "File not found"
```
