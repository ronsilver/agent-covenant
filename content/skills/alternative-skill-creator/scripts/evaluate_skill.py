#!/usr/bin/env python3
"""
Automated skill evaluation pipeline for skill-creator.

Runs evals/evals.json against target + judge models via Ollama,
computes with_skill vs without_skill baseline, and writes artifacts.

Usage:
    python evaluate_skill.py <skill-dir>
    python evaluate_skill.py <skill-dir> --target-model deepseekv4-pro:cloud --judge-model kimi-k2.6:cloud
    python evaluate_skill.py <skill-dir> --modes with_skill --iterations 3
    python evaluate_skill.py <skill-dir> --baseline --output-dir ./workspace
"""

import json
import os
import re
import sys
import time
import argparse
import statistics
import concurrent.futures
from pathlib import Path
from collections import defaultdict

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None

DEFAULT_TARGET = "deepseekv4-pro:cloud"
DEFAULT_JUDGE = "kimi-k2.6:cloud"
DEFAULT_OLLAMA_URL = os.environ.get("OLLAMA_URL", "http://localhost:11434/v1")
OLLAMA_CLOUD_URL = "https://ollama.com/v1"

VALID_TOOL_ASSERTION_TYPES = {
    "tool-called",
    "tool-not-called",
    "tool-arg-equals",
    "tool-arg-contains",
    "tool-arg-matches",
    "tool-call-count",
}


def slugify(text, fallback="eval"):
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", text).strip("-").lower()
    return slug if len(slug) >= 2 else fallback


def now_ms():
    return int(time.time() * 1000)


def deep_equal(a, b):
    if a is b:
        return True
    if type(a) is not type(b):
        return False
    if a is None or b is None:
        return False
    if not isinstance(a, (str, int, float, bool, list, dict)):
        return False
    return json.dumps(a, sort_keys=True, default=str) == json.dumps(
        b, sort_keys=True, default=str
    )


def get_by_path(root, path_str):
    tokens = []
    for m in re.finditer(r"[^.\[\]]+|\[(\d+)\]", path_str):
        idx = m.group(1)
        tokens.append(int(idx) if idx is not None else m.group(0))
    cur = root
    for tok in tokens:
        if cur is None or not isinstance(cur, (dict, list)):
            return None
        try:
            cur = cur[tok] if isinstance(cur, dict) else cur[int(tok)]
        except (IndexError, KeyError, TypeError, ValueError):
            return None
    return cur


def extract_json_object(value):
    trimmed = value.strip()
    if trimmed.startswith("{") and trimmed.endswith("}"):
        return trimmed
    first = trimmed.find("{")
    last = trimmed.rfind("}")
    return trimmed[first : last + 1] if first >= 0 and last > first else trimmed


def truncate(value, max_len=1200):
    return value if len(value) <= max_len else value[:max_len] + "..."


def parse_frontmatter(text):
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


def parse_assertion_string(entry):
    if isinstance(entry, str):
        return entry
    if isinstance(entry, dict):
        return entry.get("text") or entry.get("value") or entry.get("criterion") or ""
    raise ValueError(
        f"Assertion must be string or {{text/value/criterion: string}}, got {type(entry).__name__}"
    )


def parse_tool_assertion(entry, where):
    if not isinstance(entry, dict):
        raise ValueError(f"{where} must be an object")
    t = entry.get("type")
    if t not in VALID_TOOL_ASSERTION_TYPES:
        raise ValueError(
            f"{where}.type must be one of: {', '.join(sorted(VALID_TOOL_ASSERTION_TYPES))}"
        )
    desc = entry.get("description", "")
    name = entry.get("name")
    if t in ("tool-called", "tool-not-called"):
        if not name:
            raise ValueError(f"{where}.name is required for {t}")
        return {"type": t, "name": name, "description": desc}
    if t in ("tool-arg-equals", "tool-arg-contains", "tool-arg-matches"):
        if not name:
            raise ValueError(f"{where}.name is required")
        if not isinstance(entry.get("path"), str):
            raise ValueError(f"{where}.path is required")
        result = {"type": t, "name": name, "path": entry["path"], "description": desc}
        if t == "tool-arg-equals":
            result["value"] = entry.get("value")
        elif t == "tool-arg-contains":
            if not isinstance(entry.get("value"), str):
                raise ValueError(f"{where}.value must be a string")
            result["value"] = entry["value"]
        elif t == "tool-arg-matches":
            if not isinstance(entry.get("pattern"), str):
                raise ValueError(f"{where}.pattern is required")
            result["pattern"] = entry["pattern"]
            if isinstance(entry.get("flags"), str):
                result["flags"] = entry["flags"]
        return result
    if t == "tool-call-count":
        min_v = entry.get("min")
        max_v = entry.get("max")
        if min_v is None and max_v is None:
            raise ValueError(f"{where} requires at least one of min or max")
        result = {"type": t, "description": desc}
        if name:
            result["name"] = name
        if min_v is not None:
            result["min"] = int(min_v)
        if max_v is not None:
            result["max"] = int(max_v)
        return result
    raise ValueError(f"{where}: unhandled type {t}")


def load_skill(skill_dir):
    skill_md = Path(skill_dir) / "SKILL.md"
    evals_path = Path(skill_dir) / "evals" / "evals.json"

    if not skill_md.exists():
        raise FileNotFoundError(f"SKILL.md not found: {skill_md}")

    content = skill_md.read_text()
    fm = {}
    body = content
    if content.startswith("---"):
        m = re.match(r"^---\r?\n(.*?)\r?\n---", content, re.DOTALL)
        if m:
            fm = parse_frontmatter(m.group(1))
            body = content[m.end() :].strip()

    name = fm.get("name", Path(skill_dir).name)
    skill = {
        "name": name,
        "description": fm.get("description", ""),
        "dir": str(Path(skill_dir).resolve()),
        "skillMd": body,
        "references": [],
        "scripts": [],
        "evals": [],
        "defaults": None,
        "evalFilesDir": None,
    }

    refs_dir = Path(skill_dir) / "references"
    if refs_dir.exists():
        for f in sorted(refs_dir.rglob("*")):
            if f.is_file() and f.suffix.lower() in (".md", ".mdx"):
                skill["references"].append(
                    {"path": str(f.relative_to(skill_dir)), "content": f.read_text()}
                )

    scripts_dir = Path(skill_dir) / "scripts"
    if scripts_dir.exists():
        for f in sorted(scripts_dir.iterdir()):
            if f.is_file() and f.name != os.path.basename(__file__):
                first_line = (
                    f.read_text().split("\n", 1)[0] if f.stat().st_size > 0 else ""
                )
                skill["scripts"].append(
                    {"path": str(f.relative_to(skill_dir)), "content": first_line}
                )

    if not evals_path.exists():
        print(f"WARN: No evals/evals.json found in {skill_dir}")
        return skill

    evals_data = json.loads(evals_path.read_text())
    skill["defaults"] = parse_defaults(evals_data.get("defaults"))
    # Dual-schema support: Schema B (test_cases) carries its fields NATIVELY on
    # the case struct (expected_behaviors[] / flags_to_avoid[] / expected_tier /
    # pass_threshold), plus a synthesized expected_output for judge
    # backward-compatibility. Schema A (evals) passes through unchanged.
    if "test_cases" in evals_data:
        raw_cases = evals_data["test_cases"]
        skill["evals"] = [
            parse_eval_case(
                {
                    "id": tc.get("id", i + 1),
                    "prompt": tc.get("input", ""),
                    "expected_behaviors": tc.get("expected_behaviors"),
                    "flags_to_avoid": tc.get("flags_to_avoid"),
                    "expected_tier": tc.get("expected_tier"),
                    "pass_threshold": (evals_data.get("rubric") or {}).get(
                        "pass_threshold"
                    ),
                    "expected_output": _behaviors_to_output(
                        tc.get("expected_behaviors")
                    ),
                },
                i,
            )
            for i, tc in enumerate(raw_cases)
        ]
    else:
        skill["evals"] = [
            parse_eval_case(e, i) for i, e in enumerate(evals_data.get("evals", []))
        ]

    eval_files_dir = Path(skill_dir) / "evals" / "files"
    if eval_files_dir.exists():
        skill["evalFilesDir"] = str(eval_files_dir)
        for eval_case in skill["evals"]:
            resolved = []
            for f in eval_case.get("files") or []:
                fpath = eval_files_dir / f
                if fpath.exists():
                    resolved.append(
                        {
                            "path": f,
                            "content": fpath.read_text(),
                            "kind": "text",
                            "bytes": fpath.stat().st_size,
                        }
                    )
                else:
                    resolved.append(
                        {"path": f, "content": "", "kind": "missing", "bytes": 0}
                    )
            eval_case["_resolved_files"] = resolved

    return skill


def parse_defaults(defaults_raw):
    if not defaults_raw or not isinstance(defaults_raw, dict):
        return None
    result = {}
    for key in ("target", "judge"):
        section = defaults_raw.get(key)
        if isinstance(section, dict) and isinstance(section.get("params"), dict):
            result[key] = {"params": section["params"]}
    tools_raw = defaults_raw.get("tools")
    if isinstance(tools_raw, list):
        result["tools"] = tools_raw
    return result if result else None


def _behaviors_to_output(behaviors):
    """Flatten Schema B expected_behaviors into a single expected_output string."""
    if not isinstance(behaviors, list) or not behaviors:
        return None
    return "\n".join(str(b) for b in behaviors)


def parse_eval_case(entry, index):
    if not isinstance(entry, dict):
        raise ValueError(f"Each eval must be an object (index {index})")
    if not isinstance(entry.get("prompt"), str):
        raise ValueError(f"Each eval requires a prompt string (index {index})")
    case = {
        "id": entry.get("id", index + 1),
        "name": entry.get("name"),
        "prompt": entry["prompt"],
        "expected_output": entry.get("expected_output"),
        "expected_behaviors": entry.get("expected_behaviors")
        if isinstance(entry.get("expected_behaviors"), list)
        else None,
        "flags_to_avoid": entry.get("flags_to_avoid")
        if isinstance(entry.get("flags_to_avoid"), list)
        else None,
        "expected_tier": entry.get("expected_tier"),
        "pass_threshold": entry.get("pass_threshold"),
        "files": entry.get("files") if isinstance(entry.get("files"), list) else None,
        "assertions": None,
        "params": entry.get("params")
        if isinstance(entry.get("params"), dict)
        else None,
        "tools": entry.get("tools") if isinstance(entry.get("tools"), list) else None,
        "tool_choice": entry.get("tool_choice"),
        "tool_assertions": None,
        "_resolved_files": [],
    }
    raw_assertions = entry.get("assertions")
    if isinstance(raw_assertions, list):
        case["assertions"] = [parse_assertion_string(a) for a in raw_assertions]
    raw_tool_assertions = entry.get("tool_assertions")
    if isinstance(raw_tool_assertions, list):
        case["tool_assertions"] = [
            parse_tool_assertion(a, f"evals[{index}].tool_assertions[{i}]")
            for i, a in enumerate(raw_tool_assertions)
        ]
    return case


def merge_params(*layers):
    merged = {}
    any_set = False
    for layer in layers:
        if layer:
            merged.update(layer)
            any_set = True
    return merged if any_set else None


def render_skill_system(skill):
    parts = [
        f'<skill name="{skill["name"]}">',
        f"<description>{skill['description']}</description>",
        "<instructions>",
        skill["skillMd"],
        "</instructions>",
    ]
    if skill.get("references"):
        parts.append("<references>")
        for ref in skill["references"]:
            parts.append(
                f'<reference path="{ref["path"]}">\n{ref["content"]}\n</reference>'
            )
        parts.append("</references>")
    if skill.get("scripts"):
        parts.append("<scripts>")
        for sc in skill["scripts"]:
            parts.append(f'<script path="{sc["path"]}">\n{sc["content"]}\n</script>')
        parts.append("</scripts>")
    parts.append("</skill>")
    return "\n".join(parts)


def build_messages(skill, eval_case, mode, ollama_client, target_model):
    user_msg = eval_case["prompt"]
    files = eval_case.get("_resolved_files") or []
    file_blocks = []
    for f in files:
        if f["kind"] == "text":
            file_blocks.append(f'<file path="{f["path"]}">\n{f["content"]}\n</file>')

    if mode == "with_skill":
        system = render_skill_system(skill)
        if file_blocks:
            user_msg = "\n\n".join(file_blocks) + "\n\n---USER PROMPT---\n" + user_msg
        return [
            {"role": "system", "content": system},
            {"role": "user", "content": user_msg},
        ]
    else:
        if file_blocks:
            user_msg = "\n\n".join(file_blocks) + "\n\n---USER PROMPT---\n" + user_msg
        return [
            {"role": "user", "content": user_msg},
        ]


def call_ollama(messages, model, client, params=None):
    start = now_ms()
    kwargs = {
        "model": model,
        "messages": messages,
        "temperature": (params or {}).get("temperature", 0),
    }
    if params:
        for k, v in params.items():
            if k in ("max_tokens", "top_p", "frequency_penalty", "presence_penalty"):
                kwargs[k] = v
    try:
        resp = client.chat.completions.create(**kwargs)
        elapsed = now_ms() - start
        choice = resp.choices[0] if resp.choices else None
        output = choice.message.content if choice else ""
        tool_calls = []
        if choice and choice.message.tool_calls:
            for tc in choice.message.tool_calls:
                parsed = {}
                try:
                    parsed = (
                        json.loads(tc.function.arguments)
                        if tc.function.arguments
                        else {}
                    )
                except (json.JSONDecodeError, TypeError):
                    pass
                tool_calls.append(
                    {
                        "id": tc.id,
                        "function": {
                            "name": tc.function.name,
                            "arguments": tc.function.arguments or "",
                        },
                        "parsedArguments": parsed,
                    }
                )
        return {
            "output": output,
            "tool_calls": tool_calls,
            "timing": {
                "total_tokens": (resp.usage.prompt_tokens if resp.usage else 0)
                + (resp.usage.completion_tokens if resp.usage else 0),
                "duration_ms": elapsed,
            },
            "error": None,
        }
    except Exception as e:
        elapsed = now_ms() - start
        return {
            "output": "",
            "tool_calls": [],
            "timing": {"total_tokens": 0, "duration_ms": elapsed},
            "error": str(e),
        }


def run_tool_assertions(tool_calls, tool_assertions):
    results = []
    if not tool_assertions:
        return results

    for a in tool_assertions:
        text = a.get("description") or f"{a['type']}"
        name = a.get("name")
        matches = [
            tc
            for tc in (tool_calls or [])
            if not name or tc["function"]["name"] == name
        ]
        observed_names = (
            ", ".join(tc["function"]["name"] for tc in (tool_calls or [])) or "(none)"
        )

        if a["type"] == "tool-called":
            passed = len(matches) > 0
            results.append(
                {
                    "text": text,
                    "passed": passed,
                    "evidence": f"{name} called {len(matches)} time(s)"
                    if passed
                    else f"{name} not called; observed: {observed_names}",
                }
            )
        elif a["type"] == "tool-not-called":
            passed = len(matches) == 0
            results.append(
                {
                    "text": text,
                    "passed": passed,
                    "evidence": f"confirmed: {name} never called"
                    if passed
                    else f"{name} was called {len(matches)} time(s)",
                }
            )
        elif a["type"] in ("tool-arg-equals", "tool-arg-contains", "tool-arg-matches"):
            if len(matches) == 0:
                results.append(
                    {
                        "text": text,
                        "passed": False,
                        "evidence": f"{name} not called; observed: {observed_names}",
                    }
                )
                continue
            path = a["path"]
            passed = False
            evidence = f"expected {a.get('value', a.get('pattern', ''))}; not matched"
            for tc in matches:
                args = tc.get("parsedArguments")
                if args is None:
                    continue
                actual = get_by_path(args, path)
                if a["type"] == "tool-arg-equals" and deep_equal(
                    actual, a.get("value")
                ):
                    passed = True
                    evidence = f"{name}.{path} = {json.dumps(actual)}"
                    break
                elif (
                    a["type"] == "tool-arg-contains"
                    and isinstance(actual, str)
                    and a.get("value") in actual
                ):
                    passed = True
                    evidence = f"{name}.{path} = {json.dumps(actual)}"
                    break
                elif a["type"] == "tool-arg-matches":
                    try:
                        regex = re.compile(
                            a["pattern"],
                            re.IGNORECASE if a.get("flags", "").find("i") >= 0 else 0,
                        )
                        if isinstance(actual, str) and regex.search(actual):
                            passed = True
                            evidence = f"{name}.{path} = {json.dumps(actual)}"
                            break
                    except re.error:
                        evidence = f"invalid regex /{a['pattern']}/"
            seen = (
                ", ".join(
                    json.dumps(get_by_path(tc.get("parsedArguments"), path))
                    for tc in matches
                )
                or "(none)"
            )
            if not passed:
                evidence = f"{evidence}; observed {seen}"
            results.append({"text": text, "passed": passed, "evidence": evidence})
        elif a["type"] == "tool-call-count":
            count = len(matches)
            min_ok = a.get("min") is None or count >= a["min"]
            max_ok = a.get("max") is None or count <= a["max"]
            passed = min_ok and max_ok
            expected = " and ".join(
                f"{'>=' if k == 'min' else '<='}{a[k]}"
                for k in ("min", "max")
                if a.get(k) is not None
            )
            results.append(
                {
                    "text": text,
                    "passed": passed,
                    "evidence": f"{name or 'tools'} called {count} time(s)"
                    + (f"; expected {expected}" if not passed else ""),
                }
            )
    return results


def render_judge_prompt(eval_case, model_output, tool_calls, previous_bad=None):
    assertions = eval_case.get("assertions") or (
        [f"The output satisfies this expected output: {eval_case['expected_output']}"]
        if eval_case.get("expected_output")
        else []
    )
    if not assertions:
        return "", []

    tool_block = ""
    if tool_calls:
        lines = []
        for i, tc in enumerate(tool_calls):
            args = json.dumps(tc.get("parsedArguments") or {}, indent=2)
            lines.append(f"[{i + 1}] {tc['function']['name']}\n{args}")
        tool_block = f"\n\nTool calls (structured):\n{''.join(lines)}"

    bad_hint = (
        f"\nPrevious response was not parseable JSON. Try again. Bad response: {truncate(previous_bad, 500)}"
        if previous_bad
        else ""
    )

    prompt = (
        "You are grading an agentskills.io evaluation run.\n"
        "\n"
        "Grading principles:\n"
        "- Require concrete evidence for every PASS; quote or reference the output.\n"
        "- Do not give the benefit of the doubt.\n"
        "- PASS an assertion only if every condition in the assertion text holds.\n"
        "- A label without substance is a FAIL.\n"
        "- Tool calls (when present) are authoritative evidence of model behavior.\n"
        "\n"
        "Return STRICT JSON only. No markdown. Shape:\n"
        '{"assertion_results":[{"text":"...","passed":true,"evidence":"..."}],"summary":{"passed":0,"failed":0,"total":0,"pass_rate":0}}\n'
        "\n"
        "Rules:\n"
        "- Include every assertion exactly once and copy the full assertion text verbatim into text.\n"
        "- Use short concrete evidence: quote, snippet, or file reference.\n"
        "- Summary may be included, but it will be recomputed by the caller.\n"
        f"{bad_hint}"
        "\n"
        "Assertions:\n"
        f"{json.dumps(assertions, indent=2)}\n"
        "\n"
        "Model output:\n"
        f"{model_output or '(empty output)'}"
        f"{tool_block}"
    )
    return prompt, assertions


def grade_with_judge(
    judge_client, judge_model, prompt, assertions, params, tool_results
):
    if not assertions:
        return (
            {"assertion_results": tool_results, "summary": summarize(tool_results)},
            "",
            "",
        )

    bad_response = ""
    last_prompt = ""
    last_text = ""
    rubric_results = None

    for attempt in range(2):
        last_prompt = render_judge_prompt(
            {"assertions": assertions, "expected_output": None},
            prompt,
            None,
            bad_response or None,
        )[0]
        result = call_ollama(
            [{"role": "user", "content": last_prompt}],
            judge_model,
            judge_client,
            params,
        )
        last_text = result["output"]
        if not last_text:
            bad_response = "(empty response)"
            continue
        try:
            parsed = json.loads(extract_json_object(last_text))
            if not isinstance(parsed, dict):
                raise ValueError("not an object")
            raw_results = parsed.get("assertion_results")
            if not isinstance(raw_results, list):
                raise ValueError("missing assertion_results array")
            rubric_results = []
            for i, text in enumerate(assertions):
                r = raw_results[i] if i < len(raw_results) else {}
                rubric_results.append(
                    {
                        "text": text,
                        "passed": r.get("passed") is True
                        if isinstance(r, dict)
                        else False,
                        "evidence": (r.get("evidence") or "").strip()
                        if isinstance(r, dict)
                        else "judge omitted this result",
                    }
                )
            break
        except (json.JSONDecodeError, ValueError, IndexError, TypeError):
            bad_response = last_text

    if rubric_results is None:
        rubric_results = [
            {
                "text": a,
                "passed": False,
                "evidence": f"judge returned unparseable response: {truncate(bad_response, 500)}",
            }
            for a in assertions
        ]

    combined = rubric_results + tool_results
    return (
        {"assertion_results": combined, "summary": summarize(combined)},
        last_prompt,
        last_text,
    )


def summarize(results):
    total = len(results)
    passed = sum(1 for r in results if r["passed"])
    return {
        "passed": passed,
        "failed": total - passed,
        "total": total,
        "pass_rate": passed / total if total > 0 else 1.0,
    }


def write_artifacts(run_dir, timing, grading, raw_output, messages_info, tool_calls):
    outputs_dir = Path(run_dir) / "outputs"
    outputs_dir.mkdir(parents=True, exist_ok=True)

    with open(Path(run_dir) / "timing.json", "w") as f:
        json.dump(timing, f, indent=2)

    with open(Path(run_dir) / "grading.json", "w") as f:
        json.dump(grading, f, indent=2)

    with open(outputs_dir / "response.txt", "w") as f:
        f.write(raw_output)

    with open(Path(run_dir) / "prompts.json", "w") as f:
        json.dump(messages_info, f, indent=2)

    if tool_calls:
        with open(Path(run_dir) / "tool_calls.json", "w") as f:
            json.dump(tool_calls, f, indent=2)


def build_benchmark(all_runs):
    by_mode = defaultdict(list)
    for run in all_runs:
        by_mode[run["mode"]].append(run)

    result = {}
    for mode in ("with_skill", "without_skill"):
        runs = by_mode.get(mode, [])
        if not runs:
            continue
        pass_rates = [r["grading"]["summary"]["pass_rate"] for r in runs]
        times = [r["timing"]["duration_ms"] / 1000.0 for r in runs]
        tokens = [r["timing"]["total_tokens"] for r in runs]

        def stats(values):
            return {
                "mean": statistics.mean(values) if len(values) > 0 else 0,
                "stddev": statistics.stdev(values) if len(values) > 1 else 0,
            }

        result[mode] = {
            "pass_rate": stats(pass_rates),
            "time_seconds": stats(times),
            "tokens": stats(tokens),
        }

    if "with_skill" in result and "without_skill" in result:
        result["delta"] = {
            "pass_rate": round(
                result["with_skill"]["pass_rate"]["mean"]
                - result["without_skill"]["pass_rate"]["mean"],
                4,
            ),
            "time_seconds": round(
                result["with_skill"]["time_seconds"]["mean"]
                - result["without_skill"]["time_seconds"]["mean"],
                2,
            ),
            "tokens": round(
                result["with_skill"]["tokens"]["mean"]
                - result["without_skill"]["tokens"]["mean"],
                1,
            ),
        }

    return {"run_summary": result}


def run_eval_case(
    skill,
    eval_case,
    mode,
    target_client,
    target_model,
    judge_client,
    judge_model,
    effective_target_params,
    effective_judge_params,
    iteration_dir,
):
    slug = slugify(
        eval_case.get("name") or f"eval-{eval_case['id']}", f"eval-{eval_case['id']}"
    )
    run_dir = Path(iteration_dir) / slug / mode
    run_dir.mkdir(parents=True, exist_ok=True)

    messages = build_messages(skill, eval_case, mode, target_client, target_model)
    completion = call_ollama(
        messages, target_model, target_client, effective_target_params
    )
    raw_output = (
        f"ERROR: {completion['error']}" if completion["error"] else completion["output"]
    )
    tool_calls = completion["tool_calls"]

    assertions = eval_case.get("assertions") or (
        [f"The output satisfies this expected output: {eval_case['expected_output']}"]
        if eval_case.get("expected_output")
        else []
    )

    tool_results = run_tool_assertions(
        completion["tool_calls"], eval_case.get("tool_assertions")
    )
    grading, judge_prompt, judge_response = grade_with_judge(
        judge_client,
        judge_model,
        raw_output,
        assertions,
        effective_judge_params,
        tool_results,
    )

    timing = completion["timing"]
    write_artifacts(
        str(run_dir),
        timing,
        grading,
        raw_output,
        {
            "system": messages[0]["content"]
            if len(messages) > 1 and messages[0]["role"] == "system"
            else None,
            "user": messages[-1]["content"],
            "judgePrompt": judge_prompt,
            "fileCount": len(eval_case.get("_resolved_files", [])),
            "tools": eval_case.get("tools")
            or (skill.get("defaults") or {}).get("tools"),
            "tool_choice": eval_case.get("tool_choice"),
            "judgeResponse": judge_response,
        },
        tool_calls,
    )

    return {
        "mode": mode,
        "slug": slug,
        "timing": timing,
        "grading": grading,
        "rawOutput": raw_output,
        "toolCalls": tool_calls,
    }


def evaluate_skill(
    skill_dir,
    target_model=DEFAULT_TARGET,
    judge_model=DEFAULT_JUDGE,
    ollama_url=DEFAULT_OLLAMA_URL,
    modes=("with_skill", "without_skill"),
    iterations=1,
    concurrency=1,
    output_dir=None,
    baseline=False,
):
    skill = load_skill(skill_dir)
    if not skill["evals"]:
        print("No eval cases found. Run complete.")
        return

    if OpenAI is None:
        print("ERROR: 'openai' package required. Install: pip install openai")
        sys.exit(1)

    api_key = os.environ.get("OPENAI_API_KEY", "ollama")
    client = OpenAI(base_url=ollama_url, api_key=api_key)
    ws_root = Path(output_dir or Path(skill_dir) / "workspace").resolve()
    ws_root.mkdir(parents=True, exist_ok=True)
    skill_ws = ws_root / slugify(skill["name"], "skill")
    skill_ws.mkdir(parents=True, exist_ok=True)

    defaults = skill.get("defaults") or {}

    for iteration in range(1, iterations + 1):
        iter_dir = skill_ws / f"iteration-{iteration}"
        iter_dir.mkdir(parents=True, exist_ok=True)
        print(f"\n--- Iteration {iteration}/{iterations} ---")

        all_runs = []
        case_count = len(skill["evals"])

        with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as pool:
            futures = []
            for ei, eval_case in enumerate(skill["evals"]):
                for mode in modes:
                    effective_target_params = merge_params(
                        defaults.get("target", {}).get("params"),
                        eval_case.get("params"),
                    )
                    effective_judge_params = merge_params(
                        defaults.get("judge", {}).get("params"),
                    )
                    future = pool.submit(
                        run_eval_case,
                        skill,
                        eval_case,
                        mode,
                        client,
                        target_model,
                        client,
                        judge_model,
                        effective_target_params,
                        effective_judge_params,
                        str(iter_dir),
                    )
                    futures.append(future)

            for future in concurrent.futures.as_completed(futures):
                run_result = future.result()
                all_runs.append(run_result)
                mode_label = f"[{run_result['mode']}]"
                pass_rate = run_result["grading"]["summary"]["pass_rate"]
                print(
                    f"  {mode_label} {run_result['slug']}: pass_rate={pass_rate:.2f}, "
                    f"tokens={run_result['timing']['total_tokens']}, "
                    f"time={run_result['timing']['duration_ms']}ms"
                )

        benchmark = build_benchmark(all_runs)
        bench_path = iter_dir / "benchmark.json"
        with open(bench_path, "w") as f:
            json.dump(benchmark, f, indent=2)

        print(f"  Benchmark: {bench_path}")
        if "delta" in benchmark.get("run_summary", {}):
            d = benchmark["run_summary"]["delta"]
            print(
                f"  Delta: pass_rate={d['pass_rate']:+.4f} pp, "
                f"time={d['time_seconds']:+.2f}s, tokens={d['tokens']:+.0f}"
            )
        if "with_skill" in benchmark.get("run_summary", {}):
            ws = benchmark["run_summary"]["with_skill"]
            print(
                f"  With skill: pass_rate={ws['pass_rate']['mean']:.2f} "
                f"(sd={ws['pass_rate']['stddev']:.2f}), "
                f"avg_time={ws['time_seconds']['mean']:.1f}s, "
                f"avg_tokens={ws['tokens']['mean']:.0f}"
            )

    return benchmark


def main():
    parser = argparse.ArgumentParser(description="Evaluate a skill via Ollama models")
    parser.add_argument(
        "skill_dir", nargs="?", default=".", help="Path to skill directory"
    )
    parser.add_argument(
        "--target-model",
        default=DEFAULT_TARGET,
        help=f"Ollama model for evals (default: {DEFAULT_TARGET})",
    )
    parser.add_argument(
        "--judge-model",
        default=DEFAULT_JUDGE,
        help=f"Ollama model for grading (default: {DEFAULT_JUDGE})",
    )
    parser.add_argument(
        "--ollama-url",
        default=DEFAULT_OLLAMA_URL,
        help=f"Ollama API base URL (default: {DEFAULT_OLLAMA_URL})",
    )
    parser.add_argument(
        "--ollama-cloud",
        action="store_true",
        help=f"Shortcut for --ollama-url {OLLAMA_CLOUD_URL} (requires $OPENAI_API_KEY)",
    )
    parser.add_argument(
        "--modes",
        default="with_skill,without_skill",
        help="Comma-separated modes (default: both)",
    )
    parser.add_argument(
        "--iterations", type=int, default=1, help="Number of iterations (default: 1)"
    )
    parser.add_argument(
        "--concurrency",
        type=int,
        default=1,
        help="Max parallel eval cases (default: 1)",
    )
    parser.add_argument(
        "--output-dir",
        help=f"Workspace output directory (default: <skill-dir>/workspace)",
    )
    parser.add_argument(
        "--baseline", action="store_true", help="Reuse existing without_skill results"
    )
    args = parser.parse_args()

    modes = [m.strip() for m in args.modes.split(",") if m.strip()]

    if args.ollama_cloud:
        args.ollama_url = OLLAMA_CLOUD_URL

    print(f"Skill Evaluation Pipeline")
    print(f"  Target: {args.target_model}")
    print(f"  Judge:  {args.judge_model}")
    print(f"  Ollama: {args.ollama_url}")
    print(f"  Modes:  {', '.join(modes)}")
    print(f"  Iter:   {args.iterations}")
    print(f"  Concurrency: {args.concurrency}")

    result = evaluate_skill(
        args.skill_dir,
        target_model=args.target_model,
        judge_model=args.judge_model,
        ollama_url=args.ollama_url,
        modes=modes,
        iterations=args.iterations,
        concurrency=args.concurrency,
        output_dir=args.output_dir,
        baseline=args.baseline,
    )

    print("\nDone.")
    return result


if __name__ == "__main__":
    main()
