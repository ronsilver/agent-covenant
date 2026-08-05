#!/usr/bin/env python3
"""
Ecosystem-wide skill evaluation runner.

Batch-evaluates all or filtered skills in content/skills/:
  - Structural 7-pillar scoring via validate-skill-quality.py
  - Automated evals via evaluate_skill.py (Ollama Cloud)

Usage:
    # Structural scoring only (fast, no LLM)
    python evaluate_ecosystem.py --skip-evals

    # Reuse existing benchmark.json from eval dirs
    python evaluate_ecosystem.py --reuse-benchmarks

    # Full evaluation with Ollama Cloud
    export OPENAI_API_KEY=<key>
    python evaluate_ecosystem.py --ollama-cloud --concurrency 3

    # Filter by name pattern
    python evaluate_ecosystem.py --filter "expert" --skip-evals

    # Skills lacking evals/evals.json
    python evaluate_ecosystem.py --only-missing-evals --skip-evals

    # JSON output for pipeline consumption
    python evaluate_ecosystem.py --reuse-benchmarks --json
"""

import json
import os
import sys
import time
import argparse
import subprocess
from pathlib import Path

SKILLS_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent / "content" / "skills"
REPO_SCRIPTS_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent / "scripts"
SKILL_CREATOR_DIR = Path(__file__).resolve().parent.parent
VALIDATE_SCRIPT = REPO_SCRIPTS_DIR / "validate-skill-quality.py"
EVALUATE_SCRIPT = SKILL_CREATOR_DIR / "scripts" / "evaluate_skill.py"
EXCLUDE = {"_TEMPLATE", "new-skill"}
OLLAMA_CLOUD_URL = "https://ollama.com/v1"


def discover_skills(filter_pattern=None):
    skills = []
    for d in sorted(SKILLS_DIR.iterdir()):
        if not d.is_dir() or d.name in EXCLUDE:
            continue
        skill_md = d / "SKILL.md"
        if not skill_md.exists():
            continue
        has_evals = (d / "evals" / "evals.json").exists()
        skills.append({
            "name": d.name,
            "dir": str(d),
            "has_evals": has_evals,
        })
    if filter_pattern:
        skills = [s for s in skills if filter_pattern.lower() in s["name"].lower()]
    return skills


def run_structural_scoring(skills):
    cmd = [
        sys.executable, str(VALIDATE_SCRIPT),
        "--json", "--min", "0",
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    if result.returncode != 0:
        return {"error": f"validate-skill-quality.py failed: {result.stderr}"}
    try:
        raw = json.loads(result.stdout)
    except json.JSONDecodeError as e:
        return {"error": f"JSON parse error: {e}. stdout: {result.stdout[:500]}"}

    scores = {}
    for r in raw.get("results", []):
        name = r.get("name")
        if name:
            scores[name] = {
                "total": r.get("total", 0),
                "pillars": r.get("pillars", {}),
            }
    return {
        "summary": {
            "total": raw.get("summary", {}).get("total", 0),
            "passing": raw.get("summary", {}).get("passing", 0),
            "failing": raw.get("summary", {}).get("failing", 0),
            "average": raw.get("summary", {}).get("average", 0),
        },
        "scores": scores,
    }


def skills_missing_evals(skills):
    return [s for s in skills if not s["has_evals"]]


def run_auto_evals(skills, ollama_url, target_model, judge_model, concurrency, output_dir):
    results = []
    for skill in skills:
        if not skill["has_evals"]:
            print(f"  SKIP {skill['name']}: no evals/evals.json")
            continue
        print(f"  EVAL {skill['name']}...", end=" ", flush=True)
        cmd = [
            sys.executable, str(EVALUATE_SCRIPT),
            skill["dir"],
            "--target-model", target_model,
            "--judge-model", judge_model,
            "--ollama-url", ollama_url,
            "--modes", "with_skill",
            "--iterations", "1",
            "--concurrency", str(concurrency),
        ]
        if output_dir:
            cmd += ["--output-dir", output_dir]
        start = time.time()
        try:
            r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            elapsed = time.time() - start
            skill_dir = Path(skill["dir"])
            wdir = output_dir or str(skill_dir)
            bm_path = Path(wdir) / skill["name"] / "iteration-1" / "benchmark.json"
            benchmark = None
            if bm_path.exists():
                try:
                    benchmark = json.loads(bm_path.read_text())
                except (json.JSONDecodeError, OSError):
                    pass
            if r.returncode == 0:
                print(f"OK ({elapsed:.0f}s)")
                results.append({"skill": skill["name"], "status": "ok", "elapsed": elapsed, "benchmark": benchmark})
            else:
                print(f"FAIL ({elapsed:.0f}s)")
                results.append({"skill": skill["name"], "status": "fail", "elapsed": elapsed, "benchmark": benchmark, "stderr": r.stderr[:500]})
        except subprocess.TimeoutExpired:
            print(f"TIMEOUT")
            results.append({"skill": skill["name"], "status": "timeout"})
    return results


def scan_existing_benchmarks(skills):
    for s in skills:
        wdir = Path(s["dir"]) / "workspace"
        bm_file = None
        if wdir.exists():
            bm_files = sorted(wdir.rglob("benchmark.json"))
            if bm_files:
                bm_file = bm_files[0]
        if bm_file:
            try:
                bm = json.loads(bm_file.read_text())
                rs = bm.get("run_summary", {})
                ws = rs.get("with_skill", {})
                pr = ws.get("pass_rate", {})
                rate = pr.get("mean")
                s["benchmark_pass_rate"] = round(rate, 4) if rate is not None else None
                s["benchmark_tokens"] = round(ws.get("tokens", {}).get("mean", 0), 0)
                s["benchmark_time"] = round(ws.get("time_seconds", {}).get("mean", 0), 2)
                s["has_benchmark"] = True
            except Exception as e:
                s["has_benchmark"] = False
        else:
            s["has_benchmark"] = False
    return skills


def merge_benchmarks_into_report(report, skills):
    with_bm = 0
    for sk in report["skills"]:
        name = sk["name"]
        for s in skills:
            if s["name"] == name:
                for k in ["benchmark_pass_rate", "benchmark_tokens", "benchmark_time"]:
                    if k in s and s[k] is not None:
                        sk[k.replace("benchmark_", "eval_")] = s[k]
                if s.get("has_benchmark"):
                    with_bm += 1
                break
    report["summary"]["skills_with_auto_evals"] = with_bm
    report["summary"]["skills_missing_auto_evals"] = report["summary"]["total_skills"] - with_bm
    evals = [sk.get("eval_pass_rate") for sk in report["skills"] if sk.get("eval_pass_rate") is not None]
    if evals:
        report["summary"]["average_eval_pass_rate"] = round(sum(evals) / len(evals), 4)
    return report


def build_report(structural, auto_evals, start_time):
    combined = []
    for name, score in structural.get("scores", {}).items():
        total = score.get("total", 0)
        auto = None
        if auto_evals:
            for a in auto_evals:
                if a["skill"] == name and a.get("benchmark"):
                    bm = a["benchmark"]
                    run_summary = bm.get("run_summary", {})
                    ws = run_summary.get("with_skill", {})
                    ws_pr = ws.get("pass_rate", {})
                    ws_time = ws.get("time_seconds", {})
                    ws_tok = ws.get("tokens", {})
                    delta = run_summary.get("delta", {})
                    auto = {
                        "pass_rate": ws_pr.get("mean"),
                        "pass_rate_stddev": ws_pr.get("stddev"),
                        "time_seconds": ws_time.get("mean"),
                        "tokens": ws_tok.get("mean"),
                        "delta_pass_rate": delta.get("pass_rate"),
                        "delta_time_seconds": delta.get("time_seconds"),
                        "delta_tokens": delta.get("tokens"),
                    }
                    break
        combined.append({
            "name": name,
            "structural_score": total,
            "structural_pillars": score.get("pillars", {}),
            "eval_pass_rate": auto.get("pass_rate") if auto else None,
            "eval_tokens": auto.get("tokens") if auto else None,
            "eval_time_seconds": auto.get("time_seconds") if auto else None,
            "has_auto_evals": auto is not None,
        })

    passing_structural = sum(1 for c in combined if c["structural_score"] >= 70)
    world_class = sum(1 for c in combined if c["structural_score"] >= 80)
    avg_structural = sum(c["structural_score"] for c in combined) / max(len(combined), 1)

    return {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "elapsed_seconds": round(time.time() - start_time, 1),
        "summary": {
            "total_skills": len(combined),
            "passing_structural_70": passing_structural,
            "world_class_80": world_class,
            "average_structural_score": round(avg_structural, 1),
            "skills_with_auto_evals": sum(1 for c in combined if c.get("has_auto_evals")),
            "skills_missing_auto_evals": sum(1 for c in combined if not c.get("has_auto_evals")),
        },
        "skills": sorted(combined, key=lambda x: x["structural_score"]),
    }


def format_text_report(report):
    s = report["summary"]
    lines = [
        f"{'='*60}",
        f"  Ecosystem Quality Report",
        f"{'='*60}",
        f"  Generated: {report['generated_at']}",
        f"  Elapsed: {report['elapsed_seconds']}s",
        f"",
        f"  Total skills: {s['total_skills']}",
        f"  Passing (structural >=70): {s['passing_structural_70']}",
        f"  World-class (structural >=80): {s['world_class_80']}",
        f"  Average structural score: {s['average_structural_score']}",
        f"  Avg eval pass rate: {s.get('average_eval_pass_rate', 'N/A')}",
        f"  With benchmark data: {s['skills_with_auto_evals']}",
        f"  Missing benchmark data: {s['skills_missing_auto_evals']}",
        f"",
        f"  {'Skill':35s} {'Struct':>6s} {'Eval%':>7s} {'Tokens':>8s} {'Time':>7s}",
        f"  {'-'*35} {'-'*6} {'-'*7} {'-'*8} {'-'*7}",
    ]
    for sk in report["skills"]:
        structural = sk["structural_score"]
        pr = sk.get("eval_pass_rate")
        tok = sk.get("eval_tokens", "")
        tim = sk.get("eval_time_seconds", "")
        pr_str = f"{pr:.2f}" if pr is not None else "N/A"
        tok_str = f"{tok:.0f}" if tok else ""
        tim_str = f"{tim:.0f}s" if tim else ""
        status = "PASS" if structural >= 70 else "LOW"
        lines.append(f"  {sk['name']:35s} {structural:6d} {pr_str:>7s} {tok_str:>8s} {tim_str:>7s} {status:>8s}")
    lines.append(f"  {'='*60}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Batch-evaluate all skills in the ecosystem")
    parser.add_argument("--filter", help="Substring filter on skill name")
    parser.add_argument("--skip-evals", action="store_true", help="Skip LLM-based evaluation (structural only)")
    parser.add_argument("--reuse-benchmarks", action="store_true", help="Scan existing workspace dirs for benchmark.json files")
    parser.add_argument("--only-missing-evals", action="store_true", help="Only process skills lacking evals/evals.json")
    parser.add_argument("--ollama-url", default=os.environ.get("OLLAMA_URL", "http://localhost:11434/v1"), help="Ollama API base URL")
    parser.add_argument("--ollama-cloud", action="store_true", help=f"Shortcut for --ollama-url {OLLAMA_CLOUD_URL}")
    parser.add_argument("--target-model", default="deepseekv4-pro:cloud", help="Target model for evals")
    parser.add_argument("--judge-model", default="kimi-k2.6:cloud", help="Judge model for grading")
    parser.add_argument("--concurrency", type=int, default=2, help="Max parallel eval cases (default: 2)")
    parser.add_argument("--output-dir", default=None, help="Output directory for eval artifacts")
    parser.add_argument("--json", action="store_true", help="Output machine-readable JSON report to stdout")
    parser.add_argument("--report", default="ecosystem-quality-report.json", help="Output path for report JSON")
    parser.add_argument("--text", action="store_true", help="Also print formatted text report")
    args = parser.parse_args()

    if args.ollama_cloud:
        args.ollama_url = OLLAMA_CLOUD_URL

    print(f"Ecosystem Evaluation")
    print(f"  Skills dir: {SKILLS_DIR}")
    print(f"  Filter: {args.filter or '(all)'}")
    print(f"  Skip evals: {args.skip_evals}")
    print(f"  Reuse benchmarks: {args.reuse_benchmarks}")
    print(f"  Ollama URL: {args.ollama_url}")
    if not args.skip_evals and not args.reuse_benchmarks:
        print(f"  Target: {args.target_model} | Judge: {args.judge_model} | Concurrency: {args.concurrency}")
    print()

    start = time.time()

    skills = discover_skills(args.filter)
    print(f"Discovered {len(skills)} skills")
    for s in skills:
        missing = " [NO EVALS]" if not s["has_evals"] else ""
        print(f"  {s['name']}{missing}")

    if args.only_missing_evals:
        missing = skills_missing_evals(skills)
        print(f"\nSkills without evals ({len(missing)}):")
        for s in missing:
            print(f"  {s['name']}")
        skills = missing

    print(f"\nScoring structural 7-pillars...")
    structural = run_structural_scoring(skills)
    if "error" in structural:
        print(f"  ERROR: {structural['error']}")
        sys.exit(1)

    ss = structural["summary"]
    print(f"  Total: {ss['total']} | Passing (>=70): {ss['passing']} | Failing: {ss['failing']} | Avg: {ss['average']}")

    auto_evals = None
    if args.reuse_benchmarks:
        print(f"\nScanning existing benchmark.json files...")
        skills = scan_existing_benchmarks(skills)
        found = sum(1 for s in skills if s.get("has_benchmark"))
        print(f"  Found benchmarks: {found}/{len(skills)}")
    elif not args.skip_evals:
        print(f"\nRunning automated evals (Ollama)...")
        auto_results = run_auto_evals(
            skills, args.ollama_url,
            args.target_model, args.judge_model,
            args.concurrency, args.output_dir,
        )
        auto_evals = auto_results
        print(f"\nEval results:")
        for r in auto_results:
            print(f"  {r['skill']:35s} {r['status']}")

    report = build_report(structural, auto_evals, start)

    if args.reuse_benchmarks:
        report = merge_benchmarks_into_report(report, skills)

    if args.text or not args.json:
        print(f"\n{format_text_report(report)}\n")

    if args.json:
        print(json.dumps(report, indent=2))

    report_path = Path(args.report)
    report_path.write_text(json.dumps(report, indent=2))
    print(f"Report written: {report_path}")

    return report


if __name__ == "__main__":
    main()
