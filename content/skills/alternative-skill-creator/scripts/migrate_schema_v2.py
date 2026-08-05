#!/usr/bin/env python3
"""Migrate skills to schema v2: fix category enum, add status: stable where missing.

Usage:
    python3 migrate_schema_v2.py [--dry-run] [skill_dirs...]
    python3 migrate_schema_v2.py --dry-run content/skills/
    python3 migrate_schema_v2.py content/skills/
"""

import re
import sys
from pathlib import Path

CATEGORY_MAP = {
    # invalid -> valid
    "ai": "ai-agents",
    "devops": "infrastructure",
    "kubernetes": "infrastructure",
    "observability": "process",
    "sre": "process",
    "engineering": "quality",
    "testing": "quality",
    "planning": "quality",
    "git": "process",
    "architecture": "backend",
    "database": "data",
    "mobile": "frontend",
    "compliance": "security",
}

VALID_CATEGORIES = {
    "core",
    "ai-agents",
    "cloud",
    "infrastructure",
    "security",
    "data",
    "backend",
    "frontend",
    "quality",
    "process",
    "meta",
}


def fix_skill(skill_dir: Path, dry_run: bool = False) -> tuple[int, int, list[str]]:
    """Fix a single skill's SKILL.md. Returns (fixes, warnings, messages)."""
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return 0, 0, []

    original = skill_md.read_text()
    text = original
    fixes = []
    warnings = []

    # Fix category
    cat_match = re.search(r"(  category:\s*)(\S+)", text)
    if cat_match:
        cat = cat_match.group(2).strip("\"'")
        if cat not in VALID_CATEGORIES:
            if cat in CATEGORY_MAP:
                new_cat = CATEGORY_MAP[cat]
                text = text.replace(
                    cat_match.group(0), f"{cat_match.group(1)}{new_cat}", 1
                )
                fixes.append(f"category: {cat} -> {new_cat}")
            else:
                warnings.append(f"unknown category '{cat}' — manual fix needed")

    # Add status: stable if missing (inside metadata block, after category line)
    if "  status:" not in text:
        # Insert after category line
        text = re.sub(
            r"(  category:\s*\S+\n)",
            r"\1  status: stable\n",
            text,
            count=1,
        )
        fixes.append("added status: stable")

    if text == original:
        return (
            0,
            len(warnings),
            [f"  no changes needed"] + [f"  WARN {w}" for w in warnings],
        )

    if not dry_run:
        skill_md.write_text(text)

    prefix = "[DRY-RUN] " if dry_run else ""
    msgs = [f"  {prefix}FIX {f}" for f in fixes] + [f"  WARN {w}" for w in warnings]
    return len(fixes), len(warnings), msgs


def main():
    args = sys.argv[1:]
    dry_run = "--dry-run" in args
    paths = [a for a in args if not a.startswith("--")]

    if not paths:
        print("Usage: migrate_schema_v2.py [--dry-run] <skill_dir|parent_dir>...")
        sys.exit(1)

    total_fixed = 0
    total_warned = 0
    changed = []

    for p in paths:
        root = Path(p)
        # If given a parent dir, iterate children
        candidates = [root] if (root / "SKILL.md").exists() else sorted(root.iterdir())
        for candidate in candidates:
            if not candidate.is_dir():
                continue
            skill_md = candidate / "SKILL.md"
            if not skill_md.exists():
                continue
            fixes, warns, msgs = fix_skill(candidate, dry_run=dry_run)
            if fixes > 0 or warns > 0:
                print(f"{candidate.name}:")
                for m in msgs:
                    print(m)
                if fixes > 0:
                    changed.append(candidate.name)
            total_fixed += fixes
            total_warned += warns

    print(
        f"\nDone: {total_fixed} fixes, {total_warned} warnings, {len(changed)} skills modified."
    )
    if dry_run and total_fixed > 0:
        print("Re-run without --dry-run to apply.")


if __name__ == "__main__":
    main()
