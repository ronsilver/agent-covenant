# TDD (Test-Driven Development) Workflow

## Red-Green-Refactor Cycle
```
1. RED: Write a failing test that specifies desired behavior
2. GREEN: Write minimal code to make test pass
3. REFACTOR: Clean up code while tests stay green
4. REPEAT
```

## Example: Shipment Fee Calculation
### Step 1: RED
```go
func TestCalculateFee(t *testing.T) {
    got := CalculateFee(10000) // 100.00 units
    want := 350                // 3.5% rate in units
    if got != want {
        t.Errorf("CalculateFee(10000) = %d, want %d", got, want)
    }
}
// FAIL: CalculateFee not defined
```

### Step 2: GREEN
```go
func CalculateFee(amountCents int) int {
    return int(float64(amountCents) * 0.035)
}
// PASS (but uses float for money — refactor next)
```

### Step 3: REFACTOR
```go
func CalculateFee(amountCents int) int {
    return amountCents * 35 / 1000  // integer math, no float
}
// PASS with safer implementation
```

## TDD Rules
- Write test FIRST (not after implementation)
- Only write enough production code to pass the test
- Only refactor when all tests are green
- Each cycle: 2-5 minutes
- NEVER skip red phase (write test, watch it fail)
- NEVER write more code than needed for current test

## Test First Benefits
- Forces interface design before implementation
- Built-in regression suite (every feature has tests)
- Higher test coverage naturally
- Catches edge cases early (you think about them when writing tests)
- Prevents over-engineering (only code needed for tests)

## When NOT to TDD
- Exploratory/prototype code (tests would slow iteration)
- UI layout tweaks (visual tests are better post-hoc)
- Configuration/deployment scripts (test via dry-run)
- Third-party integration exploration (test against real API first)
