#!/usr/bin/env python3
"""validate-shell-safety.py — Scan content/ for ! outside fenced code blocks.

These patterns trigger Zsh history expansion when loaded by any AI agent
(OpenCode, Claude Code, Cursor, etc.), causing permission errors like:
"Bash command permission check failed for pattern '!*'"

Dangerous patterns: !"  !'  !`  !*  (bang followed by quote/backtick/star)

Usage:
  python3 scripts/validate-shell-safety.py          # scan all
  python3 scripts/validate-shell-safety.py --ci     # exit 1 on violations
  python3 scripts/validate-shell-safety.py --file x.md  # single file
"""

import os
import re
import sys

CONTENT_DIR = os.path.join(os.path.dirname(__file__), "..", "content")

def scan_file(filepath: str, content_dir: str) -> list:
    """Return list of (relative_path, line_number, line_text) for violations."""
    violations = []
    in_fence = False
    rel_path = os.path.relpath(filepath, content_dir)

    with open(filepath, "r") as f:
        for line_num, line in enumerate(f, 1):
            stripped = line.rstrip("\n")

            if stripped.startswith("```"):
                in_fence = not in_fence
                continue

            if in_fence:
                continue

            # Check for dangerous ! patterns: !"  !'  !`  !*
            if re.search(r'!["\'`\*]', stripped):
                violations.append((rel_path, line_num, stripped.strip()))

    return violations


def main():
    ci_mode = "--ci" in sys.argv
    target = None
    if "--file" in sys.argv:
        idx = sys.argv.index("--file") + 1
        if idx < len(sys.argv):
            target = sys.argv[idx]

    print("Scanning for shell-unsafe '!' patterns in content/")
    print()

    all_violations = []

    if target:
        if not os.path.isfile(target):
            print(f"File not found: {target}")
            sys.exit(1)
        all_violations = scan_file(target, os.path.dirname(target))
    else:
        for root, dirs, files in os.walk(CONTENT_DIR):
            dirs[:] = [d for d in dirs if d != "node_modules"]
            # Skip _TEMPLATE — its Shell Safety section intentionally documents dangerous patterns
            if "_TEMPLATE" in root:
                continue
            for fn in files:
                if not fn.endswith(".md"):
                    continue
                fp = os.path.join(root, fn)
                all_violations.extend(scan_file(fp, CONTENT_DIR))

    for rel_path, line_num, line_text in all_violations:
        print(f"  VIOLATION {rel_path}:{line_num}  {line_text[:80]}")

    count = len(all_violations)
    print()
    if count > 0:
        print(f"FAIL: {count} shell-unsafe '!' patterns found.")
        print("Fix: replace '!' with clear prose (e.g., 'not', 'avoid', 'without').")
        if ci_mode:
            sys.exit(1)
    else:
        print("PASS: No shell-unsafe '!' patterns found.")


if __name__ == "__main__":
    main()
