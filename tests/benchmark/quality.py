#!/usr/bin/env python3
"""Deterministic per-prompt quality scoring and batch verdicts for the
opencode benchmark harness. Pure logic, stdlib only.

Structural quality proxies are deterministic substring/structure checks; they
do not measure semantic correctness, factuality, or user value.
"""

import json
import re

import preflight
from metrics import MODES, PROMPT_IDS, RAW_METRICS, is_finite, median, validate_attempt

VERDICT_KEYS = ("token_optimization", "cost_reduction", "efficiency", "effectiveness")

# Per-prompt quality floor (both modes). Any cell below the floor fails
# effectiveness; success_rate is an absolute floor of exactly 1.0.
QUALITY_THRESHOLD = 0.75
ADHERENCE_THRESHOLD = 0.75
SUCCESS_RATE_THRESHOLD = 1.0

REFUSAL_MARKERS = (
    "i cannot",
    "i can't",
    "i am not able",
    "i'm not able",
    "i am unable",
    "i'm unable",
    "cannot assist",
    "can't assist",
    "i refuse",
)

ADHERENCE_REQUIRED = {
    "p1": ("json", "category"),
    "p2": ("skill.md", "frontmatter"),
    "p3": ("sweep-content-icons.py",),
    "p4": ("subagent", "manifest.yaml", "valid"),
    "p5": ("content/", "validation"),
}

ADHERENCE_FORBIDDEN = {
    "p1": (),
    "p2": (),
    "p3": (),
    "p4": (),
    "p5": (),
}

NON_REGRESSION_QUALITY_TOLERANCE = 0.05


def _extract_json(text):
    start, end = text.find("{"), text.rfind("}")
    if start == -1 or end <= start:
        return None
    try:
        return json.loads(text[start : end + 1])
    except ValueError:
        return None


def _category_counts(data):
    """Extract a category -> count mapping from a parsed JSON response."""
    if isinstance(data, dict):
        if all(isinstance(k, str) for k in data):
            numeric = {k: v for k, v in data.items() if isinstance(v, (int, float))}
            if numeric:
                return {str(k): float(v) for k, v in numeric.items()}
        categories = data.get("categories")
        if isinstance(categories, dict):
            return {
                str(k): float(v)
                for k, v in categories.items()
                if isinstance(v, (int, float))
            }
    if isinstance(data, list):
        result = {}
        for item in data:
            if isinstance(item, dict) and "count" in item:
                name = item.get("category") or item.get("name")
                if name is not None:
                    result[str(name)] = float(item["count"])
        return result
    return {}


def _list_item_count(text):
    return len(re.findall(r"^\s*(?:[-*]|\d+[.)])\s+\S", text, re.MULTILINE))


def score_quality(prompt_id, text):
    """Structural response correctness per prompt; 0.0 or 1.0."""
    if not isinstance(text, str):
        return 0.0
    if prompt_id == "p1":
        data = _extract_json(text)
        if data is None:
            return 0.0
        counts = _category_counts(data)
        if not counts:
            return 0.0
        if abs(sum(counts.values()) - 63.0) > 0.001:
            return 0.0
        return 1.0
    if prompt_id == "p2":
        return (
            1.0
            if ("---" in text and "name:" in text and "description:" in text)
            else 0.0
        )
    if prompt_id == "p3":
        return 1.0 if _list_item_count(text) >= 3 else 0.0
    if prompt_id == "p4":
        return 1.0 if ("manifest.yaml" in text and _list_item_count(text) >= 4) else 0.0
    if prompt_id == "p5":
        return 1.0 if _list_item_count(text) >= 3 else 0.0
    return 0.0


def score_adherence(prompt_id, text):
    """Required format, sections, and references checks; 0.0 or 1.0."""
    if not isinstance(text, str):
        return 0.0
    lowered = text.lower()
    required = ADHERENCE_REQUIRED.get(prompt_id, ())
    forbidden = ADHERENCE_FORBIDDEN.get(prompt_id, ())
    if not all(token in lowered for token in required):
        return 0.0
    if any(token in lowered for token in forbidden):
        return 0.0
    return 1.0


def score_success(prompt_id, attempt):
    """1.0 only for exit 0, non-empty output, no refusal or schema error, and
    all prompt checks executed; otherwise 0.0."""
    if not isinstance(attempt, dict):
        return 0.0
    if attempt.get("exit_code") != 0:
        return 0.0
    text = attempt.get("stdout_text", "")
    if not isinstance(text, str) or not text.strip():
        return 0.0
    lowered = text.lower()
    if any(marker in lowered for marker in REFUSAL_MARKERS):
        return 0.0
    if lowered.lstrip().startswith(("error:", "traceback")):
        return 0.0
    if score_quality(prompt_id, text) != 1.0:
        return 0.0
    return 1.0


def _median_of(cells, mode, metric, prompt_id=None):
    values = [
        cell.get("metrics", {}).get(metric, {}).get("median", 0.0)
        for cell in cells
        if cell.get("mode") == mode
        and (prompt_id is None or cell.get("prompt_id") == prompt_id)
    ]
    return median(values) if values else None


def _safety_violation(inventories):
    for inv in inventories.values():
        if isinstance(inv, dict) and inv.get("safety_ok") is False:
            return True
    return False


def _cells_complete(cells):
    if not cells:
        return False
    modes_present = {cell.get("mode") for cell in cells}
    if modes_present != set(MODES):
        return False
    per_mode_prompts = {}
    run_counts = {}
    for cell in cells:
        per_mode_prompts.setdefault(cell.get("mode"), set()).add(cell.get("prompt_id"))
        run_counts[cell.get("mode")] = cell.get("logical_run_count")
    for mode in MODES:
        if per_mode_prompts.get(mode) != set(PROMPT_IDS):
            return False
    return bool(run_counts.get("context")) and run_counts.get(
        "context"
    ) == run_counts.get("baseline")


def _inventories_ok(inventories):
    if not isinstance(inventories, dict):
        return False
    for inv in inventories.values():
        if not isinstance(inv, dict) or inv.get("valid") is not True:
            return False
    if inventories.get("context", {}).get("counts") != {
        "rules": 1,
        "skills": 63,
        "subagents": 17,
        "mcp_write_capable": 0,
    }:
        return False
    return inventories.get("baseline", {}).get("counts") == {
        "rules": 0,
        "skills": 0,
        "subagents": 0,
        "mcp_write_capable": 0,
    }


def _snapshot_ok(snapshot):
    return (
        isinstance(snapshot, dict)
        and bool(snapshot.get("files"))
        and snapshot.get("read_only") is True
    )


def _medians_finite(cells):
    for cell in cells:
        for metric in RAW_METRICS:
            med = cell.get("metrics", {}).get(metric, {}).get("median")
            if not is_finite(med):
                return False
    return True


def _cost_accounting_ok(attempts):
    known_ids = {a.get("attempt_id") for a in attempts}
    for attempt in attempts:
        if validate_attempt(attempt):
            return False
        linked = attempt.get("retry_of_attempt_id")
        if linked is not None and linked not in known_ids:
            return False
        for key in (
            "cost_usd",
            "cost_estimate_usd",
            "reserved_cost_usd",
            "released_cost_usd",
        ):
            if not is_finite(attempt.get(key, 0.0)):
                return False
    return True


def _eligible(cells, inventories, snapshot, attempts, smoke_verdict):
    if smoke_verdict != "PASS":
        return False
    if not attempts:
        return False
    return (
        _cells_complete(cells)
        and _inventories_ok(inventories)
        and _snapshot_ok(snapshot)
        and _medians_finite(cells)
        and _cost_accounting_ok(attempts)
    )


def _thresholds_ok(cells):
    """Absolute per-prompt quality floor: quality_score >= 0.75,
    instruction_adherence >= 0.75, success_rate == 1.0 in both modes."""
    for cell in cells:
        quality = cell.get("metrics", {}).get("quality_score", {}).get("median")
        adherence = (
            cell.get("metrics", {}).get("instruction_adherence", {}).get("median")
        )
        success = cell.get("metrics", {}).get("success_rate", {}).get("median")
        if not is_finite(quality) or quality < QUALITY_THRESHOLD:
            return False
        if not is_finite(adherence) or adherence < ADHERENCE_THRESHOLD:
            return False
        if not is_finite(success) or success != SUCCESS_RATE_THRESHOLD:
            return False
    return True


def _baseline_markers_found(attempts):
    """Decisive gate: any kernel literal in a baseline attempt's stdout or
    stderr fails effectiveness. The full catalog is advisory only (reported,
    never gating). Missing output files are skipped (never fatal)."""
    found = set()
    for attempt in attempts:
        if attempt.get("mode") != "baseline":
            continue
        for key in ("stdout_path", "stderr_path"):
            path = attempt.get(key)
            if not path:
                continue
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as handle:
                    text = handle.read()
            except OSError:
                continue
            for marker in preflight.KERNEL_MARKER_LITERALS:
                if marker in text:
                    found.add(marker)
    return sorted(found)


def _non_regression_gates(cells, prompt_id):
    """Return True when all three per-prompt non-regression gates pass."""
    ctx_q = _median_of(cells, "context", "quality_score", prompt_id)
    base_q = _median_of(cells, "baseline", "quality_score", prompt_id)
    ctx_a = _median_of(cells, "context", "instruction_adherence", prompt_id)
    base_a = _median_of(cells, "baseline", "instruction_adherence", prompt_id)
    ctx_s = _median_of(cells, "context", "success_rate", prompt_id)
    base_s = _median_of(cells, "baseline", "success_rate", prompt_id)
    if ctx_q is None or base_q is None or ctx_a is None or base_a is None:
        return False
    if ctx_s is None or base_s is None:
        return False
    return (
        ctx_q >= base_q - NON_REGRESSION_QUALITY_TOLERANCE
        and ctx_a >= base_a
        and ctx_s >= base_s
    )


def compute_verdicts(cells, inventories, snapshot, attempts, *, smoke_verdict=None):
    """Return exactly the four verdict keys with PASS/FAIL/INCONCLUSIVE values.

    Precedence: safety or cap violation yields FAIL; missing or incomplete
    eligibility evidence yields INCONCLUSIVE; otherwise eligible comparisons
    yield PASS or FAIL. Eligibility additionally requires a passed isolation
    smoke (``smoke_verdict == "PASS"``; None or any other value is
    INCONCLUSIVE). effectiveness fails on any quality-dimension regression,
    on any cell below the absolute threshold table, or on any loaded-evidence
    marker in a baseline attempt's stdout/stderr."""
    if _safety_violation(inventories):
        return {key: "FAIL" for key in VERDICT_KEYS}
    if not _eligible(cells, inventories, snapshot, attempts, smoke_verdict):
        return {key: "INCONCLUSIVE" for key in VERDICT_KEYS}
    ctx_tokens = _median_of(cells, "context", "tokens_total")
    base_tokens = _median_of(cells, "baseline", "tokens_total")
    ctx_cost = _median_of(cells, "context", "cost_usd")
    base_cost = _median_of(cells, "baseline", "cost_usd")
    ctx_wall = _median_of(cells, "context", "wall_ms")
    base_wall = _median_of(cells, "baseline", "wall_ms")
    if ctx_tokens is None or base_tokens is None or ctx_cost is None:
        return {key: "INCONCLUSIVE" for key in VERDICT_KEYS}
    if base_cost is None or ctx_wall is None or base_wall is None:
        return {key: "INCONCLUSIVE" for key in VERDICT_KEYS}
    gates = all(_non_regression_gates(cells, pid) for pid in PROMPT_IDS)
    thresholds_ok = _thresholds_ok(cells)
    markers_found = _baseline_markers_found(attempts)
    return {
        "token_optimization": "PASS" if ctx_tokens < base_tokens else "FAIL",
        "cost_reduction": "PASS" if ctx_cost < base_cost else "FAIL",
        "efficiency": "PASS" if (ctx_wall < base_wall and gates) else "FAIL",
        "effectiveness": "PASS"
        if (gates and thresholds_ok and not markers_found)
        else "FAIL",
    }
