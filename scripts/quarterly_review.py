#!/usr/bin/env python3
"""Quarterly Skills Review Automation — S15.

Scans all active skills and produces a review report:
- Skills not updated in N days (staleness)
- Skills missing optional quality fields (aliases, skills deps, allowed-tools)
- Category distribution summary
- Status breakdown (stable/beta/deprecated)
- Skills at risk (category mismatch, low description length)

Usage:
    python3 scripts/quarterly_review.py
    python3 scripts/quarterly_review.py --stale-days 90 --output docs/review-$(date +%Y-Q%q).md
"""

from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
from datetime import datetime, timedelta
from pathlib import Path

ROOT = Path(__file__).parent.parent
SKILLS_DIR = ROOT / "content" / "skills"

VALID_CATEGORIES = {
    "ai-agents",
    "backend",
    "cloud",
    "core",
    "data",
    "frontend",
    "infrastructure",
    "meta",
    "process",
    "quality",
    "security",
}

VALID_STATUSES = {"stable", "beta", "deprecated"}


def _parse_frontmatter(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    in_fm = False
    in_metadata = False
    for i, line in enumerate(text.splitlines()):
        if i == 0 and line.strip() == "---":
            in_fm = True
            continue
        if in_fm and line.strip() == "---":
            break
        if in_fm:
            # Detect entering metadata: block (key: with no value on same line)
            top_m = re.match(r"^([a-zA-Z_-]+)\s*:\s*$", line)
            if top_m:
                in_metadata = top_m.group(1) == "metadata"
                continue
            # Nested metadata key: "  author: Community"
            indent_m = re.match(r"^  ([a-zA-Z_-]+)\s*:\s*(.*)", line)
            if indent_m and in_metadata:
                key = indent_m.group(1).strip()
                val = indent_m.group(2).strip().strip("\"'")
                result[key] = val
                continue
            # Top-level key: "name: foo"
            m = re.match(r"^([a-zA-Z_-]+)\s*:\s*(.*)", line)
            if m:
                key, val = m.group(1).strip(), m.group(2).strip()
                val = val.strip("\"'")
                result[key] = val
    return result


def _last_commit_date(skill_dir: Path) -> datetime | None:
    try:
        out = (
            subprocess.check_output(
                ["git", "log", "-1", "--format=%ai", "--", str(skill_dir)],
                cwd=ROOT,
                stderr=subprocess.DEVNULL,
            )
            .decode()
            .strip()
        )
        if out:
            return datetime.fromisoformat(out[:19])
    except Exception:
        pass
    return None


def _description_length(fm: dict) -> int:
    return len(fm.get("description", ""))


def scan_skills(stale_days: int) -> list[dict]:
    results = []
    cutoff = datetime.now() - timedelta(days=stale_days)

    for skill_dir in sorted(SKILLS_DIR.iterdir()):
        skill_md = skill_dir / "SKILL.md"
        if not skill_md.exists():
            continue

        text = skill_md.read_text()
        fm = _parse_frontmatter(text)
        name = fm.get("name", skill_dir.name)

        issues = []
        category = fm.get("category", "")
        status = fm.get("status", "")
        version = fm.get("version", "")
        desc_len = _description_length(fm)

        # Schema v2 required fields
        if not category:
            issues.append("MISSING category")
        elif category not in VALID_CATEGORIES:
            issues.append(f"INVALID category: {category!r}")
        if not status:
            issues.append("MISSING status")
        elif status not in VALID_STATUSES:
            issues.append(f"INVALID status: {status!r}")
        if not version:
            issues.append("MISSING version")
        if not fm.get("author"):
            issues.append("MISSING author")

        # Quality checks
        if desc_len < 100:
            issues.append(f"SHORT description ({desc_len} chars)")
        has_refs = (skill_dir / "references").exists()
        has_skills_dep = bool(fm.get("skills"))
        last_commit = _last_commit_date(skill_dir)
        is_stale = last_commit and last_commit < cutoff

        results.append(
            {
                "name": name,
                "category": category or "?",
                "status": status or "?",
                "version": version or "?",
                "desc_len": desc_len,
                "has_refs": has_refs,
                "has_skills_dep": has_skills_dep,
                "last_commit": last_commit.strftime("%Y-%m-%d")
                if last_commit
                else "unknown",
                "is_stale": is_stale,
                "issues": issues,
            }
        )

    return results


def generate_report(skills: list[dict], stale_days: int) -> str:
    today = datetime.now().strftime("%Y-%m-%d")
    stale = [s for s in skills if s["is_stale"]]
    with_issues = [s for s in skills if s["issues"]]
    by_category: dict[str, int] = {}
    by_status: dict[str, int] = {}
    for s in skills:
        by_category[s["category"]] = by_category.get(s["category"], 0) + 1
        by_status[s["status"]] = by_status.get(s["status"], 0) + 1

    lines = [
        f"# Quarterly Skills Review — {today}",
        "",
        f"**Total skills scanned:** {len(skills)}  ",
        f"**Stale (not updated in {stale_days}d):** {len(stale)}  ",
        f"**Skills with issues:** {len(with_issues)}  ",
        "",
        "---",
        "",
        "## Category Distribution",
        "",
        "| Category | Count |",
        "|---|---|",
    ]
    for cat, count in sorted(by_category.items(), key=lambda x: -x[1]):
        lines.append(f"| {cat} | {count} |")

    lines += [
        "",
        "## Status Breakdown",
        "",
        "| Status | Count |",
        "|---|---|",
    ]
    for st, count in sorted(by_status.items(), key=lambda x: -x[1]):
        lines.append(f"| {st} | {count} |")

    lines += ["", "---", "", "## Skills with Issues", ""]
    if with_issues:
        lines += ["| Skill | Category | Issues |", "|---|---|---|"]
        for s in sorted(with_issues, key=lambda x: x["name"]):
            issues_str = "; ".join(s["issues"])
            lines.append(f"| `{s['name']}` | {s['category']} | {issues_str} |")
    else:
        lines.append("_No issues found._")

    lines += ["", "---", "", f"## Stale Skills (not updated in {stale_days}+ days)", ""]
    if stale:
        lines += ["| Skill | Category | Last Commit |", "|---|---|---|"]
        for s in sorted(stale, key=lambda x: x["last_commit"]):
            lines.append(f"| `{s['name']}` | {s['category']} | {s['last_commit']} |")
    else:
        lines.append("_No stale skills found._")

    lines += [
        "",
        "---",
        "",
        "## Quality Opportunities",
        "",
        "| Skill | Has references/ | Has skills deps | Description length |",
        "|---|---|---|---|",
    ]
    opportunities = [
        s
        for s in skills
        if not s["has_refs"] or not s["has_skills_dep"] or s["desc_len"] < 200
    ]
    for s in sorted(opportunities, key=lambda x: x["name"])[:20]:
        refs = "yes" if s["has_refs"] else "**no**"
        deps = "yes" if s["has_skills_dep"] else "no"
        lines.append(f"| `{s['name']}` | {refs} | {deps} | {s['desc_len']} |")

    lines += ["", "---", "", "_Generated by `scripts/quarterly_review.py`_", ""]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Quarterly skills review")
    parser.add_argument(
        "--stale-days",
        type=int,
        default=90,
        help="Days before a skill is considered stale",
    )
    parser.add_argument(
        "--output", type=str, default=None, help="Output file path (default: stdout)"
    )
    args = parser.parse_args()

    skills = scan_skills(args.stale_days)
    report = generate_report(skills, args.stale_days)

    if args.output:
        Path(args.output).write_text(report)
        print(f"Report written to {args.output}", file=sys.stderr)
    else:
        print(report)


if __name__ == "__main__":
    main()
