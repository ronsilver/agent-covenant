---
name: reasoning-expert
description: "Agent reasoning improvement via Chain-of-Thought (CoT), Tree-of-Thought (ToT) for path exploration, ReAct (Reasoning + Acting), reasoning trace auditing for fallacy detection (circular logic, confirmation bias, premature convergence), and inference traceability maintenance for decision debugging. Use when evaluating agent decision quality, auditing reasoning paths, debugging poor agent outputs, or comparing reasoning patterns across model tiers. Trigger: reasoning, CoT, ToT, ReAct, fallacy detection, evidence audit, agent decision quality. Do NOT trigger for: simple single-file edits, trivial reads, basic CRUD operations."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: ai-agents
  status: stable
---
# Reasoning Expert

**CoT, ToT, ReAct patterns. Fallacy detection. Reasoning trace audits.**

## Reasoning Techniques

| Technique | Use Case |
|---|---|
| Chain-of-Thought (CoT) | Multi-step problems, debugging, analysis |
| Tree-of-Thought (ToT) | Multiple options, compare alternatives |
| ReAct | Tool-using agents (think -> act -> observe) |

## Fallacy Detection

### Circular Logic — "X is correct because X is standard"
Fix: Demand external evidence, not self-reference.

### Confirmation Bias — reads 3 supporting files, skips contradicting one
Fix: "What would prove this wrong?"

### Premature Convergence — locks on first solution, <=1 alternative
Fix: "List 3 approaches. Pick best. State why others rejected."

### Authority Over-Reliance — "docs say X" without questioning recency
Fix: Cross-validate: docs vs code vs tests.

### Causal Confusion — "correlation = causation" in debugging
Fix: Reproduce with suspected cause reverted.

### Premise Acceptance — accepts user claims about third-party software capabilities without verification
Fix: Verify against official docs before planning. Flag unverified claims as `[UNVERIFIED PREMISE]`.
- **CLAIM:** "Tool X has feature Y" → verify before accepting.
- **REQUIREMENT:** "We need feature Y from Tool X" → verify Tool X has it before planning.
- Both require verification. When ambiguous, treat as REQUIREMENT (verify + find alternatives if needed).

## Reasoning Audit Report
```
## Reasoning Trace Audit
Agent: {id} | Model: {model}

### Fallacies Detected
- [{type}] at step {N}: {quote}
  Impact: {effect on conclusion}
  Fix: {correct approach}

### Evidence Score
- STATIC: {N} | EXECUTED: {N} | INFERRED: {N} | BLOCKED: {N}
- Quality: {A-F}

### Recommendations
- {actionable fix}
```

## Constraints
- NEVER use CoT for trivial tasks (reads, single-file edits)
- NEVER skip evidence labeling (STATIC/EXECUTED/INFERRED)
- ALWAYS explore >=3 alternatives before converging
- NEVER accept "docs say X" without checking source freshness
- ALWAYS verify user claims about external tool capabilities before planning implementation

## Overview

Structured reasoning patterns (Chain-of-Thought, Tree-of-Thought, ReAct) for AI agent decision quality. Covers fallacy detection (circular logic, confirmation bias, premature convergence), evidence labeling (STATIC/EXECUTED/INFERRED), reasoning trace auditing, and model-appropriate technique selection.

## Quick Reference

| Scenario | Technique |
|---|---|
| Multi-step problem solving (debug, analysis) | Chain-of-Thought (CoT) — linear decomposition |
| Multiple approaches, need to compare | Tree-of-Thought (ToT) — branch exploration |
| Agent needs to use tools and observe results | ReAct — think → act → observe loop |
| Auditing why an agent made a bad decision | Reasoning trace audit with fallacy detection and evidence score |
| Simple read or single-file edit | No technique (CoT wastes tokens on trivial tasks) |

## Workflow

1. **Classify task complexity** — Trivial (0t), Simple (≤500t), Moderate (≤2000t), Complex (≤5000t).
2. **Select technique** — CoT for linear multi-step, ToT for branching alternatives, ReAct for tool-using agents.
3. **Explore ≥3 alternatives** — List approaches; pick best; document why others are rejected.
4. **Label evidence** — `STATIC` (read file), `EXECUTED` (ran command), `INFERRED` (logical deduction), `BLOCKED` (source missing). See `operating-protocol` for canonical labels.
5. **Detect fallacies** — Check for circular logic, confirmation bias, premature convergence, authority over-reliance, causal confusion.
6. **Generate reasoning audit** — Record fallacies detected, evidence score (A-F), and actionable fixes.
7. **Verify solution** — Does the conclusion follow from the evidence? Could a different conclusion be drawn from the same evidence?

## References

| Resource | URL | Last verified |
|---|---|---|
| Chain-of-Thought Prompting (Wei et al.) | https://arxiv.org/abs/2201.11903 | 2025-05 |
| Tree-of-Thought (Yao et al.) | https://arxiv.org/abs/2305.10601 | 2025-05 |
| ReAct: Synergizing Reasoning and Acting (Yao et al.) | https://arxiv.org/abs/2210.03629 | 2025-05 |
| Cognitive Biases Cheatsheet | https://betterhumans.pub/cognitive-bias-cheat-sheet-55a472476b18 | 2025-05 |

- [references/fallacy-reference.md](references/fallacy-reference.md)
- [references/react-pattern.md](references/react-pattern.md)

## Verification Checklist

- [ ] Task complexity classified before selecting technique (CoT/ToT/ReAct)
- [ ] At least 3 alternatives explored before converging on solution
- [ ] All claims labeled with evidence tier per operating-protocol: `STATIC`, `EXECUTED`, `INFERRED`, `BLOCKED`
- [ ] Reasoning trace checked for fallacies: circular logic, confirmation bias, premature convergence
- [ ] CoT not used for trivial tasks (reads, single-file edits) to avoid token waste
- [ ] Conclusion re-verified: could different evidence support a different conclusion?

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Agent converges on wrong approach too quickly | Premature convergence — only 1 alternative evaluated | Force ≥3 alternatives before selecting; document explicit rejection rationale |
| Reasoning trace contradicts actual code behavior | Evidence mislabeled: `INFERRED` used when code was not read | Re-label evidence as `V` only after reading/running code; re-verify assumptions |
| Model applies CoT on trivial read task | Task complexity misclassified as complex | Skip CoT for tasks with <100 lines changed or single-file edits |
| Reasoning audit shows no fallacies but answer is still wrong (known issue: model hallucinates reasoning) | Model fabricates plausible-sounding intermediate steps | Add verification step: each CoT step must cite specific evidence (file:line); enforce evidence gate before conclusion |
| Agent accepts user claim about third-party tool capability without checking docs | Premise Acceptance fallacy — user stated capability as fact | Flag as [UNVERIFIED PREMISE]; verify against official docs before planning; BLOCK planning if capability does not exist |

| [WARN] Agent cites file:line evidence but the line was modified since read (staleness gotcha) | File changed between read and assertion; agent did not re-read before citing | Re-read file immediately before citing evidence; add "last_read_timestamp" to evidence claim |
