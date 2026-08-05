---
name: openapi-expert
description: "Formal specification of REST APIs with OpenAPI 3.x: endpoint design, request/response schemas, versioning, pagination (cursor/offset), RFC 7807 error handling, stub generation, contract validation, and interactive documentation with Swagger UI/Redoc. Use when designing REST API contracts, writing OpenAPI specs, generating API stubs, configuring spectral linting, or documenting APIs with Swagger UI. Trigger: OpenAPI spec, REST API design, spectral linting, RFC 7807, cursor pagination, Swagger UI. Do NOT trigger for: gRPC/Protobuf API design, internal service-to-service RPC contracts, GraphQL schema design."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend
  status: stable
---
# OpenAPI Expert

**REST API design with OpenAPI 3.x: contracts, versioning and validation.**

## Core Stack

- Spec: OpenAPI 3.1 (YAML/JSON)
- Docs: Swagger UI / Redoc / Scalar
- Generation: OpenAPI Generator (server stubs, client SDKs)
- Validation: spectral linting, contract testing

## API Design Principles

- Resources over RPC: `/resources/{id}/items` not `/getItems?customer=id`
- HTTP methods: GET(read), POST(create), PUT(replace), PATCH(partial update), DELETE(remove)
- Status codes: 200/201(success), 400(validation), 401(auth), 403(forbidden), 404(not found), 409(conflict), 422(unprocessable), 429(rate limit), 500(server error)
- Versioning: URL path (`/v1/`, `/v2/`) or `Accept` header

## Idempotency

```
POST /v1/items
Idempotency-Key: key_abc123
```
- Idempotent operations: GET, PUT, DELETE (by spec)
- POST with `Idempotency-Key` header for item creation
- Return stored response for duplicate keys within window (24h)

## Pagination

```yaml
# Cursor-based (preferred for large datasets)
GET /v1/items?cursor=abc123&limit=50
Response: { data: [...], next_cursor: "def456", has_more: true }

# Offset-based (simple, small datasets only)
GET /v1/items?offset=20&limit=10
Response: { data: [...], total: 100, offset: 20, limit: 10 }
```

- Cursor-based for datasets > 1000 items or frequently-inserted data
- Offset-based for admin UIs where jumping pages is needed

## Error Format (RFC 7807)

```json
{
  "type": "https://api.example.com/errors/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "The request of 1000 units exceeds available value of 500 units",
  "instance": "/v1/items/req_abc123",
  "request_id": "req_xyz789",
  "code": "VALIDATION_ERROR"
}
```

- `type`: URL to error documentation. `code`: machine-readable enum.
- NEVER expose stack traces or internal errors in `detail`.

## OpenAPI Spec Example

```yaml
openapi: 3.1.0
info:
  title: team Items API
  version: 1.0.0
paths:
  /v1/items:
    post:
      summary: Create an item
      parameters:
        - in: header
          name: Idempotency-Key
          schema: { type: string }
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [quantity, type]
              properties:
                quantity: { type: integer, minimum: 1, description: "Quantity" }
                type: { type: string, enum: [standard, premium, enterprise] }
      responses:
        "201":
          description: Item created
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ItemResponse"
```

## Constraints

- NEVER use GET for state-changing operations (create/update/delete)
- NEVER use 200 for creation errors (400/422, not 200 with `error: true`)
- NEVER include secrets, tokens, or PII in error messages
- ALWAYS use `application/json` for request/response bodies
- ALWAYS include `request_id` in error responses for debugging
- ALWAYS version APIs (never change contract without version bump)
- NEVER remove or rename fields in active API versions (additive only)

## Overview

OpenAPI 3.x defines REST API contracts for cloud-native services with resource-oriented design, cursor-based pagination, RFC 7807 errors, and idempotency patterns. This skill covers spec design, versioning, validation with spectral, and stub generation.

## Quick Reference

| Pattern | Implementation | Purpose |
|---|---|---|
| Idempotency | `Idempotency-Key` header on POST | Safe retry for item creation |
| Pagination | Cursor-based (`cursor` + `limit`) | Scale for large datasets |
| Errors | RFC 7807 `Problem Details` | Structured error responses |
| Versioning | URL path (`/v1/`, `/v2/`) | Backward-incompatible changes |

## Workflow

1. Identify resource boundaries and define paths using nouns over verbs
2. Choose appropriate HTTP methods: GET (read), POST (create), PUT (replace), DELETE (remove)
3. Define request/response schemas with `$ref` for reusable components
4. Add `Idempotency-Key` header on mutating POST endpoints
5. Implement RFC 7807 error responses with `type`, `title`, `status`, `detail`, `code`
6. Add pagination parameters — cursor-based for large datasets, offset for admin UIs
7. Validate spec with `spectral lint` and run contract tests before deployment
8. Never remove or rename fields in active versions — additive changes only

## Anti-patterns

FAIL: Using GET for state-changing operations
PASS: Use POST for creates, PUT for replacements, DELETE for removals

```yaml
# FAIL:
GET /deleteItem?id=123

# PASS:
DELETE /v1/items/123
```

FAIL: Returning 200 with `{"error": true}` for validation failures
PASS: Use proper 4xx status codes

```json
// FAIL:
HTTP 200
{"error": true, "message": "validation failed"}

// PASS:
HTTP 422
{"type": "https://api.example.com/errors/validation-error", "title": "Validation failed", "status": 422, "detail": "Value: 500 units, required: 1000 units"}
```

FAIL: Exposing internal stack traces in error responses
PASS: Always return sanitized, user-facing messages

```json
// FAIL:
{"error": "java.lang.NullPointerException at com.example.items.ItemService.process(ItemService.java:42)"}

// PASS:
{"type": "https://api.example.com/errors/internal-error", "title": "Internal server error", "status": 500, "request_id": "req_abc123"}
```

## References

- [OpenAPI Specification 3.1](https://spec.openapis.org/oas/v3.1.0) (last_verified: 2026-05-25)
- [RFC 7807 Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc7807) (last_verified: 2026-05-25)
- [Spectral API Linting](https://docs.stoplight.io/docs/spectral/674b27b261c3e-overview) (last_verified: 2026-05-25)

- [references/error-format.md](references/error-format.md)
- [references/pagination.md](references/pagination.md)

## Verification Checklist

- [ ] Paths use nouns over verbs (`/resources/{id}/items` not `/getItems`)
- [ ] `Idempotency-Key` header defined on all mutating POST endpoints
- [ ] RFC 7807 error responses used with `type`, `title`, `status`, `detail`, `code`
- [ ] Pagination strategy chosen: cursor-based for large datasets, offset for admin UIs
- [ ] API versions in URL path (`/v1/`, `/v2/`) — additive changes only in active versions
- [ ] Spec passes `spectral lint` with no errors
- [ ] GET requests never cause state changes

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Client gets `415 Unsupported Media Type` | `Content-Type` not declared in requestBody schema | Add `application/json` to request body content type list in spec |
| Generated stub missing endpoints | OpenAPI spec had syntax errors before generation | Run `spectral lint` and `openapi-generator validate` before code generation |
| `Idempotency-Key` header ignored by server | Parameter declared in spec but not read by handler | Add middleware to extract `Idempotency-Key` from request headers |
| Known issue: `openapi-generator` produces invalid client SDK for `oneOf` discriminator mappings | Generated code uses incorrect type mapping for polymorphic schemas with `oneOf` + `discriminator` | Prefer `allOf` composition over `oneOf` discriminator for spec-first codegen; verify generated types against manual test |

| [WARN] `openapi-generator` generates wrong enum names for values with hyphens | Code generator converts hyphens to underscores inconsistently; enum constant naming is fragile | Use `x-enum-varnames` extension to pin enum constant names; avoid hyphens in enum values |
