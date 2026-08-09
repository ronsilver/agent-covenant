---
name: golang-expert
description: "Complete Go development ecosystem: concurrent microservices with Gin, gRPC/Protobuf communication, data access with GORM/pgx/example.org, OpenTelemetry instrumentation, structured logging with Zap, table-driven testing and static analysis with golangci-lint. Use when writing Go microservices, creating gRPC/Protobuf APIs, implementing data access with GORM/pgx, or setting up OpenTelemetry instrumentation. Trigger: Go microservice, gRPC Protobuf, GORM, pgx, OpenTelemetry Go, Zap logger, table-driven test, golangci-lint. Do NOT trigger for: general HTTP API design, database schema design, Dockerfile creation."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: backend
  status: stable
---
# Go Expert

**Go ecosystem: microservices, gRPC, observability, testing and linting.**

## Core Stack

- HTTP: Gin (routing, middleware, validation)
- RPC: gRPC + Protobuf (Buf, proto3, streaming)
- Data: GORM + pgx + `example.org` libs (dynamodb, sqs, sns, auth, workflow, state-machine)
- Internal: `go-kit` team (service interface, HTTP/AMQP transports, middleware)
- Logging: Zap (structured JSON)
- Tracing: OpenTelemetry (traces, metrics, context propagation)
- Testing: `go test` table-driven + Testify + benchmarks + race detector
- Linting: `golangci-lint` (vet, staticcheck, gosec, errcheck)

## Project Structure

```
cmd/server/main.go       # entry point, DI, graceful shutdown
internal/
  handler/               # HTTP handlers (thin: parse -> call service -> return)
  service/               # business logic + OTel spans
  repository/            # data access (GORM/pgx)
  model/                 # domain types
  middleware/             # RequestID, logging, recovery, auth
api/proto/               # .proto files (Buf managed)
migrations/              # SQL migration files
```

## Architecture

```
Handler -> Service -> Repository (NEVER skip layers)
```

- Handlers: thin, parse only, return status codes
- Service: business logic + OTel spans (`tracer.Start(ctx, "Op")`)
- Repository: data access with `context.Context`
- ALWAYS propagate `context.Context` through all layers
- NEVER business logic in handlers | NEVER repo from handler directly
- ALWAYS `WithContext(ctx)` on GORM | ALWAYS wrap errors with `fmt.Errorf("op: %w", err)`

## gRPC / Protobuf

```protobuf
syntax = "proto3";
package resources.v1;
option go_package = "github.com/example/resources/gen/go/resources/v1;resourcesv1";

message ProcessRequest {
  string resource_id = 1;
  int64  quantity    = 2;  // discrete = int64 units, NEVER float
  string kind        = 3;
}
```

- `buf lint` + `buf breaking --against .git#branch=main` before merge
- Enums: ALWAYS `_UNSPECIFIED = 0` first value; never remove, mark reserved
- Field numbers 1-15 for frequent fields (1-byte encoding)
- Version packages as `service.v1`; bump to `v2` for breaking changes
- Pagination: cursor-based with `page_token`, NEVER offset-based

## OpenTelemetry

- Span naming: `POST /resource` (never include IDs)
- ALWAYS `span.RecordError(err)` on every error path
- ALWAYS propagate `context.Context`; never create root spans mid-chain
- Sampling: <=10% in production (never 100%)
- NEVER high-cardinality values as metric label keys

## Linting (Golden Chain)

```
go fmt -> golangci-lint run -> go vet -> go test -> gosec
```
Stop on first failure. Never `|| true` in CI.

## Libraries

- `example.org`: 20+ sub-modules (core, http, dynamodb, aws, bindetector, auth, workflow, security, state-machine, validator, publisher, sns, sqs, notification-sender)
- `go-kit`: toolkit HTTP/AMQP, logging, tracing — 16+ dependent services
- `goauth`: JWT integration helper
- Changes to these libs have org-wide blast radius

## Testing

```go
func TestProcessItem(t *testing.T) {
    tests := []struct {
        name    string
        input   ItemRequest
        want    ItemResponse
        wantErr bool
    }{{
        name:    "valid item",
        input:   ItemRequest{Value: 1000, Kind: "standard"},
        want:    ItemResponse{Status: "ok"},
        wantErr: false,
    }}
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := svc.Process(t.Context(), tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr = %v", err, tt.wantErr)
            }
        })
    }
}
```
- Table-driven tests always. Race detector: `go test -race ./...`
- Benchmarks for hot paths: `go test -bench=. -benchmem`

## Constraints

- NEVER business logic in handlers | NEVER repo from handler directly
- NEVER expose internal errors to clients
- NEVER reuse field numbers in proto | NEVER remove enum values
- NEVER `float`/`double` for discrete quantities — `int64` units
- ALWAYS `context.Context` | ALWAYS `WithContext(ctx)` on GORM
- ALWAYS wrap errors | ALWAYS structured logging with `trace_id`
- ALWAYS graceful shutdown with `signal.NotifyContext`
- NEVER `go fmt || true` — stop on lint failure
- NEVER hardcode secrets — use env/config with secrets manager

## Security

- ALWAYS run `gosec` in CI and `govulncheck` for dependency CVEs (supply chain, OWASP A03)
- NEVER allow SSRF (CWE-918): validate and allowlist all URLs passed to HTTP clients
- NEVER deserialize untrusted bytes into structs (CWE-502) — decode with strict schemas only
- ALWAYS pin direct and transitive dependencies; review `go mod graph` for drift

## Overview

Go microservices in this project use Gin for HTTP, gRPC+Protobuf for internal RPC, GORM/pgx for data access, and OpenTelemetry for observability. The `example.org` library suite provides shared infrastructure across 20+ services.

## Quick Reference

| Layer | Library | Responsibility |
|---|---|---|
| HTTP | Gin | Routing, middleware, validation |
| RPC | gRPC + Protobuf (Buf) | Internal service-to-service communication |
| Data | GORM + pgx + example.org | ORM, raw SQL, DynamoDB/SQS/SNS helpers |
| Observability | OpenTelemetry + Zap | Traces, metrics, structured JSON logging |
| Linting | golangci-lint (vet, staticcheck, gosec, errcheck) | Static analysis |

## Workflow

1. Define `.proto` service schema with `buf lint` + `buf breaking` check
2. Generate Go code from protos and implement gRPC server/handler
3. Implement handler layer: parse request → call service → return response
4. Implement service layer with business logic + OpenTelemetry spans
5. Implement repository layer with `context.Context` and GORM `WithContext`
6. Write table-driven tests with `go test -race ./...`
7. Run golden chain: `go fmt` → `golangci-lint run` → `go vet` → `go test` → `gosec`

## Anti-patterns

FAIL: Business logic in HTTP handlers
PASS: Handlers only parse input; business logic in service layer

```go
// FAIL:
func (h *Handler) CreateItem(c *gin.Context) {
    var req ItemRequest
    if err := c.BindJSON(&req); err != nil { ... }
    if req.Value <= 0 { ... } // business logic
    result := h.db.Create(&Item{Value: req.Value}) // data access
    c.JSON(201, result)
}

// PASS:
func (h *Handler) CreateItem(c *gin.Context) {
    var req ItemRequest
    if err := c.BindJSON(&req); err != nil { ... }
    result, err := h.svc.Process(c.Request.Context(), req)
    if err != nil { ... }
    c.JSON(201, result)
}
```

FAIL: Using `float`/`double` for discrete quantities
PASS: Always use `int64` units

```go
// FAIL:
type Item struct {
    Value float64  // floating point rounding errors
}

// PASS:
type Item struct {
    Value int64  // use integer units
}
```

FAIL: Silently swallowing errors with `|| true` in CI linting
PASS: All linting steps must fail if any rule is violated

```makefile
# FAIL:
lint:
	go fmt || true
	golangci-lint run || true

# PASS:
lint:
	go fmt && golangci-lint run && go vet
```

## References

- [Effective Go](https://go.dev/doc/effective_go) (last_verified: 2026-05-25)
- [gRPC Go Documentation](https://grpc.io/docs/languages/go/) (last_verified: 2026-05-25)
- [OpenTelemetry Go](https://opentelemetry.io/docs/languages/go/) (last_verified: 2026-05-25)

- [references/concurrency.md](references/concurrency.md)
- [references/performance.md](references/performance.md)
- [references/testing.md](references/testing.md)

## Verification Checklist

- [ ] Handler layer is thin (parse request → call service → return response, no business logic)
- [ ] `context.Context` propagated through all layers (handler → service → repository)
- [ ] Discrete quantities use `int64` units (never float/double)
- [ ] gRPC protos pass `buf lint` and `buf breaking` checks
- [ ] OpenTelemetry spans created with `RecordError` on all error paths
- [ ] Table-driven tests written with `go test -race ./...` passing
- [ ] `gosec` and `govulncheck` run clean in CI (no HIGH/Critical findings)

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `sql: database is closed` | Missing `WithContext(ctx)` on GORM call | Ensure every GORM query uses `db.WithContext(ctx)` |
| gRPC `Unavailable` error | Server not registered or port mismatch | Verify `grpcServer.Serve(lis)` called with correct listener address |
| Traces not appearing in backend | Missing OTel exporter or incorrect endpoint | Check `OTEL_EXPORTER_OTLP_ENDPOINT` env var and service name in SDK init |
| Edge case: `go test -race` false positive on atomic operations | Race detector flags intentional concurrent access patterns | Use `sync/atomic` for counters; mark deliberate races with `//nolint:race` comment |

| [WARN] go-kit endpoint panics on nil request | Endpoint `DecodeRequestFunc` returns nil if decoding fails; transport sends nil to endpoint | Check `req != nil` in endpoint before passing to `next`; always wrap decode with error return |
| go.mod indirect dependency pinned to broken version by a team internal module | team internal example.org module pins a vulnerable transitive dep that cannot be upgraded | Add replace directive in go.mod; request the owning team to update their dependency version |
| Known bug: go-kit logging middleware drops context fields when logger is passed by value | go-kit logger interface used with value receiver; context fields lost between middleware layers | Always pass *log.Logger pointer; verify context fields survive middleware chain |
