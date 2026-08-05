# Production Evaluation Pipeline

## Continuous Evaluation
```python
class EvaluationPipeline:
    def __init__(self, rubric, test_set):
        self.rubric = rubric
        self.test_set = test_set  # >= 50 cases

    def run(self, system_output):
        results = []
        for case in self.test_set:
            score = self.judge.evaluate(case, system_output)
            results.append({"case_id": case.id, "score": score})
        return self.aggregate(results)

    def aggregate(self, results):
        strata = self.group_by_stratum(results)
        return {
            "overall": mean([r.score for r in results]),
            "by_stratum": {s: mean([r.score for r in rs]) for s, rs in strata.items()},
            "dimensions": self.per_dimension_breakdown(results),
            "passes_threshold": all(d >= threshold for d in breakdown.values())
        }
```

## Gates
| Check | Threshold | Action on Fail |
|---|---|---|
| Overall pass rate | >= 0.7 (general), >= 0.9 (high-stakes) | Block deploy |
| Per dimension min | >= threshold | Investigate specific weakness |
| Regression | baseline - current < 0.05 | Warn, investigate |
| Coverage | >= 50 test cases | Increase test set |

## Monitoring
- Track pass rate over time (regression detection)
- Alert if pass rate drops >5% in one day
- Weekly: human review 10% of eval results
- Monthly: rotate test inputs, audit rubric

## LLM-as-Judge Pipeline
```
Input -> Generator -> Output
Output + Rubric + Expected -> Judge (different model family) -> Score + Justification
```
Bias mitigation: position swap, panel of judges, confidence thresholds.
