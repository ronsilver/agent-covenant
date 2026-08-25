#!/usr/bin/env python3
"""Attempt-schema validation for the opencode benchmark harness. Stdlib only.

The authoritative attempt schema is defined by the plan; this module encodes
its required fields, type rules, and nullable-timestamp contract. metrics.py
re-exports validate_attempt so the canonical pure-metrics module keeps the
full plan-named helper surface.
"""

import re
from datetime import datetime

SCHEMA_KEYS = (
    "record_type",
    "batch_id",
    "logical_run_id",
    "attempt_id",
    "attempt_index",
    "retry_of_attempt_id",
    "retry_reason",
    "mode",
    "prompt_id",
    "prompt_file",
    "snapshot_path",
    "snapshot_sha256",
    "source_prompt_sha256",
    "snapshot_read_only",
    "started_at",
    "finished_at",
    "timeout_s",
    "timed_out",
    "wall_ms",
    "first_token_ms",
    "exit_code",
    "session_id",
    "input_raw",
    "cache_read",
    "cache_write",
    "reasoning",
    "output",
    "billable_input",
    "tokens_total",
    "cost_usd",
    "cost_estimate_usd",
    "reserved_cost_usd",
    "released_cost_usd",
    "cost_state",
    "quality_score",
    "instruction_adherence",
    "success_rate",
    "model_refusal",
    "stdout_path",
    "stderr_path",
    "raw_events_path",
    "token_source",
    "error_count",
)

INT_GE0 = (
    "attempt_index",
    "wall_ms",
    "exit_code",
    "input_raw",
    "cache_read",
    "cache_write",
    "reasoning",
    "output",
    "billable_input",
    "tokens_total",
    "error_count",
)
# first_token_ms uses -1 as the "no first token observed" sentinel.
FIRST_TOKEN_ALLOWED = {-1}
FLOAT_GE0 = (
    "cost_usd",
    "cost_estimate_usd",
    "reserved_cost_usd",
    "released_cost_usd",
    "quality_score",
    "instruction_adherence",
    "success_rate",
)

MODES = ("context", "baseline")
PROMPT_IDS = ("p1", "p2", "p3", "p4", "p5")
COST_STATES = ("reserved", "committed", "released", "not_reserved")
TOKEN_SOURCES = ("export", "event_stream")


def is_finite(value):
    """True only for finite numeric values (rejects NaN and infinities)."""
    if isinstance(value, bool):
        return False
    try:
        return float(value) == float(value) and abs(float(value)) != float("inf")
    except (TypeError, ValueError):
        return False


def _is_iso_utc(value):
    if not isinstance(value, str) or not value:
        return False
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return False
    return parsed.tzinfo is not None and parsed.utcoffset() is not None


def _check_first_token(record, errors):
    value = record.get("first_token_ms")
    if not isinstance(value, int) or isinstance(value, bool):
        errors.append("first_token_ms must be an int")
    elif value < 0 and value not in FIRST_TOKEN_ALLOWED:
        errors.append("first_token_ms must be >= 0 or the -1 sentinel")


def _check_required_fields(record, errors):
    for key in SCHEMA_KEYS:
        if key not in record:
            errors.append(f"missing field: {key}")
    if record.get("record_type") != "attempt":
        errors.append("record_type must be 'attempt'")
    for key in ("batch_id", "logical_run_id", "attempt_id"):
        if not isinstance(record.get(key), str) or not record.get(key):
            errors.append(f"{key} must be a non-empty string")
    if record.get("mode") not in MODES:
        errors.append(f"mode must be one of {MODES}")
    if record.get("prompt_id") not in PROMPT_IDS:
        errors.append(f"prompt_id must be one of {PROMPT_IDS}")


def _check_paths_and_types(record, errors):
    for key in (
        "prompt_file",
        "snapshot_path",
        "stdout_path",
        "stderr_path",
        "raw_events_path",
    ):
        if not isinstance(record.get(key), str) or not record.get(key):
            errors.append(f"{key} must be a non-empty string")
    for key in ("retry_of_attempt_id", "retry_reason", "session_id"):
        value = record.get(key)
        if value is not None and not isinstance(value, str):
            errors.append(f"{key} must be string or null")
    for key in ("snapshot_sha256", "source_prompt_sha256"):
        value = record.get(key)
        if not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{64}", value):
            errors.append(f"{key} must be a 64-char hex string")
    for key in ("snapshot_read_only", "timed_out", "model_refusal"):
        if not isinstance(record.get(key), bool):
            errors.append(f"{key} must be bool")


def _check_numbers(record, errors):
    for key in INT_GE0:
        value = record.get(key)
        if not isinstance(value, int) or isinstance(value, bool) or value < 0:
            errors.append(f"{key} must be an int >= 0")
    _check_first_token(record, errors)
    for key in FLOAT_GE0:
        value = record.get(key)
        if value is None or not is_finite(value) or float(value) < 0.0:
            errors.append(f"{key} must be a finite float >= 0")
    for key in ("quality_score", "instruction_adherence", "success_rate"):
        value = record.get(key)
        if value is not None:
            numeric = float(value)
            if numeric < 0.0 or numeric > 1.0:
                errors.append(f"{key} must be within [0, 1]")
    timeout_s = record.get("timeout_s")
    if timeout_s is None or not is_finite(timeout_s) or float(timeout_s) <= 0.0:
        errors.append("timeout_s must be finite and > 0")
    if record.get("cost_state") not in COST_STATES:
        errors.append(f"cost_state must be one of {COST_STATES}")
    if record.get("token_source") not in TOKEN_SOURCES:
        errors.append(f"token_source must be one of {TOKEN_SOURCES}")


def _check_timestamps(record, errors):
    started, finished = record.get("started_at"), record.get("finished_at")
    if started is None and finished is None:
        return  # pre-launch record: both timestamps null is allowed
    if started is None or finished is None:
        errors.append("a launched attempt requires both timestamps")
        return
    if not _is_iso_utc(started) or not _is_iso_utc(finished):
        errors.append("timestamps must be ISO-8601 UTC")
    elif finished < started:
        errors.append("finished_at must be >= started_at")


def validate_attempt(record):
    """Return a list of schema errors; empty list means the record is valid."""
    errors = []
    if not isinstance(record, dict):
        return ["record is not a dict"]
    _check_required_fields(record, errors)
    _check_paths_and_types(record, errors)
    _check_numbers(record, errors)
    _check_timestamps(record, errors)
    return errors
