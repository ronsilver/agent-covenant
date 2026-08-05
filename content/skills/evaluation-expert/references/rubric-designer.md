# Evaluation Rubric Designer

## Dimensions
| Dim | Weight | 0.0 | 0.5 | 1.0 |
|---|---|---|---|---|
| Accuracy | 0.4 | Wrong | Partial | Exact |
| Completeness | 0.2 | Missing | Partial | Complete |
| Tool Efficiency | 0.2 | Excessive | Moderate | Optimal |
| Citation | 0.2 | None | Partial | Full |

## LLM-as-Judge Prompt
```
Task: {description}
Response: {output}
Criteria: {criteria}
Instructions: find evidence -> score(1-5) -> justify -> suggest improvement
Output JSON: {criterion, score, evidence[], justification, improvement}
```

## Bias Mitigation
- Position bias: swap A/B, run twice. Inconsistent = TIE
- Self-enhancement: NEVER same model family for generator + judge
- Length bias: add length-neutrality instruction to rubric
