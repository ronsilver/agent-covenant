#!/usr/bin/env python3
"""Sweep all status icons and dingbats from content/ files.
Replaces icons with text labels per AGENTS.md invariant #9.
Excludes: arrows (→ ←), bullets (•), em-dashes — prose typography.
Run: python3 scripts/sweep-content-icons.py
"""

import os, sys

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
]

CONTENT_DIR = os.path.join(os.path.dirname(__file__), "..", "content")
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
            with open(fpath, "w", encoding="utf-8") as f:
                f.write(content)
            changed_files.append((fpath, file_replacements))
            total_replacements += file_replacements

print(
    f"Sweep complete: {total_replacements} replacements in {len(changed_files)} files"
)
for fpath, n in sorted(changed_files, key=lambda x: -x[1])[:30]:
    print(f"  {n:4d}  {fpath}")
sys.exit(0)
