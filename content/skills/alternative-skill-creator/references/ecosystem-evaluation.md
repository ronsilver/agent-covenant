# Ecosystem Evaluation

Batch evaluation of ALL skills in `content/skills/` using `evaluate_ecosystem.py`.

## Use Case

Audit the entire skill catalog in one pass — structural quality (7 pillars) + automated evals (LLM-as-judge). Detect regressions, track improvement over time, and identify skills needing attention.

## Quick Start

```bash
# Structural scoring only (fast, no LLM needed)
python3 scripts/evaluate_ecosystem.py --skip-evals

# Full evaluation with Ollama Cloud
export OPENAI_API_KEY=<your-key>
python3 scripts/evaluate_ecosystem.py --ollama-cloud
```

## Output

Generates `ecosystem-quality-report.json` with:

| Field | Description |
|---|---|
| `summary` | Aggregate stats: total, passing, world-class, average score |
| `skills[]` | Per-skill: structural score, pillar breakdown, eval pass rate, tokens, time |
| `generated_at` | ISO 8601 timestamp |
| `elapsed_seconds` | Wall clock time for the run |

## Workflow

```
1. Structural scan (gratis)
   python3 evaluate_ecosystem.py --skip-evals --text

2. Review report — identify low-scoring skills

3. LLM-based evals (costs tokens)
   python3 evaluate_ecosystem.py --ollama-cloud \
     --target-model deepseekv4-pro:cloud \
     --judge-model kimi-k2.6:cloud \
     --concurrency 3

4. Compare before/after reports → track improvement
```

## Filtering

```bash
# Only skills matching name pattern
--filter "expert"

# Only skills missing evals/evals.json
--only-missing-evals --skip-evals
```

## Thresholds

| Metric | Threshold | Action |
|---|---|---|
| Structural score < 70 | FAIL | Must fix pillars |
| Structural score 70-79 | Needs improvement | Iterate weakest pillar |
| Structural score >= 80 | World-class | OK |
| Eval pass rate < 0.5 | FAIL | Improve SKILL.md content |
| Missing evals.json | WARN | Create evals per schema |

## CI Integration

```bash
# Block PR if any skill below threshold
python3 evaluate_ecosystem.py --skip-evals --json | \
  python3 -c "import json,sys; r=json.load(sys.stdin); [exit(1) for s in r['skills'] if s['structural_score']<70]"
```

## References

- [evaluating-skills.md](evaluating-skills.md) — per-skill eval patterns
- [eval-schema.md](eval-schema.md) — evals.json schema
- [../../../../scripts/validate-skill-quality.py](../../../../scripts/validate-skill-quality.py) — 7-pillar scorer
