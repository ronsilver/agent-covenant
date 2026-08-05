# Go Testing & Linting Patterns

## Table-Driven Tests (MANDATORY)

```go
func TestProcessShipment(t *testing.T) {
    tests := []struct {
        name    string
        input   ShipmentRequest
        want    ShipmentResponse
        wantErr bool
    }{
        {name: "valid quantity shipment", input: ShipmentRequest{Quantity: 1000, Currency: "USD"}, want: ShipmentResponse{Status: "label_created"}},
        {name: "zero quantity", input: ShipmentRequest{Quantity: 0, Currency: "USD"}, wantErr: true},
        {name: "unsupported currency", input: ShipmentRequest{Quantity: 1000, Currency: "EUR"}, wantErr: true},
    }
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

## Benchmarks

```go
func BenchmarkProcessShipment(b *testing.B) {
    svc := setupService()
    req := ShipmentRequest{Quantity: 1000, Currency: "USD"}
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        svc.Process(context.Background(), req)
    }
}
```

Run: `go test -bench=. -benchmem -count=5`

## Race Detector

`go test -race ./...` — ALWAYS in CI. Never skip for concurrency-sensitive code.

## Golden Chain (Pre-commit)

```bash
go fmt ./...
golangci-lint run --timeout=5m
go vet ./...
go test -race -cover ./...
gosec ./...
```

## Common Linter Rules

```yaml
# .golangci.yml
linters:
  enable:
    - errcheck    # check ignored errors
    - gosimple    # simplify code
    - govet       # vet reports
    - ineffassign # ineffectual assignments
    - staticcheck # static analysis
    - unused      # unused code
    - gosec       # security checks
    - bodyclose   # HTTP response body must be closed
    - contextcheck # verify context propagation
```
