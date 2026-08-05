#!/usr/bin/env python3
"""
Benchmark aggregator for skill evaluation results.

Reads grading.json files from a workspace directory, computes
AggStats (mean/stddev for pass_rate, time_seconds, tokens),
and produces benchmark.json with with_skill vs without_skill delta.

Usage:
    python benchmark.py <workspace-dir>
    python benchmark.py <workspace-dir> --output ./results
    python benchmark.py <workspace-dir> --summary-only
"""

import json
import sys
import argparse
import statistics
from pathlib import Path
from collections import defaultdict


def find_all_gradings(workspace_root):
    gradings = []
    for grad_path in Path(workspace_root).rglob("grading.json"):
        timing_path = grad_path.parent / "timing.json"
        if not timing_path.exists():
            continue
        try:
            grading = json.loads(grad_path.read_text())
            timing = json.loads(timing_path.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        parts = grad_path.relative_to(workspace_root).parts
        mode = parts[-2] if len(parts) >= 2 else "unknown"
        eval_slug = parts[-3] if len(parts) >= 3 else "unknown"
        gradings.append({
            "mode": mode,
            "eval": eval_slug,
            "pass_rate": grading.get("summary", {}).get("pass_rate", 0),
            "total_tokens": timing.get("total_tokens", 0),
            "duration_ms": timing.get("duration_ms", 0),
        })
    return gradings


def compute_stats(values):
    if len(values) == 0:
        return {"mean": 0.0, "stddev": 0.0}
    return {
        "mean": round(statistics.mean(values), 4),
        "stddev": round(statistics.stdev(values), 4) if len(values) > 1 else 0.0,
    }


def build_benchmark(gradings):
    by_mode = defaultdict(list)
    for g in gradings:
        by_mode[g["mode"]].append(g)

    result = {}
    for mode in ("with_skill", "without_skill"):
        items = by_mode.get(mode, [])
        if not items:
            continue
        result[mode] = {
            "pass_rate": compute_stats([i["pass_rate"] for i in items]),
            "time_seconds": compute_stats([i["duration_ms"] / 1000.0 for i in items]),
            "tokens": compute_stats([i["total_tokens"] for i in items]),
        }

    if "with_skill" in result and "without_skill" in result:
        result["delta"] = {
            "pass_rate": round(
                result["with_skill"]["pass_rate"]["mean"] - result["without_skill"]["pass_rate"]["mean"], 4
            ),
            "time_seconds": round(
                result["with_skill"]["time_seconds"]["mean"] - result["without_skill"]["time_seconds"]["mean"], 2
            ),
            "tokens": round(
                result["with_skill"]["tokens"]["mean"] - result["without_skill"]["tokens"]["mean"], 1
            ),
        }

    return {"run_summary": result}


def format_benchmark(benchmark):
    lines = []
    rs = benchmark.get("run_summary", {})
    for mode in ("with_skill", "without_skill"):
        stats = rs.get(mode)
        if not stats:
            continue
        lines.append(f"[{mode}]")
        lines.append(f"  pass_rate:   {stats['pass_rate']['mean']:.4f} (sd={stats['pass_rate']['stddev']:.4f})")
        lines.append(f"  time_seconds: {stats['time_seconds']['mean']:.2f}s (sd={stats['time_seconds']['stddev']:.2f})")
        lines.append(f"  tokens:      {stats['tokens']['mean']:.0f} (sd={stats['tokens']['stddev']:.0f})")
    delta = rs.get("delta")
    if delta:
        lines.append("[delta (with - without)]")
        lines.append(f"  pass_rate:   {delta['pass_rate']:+.4f} pp")
        lines.append(f"  time_seconds: {delta['time_seconds']:+.2f}s")
        lines.append(f"  tokens:      {delta['tokens']:+.0f}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Aggregate evaluation results into benchmark.json")
    parser.add_argument("workspace_dir", help="Path to workspace directory containing grading.json files")
    parser.add_argument("--output", "-o", help="Output path for benchmark.json (default: <workspace_dir>/benchmark.json)")
    parser.add_argument("--summary-only", action="store_true", help="Only print summary, skip writing")
    args = parser.parse_args()

    gradings = find_all_gradings(args.workspace_dir)
    if not gradings:
        print(f"No grading.json files found under {args.workspace_dir}")
        sys.exit(1)

    benchmark = build_benchmark(gradings)
    summary = format_benchmark(benchmark)

    print(f"Found {len(gradings)} runs in {args.workspace_dir}\n")
    print(summary)

    if not args.summary_only:
        output_path = Path(args.output or args.workspace_dir) / "benchmark.json"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(json.dumps(benchmark, indent=2))
        print(f"\nWrote: {output_path}")

    sys.exit(0)


if __name__ == "__main__":
    main()
