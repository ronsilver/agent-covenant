#!/usr/bin/env python3
"""Exact p1 manifest parser for the opencode benchmark harness. Stdlib only.

Parses only the ``skills.directories`` YAML sequence from ``manifest.yaml``.
Requires exactly 63 unique existing strings. Rejects malformed YAML, duplicate
entries, missing paths, unexpected types, or any I/O error by raising
``ManifestError``; the CLI maps that to exit 2 and ``INCONCLUSIVE``. There is
no fallback count.
"""

from pathlib import Path

REQUIRED_SKILL_COUNT = 63


class ManifestError(ValueError):
    """Raised when the manifest skills block is malformed or non-conformant."""


def _find_directories_block(lines):
    """Locate the skills.directories sequence; return (start, indent, end)."""
    in_skills = False
    in_directories = False
    seq_indent = None
    start = None
    for idx, raw in enumerate(lines):
        line = raw.rstrip("\n")
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        if not in_skills:
            if stripped == "skills:" and indent == 0:
                in_skills = True
            continue
        if in_directories:
            if stripped.startswith("- ") and indent == seq_indent:
                continue
            return start, idx  # sequence ended
        if stripped == "directories:" and indent == 2:
            in_directories = True
            seq_indent = indent + 2
            start = idx + 1
            continue
        if indent == 0:
            return None, None  # left skills mapping without directories
    if in_directories:
        return start, len(lines)
    return None, None


def parse_manifest_skills(path):
    """Return the validated list of 63 unique skill directory names.

    Raises ManifestError for malformed YAML, duplicates, missing paths,
    unexpected types, or I/O errors."""
    try:
        text = Path(path).read_text(encoding="utf-8")
    except OSError as exc:
        raise ManifestError(f"cannot read manifest: {exc}") from exc
    lines = text.splitlines()
    start, end = _find_directories_block(lines)
    if start is None:
        raise ManifestError("skills.directories sequence not found")
    names = []
    for raw in lines[start:end]:
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if not stripped.startswith("- "):
            raise ManifestError(f"malformed YAML in skills.directories: {stripped!r}")
        item = stripped[2:].strip()
        if not item or any(ch in item for ch in "{}[]:"):
            raise ManifestError(f"unexpected YAML type in skills.directories: {item!r}")
        names.append(item)
    if len(names) != REQUIRED_SKILL_COUNT:
        raise ManifestError(
            f"skills.directories has {len(names)} entries; "
            f"expected {REQUIRED_SKILL_COUNT}"
        )
    if len(set(names)) != len(names):
        raise ManifestError("skills.directories contains duplicate entries")
    for name in names:
        skill_dir = Path(path).resolve().parent / "content" / "skills" / name
        if not (skill_dir / "SKILL.md").is_file():
            raise ManifestError(f"skill path missing: {skill_dir}")
    return names
