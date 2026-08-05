#!/usr/bin/env python3
"""
Quick validation script for skills - v2 (schema v2 support).

Usage:
    python quick_validate.py <skill_directory>           # legacy mode (default)
    python quick_validate.py <skill_directory> --strict  # strict mode (schema v2)
    python quick_validate.py <skill_directory> --legacy  # explicit legacy mode

Modes:
    --legacy (default): only errors on required v1 fields (name, description, license).
                        Missing v2 fields (metadata.author/version/category) emit WARNINGs.
    --strict:           errors on all required v2 fields. Use after S5 migration is complete.

See: docs/adr/0006-skill-metadata-schema.md
"""

import sys
import re
from pathlib import Path

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

VALID_STATUSES = {"stable", "beta", "deprecated"}

ALLOWED_PROPERTIES = {
    "name",
    "description",
    "license",
    "metadata",
    "aliases",
    "allowed-tools",
    "skills",
    "compatibility",
    "disable-model-invocation",
    "applyTo",
    "setup",
}


def _parse_frontmatter(text):
    """Parse simple YAML frontmatter using regex (no PyYAML dependency).

    Handles single-line 'key: value' and two-level 'key:\n  subkey: value' pairs.
    Returns a flat dict where nested keys are joined with '.'.
    """
    result = {}
    current_parent = None
    for line in text.splitlines():
        indent_match = re.match(r"^( +)([a-zA-Z_-]+)\s*:\s*(.*)", line)
        top_match = re.match(r"^([a-zA-Z_-]+)\s*:\s*(.*)", line)
        if indent_match and current_parent:
            _, key, val = indent_match.groups()
            val = val.strip().strip('"').strip("'")
            result[f"{current_parent}.{key.strip()}"] = val
        elif top_match and not line.startswith(" "):
            key, val = top_match.group(1).strip(), top_match.group(2).strip()
            val = val.strip('"').strip("'")
            result[key] = val
            current_parent = key if not val else None
    return result


def _check_semver(version):
    """Return True if version looks like semver (1.0, 1.0.0, 2.1)."""
    return bool(re.match(r"^\d+\.\d+(\.\d+)?$", version))


def validate_skill(skill_path, strict=False):
    """Validate a skill directory against schema v1 (legacy) or v2 (strict).

    Returns (errors, warnings) — both lists of strings.
    """
    errors = []
    warnings = []
    skill_path = Path(skill_path)

    skill_md = skill_path / "SKILL.md"
    if not skill_md.exists():
        errors.append("SKILL.md not found")
        return errors, warnings

    content = skill_md.read_text()
    if not content.startswith("---"):
        errors.append("No YAML frontmatter found")
        return errors, warnings

    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        errors.append("Invalid frontmatter format")
        return errors, warnings

    frontmatter_text = match.group(1)
    frontmatter = _parse_frontmatter(frontmatter_text)

    if not frontmatter:
        errors.append("Frontmatter must be a YAML dictionary with key-value pairs")
        return errors, warnings

    top_keys = {k.split(".")[0] for k in frontmatter}
    unexpected = top_keys - ALLOWED_PROPERTIES
    if unexpected:
        errors.append(
            f"Unexpected key(s) in frontmatter: {', '.join(sorted(unexpected))}. "
            f"Allowed: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # ── Required v1 fields (always errors) ──────────────────────────────────
    if "name" not in frontmatter:
        errors.append("Missing required field: 'name'")
    else:
        name = frontmatter["name"].strip()
        if not re.match(r"^[a-z0-9-]+$", name):
            errors.append(f"'name' must be kebab-case, got: '{name}'")
        elif name.startswith("-") or name.endswith("-") or "--" in name:
            errors.append(
                f"'name' cannot start/end with hyphen or have consecutive hyphens: '{name}'"
            )
        elif len(name) > 64:
            errors.append(f"'name' too long ({len(name)} chars, max 64)")

    if "description" not in frontmatter:
        errors.append("Missing required field: 'description'")
    else:
        desc = frontmatter["description"].strip()
        if "<" in desc or ">" in desc:
            errors.append("'description' cannot contain angle brackets")
        if len(desc) > 1024:
            errors.append(f"'description' too long ({len(desc)} chars, max 1024)")
        if len(desc) < 50:
            warnings.append(
                f"'description' is very short ({len(desc)} chars, recommend ≥50)"
            )
        if "use when" not in desc.lower():
            warnings.append("'description' should contain 'Use when' to guide routing")

    if "license" not in frontmatter:
        errors.append("Missing required field: 'license'")

    # ── Required v2 fields (error in strict, warning in legacy) ─────────────
    def _v2_require(field, label):
        val = frontmatter.get(field, "").strip()
        if not val:
            msg = f"Missing required v2 field: '{label}'"
            if strict:
                errors.append(msg)
            else:
                warnings.append(f"[schema-v2] {msg}")
        return val

    author = _v2_require("metadata.author", "metadata.author")
    version = _v2_require("metadata.version", "metadata.version")
    category = _v2_require("metadata.category", "metadata.category")

    if version and not _check_semver(version):
        msg = f"'metadata.version' should be semver (e.g. '1.0'), got: '{version}'"
        if strict:
            errors.append(msg)
        else:
            warnings.append(f"[schema-v2] {msg}")

    if category and category not in VALID_CATEGORIES:
        msg = (
            f"'metadata.category' invalid: '{category}'. "
            f"Valid: {', '.join(sorted(VALID_CATEGORIES))}"
        )
        if strict:
            errors.append(msg)
        else:
            warnings.append(f"[schema-v2] {msg}")

    # ── Optional v2 fields (validation only) ────────────────────────────────
    status = frontmatter.get("metadata.status", "").strip()
    if status and status not in VALID_STATUSES:
        warnings.append(
            f"'metadata.status' should be one of {sorted(VALID_STATUSES)}, got: '{status}'"
        )

    compatibility = frontmatter.get("compatibility", "").strip()
    if compatibility and len(compatibility) > 500:
        errors.append(f"'compatibility' too long ({len(compatibility)} chars, max 500)")

    return errors, warnings


def main():
    args = sys.argv[1:]
    strict = "--strict" in args
    args = [a for a in args if a not in ("--strict", "--legacy")]

    if not args:
        print("Usage: python quick_validate.py <skill_directory> [--strict|--legacy]")
        sys.exit(1)

    skill_path = args[0]
    errors, warnings = validate_skill(skill_path, strict=strict)

    mode = "strict" if strict else "legacy"
    print(f"Validating: {skill_path} [{mode} mode]")

    for w in warnings:
        print(f"  WARN  {w}")
    for e in errors:
        print(f"  ERROR {e}")

    if not errors and not warnings:
        print("  OK    Skill is valid!")
    elif not errors:
        print(f"  OK    Skill valid with {len(warnings)} warning(s).")

    sys.exit(0 if not errors else 1)


if __name__ == "__main__":
    main()
