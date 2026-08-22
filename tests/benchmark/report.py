#!/usr/bin/env python3
"""Report renderers and writers for the opencode benchmark harness. Stdlib
only.

Exact APIs (callers must not add positional or alternate signatures):

```python
render_header(batch_meta, inventories, snapshot, verdicts)
write_summary_jsonl(path, summaries, batch_meta)
write_smoke_verdict(path, verdict)
validate_smoke_verdict(path)
```

Markdown compare tables use the 12 raw metric rows in the exact raw-list order
followed by the 5 derived rows in the exact derived-list order. Fixed report
row names are the metric names only; no aliases are accepted. Wrong record
order or extra metric names is a writer error.

The smoke verdict object has exactly 10 keys (``SMOKE_VERDICT_KEYS``):
``record_type`` (fixed "smoke"), ``batch_id``, ``marker_absent``,
``markers_found``, ``input_raw_context``, ``input_raw_baseline``,
``input_raw_ratio``, ``baseline_exit_code``, ``baseline_usage_event_valid``,
``verdict`` (one of PASS|FAIL|INCONCLUSIVE). Missing or extra keys is a
writer error.
"""

import json
from pathlib import Path

from metrics import DERIVED_METRICS, RAW_METRICS

SUMMARY_KEYS = (
    "record_type",
    "batch_id",
    "mode",
    "prompt_id",
    "logical_run_count",
    "attempt_count",
    "metrics",
    "derived",
)
BATCH_META_KEYS = (
    "record_type",
    "batch_id",
    "seed",
    "cell_order",
    "selected_prompt_ids",
    "prompt_snapshot_sha256",
    "inventories",
    "opencode_version",
    "cumulative_cost_usd",
)
SMOKE_VERDICT_KEYS = (
    "record_type",
    "batch_id",
    "marker_absent",
    "markers_found",
    "input_raw_context",
    "input_raw_baseline",
    "input_raw_ratio",
    "baseline_exit_code",
    "baseline_usage_event_valid",
    "verdict",
)
SMOKE_VERDICTS = ("PASS", "FAIL", "INCONCLUSIVE")


def _check_metric_names(metrics_dict, allowed):
    missing = [name for name in allowed if name not in metrics_dict]
    extra = [name for name in metrics_dict if name not in allowed]
    if missing or extra:
        raise ValueError(f"metric name drift: missing={missing} extra={extra}")


def render_header(batch_meta, inventories, snapshot, verdicts):
    """Render batch metadata, both inventories, snapshot, and verdicts."""
    lines = []
    lines.append(f"# Benchmark report {batch_meta.get('batch_id', '?')}")
    lines.append("")
    lines.append("## Batch metadata")
    lines.append("")
    for key in BATCH_META_KEYS:
        if key == "inventories":
            continue
        lines.append(f"- {key}: {batch_meta.get(key, '')}")
    lines.append("")
    lines.append("## Inventories")
    lines.append("")
    for mode in ("context", "baseline"):
        inv = inventories.get(mode, {})
        counts = inv.get("counts", {})
        lines.append(f"### {mode}")
        lines.append("")
        for count_key in ("rules", "skills", "subagents", "mcp_write_capable"):
            lines.append(f"- {count_key}: {counts.get(count_key, '?')}")
        lines.append(f"- valid: {inv.get('valid', False)}")
        lines.append("")
    lines.append("## Snapshot")
    lines.append("")
    lines.append(f"- path: {snapshot.get('path', '')}")
    lines.append(f"- sha256: {snapshot.get('sha256', '')}")
    lines.append(f"- read_only: {snapshot.get('read_only', '')}")
    lines.append("")
    lines.append("## Verdicts")
    lines.append("")
    for key, value in verdicts.items():
        lines.append(f"- {key}: {value}")
    lines.append("")
    return "\n".join(lines)


def _cell_summary(cell):
    metrics_part = {name: cell["metrics"].get(name) for name in RAW_METRICS}
    derived_part = {name: cell["derived"].get(name) for name in DERIVED_METRICS}
    return {
        "record_type": "cell_summary",
        "batch_id": cell.get("batch_id"),
        "mode": cell.get("mode"),
        "prompt_id": cell.get("prompt_id"),
        "logical_run_count": cell.get("logical_run_count"),
        "attempt_count": cell.get("attempt_count"),
        "metrics": metrics_part,
        "derived": derived_part,
    }


def _validate_summary(summary):
    missing = [key for key in SUMMARY_KEYS if key not in summary]
    if missing:
        raise ValueError(f"cell_summary missing keys: {missing}")
    if summary.get("record_type") != "cell_summary":
        raise ValueError("summary record_type must be 'cell_summary'")
    _check_metric_names(summary.get("metrics", {}), RAW_METRICS)
    _check_metric_names(summary.get("derived", {}), DERIVED_METRICS)


def write_summary_jsonl(path, summaries, batch_meta):
    """Write one fixed batch_meta line then fixed cell_summary lines."""
    missing = [key for key in BATCH_META_KEYS if key not in batch_meta]
    if missing or batch_meta.get("record_type") != "batch_meta":
        raise ValueError(f"batch_meta invalid: missing={missing}")
    for summary in summaries:
        _validate_summary(summary)
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        handle.write(json.dumps(batch_meta, ensure_ascii=False) + "\n")
        for summary in summaries:
            handle.write(json.dumps(_cell_summary(summary), ensure_ascii=False) + "\n")


def write_runs_jsonl(path, attempts):
    """Write the authoritative attempt records as JSONL (one per line)."""
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        handle.writelines(
            json.dumps(attempt, ensure_ascii=False) + "\n" for attempt in attempts
        )


def _validate_smoke_verdict_dict(verdict):
    if not isinstance(verdict, dict):
        raise ValueError("smoke verdict must be a JSON object")
    missing = [key for key in SMOKE_VERDICT_KEYS if key not in verdict]
    extra = [key for key in verdict if key not in SMOKE_VERDICT_KEYS]
    if missing or extra:
        raise ValueError(f"smoke verdict key drift: missing={missing} extra={extra}")
    if verdict.get("record_type") != "smoke":
        raise ValueError("smoke verdict record_type must be 'smoke'")
    if verdict.get("verdict") not in SMOKE_VERDICTS:
        raise ValueError(
            f"smoke verdict must be one of {SMOKE_VERDICTS}, "
            f"got {verdict.get('verdict')!r}"
        )


def write_smoke_verdict(path, verdict):
    """Write the smoke verdict JSON; missing or extra keys is a writer error."""
    _validate_smoke_verdict_dict(verdict)
    out = Path(path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w", encoding="utf-8") as handle:
        json.dump(verdict, handle, ensure_ascii=False, sort_keys=True)


def validate_smoke_verdict(path):
    """Read and validate a smoke verdict file; return the parsed object."""
    with open(path, "r", encoding="utf-8") as handle:
        verdict = json.load(handle)
    _validate_smoke_verdict_dict(verdict)
    return verdict


def render_compare_table(cells, metric_name):
    """Render one metric row: context median vs baseline median."""
    rows = []
    for cell in cells:
        mode = cell.get("mode")
        value = cell.get("metrics", {}).get(metric_name, {}).get("median", 0.0)
        rows.append((mode, cell.get("prompt_id"), value))
    context = {pid: value for mode, pid, value in rows if mode == "context"}
    baseline = {pid: value for mode, pid, value in rows if mode == "baseline"}
    lines = [f"| {metric_name} |", "|---|---|"]
    for prompt_id in sorted(set(context) | set(baseline)):
        c = context.get(prompt_id, 0.0)
        b = baseline.get(prompt_id, 0.0)
        lines.append(f"| {prompt_id} | {c:g} / {b:g} |")
    return "\n".join(lines)


def render_report_markdown(batch_meta, inventories, snapshot, verdicts, cells):
    """Full markdown report: header plus raw and derived compare tables."""
    parts = [render_header(batch_meta, inventories, snapshot, verdicts)]
    parts.append("## Raw metrics")
    parts.append("")
    for metric in RAW_METRICS:
        parts.append(render_compare_table(cells, metric))
        parts.append("")
    parts.append("## Derived metrics")
    parts.append("")
    for metric in DERIVED_METRICS:
        parts.append(render_compare_table(cells, metric))
        parts.append("")
    return "\n".join(parts)
