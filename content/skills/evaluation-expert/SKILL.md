---
name: evaluation-expert
description: "Comparative evaluation of technical solutions: trade-off analysis (performance vs cost, consistency vs availability per the CAP theorem), POCs with objective metrics, weighted decision matrices, AI agent evaluation with multi-dimensional rubrics and LLM-as-judge, pairwise comparison with position-bias mitigation, and automated quality gates. Use when evaluating technology choices, comparing model outputs, measuring agent quality at scale, building evaluation pipelines, or setting quality thresholds for AI systems. Trigger: trade-off analysis, LLM-as-judge, quality gates. Do NOT trigger for: single-metric performance benchmarks without multi-dimensional evaluation."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: ai-agents
  status: stable
---
# Evaluation Expert

**Technology evaluation, agent quality assessment, LLM-as-judge pipelines.**

## Decision Framework

### Trade-off Analysis
```
Matrix: Option A vs Option B vs Option C
Axes: Performance, Cost, Complexity, Risk, Team familiarity
Weight by: business priorities (core-api reliability > admin UX)
```

### POC Design
- Define measurable pass/fail criteria BEFORE starting
- Test worst-case, not ideal conditions
- Timebox: 1-3 days max

## AI Agent Evaluation

### Rubric Dimensions (0.0-1.0)
1. Factual accuracy (weight: knowledge tasks)
2. Completeness (weight: research tasks)
3. Citation accuracy (weight: trust-sensitive)
4. Source quality (weight: authoritative outputs)
5. Tool efficiency (weight: cost-sensitive)

Passing: 0.7 general | 0.9 high-stakes

### LLM-as-Judge Pipeline
- Direct Scoring: judge rates response vs rubric (objective criteria)
- Pairwise Comparison: judge picks better of two (subjective quality)
- Position bias: swap A/B, run twice; inconsistent = TIE
- NEVER same model family as generator + judge

### Metrics
| Scale | Metric |
|---|---|
| Binary | Recall, Precision, F1, Cohen's kappa |
| Ordinal (1-5) | Spearman's rho, Kendall's tau |
| Pairwise | Agreement rate, Position consistency |

## Constraints
- NEVER use single score without dimension breakdown
- NEVER same model as generator + judge
- NEVER <50 test cases (unreliable signal)
- ALWAYS establish baseline before changes
- NEVER only automate — supplement with periodic human review

## Overview

Compare technical solutions systematically: trade-off analysis (performance vs cost, CAP theorem), POCs with objective metrics, weighted decision matrices, multi-dimensional rubric evaluation of AI agents, LLM-as-judge pipelines with position bias mitigation, and automated quality gates for production deployments.

## Quick Reference

| Method | Use Case | Key Metric |
|---|---|---|
| Trade-off matrix | Tech stack selection | Weighted score per dimension |
| POC with metrics | Vendor/library evaluation | Pass/fail per criterion |
| LLM-as-judge (direct) | Response quality scoring | Dimension rubric (0.0-1.0) |
| LLM-as-judge (pairwise) | Model comparison | Agreement rate, wins/losses |
| Quality gates | CI/CD deployment block | Threshold per dimension |

## Workflow

1. Define decision criteria and weight them by business priority
2. Build trade-off matrix comparing at least 3 candidate solutions
3. Design POC with measurable pass/fail criteria before starting
4. Timebox POC: 1-3 days maximum for technology evaluation
5. For AI agents, run LLM-as-judge evaluation with multi-dim rubric
6. Set quality gates with passing thresholds before deployment

## Anti-patterns

FAIL: Using same model family as generator and judge
```python
# BAD: Claude evaluates Claude outputs
judge = ChatBedrockConverse(model="sonnet")
score = judge.evaluate(generator_output)  # same family bias

# GOOD: different model or cross-family eval
judge = ChatBedrockConverse(model="nova-pro-v1:0")
score = judge.evaluate(generator_output)
```

FAIL: Running evaluation with fewer than 50 test cases
```python
# BAD: 5 test cases — no statistical significance
test_cases = [case1, case2, case3, case4, case5]
results = [evaluate(c) for c in test_cases]

# GOOD: at least 50 cases for reliable signal
test_cases = load_test_set("regression_v3", min_count=50)
results = [evaluate(c) for c in test_cases]
```

FAIL: Reporting single aggregate score without dimension breakdown
```python
# BAD: single score hides weaknesses
report = "Overall score: 0.85"

# GOOD: dimension breakdown
report = """
factual_accuracy:  0.92
completeness:      0.78  # needs improvement
citation_accuracy: 0.88  # acceptable
source_quality:    0.95
tool_efficiency:   0.72  # needs improvement
"""
```

## References

- Anthropic evaluation guide: https://docs.anthropic.com/en/docs/build-with-claude/evaluations (last_verified: 2026-05)
- LLM-as-judge paper (Zheng et al.): https://arxiv.org/abs/2306.05685 (last_verified: 2026-05)
- Google's evaluation framework: https://ai.google.dev/responsible/privacy-and-ethics (last_verified: 2026-05)

- [references/benchmarks.md](references/benchmarks.md)
- [references/production-eval.md](references/production-eval.md)
- [references/rubric-designer.md](references/rubric-designer.md)

## Verification Checklist
- [ ] ≥50 test cases used (sufficient for statistically reliable signal)
- [ ] Judge model is different family from generator model
- [ ] Rubric dimensions defined with weights before running evaluation
- [ ] Position bias mitigation applied: swap A/B, run twice, inconsistent → TIE
- [ ] Baseline established before evaluating any change
- [ ] Quality gates set with passing thresholds for CI/CD
- [ ] Periodic human review supplements automated evaluation

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Evaluation scores are inconsistent across runs | Too few test cases (<50); judge model same family as generator | Increase test set to ≥50; use different model family for judge (e.g., Nova judges Claude) |
| LLM-as-judge always prefers option A over B | Position bias — option order influences judge | Swap A/B labels and re-run; mark as TIE when results disagree; counterbalance order across test set |
| Single aggregate score hides dimension failures | No dimension breakdown in report | Report per-dimension scores separately; set per-dimension passing thresholds |
| Quality gate passes in CI but fails in production | Test cases don't reflect production distribution; POC tested ideal not worst-case | Curate test set from real production examples; include edge cases and adversarial inputs |
| LLM-as-judge gives different results across model versions (known limitation) | Judge model updated; scoring behavior changed with new model version | Pin judge model version; version-control evaluation results alongside judge model ID; use multiple judges for consensus |
