#!/usr/bin/env python3
"""Attempt-record factory for the opencode benchmark harness. Stdlib only.

Builds authoritative attempt records (the single plan-defined schema) for the
runner. The record shape lives in schema.py; this module only fills values.

Token accounting (documented micro-decisions): ``input_raw`` = fresh input +
cache read + cache write (opencode reports fresh input separately), so
``billable_input`` = ``input_raw - cache_read - cache_write`` and
``tokens_total`` = ``input_raw + output`` (matches opencode ``tokens.total``
semantics; the plan defines only the billable formula). Cost uses the flat
estimate rates from metrics.py. When the event stream is missing or ambiguous
the record fails closed (error_count=1, token_source=event_stream) instead of
silently reporting zero usage.
"""

import time
from datetime import datetime, timezone

import metrics
import preflight
from events import UsageError, first_event_timestamp, normalize_usage
from quality import REFUSAL_MARKERS, score_adherence, score_quality, score_success
from schema import SCHEMA_KEYS

PROMPT_FILES = {
    "p1": "p1-manifest.md",
    "p2": "p2-create-skill.md",
    "p3": "p3-review-script.md",
    "p4": "p4-subagent-flow.md",
    "p5": "p5-validate-content.md",
}


def _timestamp():
    return datetime.now(timezone.utc).isoformat()


def _identity_fields(ctx, attempt_id, started, finished):
    return {
        "record_type": "attempt",
        "batch_id": ctx.batch_id,
        "logical_run_id": f"{ctx.mode}-{ctx.prompt_id}-{ctx.run_idx}",
        "attempt_id": attempt_id,
        "attempt_index": 0,
        "retry_of_attempt_id": None,
        "retry_reason": None,
        "mode": ctx.mode,
        "prompt_id": ctx.prompt_id,
        "prompt_file": f"tests/benchmark/prompts/{PROMPT_FILES[ctx.prompt_id]}",
        "snapshot_path": f"{ctx.snapshot_path}/{PROMPT_FILES[ctx.prompt_id]}",
        "snapshot_sha256": ctx.snapshot_sha256,
        "source_prompt_sha256": preflight.file_sha256(
            preflight.PROMPTS_DIR / PROMPT_FILES[ctx.prompt_id]
        ),
        "snapshot_read_only": True,
        "started_at": started,
        "finished_at": finished,
        "timeout_s": ctx.timeout_s,
    }


def _stdout_text(result):
    with open(result["stdout_path"], "r", encoding="utf-8", errors="replace") as handle:
        return handle.read()


def _usage_fields(result):
    """Real usage from the event stream; fail closed when parsing fails."""
    events = result.get("events") or []
    try:
        totals, _granularity = normalize_usage(events)
    except UsageError:
        return {
            "input_raw": 0,
            "cache_read": 0,
            "cache_write": 0,
            "reasoning": 0,
            "output": 0,
            "billable_input": 0,
            "tokens_total": 0,
            "cost_usd": 0.0,
            "error_count": 1,
        }
    raw_input = totals["input_raw"]
    cache_read = totals["cache_read"]
    cache_write = totals["cache_write"]
    output = totals["output"]
    billable = metrics.normalize_token_usage(raw_input, cache_read, cache_write)
    return {
        "input_raw": raw_input,
        "cache_read": cache_read,
        "cache_write": cache_write,
        "reasoning": totals["reasoning"],
        "output": output,
        "billable_input": billable,
        "tokens_total": raw_input + output,
        "cost_usd": metrics.estimate_cost_usd(billable, output),
        "error_count": 0,
    }


def _quality_fields(prompt_id, text):
    lowered = text.lower()
    return {
        "quality_score": score_quality(prompt_id, text),
        "instruction_adherence": score_adherence(prompt_id, text),
        "model_refusal": any(marker in lowered for marker in REFUSAL_MARKERS),
    }


def _first_token_ms(events, started_epoch_ms):
    event_ts = first_event_timestamp(events) if events else None
    if event_ts is None:
        return -1
    return max(0, event_ts - started_epoch_ms)


def new_attempt(ctx, snapshot, result):
    """Build one authoritative attempt record from a run context."""
    attempt_id = f"{ctx.mode}-{ctx.prompt_id}-{ctx.run_idx}-{ctx.attempt_suffix}"
    now_ms = int(time.time() * 1000)
    started_epoch_ms = now_ms - result["wall_ms"]
    started = datetime.fromtimestamp(
        started_epoch_ms / 1000.0, tz=timezone.utc
    ).isoformat()
    finished = _timestamp()
    record = _identity_fields(ctx, attempt_id, started, finished)
    text = _stdout_text(result)
    usage = _usage_fields(result)
    quality = _quality_fields(ctx.prompt_id, text)
    events = result.get("events") or []
    events_path = result.get("events_path") or (
        f"{ctx.out_dir}/raw/{ctx.mode}-{ctx.prompt_id}-{ctx.run_idx}.jsonl"
    )
    record.update(
        {
            "timed_out": result["timed_out"],
            "wall_ms": result["wall_ms"],
            "first_token_ms": _first_token_ms(events, started_epoch_ms),
            "exit_code": result["exit_code"],
            "session_id": result.get("session_id"),
            "input_raw": usage["input_raw"],
            "cache_read": usage["cache_read"],
            "cache_write": usage["cache_write"],
            "reasoning": usage["reasoning"],
            "output": usage["output"],
            "billable_input": usage["billable_input"],
            "tokens_total": usage["tokens_total"],
            "cost_usd": usage["cost_usd"],
            "cost_estimate_usd": usage["cost_usd"],
            "reserved_cost_usd": 0.0,
            "released_cost_usd": 0.0,
            "cost_state": "not_reserved",
            "quality_score": quality["quality_score"],
            "instruction_adherence": quality["instruction_adherence"],
            "model_refusal": quality["model_refusal"],
            "stdout_path": result["stdout_path"],
            "stderr_path": result["stderr_path"],
            "raw_events_path": events_path,
            "token_source": "event_stream",
            "error_count": usage["error_count"],
        }
    )
    record["stdout_text"] = text
    record["success_rate"] = score_success(ctx.prompt_id, record)
    return {key: record.get(key) for key in SCHEMA_KEYS}
