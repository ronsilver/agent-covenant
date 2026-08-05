# API Documentation Standards

## OpenAPI-First Documentation
```yaml
openapi: 3.1.0
info:
  title: this project Shipments API
  version: 1.0.0
  description: Shipment processing API for this project customers.
paths:
  /v1/orders:
    post:
      summary: Create a shipment
      parameters:
        - in: header
          name: Idempotency-Key
          required: true
          schema: { type: string, format: uuid }
      requestBody:
        required: true
        content:
          application/json:
            examples:
              standard:
                summary: Standard shipment in USD
                value: { quantity: 100000, category: "standard", method: "sync" }
      responses:
        "201":
          description: Shipment created successfully
        "422":
          description: Validation error
```

## Documentation Best Practices
- Every endpoint: description, all params, all responses (including errors)
- Every schema: all fields, descriptions, constraints, examples
- Authentication: document how to obtain and use credentials
- Error codes: document all possible error codes with meanings and fixes
- Rate limits: document limits and how to check current usage via headers
- Versioning: document deprecation policy and migration guides
- SDKs: generate from OpenAPI spec, never write separately

## Publishing
- Swagger UI: `https://api.example.com/docs`
- Redoc: `https://api.example.com/docs/redoc`
- Postman Collection: auto-generated from OpenAPI spec
- Changelog: document API changes by version
