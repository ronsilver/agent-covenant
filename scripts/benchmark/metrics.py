#!/usr/bin/env python3
"""Pure metrics, token normalization, aggregation, and cost reservation helpers
for the opencode benchmark harness. Stdlib only; no I/O except what callers
pass in. Attempt-schema validation lives in schema.py and is re-exported here
so this module keeps the full plan-named helper surface.
"""

from schema import MODES, PROMPT_IDS, is_finite, validate_attempt

__all__ = [
    "DERIVED_METRICS",
    "MODES",
    "PROMPT_IDS",
    "RAW_METRICS",
    "aggregate",
    "can_reserve",
    "commit",
    "compute_derived",
    "delta_pct",
    "estimate_cost_usd",
    "iqr",
    "is_finite",
    "median",
    "median_iqr",
    "normalize_token_usage",
    "ratio",
    "release",
    "reserve_attempt",
    "validate_attempt",
    "validate_cap",
]

RAW_METRICS = [
    "billable_input",
    "cache_read",
    "cache_write",
    "reasoning",
    "output",
    "tokens_total",
    "cost_usd",
    "wall_ms",
    "first_token_ms",
    "quality_score",
    "instruction_adherence",
    "success_rate",
]

DERIVED_METRICS = [
    "quality_per_billable_input",
    "quality_per_cost",
    "tokens_per_second",
    "cost_per_success",
    "tokens_per_success",
]

# Estimate constants used only when the export does not carry a cost value.
ESTIMATED_INPUT_RATE_USD_PER_1K = 0.0008
ESTIMATED_OUTPUT_RATE_USD_PER_1K = 0.0016


class SchemaError(ValueError):
    """Raised for invalid attempt records or malformed metric input."""


def median(values):
    """Median of a sequence; empty input yields 0.0."""
    vals = sorted(float(v) for v in values)
    n = len(vals)
    if n == 0:
        return 0.0
    if n % 2 == 1:
        return vals[n // 2]
    return (vals[n // 2 - 1] + vals[n // 2]) / 2.0


def _pctl(values, q):
    """Linear-interpolation percentile (numpy-style) over sorted values."""
    vals = sorted(float(v) for v in values)
    n = len(vals)
    if n == 0:
        return 0.0
    if n == 1:
        return vals[0]
    rank = q * (n - 1)
    lo = int(rank)
    frac = rank - lo
    if lo + 1 >= n:
        return vals[-1]
    return vals[lo] + frac * (vals[lo + 1] - vals[lo])


def iqr(values):
    """Interquartile range (Q3 - Q1); empty input yields 0.0."""
    if not values:
        return 0.0
    return _pctl(values, 0.75) - _pctl(values, 0.25)


def median_iqr(values):
    """Return (median, iqr); empty input yields (0.0, 0.0)."""
    if not values:
        return 0.0, 0.0
    return median(values), iqr(values)


def delta_pct(base, current):
    """Percentage delta from base to current; zero base yields 0.0."""
    if not is_finite(base) or not is_finite(current):
        raise ValueError("delta_pct requires finite values")
    if base == 0.0:
        return 0.0
    return (current - base) / base * 100.0


def ratio(a, b):
    """a / b; zero denominator yields 0.0 (deterministic, no exception)."""
    if not is_finite(a) or not is_finite(b):
        raise ValueError("ratio requires finite values")
    if b == 0.0:
        return 0.0
    return a / b


def normalize_token_usage(input_raw, cache_read, cache_write):
    """billable_input = input_raw - cache_read - cache_write; rejects missing,
    negative, or non-finite values by raising SchemaError."""
    for name, value in (
        ("input_raw", input_raw),
        ("cache_read", cache_read),
        ("cache_write", cache_write),
    ):
        if not is_finite(value) or float(value) < 0.0:
            raise SchemaError(f"invalid token value for {name}: {value!r}")
    billable = float(input_raw) - float(cache_read) - float(cache_write)
    if billable < 0.0:
        raise SchemaError(f"negative billable_input: {billable}")
    return billable


def estimate_cost_usd(billable_input, output):
    """Estimated USD cost for an attempt using the documented flat rates.

    ``billable_input`` excludes cache reads/writes; ``output`` is charged at
    the output rate. Returns a float; non-finite or negative inputs raise
    SchemaError."""
    for name, value in (("billable_input", billable_input), ("output", output)):
        if not is_finite(value) or float(value) < 0.0:
            raise SchemaError(f"invalid token value for {name}: {value!r}")
    return (
        float(billable_input) / 1000.0 * ESTIMATED_INPUT_RATE_USD_PER_1K
        + float(output) / 1000.0 * ESTIMATED_OUTPUT_RATE_USD_PER_1K
    )


def compute_derived(metrics_dict):
    """Compute the 5 derived metrics from a dict of raw metric values."""

    def raw(name, default=0.0):
        value = metrics_dict.get(name, default)
        return float(value) if is_finite(value) else default

    billable = raw("billable_input")
    cost = raw("cost_usd")
    quality = raw("quality_score")
    wall_ms = raw("wall_ms")
    total = raw("tokens_total")
    success = raw("success_rate")
    return {
        "quality_per_billable_input": ratio(quality, billable),
        "quality_per_cost": ratio(quality, cost),
        "tokens_per_second": ratio(total, wall_ms / 1000.0),
        "cost_per_success": ratio(cost, success),
        "tokens_per_success": ratio(total, success),
    }


def aggregate(values, token_source="event_stream", event_aggregation="per-step"):
    """Aggregate cell values while recording where they came from."""
    med, iqr_val = median_iqr(values)
    return {
        "median": med,
        "iqr": iqr_val,
        "token_source": token_source,
        "event_aggregation": event_aggregation,
    }


def validate_cap(cap):
    """Validate a cost cap is present, finite, and non-negative."""
    if cap is None or cap == 0.0:
        return
    if not is_finite(cap) or float(cap) < 0.0:
        raise SchemaError(f"invalid cost cap: {cap!r}")


def can_reserve(cap, observed_cost, reserved_cost, estimate):
    """observed_cost + reserved_cost + estimate <= cap (cap 0 disables)."""
    if cap is None or cap == 0.0:
        return True
    return (float(observed_cost) + float(reserved_cost) + float(estimate)) <= float(cap)


def reserve_attempt(cap, observed_cost, reserved_cost, estimate):
    """Reserve an estimate; raises SchemaError when the cap would be exceeded."""
    validate_cap(cap)
    if not can_reserve(cap, observed_cost, reserved_cost, estimate):
        raise SchemaError(
            f"cap {cap} exceeded: observed={observed_cost} reserved="
            f"{reserved_cost} estimate={estimate}"
        )
    return float(reserved_cost) + float(estimate)


def commit(observed_cost, reserved_cost, actual_cost):
    """Fold actual cost into observed; return (observed, remaining reserve)."""
    return float(observed_cost) + float(actual_cost), max(
        0.0, float(reserved_cost) - float(actual_cost)
    )


def release(reserved_cost, estimate):
    """Release an unused reservation."""
    return max(0.0, float(reserved_cost) - float(estimate))
