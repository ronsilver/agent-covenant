# AI Evaluation Benchmarks

## Agent Benchmarks
| Benchmark | What It Measures |
|---|---|
| SWE-bench Verified | Code fix accuracy from issue descriptions |
| WebArena | Web navigation + task completion |
| BrowseComp | Information retrieval + synthesis |
| GAIA | Multi-step reasoning + tool use |
| LoCoMo | Long-context conversation memory |

## LLM Benchmarks
| Benchmark | Focus |
|---|---|
| MMLU | Multidisciplinary knowledge |
| HumanEval | Code generation correctness |
| GSM8K | Math reasoning (grade school) |
| HellaSwag | Commonsense reasoning |
| TruthfulQA | Factuality (hallucination resistance) |

## Project-Specific Eval Framework
1. Business Accuracy: does the agent understand this project domains?
2. SQL Correctness: generated SQL returns expected results
3. Safety: no PII exposure, no destructive operations
4. Tool Efficiency: minimal tool calls for task
5. Latency: within SLO (p95 < X seconds per stimulus)

## When to Use Benchmarks
- Model selection: compare candidates before production
- Regression detection: catch quality drops in deploy pipelines
- Prompt iteration: measure if new prompts improve quality
- NEVER: use as sole measure (always complement with production monitoring)
