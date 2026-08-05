# Evaluating Skill Output Quality

Structured evals give you a feedback loop for improving skills systematically — answering whether a skill works reliably, across varied prompts, better than no skill at all.

## Test Case Design

A test case has three parts:

- **Prompt**: a realistic user message
- **Expected output**: human-readable description of what success looks like
- **Input files** (optional): files the skill needs

Store test cases in `evals/evals.json` inside the skill directory:

```json
{
  "skill_name": "csv-analyzer",
  "evals": [
    {
      "id": 1,
      "prompt": "I have a CSV of monthly sales data in data/sales_2025.csv. Find the top 3 months by revenue and make a bar chart.",
      "expected_output": "A bar chart showing top 3 months by revenue, with labeled axes and values.",
      "files": ["evals/files/sales_2025.csv"]
    },
    {
      "id": 2,
      "prompt": "there's a csv in my downloads called customers.csv, some rows have missing emails — can you clean it up and tell me how many were missing?",
      "expected_output": "A cleaned CSV with missing emails handled, plus a count of how many were missing.",
      "files": ["evals/files/customers.csv"]
    }
  ]
}
```

**Tips:**
- Start with 2-3 cases; expand after first results
- Vary phrasing, formality, and detail level
- Include at least one edge case (malformed input, unusual request)
- Use realistic context: file paths, column names, personal context

## Running Evals: Workspace Structure

Run each test case **with the skill** and **without it** (baseline). Each iteration gets its own directory:

```
csv-analyzer/
├── SKILL.md
└── evals/
    └── evals.json
csv-analyzer-workspace/
└── iteration-1/
    ├── eval-top-months-chart/
    │   ├── with_skill/
    │   │   ├── outputs/
    │   │   ├── timing.json
    │   │   └── grading.json
    │   └── without_skill/
    │       ├── outputs/
    │       ├── timing.json
    │       └── grading.json
    └── benchmark.json
```

Each run must start with a **clean context** — no leftover state. In Claude Code, each child task starts fresh automatically.

### timing.json

```json
{
  "total_tokens": 84852,
  "duration_ms": 23332
}
```

## Writing Assertions

Add assertions **after** seeing first-round outputs — you often don't know what "good" looks like until the skill has run.

**Good assertions** (verifiable):
- `"The output file is valid JSON"`
- `"The bar chart has labeled axes"`
- `"The report includes at least 3 recommendations"`

**Weak assertions** (avoid):
- `"The output looks good"`
- `"The skill worked correctly"`

Store in `grading.json`:

```json
{
  "eval_id": 1,
  "assertions": [
    { "id": "a1", "description": "Output is a valid PNG image", "result": "pass" },
    { "id": "a2", "description": "Chart has labeled axes", "result": "pass" },
    { "id": "a3", "description": "Shows exactly top 3 months", "result": "fail", "note": "Showed top 5 instead" }
  ],
  "pass_rate": 0.67
}
```

## Grading with LLM-as-Judge

For outputs that can't be verified programmatically (prose quality, chart aesthetics), use LLM-as-judge:

```
Grade this output against the expected result.

Expected: A bar chart showing top 3 months by revenue with labeled axes.
Actual output: [description or image]

For each assertion, respond with pass/fail and a brief reason.
```

## Iterating on Results

After each iteration:

1. Review `benchmark.json` for pass rates
2. Read grading notes to identify patterns
3. Update SKILL.md or references to address failures
4. Snapshot the current skill before editing: `cp -r <skill-path> <workspace>/skill-snapshot/`
5. Re-run evals against the updated skill vs. the snapshot as baseline

Even a single execute-then-revise pass noticeably improves quality.

## Automated Evaluation Pipeline

Instead of manual grading for production evaluation, use the automated pipeline:

```bash
# Full evaluation with baseline comparison against Ollama models
python3 scripts/evaluate_skill.py <skill-dir> \
  --target-model deepseekv4-pro:cloud \
  --judge-model kimi-k2.6:cloud \
  --modes with_skill,without_skill \
  --iterations 1 --concurrency 2

# Review benchmark results
cat <skill-dir>/workspace/<skill>/iteration-1/benchmark.json

# Run multiple iterations for statistical significance
python3 scripts/evaluate_skill.py <skill-dir> --iterations 3

# Aggregate results from a workspace
python3 scripts/benchmark.py <skill-dir>/workspace/<skill>
```

### Quality Targets

| Metric | Passing | Target |
|--------|---------|--------|
| `delta.pass_rate` | ≥ +0.05 pp | ≥ +0.10 pp |
| with_skill pass_rate | ≥ 0.5 | ≥ 0.7 |
| with_skill time | — | ≤ without_skill + 20% |

### Extended evals.json Schema

Tool assertions now supported alongside rubric assertions. See [eval-schema.md](eval-schema.md) for full reference.

### Known Limitations

- Requires Ollama running locally or accessible via `--ollama-url`
- Tool assertions require models that support tool calling (deepseekv4-pro:cloud does)
- LLM judge grading adds latency; use for final quality gates, not rapid iteration

## Ollama Cloud Setup

For cloud-hosted Ollama (no local instance needed):

```bash
export OPENAI_API_KEY=<your-api-key>

# Single skill evaluation
python3 scripts/evaluate_skill.py <skill-dir> --ollama-cloud

# Batch ecosystem evaluation
python3 scripts/evaluate_ecosystem.py --ollama-cloud
```

### Configuration reference

| Variable / Flag | Purpose | Default |
|---|---|---|
| `$OPENAI_API_KEY` | API key for Ollama Cloud | `ollama` (local fallback) |
| `--ollama-url <url>` | Custom endpoint URL | `http://localhost:11434/v1` |
| `--ollama-cloud` | Shortcut for `https://ollama.com/v1` | — |
| `OLLAMA_URL` (env) | Override default Ollama URL | `http://localhost:11434/v1` |

### Auth precedence

1. `$OPENAI_API_KEY` env var (highest priority)
2. Hardcoded `"ollama"` (local fallback, no auth)
