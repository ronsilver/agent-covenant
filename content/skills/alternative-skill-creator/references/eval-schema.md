# evals.json Schema Reference

Extended schema for automated skill evaluation via `evaluate_skill.py`.
Backward-compatible with `agent-skills-eval` specification.

## File Location

```
<skill-dir>/evals/evals.json
```

## Top-Level Structure

```json
{
  "skill_name": "my-skill",
  "defaults": {
    "target": {"params": {"temperature": 0}},
    "judge": {"params": {"temperature": 0}},
    "tools": []
  },
  "evals": []
}
```

| Field | Required | Type | Description |
|---|---|---|---|
| `skill_name` | yes | string | Must match `SKILL.md` frontmatter `name` |
| `defaults` | no | object | Skill-wide defaults for target/judge/tools |
| `evals` | yes | array | Array of eval case objects |

## defaults Block

```json
{
  "target": {"params": {"temperature": 0.0, "max_tokens": 4096}},
  "judge":  {"params": {"temperature": 0.0}},
  "tools": [{"type": "function", "function": {"name": "get_weather", "description": "...", "parameters": {}}}]
}
```

| Subfield | Purpose |
|---|---|
| `target.params` | Inference params for the target model (lowest precedence) |
| `judge.params` | Inference params for the judge model (lowest precedence) |
| `tools` | Tools available to every eval case unless overridden at eval level |

## Eval Case Object

```json
{
  "id": 1,
  "name": "top revenue month",
  "prompt": "Use the attached CSV to identify the month with the highest revenue.",
  "expected_output": "The response identifies February as the highest revenue month with revenue of 18.",
  "files": ["evals/files/revenue.csv"],
  "assertions": ["The output names February as the highest revenue month."],
  "params": {"temperature": 0.2},
  "tools": [{"type": "function", "function": {"name": "analyze_csv", ...}}],
  "tool_choice": "auto",
  "tool_assertions": [
    {"type": "tool-called", "name": "analyze_csv"},
    {"type": "tool-arg-equals", "name": "analyze_csv", "path": "file", "value": "revenue.csv"}
  ]
}
```

| Field | Required | Type | Description |
|---|---|---|---|
| `id` | no | string/number | Unique identifier |
| `name` | no | string | Human-readable name for reports |
| `prompt` | yes | string | User message sent to the target model |
| `expected_output` | no | string | Description of correct output (promoted to assertion if `assertions` absent) |
| `files` | no | array | Relative paths to files in `evals/files/` |
| `assertions` | no | array | Rubric assertions graded by LLM judge |
| `params` | no | object | Per-eval override of target params (highest precedence) |
| `tools` | no | array | Per-eval tools (overrides skill defaults completely if set) |
| `tool_choice` | no | string/object | "auto"/"none"/"required" or `{type:"function",function:{name:...}}` |
| `tool_assertions` | no | array | Deterministic assertions against tool calls |

## Assertion Types

### Rubric Assertions (LLM Judge)

String assertions evaluated by the judge model:

```json
"assertions": [
  "The output names February as the highest revenue month.",
  "The output includes the value 18.",
  "No errors or warnings in the response."
]
```

Object form also accepted for compatibility:

```json
{"text": "The output names February.", "value": "February is mentioned", "criterion": "Must mention February"}
```

### Tool Assertions (Deterministic, No LLM)

Six types, all evaluated locally against structured tool calls:

#### tool-called

```json
{"type": "tool-called", "name": "get_weather", "description": "weather tool was invoked"}
```

Passes if `get_weather` was called at least once.

#### tool-not-called

```json
{"type": "tool-not-called", "name": "delete_record"}
```

Passes if `delete_record` was never called.

#### tool-arg-equals

```json
{"type": "tool-arg-equals", "name": "get_weather", "path": "location", "value": "NYC"}
```

Deep-equal check on parsed arguments. `path` uses dot/bracket notation: `location`, `input.city`, `files[0].name`.

#### tool-arg-contains

```json
{"type": "tool-arg-contains", "name": "write_file", "path": "filename", "value": ".json"}
```

Substring check on the argument value.

#### tool-arg-matches

```json
{"type": "tool-arg-matches", "name": "write_file", "path": "filename", "pattern": "\\.json$"}
```

Regex test on the argument value. Optional `flags` field: `"i"` for case insensitive.

#### tool-call-count

```json
{"type": "tool-call-count", "name": "get_weather", "min": 1, "max": 3}
{"type": "tool-call-count", "min": 0, "max": 0}
```

Bounds check on call count. Name is optional; omit to count all tools.

## Parameter Precedence

Params are merged with lowest-to-highest precedence:

| Level | Source | Example |
|---|---|---|
| 1 (lowest) | Caller-level CLI args | `--target-model` flags |
| 2 | `defaults.target.params` | Skill-wide defaults in evals.json |
| 3 (highest) | `evals[].params` | Per-ease overrides |

For tools:
- Eval-level `tools` **completely replaces** skill `defaults.tools` when set
- `tool_choice` defaults to `"auto"` when tools are present and not explicitly set

## Example: Minimal

```json
{
  "skill_name": "hello-world",
  "evals": [
    {
      "id": 1,
      "prompt": "Say hello to the user.",
      "expected_output": "A friendly greeting."
    }
  ]
}
```

## Example: Full

```json
{
  "skill_name": "data-analyzer",
  "defaults": {
    "target": {"params": {"temperature": 0}},
    "judge": {"params": {"temperature": 0}}
  },
  "evals": [
    {
      "id": "missing-values",
      "name": "handle missing emails",
      "prompt": "Clean customers.csv and tell me how many emails were missing.",
      "files": ["evals/files/customers.csv"],
      "assertions": [
        "The output includes the count of missing emails.",
        "The output produces a cleaned file."
      ],
      "params": {"temperature": 0.1}
    },
    {
      "id": 2,
      "name": "tool-based analysis",
      "prompt": "Analyze sales.csv and find the top 3 months.",
      "files": ["evals/files/sales.csv"],
      "assertions": ["The analysis identifies top 3 months by revenue."],
      "tools": [{"type": "function", "function": {"name": "analyze_csv", "parameters": {"type": "object", "properties": {"file": {"type": "string"}}}}}],
      "tool_assertions": [
        {"type": "tool-called", "name": "analyze_csv"},
        {"type": "tool-arg-equals", "name": "analyze_csv", "path": "file", "value": "sales.csv"}
      ]
    }
  ]
}
```

## Schema Compatibility

This schema is a superset of the `agent-skills-eval` specification v0.1.1.
Additions beyond the base spec:
- Object-form assertions (`{text, value, criterion}`)
- `params` override at eval level
- `defaults` block

All base-spec features are fully compatible.
