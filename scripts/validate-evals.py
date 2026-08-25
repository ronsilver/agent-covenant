#!/usr/bin/env python3
"""Validate presence, schema, and minimal quality of skill evals.

Dual-schema validator:
  Schema A: {"skill_name", "evals": [{"prompt", "expected_output", ...}]}
  Schema B: {"skill", "version", "rubric", "test_cases": [{"input", "stratum",
            "expected_behaviors", "flags_to_avoid", ...}]}

Schema B validation is TWO-TIER:
  - Legacy variant (5 Core skills in SCHEMA_B_LEGACY_VARIANT): validated
    leniently. A case passes with >=1 non-empty behavior field (string or list)
    among BEHAVIOR_FIELDS; flags_to_avoid is optional but must be a list when
    present. Core files are NOT retrofitted (governance gate).
  - Canonical (all other Schema B files): validated strictly. Each case must
    have non-empty expected_behaviors AND non-empty flags_to_avoid; the file
    must have a numeric rubric.pass_threshold.

Usage:
  python3 scripts/validate-evals.py            # report mode (exit 0)
  python3 scripts/validate-evals.py --ci      # CI gate (exit 1 on any error)
"""

import argparse
import json
import os
import sys

SKILLS_DIR = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "content", "skills"
)
EVALS_RELPATH = os.path.join("evals", "evals.json")

# Tool-generated skills (gitnexus analyze); ADR-0037 exemption.
EXEMPT_SKILLS = {
    "gitnexus-cli",
    "gitnexus-debugging",
    "gitnexus-exploring",
    "gitnexus-guide",
    "gitnexus-impact-analysis",
    "gitnexus-pdg-query",
    "gitnexus-pr-review",
    "gitnexus-refactoring",
    "gitnexus-taint-analysis",
}

# Core skills use the real-world Schema B variant (routing/behavior fields).
# They are NOT retrofitted (governance gate) and are validated leniently.
SCHEMA_B_LEGACY_VARIANT = {
    "context-management",
    "engineering-standards",
    "operating-protocol",
    "skill-router",
    "tool-usage",
}

# Any of these fields, non-empty (string or list), marks a legacy case valid.
BEHAVIOR_FIELDS = (
    "expected_behaviors",
    "expected_skill",
    "must_not_route_to",
    "expected_tools",
    "discouraged_tools",
    "expected_flags",
    "expected_tier",
    "expected_behavior",
    "must_not",
    "reasoning",
    "expected_sequence",
    "routing",
)

STRATA = {"simple", "medium", "complex"}

errors = []
warnings = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warnings.append(msg)


def non_empty(value):
    """True for a non-empty string or a non-empty list."""
    if isinstance(value, str):
        return bool(value.strip())
    if isinstance(value, list):
        return bool(value)
    return False


def validate_schema_a(name, data):
    if data.get("skill_name") != name:
        err(
            f"[ERROR] {name}: Schema A 'skill_name' != dirname ({data.get('skill_name')!r})"
        )
    evals = data.get("evals")
    if not isinstance(evals, list):
        err(f"[ERROR] {name}: Schema A requires top-level 'evals' list")
        return
    if not evals:
        err(f"[ERROR] {name}: 'evals' list is empty (need >=1 case)")
        return
    for i, case in enumerate(evals):
        if not isinstance(case, dict):
            err(f"[ERROR] {name}: evals[{i}] is not an object")
            continue
        prompt = case.get("prompt")
        if not isinstance(prompt, str) or not prompt.strip():
            err(f"[ERROR] {name}: evals[{i}] missing non-empty 'prompt' string")
        exp = case.get("expected_output")
        if not isinstance(exp, str) or len(exp.strip()) < 60:
            err(
                f"[ERROR] {name}: evals[{i}] 'expected_output' must be a string >=60 chars"
            )
        for ph in ("[TODO", "PLACEHOLDER", "lorem ipsum"):
            if isinstance(prompt, str) and ph in prompt:
                err(f"[ERROR] {name}: evals[{i}] prompt contains placeholder {ph!r}")
            if isinstance(exp, str) and ph in exp:
                err(
                    f"[ERROR] {name}: evals[{i}] expected_output contains placeholder {ph!r}"
                )


def validate_schema_b(name, data):
    if data.get("skill") != name:
        err(f"[ERROR] {name}: Schema B 'skill' != dirname ({data.get('skill')!r})")
    tcs = data.get("test_cases")
    if not isinstance(tcs, list):
        err(f"[ERROR] {name}: Schema B requires top-level 'test_cases' list")
        return
    if not tcs:
        err(f"[ERROR] {name}: 'test_cases' list is empty (need >=1 case)")
        return
    legacy = name in SCHEMA_B_LEGACY_VARIANT
    if not legacy:
        rubric = data.get("rubric")
        if not isinstance(rubric, dict) or not isinstance(
            rubric.get("pass_threshold"), (int, float)
        ):
            err(
                f"[ERROR] {name}: canonical Schema B requires numeric rubric.pass_threshold"
            )
    for i, tc in enumerate(tcs):
        if not isinstance(tc, dict):
            err(f"[ERROR] {name}: test_cases[{i}] is not an object")
            continue
        inp = tc.get("input")
        if not isinstance(inp, str) or not inp.strip():
            err(f"[ERROR] {name}: test_cases[{i}] missing non-empty 'input' string")
        stratum = tc.get("stratum")
        if stratum not in STRATA:
            err(
                f"[ERROR] {name}: test_cases[{i}] 'stratum' must be one of {sorted(STRATA)}"
            )
        if legacy:
            if not any(non_empty(tc.get(f)) for f in BEHAVIOR_FIELDS):
                err(
                    f"[ERROR] {name}: test_cases[{i}] legacy Schema B requires >=1 non-empty behavior field from {sorted(BEHAVIOR_FIELDS)}"
                )
            fta = tc.get("flags_to_avoid")
            if fta is not None and not isinstance(fta, list):
                err(
                    f"[ERROR] {name}: test_cases[{i}] 'flags_to_avoid' must be a list when present"
                )
        else:
            eb = tc.get("expected_behaviors")
            if not isinstance(eb, list) or not eb:
                err(
                    f"[ERROR] {name}: test_cases[{i}] 'expected_behaviors' must be a non-empty list"
                )
            fta = tc.get("flags_to_avoid")
            if not isinstance(fta, list) or not fta:
                err(
                    f"[ERROR] {name}: test_cases[{i}] 'flags_to_avoid' must be a non-empty list"
                )


def main():
    ap = argparse.ArgumentParser(description="Validate skill evals")
    ap.add_argument("--ci", action="store_true", help="CI gate: exit 1 on any error")
    args = ap.parse_args()

    if not os.path.isdir(SKILLS_DIR):
        err(f"[ERROR] skills dir not found: {SKILLS_DIR}")
    else:
        for name in sorted(os.listdir(SKILLS_DIR)):
            skill_dir = os.path.join(SKILLS_DIR, name)
            if not os.path.isdir(skill_dir):
                continue
            if name.startswith("_") or name.startswith("."):
                continue
            evals_path = os.path.join(skill_dir, EVALS_RELPATH)
            if not os.path.exists(evals_path):
                if name not in EXEMPT_SKILLS:
                    err(f"[ERROR] {name}: missing {EVALS_RELPATH}")
                else:
                    warn(f"[WARN] {name}: exempt from evals (allowlist)")
                continue
            try:
                with open(evals_path, encoding="utf-8") as fh:
                    data = json.load(fh)
            except json.JSONDecodeError as exc:
                err(f"[ERROR] {name}: invalid JSON in {EVALS_RELPATH}: {exc}")
                continue
            if not isinstance(data, dict):
                err(f"[ERROR] {name}: evals.json top level must be an object")
                continue
            if "test_cases" in data:
                validate_schema_b(name, data)
            elif "evals" in data:
                validate_schema_a(name, data)
            else:
                err(
                    f"[ERROR] {name}: evals.json has neither 'test_cases' nor 'evals' (unknown schema)"
                )

    for msg in errors:
        print(msg)
    for msg in warnings:
        print(msg)

    print(f"[RESULT] {len(errors)} error(s), {len(warnings)} warning(s)")
    if args.ci:
        return 1 if errors else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
