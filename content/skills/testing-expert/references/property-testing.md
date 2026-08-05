# Property-Based Testing

## Python (Hypothesis)
```python
from hypothesis import given, strategies as st

@given(
    value=st.integers(min_value=1, max_value=99999999),
    unit=st.sampled_from(["metric", "imperial"])
)
def test_convert_never_negative(value, unit):
    result = convert_value(value, unit)
    assert result >= 0

def test_convert_is_idempotent(value, unit):
    first = convert_value(value, unit)
    second = convert_value(value, unit)
    assert first == second
```

## Go (rapid)
```go
import "pgregory.net/rapid"

func TestConvertProperties(t *testing.T) {
    rapid.Check(t, func(t *rapid.T) {
        value := rapid.IntRange(1, 99999999).Draw(t, "value")
        unit := rapid.SampledFrom([]string{"metric","imperial"}).Draw(t, "unit")
        result := ConvertValue(value, unit)
        if result < 0 { t.Fatal("negative result") }
    })
}
```

## Flaky Test Detection
- Run test 10+ times: `pytest --count=10 test_orders.py`
- Tag `@flaky` for known issues
- Common causes: shared state, time dependency, external services
