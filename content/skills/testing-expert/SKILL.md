---
name: testing-expert
description: "Testing strategy design based on the Cohn test pyramid: fast unit tests with TDD (Red-Green-Refactor), integration tests with Test Doubles (mocks, stubs, fakes), contract tests with Pact, property-based testing (QuickCheck/Hypothesis), and fuzz testing. Metrics: coverage as a signal (not proof), flaky test detection, and a no-test-no-fix culture. Use when designing test strategies, implementing TDD workflows, choosing test types (unit vs integration vs E2E), configuring test infrastructure, or evaluating test suite quality. Trigger: TDD, pytest, Jest, Pact, property-based test, flaky test, coverage, test pyramid. Do NOT trigger for: writing production code, deployment pipeline setup, monitoring configuration, E2E testing (use playwright-expert), accessibility testing (use accessibility-expert), security penetration testing (use security-expert), pytest framework setup (use python-expert), Jest/Vitest configuration (use typescript-expert)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: quality
  status: stable
---
# Testing Expert

**Test strategy: TDD, test pyramid, contract testing and quality metrics.**

## Test Pyramid

```
        /\
       /E2E\        Playwright (critical flows only)
      /------\
     /Integr.\      API tests, DB tests, contract tests (Pact)
    /----------\
   /   Unit     \    Fast, isolated, TDD (90% of tests)
  /--------------\
```

## TDD — Red-Green-Refactor

1. **Red**: Write a failing test that specifies desired behavior
2. **Green**: Write minimal code to make test pass (don't over-engineer)
3. **Refactor**: Clean up code while tests stay green

```go
func TestCalculateRate(t *testing.T) {
    tests := []struct {
        name   string
        amount int64
        want   int64
    }{{
        name: "standard rate",
        amount: 10000,
        want: 350,        // calculated rate value
    }}
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := CalculateRate(tt.amount)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

## Test Doubles

| Type | Use |
|---|---|
| Stub | Fixed return values, no logic |
| Mock | Expectations + verification |
| Fake | Working implementation (in-memory DB) |
| Spy | Records calls for later verification |

```python
# Mock at network layer, never at module import
from unittest.mock import AsyncMock

async def test_item_creation():
    mock_processor = AsyncMock()
    mock_processor.process.return_value = {"status": "ok"}
    
    service = ProcessingService(client=mock_processor)
    result = await service.create_item(value=1000)
    
    assert result.status == "ok"
    mock_processor.process.assert_called_once()
```

## Contract Testing (Pact)

```
Consumer (item workflow) ----[Pact contract]----> Provider (items)

Contract: POST /v1/items
  request: { value: integer, category: string }
  response: { id: string, status: string }
```

## Property-Based Testing

```python
from hypothesis import given, strategies as st

@given(
    value=st.integers(min_value=1, max_value=9999999),
    category=st.sampled_from(["standard", "premium", "basic"])
)
def test_convert_value(value, category):
    result = convert_value(value, category)
    assert result >= 0
    assert result == value  # identity mapping for these categories
```

## Flaky Test Detection

- Run test 10+ times in CI to detect flakiness
- Tag flaky tests with `@flaky` and prioritize fixing
- Common causes: shared state, time dependency, external service instability

## Constraints

- NEVER skip test phase in pre-commit chain
- NEVER use real user data in tests (synthetic fixtures only)
- NEVER write tests that pass accidentally (asserts must be meaningful)
- ALWAYS test error paths + edge cases (not just happy path)
- ALWAYS mock at network/interface layer, never at module import level
- NEVER rely on test order (tests must be independent)

## Overview

Design test strategies based on Cohn's test pyramid: fast unit tests with TDD (Red-Green-Refactor), integration tests with test doubles, contract tests with Pact, property-based testing with Hypothesis/QuickCheck, and fuzz testing for cloud-native services.

## Quick Reference

| Test Type | Speed | Proportion | Framework |
|---|---|---|---|
| Unit | <10ms | ~90% | Go testing, pytest, Jest |
| Integration | <1s | ~8% | Testcontainers, Docker Compose |
| Contract | <5s | ~1% | Pact (consumer-driven) |
| E2E | <30s | ~1% | Playwright, Cypress |
| Property-based | varies | targeted | Hypothesis (Python), QuickCheck |

## Workflow

1. Write failing test first (Red) — specifies desired behavior
2. Write minimal code to pass (Green) — don't over-engineer
3. Refactor code while tests stay green
4. Add integration test for persistence or external API boundaries
5. Add contract test if service is consumed by another team
6. Run full test suite before committing (stop on first failure)

## Anti-patterns

FAIL: Testing implementation details instead of behavior
```go
// BAD: testing private helper count
assert.Equal(t, 3, service.calculateRateCallCount)

// GOOD: testing public behavior
result := service.CreateItem(value: 10000)
assert.Equal(t, 350, result.Rate)
```

FAIL: Using real databases in unit tests
```python
# BAD: hitting real DB in unit test
db = PostgreSQLConnection(host="localhost")
user = db.query("SELECT * FROM users")

# GOOD: mock at boundary
mock_db = AsyncMock()
mock_db.query.return_value = [{"id": 1, "name": "test"}]
```

FAIL: Writing tests that pass without meaningful assertions
```python
# BAD: no assertion
result = service.process_item(value=100)
print(result)  # manual check — not a real test

# GOOD: explicit assertion
result = service.process_item(value=100)
assert result.status == "ok"
```

## References

- Martin Fowler on test pyramid: https://martinfowler.com/bliki/TestPyramid.html (last_verified: 2026-05)
- Pact documentation: https://docs.pact.io/ (last_verified: 2026-05)
- Hypothesis documentation: https://hypothesis.readthedocs.io/ (last_verified: 2026-05)

- [references/contract-testing.md](references/contract-testing.md)
- [references/fixture-strategies.md](references/fixture-strategies.md)
- [references/property-testing.md](references/property-testing.md)
- [references/tdd-workflow.md](references/tdd-workflow.md)

## Verification Checklist

- [ ] TDD flow followed: Red (failing test) → Green (minimal code) → Refactor
- [ ] Error paths and edge cases tested (not just happy path)
- [ ] Tests mock at network/interface layer (never at module import level)
- [ ] No real user data in tests — synthetic fixtures only
- [ ] Tests are independent (no reliance on test execution order)
- [ ] Flaky tests identified by running ≥10 times in CI
- [ ] Test pyramid respected: ~90% unit, ~8% integration, ~1% contract, ~1% E2E

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Test fails intermittently (flaky) | Shared mutable state or time dependency | Isolate test data per test; use fixed timestamps; avoid wall-clock comparisons |
| Test passes locally but fails in CI | Environment mismatch (DB, timezone, file paths) | Use Testcontainers for env; match CI locale/timezone settings locally |
| Contract test fails after provider update | Provider changed API without updating Pact contract | Run `can-i-deploy` check before provider deploy; update Pact contract to match new API |
| Property-based test fails only for certain random seeds and cannot reproduce (known issue: non-deterministic failure) | Hypothesis shrinks to minimal failing case but seed not recorded | Set `--hypothesis-seed` in CI; always log seed in test output for reproduction |

| [WARN] Mock with `EXPECT_CALL` passes but real implementation throws different error (brittle mock) | Mock verifies call pattern only, not behavior; mock does not reproduce real error conditions | Add negative test cases that reproduce real error paths; use contract tests in addition to mocks |
