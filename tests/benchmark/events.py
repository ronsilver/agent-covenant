#!/usr/bin/env python3
"""Parse the ``opencode run --format json`` event stream and normalize usage
for the opencode benchmark harness. Stdlib only.

Events are newline-delimited JSON objects. Usage accounting comes from
``step_finish`` events, whose ``part.tokens`` object carries per-step
``input`` (fresh, non-cached), ``output``, ``reasoning``, and
``cache.read``/``cache.write`` counts. opencode reports per-step usage, so
totals are the sum across steps; the probe fails closed on mixed or
ambiguous granularity rather than guessing totals. Missing usage is never
silently converted to zero.
"""

import json
from pathlib import Path

USAGE_TOTAL_KEYS = ("input_raw", "cache_read", "cache_write", "reasoning", "output")


class UsageError(ValueError):
    """Raised when the event-stream usage is missing, incomplete, or ambiguous."""


def parse_event_lines(text):
    """Parse newline-delimited JSON text into a list of event dicts.

    Non-JSON lines are skipped (stray warnings); lines that parse to non-dict
    values are skipped as well."""
    events = []
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except ValueError:
            continue
        if isinstance(obj, dict):
            events.append(obj)
    return events


def read_events_file(path):
    """Read a raw-events JSONL file into a list of event dicts."""
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return parse_event_lines(handle.read())


def write_events_file(path, events):
    """Write event dicts as one JSON object per line."""
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        for event in events:
            handle.write(json.dumps(event, ensure_ascii=False) + "\n")


def _as_int(value, name):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise UsageError(f"step_finish usage field {name!r} must be numeric")
    number = float(value)
    if number < 0.0:
        raise UsageError(f"step_finish usage field {name!r} must be >= 0")
    return int(number)


def _usage_of(event):
    """Normalized usage dict for one step_finish event, or None when the event
    does not carry usage tokens."""
    if not isinstance(event, dict) or event.get("type") != "step_finish":
        return None
    part = event.get("part")
    tokens = part.get("tokens") if isinstance(part, dict) else None
    if not isinstance(tokens, dict):
        tokens = event.get("tokens")
    if not isinstance(tokens, dict):
        return None
    input_value = tokens.get("input")
    output_value = tokens.get("output")
    if input_value is None or output_value is None:
        return None
    cache = tokens.get("cache")
    cache_read = (
        cache.get("read") if isinstance(cache, dict) else tokens.get("cache_read", 0)
    )
    cache_write = (
        cache.get("write") if isinstance(cache, dict) else tokens.get("cache_write", 0)
    )
    raw_input = _as_int(input_value, "input")
    output = _as_int(output_value, "output")
    read_tokens = _as_int(cache_read, "cache.read")
    write_tokens = _as_int(cache_write, "cache.write")
    reasoning_tokens = _as_int(tokens.get("reasoning", 0), "reasoning")
    return {
        "input_raw": raw_input + read_tokens + write_tokens,
        "cache_read": read_tokens,
        "cache_write": write_tokens,
        "reasoning": reasoning_tokens,
        "output": output,
    }


def _sum_usage(usages):
    return {key: sum(usage[key] for usage in usages) for key in USAGE_TOTAL_KEYS}


def normalize_usage(events):
    """Return ``(totals, granularity)`` from step_finish usage events.

    Granularity detection: a single usage event yields its own totals
    (``single``); when the last event equals the elementwise sum of all events
    the usage is cumulative and the last event is authoritative; when the sum
    strictly exceeds the last event the usage is per-step and totals are the
    sum. A step_finish without usage tokens, an empty stream, or any other
    mixed or ambiguous shape raises UsageError (fail closed, no guessed
    totals)."""
    usages = []
    for event in events:
        if not isinstance(event, dict) or event.get("type") != "step_finish":
            continue
        usage = _usage_of(event)
        if usage is None:
            raise UsageError("step_finish event missing usage tokens")
        usages.append(usage)
    if not usages:
        raise UsageError("no step_finish usage events found")
    if len(usages) == 1:
        return dict(usages[0]), "single"
    totals = _sum_usage(usages)
    last = usages[-1]
    if all(last[key] == totals[key] for key in USAGE_TOTAL_KEYS):
        return dict(last), "cumulative"
    if all(totals[key] >= last[key] for key in USAGE_TOTAL_KEYS) and any(
        totals[key] > last[key] for key in USAGE_TOTAL_KEYS
    ):
        return totals, "per-step"
    raise UsageError("ambiguous usage granularity (mixed cumulative/per-step)")


def first_event_timestamp(events):
    """Return the first event's Unix millisecond timestamp, or None."""
    for event in events:
        timestamp = event.get("timestamp")
        if isinstance(timestamp, bool):
            continue
        if isinstance(timestamp, (int, float)) and timestamp > 0:
            return int(timestamp)
    return None


def session_id_of(events):
    """Return the first non-empty sessionID carried by the event stream.

    opencode assigns the session id; ``--session`` only continues an existing
    session, so a fresh run's id is read back from the stream. Returns None
    when no event carries one."""
    for event in events:
        value = event.get("sessionID") if isinstance(event, dict) else None
        if isinstance(value, str) and value:
            return value
    return None
