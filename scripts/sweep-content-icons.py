#!/usr/bin/env python3
"""Sweep all status icons and dingbats from content/ files.
Replaces icons with text labels per AGENTS.md invariant #9.
Excludes: arrows (→ ←), bullets (•), em-dashes — prose typography.
Run: python3 scripts/sweep-content-icons.py          # fixer: rewrite files in place, exit 0
     python3 scripts/sweep-content-icons.py --check  # gate: report + exit 1 if any replacement is needed
Exit 0 = clean (or fixed); exit 1 = --check found replacements the fixer would make.
"""

import os
import sys

# Icon → replacement map (order matters: longest/most-specific first)
REPLACEMENTS = [
    # Colored circles (severity)
    ("🔴", "[BLOCKER]"),
    ("🟠", "[MAJOR]"),
    ("🟡", "[WARN]"),
    ("🟢", "[LOW]"),
    ("⚪", "[INFO]"),
    ("⚫", "[INFO]"),
    # Status emoji
    ("✅", "PASS:"),
    ("❌", "FAIL:"),
    ("❎", "FAIL:"),
    ("⚠️", "[WARN]"),
    ("⚠", "[WARN]"),
    ("⚡", "[WARN]"),
    ("🔒", "[LOCKED]"),
    ("🔓", "[UNLOCKED]"),
    ("🔐", "[ENCRYPTED]"),
    ("🏷️", "[LABEL]"),
    ("🏷", "[LABEL]"),
    ("✏️", "[EDIT]"),
    ("✏", "[EDIT]"),
    ("⭐", "[STAR]"),
    ("✨", "[NEW]"),
    ("💡", "[TIP]"),
    ("🔥", "[HOT]"),
    ("📌", "[PIN]"),
    ("🔍", "[SEARCH]"),
    ("🚨", "[ALERT]"),
    ("💬", "[COMMENT]"),
    ("🎉", "[DONE]"),
    # Dingbats used as status markers
    ("✔", "PASS"),
    ("✖", "FAIL"),
    ("✓", "PASS"),
    ("✗", "FAIL"),
    ("▶", ">"),
    ("◀", "<"),
    # Exclamation/question emoji
    ("❗", "!"),
    ("❓", "?"),
    ("❔", "?"),
    ("❕", "!"),
    # Skip-ahead glyph (validation workflow status markers)
    ("⏭️", "[SKIPPED]"),
    ("⏭", "[SKIPPED]"),
]

CONTENT_DIR = os.path.join(os.path.dirname(__file__), "..", "content")
CHECK_MODE = "--check" in sys.argv

changed_files = []
total_replacements = 0

for root, dirs, files in os.walk(CONTENT_DIR):
    for fname in files:
        fpath = os.path.join(root, fname)
        if not fpath.endswith((".md", ".py", ".sh", ".json", ".yaml", ".yml")):
            continue
        if fname == ".DS_Store":
            continue
        try:
            with open(fpath, encoding="utf-8") as f:
                content = f.read()
        except (UnicodeDecodeError, IsADirectoryError):
            continue
        original = content
        file_replacements = 0
        for icon, replacement in REPLACEMENTS:
            count = content.count(icon)
            if count:
                content = content.replace(icon, replacement)
                file_replacements += count
        if content != original:
            changed_files.append((fpath, file_replacements))
            total_replacements += file_replacements
            if not CHECK_MODE:
                with open(fpath, "w", encoding="utf-8") as f:
                    f.write(content)

if CHECK_MODE:
    if total_replacements:
        print(
            f"Check failed: {total_replacements} replacement(s) needed in "
            f"{len(changed_files)} file(s). Run the fixer (no --check) to apply."
        )
        for fpath, n in sorted(changed_files, key=lambda x: -x[1])[:30]:
            print(f"  {n:4d}  {fpath}")
        sys.exit(1)
    print("Check passed: no icons or dingbats found in content/.")
    sys.exit(0)

print(
    f"Sweep complete: {total_replacements} replacements in {len(changed_files)} files"
)
for fpath, n in sorted(changed_files, key=lambda x: -x[1])[:30]:
    print(f"  {n:4d}  {fpath}")
sys.exit(0)
