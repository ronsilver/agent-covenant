# API Pagination Patterns

## Cursor-Based (preferred for >1000 items)
```json
GET /v1/transactions?cursor=abc123&limit=50
{
  "data": [...],
  "next_cursor": "def456",
  "has_more": true
}
```

## Offset-Based (admin UIs only)
```json
GET /v1/customers?offset=20&limit=10
{
  "data": [...],
  "total": 100,
  "offset": 20,
  "limit": 10
}
```

## Why Cursor > Offset
- Stable across data changes (no missing/skipped rows)
- Better performance on large datasets (uses index seek, not count skip)
- Works consistently with frequently-inserted data
