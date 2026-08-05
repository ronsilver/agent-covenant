# RFC 7807 Error Format

## Standard Response
```json
{
  "type": "https://api.example.com/errors/insufficient-stock",
  "title": "Insufficient stock",
  "status": 422,
  "detail": "Shipment of 1000 units exceeds available stock of 500 units",
  "instance": "/v1/items/item_abc123",
  "request_id": "req_xyz789",
  "code": "INSUFFICIENT_STOCK"
}
```
- type: URL to error documentation
- code: machine-readable enum for client handling
- request_id: for log correlation
- NEVER expose stack traces in detail

## Error Codes (Generic)
| Code | Status |
|---|---|
| INVALID_REQUEST | 400 |
| UNAUTHORIZED | 401 |
| FORBIDDEN | 403 |
| NOT_FOUND | 404 |
| DUPLICATE_REQUEST | 409 |
| RATE_LIMITED | 429 |
| INSUFFICIENT_STOCK | 422 |
| PROVIDER_ERROR | 502 |
| SERVICE_UNAVAILABLE | 503 |
