#!/usr/bin/env python3
"""
validate-skill-quality.py — Score each SKILL.md against the 7-pillar standard.

Scoring:
  - Autosuficiencia (20pt): % of content inline (not delegated to references/)
  - Árbol de decisiones (15pt): presence of decision table with >=3 branches
  - Anti-patrones (15pt): >=3 ❌/✅ pairs with code
  - Verificación (15pt): verification checklist or verify steps
  - Profundidad (10pt): known bug or platform quirk documented
  - Triggers precisos (15pt): description with >=3 trigger + >=1 anti-trigger
  - Referencias vivas (10pt): >=2 external URLs + last_verified date

Usage:
  python3 scripts/validate-skill-quality.py              # all skills
  python3 scripts/validate-skill-quality.py --min 80     # fail if any < 80
  python3 scripts/validate-skill-quality.py --report     # detailed per-skill
  python3 scripts/validate-skill-quality.py --ci         # exit 1 if any < threshold
"""

import json
import os
import re
import sys
import yaml

SKILLS_DIR = os.path.join(os.path.dirname(__file__), "..", "content", "skills")
MIN_SCORE = int(os.environ.get("QUALITY_MIN_SCORE", "70"))
EXCLUDE = {
    "_TEMPLATE",
    "new-skill",
    "gitnexus-cli",
    "gitnexus-debugging",
    "gitnexus-exploring",
    "gitnexus-guide",
    "gitnexus-impact-analysis",
    "gitnexus-pdg-query",
    "gitnexus-pr-review",
    "gitnexus-refactoring",
    "gitnexus-taint-analysis",
}  # always skip; gitnexus-*: tool-generated, exempt per ADR-0037


def extract_frontmatter(text: str) -> dict:
    """Extract YAML frontmatter from a SKILL.md file."""
    match = re.match(r"^---\n(.*?)\n---", text, re.DOTALL)
    if not match:
        return {}
    try:
        return yaml.safe_load(match.group(1)) or {}
    except yaml.YAMLError:
        return {}


def score_autosuficiencia(text: str, skill_dir: str) -> tuple:
    """20pt: what fraction of content is inline vs delegated to references/."""
    ref_dir = os.path.join(skill_dir, "references")
    ref_files = []
    if os.path.isdir(ref_dir):
        ref_files = [f for f in os.listdir(ref_dir) if f.endswith(".md")]

    # Count explicit reference links
    ref_links = len(re.findall(r"references/[\w.-]+\.md", text))

    # Lines that are actual content (not frontmatter, not blank)
    body = re.sub(r"^---\n.*?\n---\n", "", text, flags=re.DOTALL)
    total_lines = len([l for l in body.split("\n") if l.strip()])
    ref_lines = sum(len(re.findall(r"\n", rf)) for rf in ref_files) if ref_files else 0

    # Check for empty reference files (size 0 or no alphabetic content)
    empty_refs = 0
    for ref_file in ref_files:
        ref_path = os.path.join(ref_dir, ref_file)
        try:
            if os.path.getsize(ref_path) == 0:
                empty_refs += 1
            else:
                with open(ref_path) as f:
                    if not re.search(r"[a-zA-Z]", f.read()):
                        empty_refs += 1
        except OSError:
            empty_refs += 1

    if ref_files:
        inline_ratio = total_lines / max(total_lines + ref_lines, 1)
    else:
        inline_ratio = 1.0

    score = min(20, int(20 * inline_ratio))
    # Penalize: -5pt per empty file, max -10
    if empty_refs:
        score = max(0, score - min(10, empty_refs * 5))

    evidence = f"inline={total_lines}L refs={len(ref_files)}files empty={empty_refs} ratio={inline_ratio:.2f}"
    return score, evidence


def score_decision_tree(text: str) -> tuple:
    """15pt: presence of decision table with >= 3 branches."""
    # Look for markdown tables with "When" or "If" in header
    tables = re.findall(r"\|.*\|.*\|.*\n\|[-\s|]+\n((?:\|.*\|.*\n)*)", text)

    best_branches = 0
    for table in tables:
        rows = [r for r in table.strip().split("\n") if r.strip() and "|" in r]
        # Exclude header/separator rows
        content_rows = [r for r in rows if not re.match(r"^\|[-\s|]+\|$", r)]
        if len(content_rows) >= best_branches:
            best_branches = len(content_rows)

    # Also check for "If X:" or "When Y:" patterns
    conditional_branches = len(
        re.findall(r"(?:^|\n)\s*(?:If|When|If yes|If no)\s+", text)
    )

    total_branches = max(best_branches, conditional_branches)
    score = min(15, max(0, total_branches * 5 if total_branches < 3 else 15))
    if total_branches >= 3:
        score = 15
    evidence = f"table_rows={best_branches} conditionals={conditional_branches}"
    return score, evidence


def score_anti_patterns(text: str) -> tuple:
    """15pt: >=3 ❌/✅ pairs with code."""
    wrong_markers = len(re.findall(r"(?:❌|WRONG|BAD\b|DON'?T\b)", text, re.IGNORECASE))
    correct_markers = len(
        re.findall(r"(?:✅|CORRECT|GOOD\b|DO\b)", text, re.IGNORECASE)
    )
    code_blocks = len(re.findall(r"```[\w]*\n.*?\n```", text, re.DOTALL))

    pairs = min(wrong_markers, correct_markers)
    score = min(15, pairs * 5)
    if pairs >= 3 and code_blocks >= 3:
        score = 15
    evidence = f"❌={wrong_markers} ✅={correct_markers} code_blocks={code_blocks} pairs={pairs}"
    return score, evidence


def score_verification(text: str) -> tuple:
    """15pt: verification checklist or verify steps."""
    checklist_items = len(re.findall(r"- \[ \]", text))
    verify_keywords = len(
        re.findall(r"(?:verify|confirm|validate|check|ensure)\s", text, re.IGNORECASE)
    )
    verify_table = len(
        re.findall(r"\|.*(?:verify|check|confirm).*\|", text, re.IGNORECASE)
    )

    has_verify_section = bool(re.search(r"##\s*Verification", text, re.IGNORECASE))

    score = 0
    if has_verify_section:
        score += 7
    if checklist_items >= 3:
        score += 5
    elif checklist_items >= 1:
        score += 2
    if verify_keywords >= 5:
        score += 3
    elif verify_keywords >= 2:
        score += 1

    score = min(15, score)
    evidence = f"checklist={checklist_items} verify_keywords={verify_keywords} has_section={has_verify_section}"
    return score, evidence


def score_profundidad(text: str) -> tuple:
    """10pt: known bug or platform quirk documented."""
    bug_keywords = re.findall(
        r"(?:known bug|platform quirk|gotcha|⚠|KNOWN ISSUE|BUG|limitation|works around|workaround|edge case)",
        text,
        re.IGNORECASE,
    )
    troubleshooting = bool(re.search(r"##\s*Troubleshooting", text, re.IGNORECASE))
    depth_keywords = len(set(k.lower() for k in bug_keywords))

    score = 0
    if troubleshooting:
        score += 4
    if depth_keywords >= 3:
        score += 6
    elif depth_keywords >= 1:
        score += 3

    score = min(10, score)
    evidence = f"depth_keywords={depth_keywords} troubleshooting={troubleshooting}"
    return score, evidence


def score_triggers(text: str) -> tuple:
    """15pt: description with >=3 trigger + >=1 anti-trigger keywords."""
    frontmatter = extract_frontmatter(text)
    desc = frontmatter.get("description", "")

    # Count trigger keywords (comma-separated or bullet list)
    trigger_section = re.findall(r"Trigger:\s*(.+?)(?:\.|$)", desc, re.IGNORECASE)
    anti_trigger_section = re.findall(
        r"(?:Do NOT|Don'?t|Avoid|Skip)\s*(?:trigger|use|apply|activate)\s*(?:for|when|if|on)?\s*:\s*(.+?)(?:\.|$)",
        desc,
        re.IGNORECASE,
    )

    triggers = 0
    anti_triggers = 0

    if trigger_section:
        triggers = len(re.findall(r"[,\/]", trigger_section[0])) + 1
    if anti_trigger_section:
        anti_triggers = len(re.findall(r"[,\/]", anti_trigger_section[0])) + 1

    # Fallback: count keywords in description
    if triggers < 3:
        keyword_markers = re.findall(
            r"(?:trigger|activate|when working|use when|for work|building|implementing|debugging)",
            desc,
            re.IGNORECASE,
        )
        triggers = max(triggers, len(keyword_markers))

    score = 0
    if triggers >= 3:
        score += 10
    elif triggers >= 1:
        score += 5

    if anti_triggers >= 1:
        score += 5

    score = min(15, score)
    evidence = f"triggers={triggers} anti_triggers={anti_triggers}"
    return score, evidence


def score_references(text: str, skill_dir: str) -> tuple:
    """10pt: >=2 external URLs + last_verified dates."""
    urls = re.findall(r"https?://[^\s\)\]]+", text)
    external_urls = [u for u in urls if "github.com/EXAMPLE" not in u]

    # Count dates in References section or inline last_verified:
    # Pattern 1: | 2026-05-25 |  (table cells)
    # Pattern 2: last_verified: 2026-05-25 (inline)
    # Pattern 3: 2026-05-25 anywhere in References section
    ref_section = re.search(
        r"(?:##\s*References|Last verified).*?(?=##|$)", text, re.IGNORECASE | re.DOTALL
    )
    ref_dates = 0
    if ref_section:
        ref_dates = len(re.findall(r"\d{4}-\d{2}(?:-\d{2})?", ref_section.group()))

    table_dates = len(re.findall(r"\|\s*\d{4}-\d{2}(?:-\d{2})?\s*\|", text))
    inline_last_verified = len(
        re.findall(
            r"last[_ ]?verified[\s:]*\d{4}-\d{2}(?:-\d{2})?", text, re.IGNORECASE
        )
    )

    total_verified = max(ref_dates, table_dates, inline_last_verified)

    score = 0
    if len(external_urls) >= 2:
        score += 5
    elif len(external_urls) >= 1:
        score += 3

    if total_verified >= 2:
        score += 5
    elif total_verified >= 1:
        score += 3

    score = min(10, score)
    evidence = f"external_urls={len(external_urls)} last_verified={total_verified}"
    return score, evidence


def score_skill(skill_name: str) -> dict:
    """Score a single skill across all 7 pillars."""
    skill_dir = os.path.join(SKILLS_DIR, skill_name)
    skill_path = os.path.join(skill_dir, "SKILL.md")

    if not os.path.isfile(skill_path):
        return {"name": skill_name, "error": "SKILL.md not found", "total": 0}

    with open(skill_path, "r") as f:
        text = f.read()

    pillars = {
        "autosuficiencia": score_autosuficiencia(text, skill_dir),
        "decision_tree": score_decision_tree(text),
        "anti_patterns": score_anti_patterns(text),
        "verification": score_verification(text),
        "profundidad": score_profundidad(text),
        "triggers": score_triggers(text),
        "references": score_references(text, skill_dir),
    }

    total = sum(v[0] for v in pillars.values())

    return {
        "name": skill_name,
        "total": total,
        "pillars": {k: {"score": v[0], "evidence": v[1]} for k, v in pillars.items()},
    }


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Score SKILL.md files against 7-pillar standard"
    )
    parser.add_argument(
        "--min",
        type=int,
        default=MIN_SCORE,
        help=f"Minimum score threshold (default: {MIN_SCORE})",
    )
    parser.add_argument(
        "--report", action="store_true", help="Detailed per-skill report"
    )
    parser.add_argument(
        "--ci", action="store_true", help="CI mode: exit 1 if any skill below threshold"
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    args = parser.parse_args()

    skills = sorted(
        d
        for d in os.listdir(SKILLS_DIR)
        if os.path.isdir(os.path.join(SKILLS_DIR, d)) and d not in EXCLUDE
    )

    results = []
    fails = []

    for skill_name in skills:
        result = score_skill(skill_name)
        results.append(result)
        if "error" in result:
            print(f"⚠  {skill_name}: {result['error']}")
        elif result["total"] < args.min:
            fails.append(result)

    # Summary
    total = len(results)
    passing = sum(1 for r in results if r["total"] >= args.min)
    failing = total - passing
    avg = sum(r["total"] for r in results) / max(total, 1)

    if args.json:
        print(
            json.dumps(
                {
                    "results": results,
                    "summary": {
                        "total": total,
                        "passing": passing,
                        "failing": failing,
                        "average": round(avg, 1),
                    },
                },
                indent=2,
            )
        )
        return

    print(f"\n{'=' * 60}")
    print(f"  Skill Quality Report — 7-Pillar Standard (min: {args.min})")
    print(f"{'=' * 60}")
    print(
        f"  Total: {total} | Passing: {passing} | Failing: {failing} | Avg: {avg:.1f}"
    )
    print()

    for r in sorted(results, key=lambda x: x["total"]):
        status = "✅" if r["total"] >= args.min else "❌"
        print(f"  {status} {r['name']:35s} {r['total']:3d}/100", end="")
        if args.report and "pillars" in r:
            details = " | ".join(
                f"{k[:6]}={v['score']:2d}" for k, v in r["pillars"].items()
            )
            print(f"  [{details}]", end="")
        print()

    if fails:
        print(f"\n  ❌ FAILING SKILLS (below {args.min}):")
        for f in fails:
            print(f"     {f['name']:35s} {f['total']:3d}/100")
            if args.report:
                for p, v in f["pillars"].items():
                    print(f"       {p:20s} {v['score']:2d}/... — {v['evidence']}")

    print(f"\n  {'=' * 60}")

    if args.ci and fails:
        print(f"\n  ❌ CI BLOCKED: {len(fails)} skills below threshold ({args.min})")
        sys.exit(1)

    print(f"  ✅ Quality validation complete")
    print(f"  {'=' * 60}\n")


if __name__ == "__main__":
    main()
