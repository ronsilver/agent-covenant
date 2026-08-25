#!/usr/bin/env python3
"""Deterministic stdlib-only benchmark runner for `opencode run`.

Canonical modes: ``context`` (1 global rule, 71 skills, 17 subagents, 0
write-capable MCP) and ``baseline`` (0/0/0/0). ``paired`` is a CLI selection
that runs both canonical modes; it is not a third execution mode.

All artifacts live under ``tests/benchmark/``. No stale mode vocabulary or
obsolete singular benchmark paths are permitted.
"""

import argparse
import atexit
import json
import os
import signal
import sys
import time
from pathlib import Path

import metrics
import preflight
import process
import records
import report
from manifest import ManifestError

DEFAULT_MODEL = "opencode-go/deepseek-v4-flash"
DEFAULT_AGENT = "build"
DEFAULT_SEED = 20260818
DEFAULT_OUT = "tests/benchmark/out"
EXIT_SMOKE_FAIL = 1
EXIT_VALIDATION = 2
EXIT_SAFETY = 3


def build_parser():
    parser = argparse.ArgumentParser(
        prog="benchmark",
        description="Deterministic benchmark harness for `opencode run`.",
    )
    parser.add_argument(
        "--mode", default=None, choices=["context", "baseline", "paired"]
    )
    parser.add_argument("--prompts", default=None, help="all|p1,p2,p3,p4,p5")
    parser.add_argument("--runs", type=int, default=None, help="1..10")
    parser.add_argument("--seed", type=int, default=DEFAULT_SEED)
    parser.add_argument("--jitter", type=float, default=0.0, help="finite and >= 0")
    parser.add_argument("--timeout", type=float, default=600.0, help="finite and > 0")
    parser.add_argument("--max-runs", type=int, default=10)
    parser.add_argument("--max-batch-runs", type=int, default=0, help="0 disables")
    parser.add_argument("--max-cost-usd", type=float, default=0.0, help="0 disables")
    parser.add_argument("--max-batch-seconds", type=float, default=7200.0)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--agent", default=DEFAULT_AGENT)
    parser.add_argument("--out", default=DEFAULT_OUT)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--probe-only", action="store_true")
    parser.add_argument(
        "--smoke",
        action="store_true",
        help="isolation smoke: paired/p1/runs=1, exit 0 PASS / 1 FAIL / 2 INCONCLUSIVE",
    )
    parser.add_argument(
        "--pure",
        action="store_true",
        help="defense-in-depth: pass --pure to opencode in all modes",
    )
    return parser


def _fail(message):
    print(f"benchmark: error: {message}", file=sys.stderr)
    sys.exit(EXIT_VALIDATION)


def select_prompts(value):
    if value == "all":
        return list(records.PROMPT_FILES)
    ids = [item.strip() for item in value.split(",") if item.strip()]
    if not ids or any(pid not in records.PROMPT_FILES for pid in ids):
        _fail(f"unknown or empty prompt selection: {value!r}")
    return ids


def validate_args(args):
    if not (1 <= args.runs <= 10):
        _fail(f"--runs must be within 1..10, got {args.runs}")
    if args.runs > args.max_runs:
        _fail(f"--runs ({args.runs}) exceeds --max-runs ({args.max_runs})")
    for name, value, ok in (
        ("--jitter", args.jitter, metrics.is_finite(args.jitter) and args.jitter >= 0),
        (
            "--timeout",
            args.timeout,
            metrics.is_finite(args.timeout) and args.timeout > 0,
        ),
        (
            "--max-cost-usd",
            args.max_cost_usd,
            metrics.is_finite(args.max_cost_usd) and args.max_cost_usd >= 0,
        ),
        (
            "--max-batch-seconds",
            args.max_batch_seconds,
            metrics.is_finite(args.max_batch_seconds) and args.max_batch_seconds > 0,
        ),
    ):
        if not ok:
            _fail(f"{name} must be finite and in range, got {value!r}")
    if args.max_batch_runs < 0:
        _fail("--max-batch-runs must be >= 0")
    select_prompts(args.prompts)


def _read_message(prompt_path):
    """Read the prompt snapshot as the run message.

    Reads snapshot bytes, decodes utf-8, and strips one trailing newline.
    In dry-run/probe mode the snapshot does not exist yet, so the source
    prompt file is read instead (display only; live runs always use the
    snapshot)."""
    path = Path(prompt_path)
    if not path.exists():
        path = preflight.PROMPTS_DIR / path.name
    with open(path, "r", encoding="utf-8", errors="replace") as handle:
        return handle.read().rstrip("\n")


def build_command(args, mode, prompt_path, live=False):
    """Valid opencode 1.18.18 CLI invocation; position-args only, no
    --prompt-file/--out (neither flag exists in this CLI version).

    ``--session`` is intentionally absent: the flag only continues an existing
    session and rejects unknown ids ("Session not found"); a fresh run's id is
    read back from the event stream and stored in the attempt record. ``--pure``
    is appended only when the caller sets it; it is decorative defense-in-depth,
    never a substitute for the HOME isolation preflight."""
    message = _read_message(prompt_path)
    cmd = [
        "opencode",
        "run",
        message,
        "--format",
        "json",
        "--model",
        args.model,
        "--agent",
        args.agent,
    ]
    if args.pure:
        cmd.append("--pure")
    return cmd


def dry_run(args):
    prompts = select_prompts(args.prompts)
    modes = ["context", "baseline"] if args.mode == "paired" else [args.mode]
    env = preflight.build_env_allowlist()
    snapshot = f"{args.out}/snapshot/prompts"
    for mode in modes:
        print(f"HOME[{mode}]={preflight.build_env(mode)['HOME']}")
        for prompt_id in prompts:
            prompt_path = f"{snapshot}/{records.PROMPT_FILES[prompt_id]}"
            cmd = build_command(args, mode, prompt_path)
            print(f"[{mode}] {prompt_id}: " + " ".join(cmd))
    print("environment names: " + ",".join(sorted(env)))


def probe_dry_run(args):
    snapshot = f"{args.out}/snapshot/prompts"
    for mode in ("context", "baseline"):
        prompt_path = f"{snapshot}/{records.PROMPT_FILES['p1']}"
        cmd = build_command(args, mode, prompt_path)
        print(f"HOME[{mode}]={preflight.build_env(mode)['HOME']}")
        print(f"[{mode}] " + " ".join(cmd))
    print("environment names: " + ",".join(sorted(preflight.build_env_allowlist())))


def _inventory(mode, batch_home=None):
    try:
        return preflight.build_inventory(mode, batch_home=batch_home)
    except (ManifestError, RuntimeError) as exc:
        print(f"benchmark: error: inventory {mode} failed: {exc}", file=sys.stderr)
        sys.exit(EXIT_VALIDATION)


def _preflight(modes, batch_home=None):
    inventories = {}
    for mode in modes:
        inv = _inventory(mode, batch_home=batch_home)
        if not inv["valid"]:
            print(
                f"benchmark: error: inventory drift for {mode}: {inv['counts']}",
                file=sys.stderr,
            )
            sys.exit(EXIT_VALIDATION)
        inventories[mode] = inv
    return inventories


def _run_one(args, run, snapshot, batch_id, batch_home=None):
    mode, prompt_id, run_idx = run
    attempt_suffix = f"{int(time.time() * 1000)}"
    out_dir = Path(args.out)
    prompt_path = f"{snapshot['path']}/{records.PROMPT_FILES[prompt_id]}"
    cmd = build_command(args, mode, prompt_path, live=True)
    env = preflight.build_env(mode, batch_home)
    result = process.run_command_with_timeout(
        cmd, env, args.timeout, str(out_dir / "raw"), f"{mode}-{prompt_id}-{run_idx}"
    )
    ctx = SimpleContext(
        batch_id=batch_id,
        mode=mode,
        prompt_id=prompt_id,
        run_idx=run_idx,
        attempt_suffix=attempt_suffix,
        timeout_s=args.timeout,
        out_dir=str(out_dir),
        snapshot_path=snapshot["path"],
        snapshot_sha256=snapshot["sha256"],
    )
    return records.new_attempt(ctx, snapshot, result)


class SimpleContext:
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)


def run_batch(args, modes, prompt_ids, snapshot, batch_home=None):
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    batch_id = f"b{int(time.time())}"
    order = []
    attempts = []
    for prompt_id in prompt_ids:
        for mode in modes:
            for run_idx in range(1, args.runs + 1):
                order.append(f"{prompt_id}:{mode}:{run_idx}")
                attempts.append(
                    _run_one(
                        args,
                        (mode, prompt_id, run_idx),
                        snapshot,
                        batch_id,
                        batch_home=batch_home,
                    )
                )
    return batch_id, attempts, order


def _validate_smoke_args(args):
    """--smoke forces paired/p1/runs=1 and rejects conflicting flags."""
    if args.dry_run:
        _fail("--smoke cannot be combined with --dry-run")
    if args.probe_only:
        _fail("--smoke cannot be combined with --probe-only")
    if args.mode is not None and args.mode != "paired":
        _fail("--smoke forces --mode paired")
    if args.prompts is not None:
        _fail("--smoke forces --prompts p1")
    if args.runs is not None:
        _fail("--smoke forces --runs 1")
    ns = SimpleContext(
        mode="paired",
        prompts="p1",
        runs=1,
        max_runs=args.max_runs,
        jitter=args.jitter,
        timeout=args.timeout,
        max_cost_usd=args.max_cost_usd,
        max_batch_seconds=args.max_batch_seconds,
        max_batch_runs=args.max_batch_runs,
    )
    validate_args(ns)


def _read_text(path_value):
    if not path_value:
        return ""
    try:
        with open(path_value, "r", encoding="utf-8", errors="replace") as handle:
            return handle.read()
    except OSError:
        return ""


def _register_home_cleanup(batch_home):
    """SIGTERM/SIGINT handlers and atexit perform the same idempotent cleanup
    as the main finally block."""

    def _cleanup():
        preflight.cleanup_baseline_home(batch_home)

    atexit.register(_cleanup)
    for sig in (signal.SIGTERM, signal.SIGINT):
        try:
            signal.signal(
                sig, lambda signum, frame: _cleanup() or os._exit(128 + signum)
            )
        except (ValueError, OSError):
            pass


def run_smoke(args):
    """Isolation smoke: paired/p1/runs=1. Exit 0 PASS, 1 FAIL (marker or
    invalid baseline), 2 INCONCLUSIVE (isolation preflight failed closed).

    A smoke verdict JSON is always written to out/smoke-<batch_id>.json and
    printed to stdout, including the INCONCLUSIVE case."""
    batch_id = f"b{int(time.time())}"
    verdict_path = Path(args.out) / f"smoke-{batch_id}.json"
    batch_home = None
    try:
        preflight.check_app_support_opencode()
        batch_home = preflight.build_baseline_home()
    except preflight.IsolationError as exc:
        print("auth copy: failed", file=sys.stderr)
        print(f"benchmark: error: isolation preflight failed: {exc}", file=sys.stderr)
        verdict = {
            "record_type": "smoke",
            "batch_id": batch_id,
            "marker_absent": False,
            "markers_found": [],
            "input_raw_context": 0,
            "input_raw_baseline": 0,
            "input_raw_ratio": "N/A",
            "baseline_exit_code": None,
            "baseline_usage_event_valid": False,
            "verdict": "INCONCLUSIVE",
        }
        report.write_smoke_verdict(str(verdict_path), verdict)
        print(json.dumps(verdict))
        return EXIT_VALIDATION
    try:
        _preflight(["context", "baseline"], batch_home=batch_home)
        snapshot = preflight.create_snapshot(["p1"], args.out)
        ctx_attempt = _run_one(
            args, ("context", "p1", 1), snapshot, batch_id, batch_home=batch_home
        )
        base_attempt = _run_one(
            args, ("baseline", "p1", 1), snapshot, batch_id, batch_home=batch_home
        )
        markers = preflight.marker_catalog()["markers"]
        base_stdout = _read_text(base_attempt.get("stdout_path"))
        base_stderr = _read_text(base_attempt.get("stderr_path"))
        markers_found = sorted(
            {
                marker
                for marker in markers
                if marker in base_stdout or marker in base_stderr
            }
        )
        # advisory only: keep marker_found for reporting/advisory purposes
        # but decisive gate uses only kernel literals
        kernel_markers_present = any(
            marker in base_stderr for marker in preflight.KERNEL_MARKER_LITERALS
        )
        marker_absent = not kernel_markers_present
        ctx_input = ctx_attempt.get("input_raw") or 0
        base_input = base_attempt.get("input_raw") or 0
        if base_input > 0:
            input_raw_ratio = ctx_input / base_input
        else:
            input_raw_ratio = "N/A"
        baseline_valid = base_attempt.get("error_count") == 0
        baseline_exit = base_attempt.get("exit_code")
        verdict_value = (
            "PASS"
            if marker_absent and baseline_exit == 0 and baseline_valid
            else "FAIL"
        )
        verdict = {
            "record_type": "smoke",
            "batch_id": batch_id,
            "marker_absent": marker_absent,
            "markers_found": markers_found,
            "input_raw_context": ctx_attempt.get("input_raw") or 0,
            "input_raw_baseline": base_input,
            "input_raw_ratio": input_raw_ratio,
            "baseline_exit_code": baseline_exit,
            "baseline_usage_event_valid": baseline_valid,
            "verdict": verdict_value,
        }
        report.write_smoke_verdict(str(verdict_path), verdict)
        print(json.dumps(verdict))
        return 0 if verdict_value == "PASS" else EXIT_SMOKE_FAIL
    finally:
        preflight.cleanup_baseline_home(batch_home)


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    if args.smoke:
        _validate_smoke_args(args)
        return run_smoke(args)
    args.mode = args.mode or "paired"
    args.prompts = args.prompts or "all"
    args.runs = 5 if args.runs is None else args.runs
    validate_args(args)
    if args.dry_run:
        if args.probe_only:
            probe_dry_run(args)
        else:
            dry_run(args)
        return 0
    if args.probe_only:
        print(
            "benchmark: error: --probe-only requires --dry-run in this build",
            file=sys.stderr,
        )
        return EXIT_VALIDATION
    modes = ["context", "baseline"] if args.mode == "paired" else [args.mode]
    prompt_ids = select_prompts(args.prompts)
    batch_home = None
    if "baseline" in modes:
        try:
            preflight.check_app_support_opencode()
            batch_home = preflight.build_baseline_home()
        except preflight.IsolationError as exc:
            print("auth copy: failed", file=sys.stderr)
            print(
                f"benchmark: error: isolation preflight failed: {exc}", file=sys.stderr
            )
            return EXIT_VALIDATION
        _register_home_cleanup(batch_home)
    try:
        inventories = _preflight(modes, batch_home=batch_home)
        fingerprint_before = preflight.repo_fingerprint()
        snapshot = preflight.create_snapshot(prompt_ids, args.out)
        batch_id, attempts, order = run_batch(
            args, modes, prompt_ids, snapshot, batch_home=batch_home
        )
        fingerprint_after = preflight.repo_fingerprint()
        if fingerprint_before != fingerprint_after:
            print("benchmark: error: repository mutated during run", file=sys.stderr)
            return EXIT_SAFETY
        batch_meta = {
            "record_type": "batch_meta",
            "batch_id": batch_id,
            "seed": args.seed,
            "cell_order": order,
            "selected_prompt_ids": prompt_ids,
            "prompt_snapshot_sha256": snapshot["sha256"],
            "inventories": inventories,
            "opencode_version": "unknown",
            "cumulative_cost_usd": 0.0,
        }
        summary_path = Path(args.out) / f"summary-{batch_id}.jsonl"
        with open(summary_path, "w", encoding="utf-8") as handle:
            handle.write(json.dumps(batch_meta, ensure_ascii=False) + "\n")
        runs_path = Path(args.out) / f"runs-{batch_id}.jsonl"
        report.write_runs_jsonl(runs_path, attempts)
        return 0
    finally:
        preflight.cleanup_baseline_home(batch_home)


if __name__ == "__main__":
    sys.exit(main())
