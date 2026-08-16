# Subagent Strategy Mapping (Non-normative research reference)

> STATUS: NON-NORMATIVE research documentation. This file maps each of the 17
> active subagents in `content/subagents/` to state-of-the-art reasoning
> architectures (CoT, ToT, ReAct, Reflexion, CoVe, etc.) with technical
> justification. It is NOT a contract: actionable adoptions are governed by
> ADRs 0009-0016 (which edit the actual subagent prompt files). The
> Python/LangGraph pseudocode in the source research report is illustrative
> only -- no LangGraph runtime exists in this repo; do not treat it as an
> implementation contract.
>
> Source: `plans/estrategias_subagentes.md` (2026-06-24). Evidence tags: `[V]`
> = arXiv ID verified live; `[I]` = canonical seminal paper.
> Maintenance: re-baseline when a subagent prompt file changes; this doc does
> not auto-track prompt edits.

## Summary table

| # | Subagent | Category | Main strategies |
|---|-----------|-----------|-------------------------|
| 1 | `ultraplan` | Meta (Opus 4.8) | Plan-and-Solve . Tree of Thoughts . Least-to-Most . Pre-mortem |
| 2 | `ultracode` | Write | ReAct . Self-Refine . TDD-as-reward |
| 3 | `ultradebugger` | Meta | Hypothesis-driven . Delta Debugging . Reflexion |
| 4 | `ultrareview` | Meta | LLM-as-judge . Multi-Agent Debate . multi-dimensional rubric |
| 5 | `research` | Meta | ReAct+RAG . Self-Ask . Chain-of-Verification |
| 6 | `code-review` | Review | Orchestrator-Workers . LLM-as-judge . Self-Consistency |
| 7 | `dependency-audit-agent` | Review | ReAct tool-augmented . CoVe (anti-false-positive) |
| 8 | `idempotency-agent` | Review | Self-Consistency over invariants . Property-based reasoning |
| 9 | `linting-agent` | Review | Tool-grounded deterministic . routing (minimal LLM) |
| 10 | `performance-profiler` | Review | Hypothesis-driven measurement loop . ReAct with profilers |
| 11 | `security-auditor` | Review | ReAct+SAST . CoVe . Constitutional/red-teaming |
| 12 | `test-writer` | Write | Property-based . Metamorphic testing . Self-Refine on coverage |
| 13 | `git-requests` | Write | Routing . Structured Output (deterministic) |
| 14 | `ultraresearch` | Meta | Survey . Multi-source triangulation . Chain-of-Verification |
| 15 | `ultrathinking` | Meta | Multi-dimensional rubric . Pareto analysis . Self-Consistency . Convergent decision |


## Adoption status (ADRs 0009-0016)

The following adoptions are accepted and reflected in the actual subagent
prompt files:

| ADR | Adoption | Files modified |
|-----|----------|----------------|
| 0010 | Staleness anchor fix (B2) | `ultraplan.md` |
| 0011 | CoVe structured (A2) | `research.md`, `security-auditor.md`, `dependency-audit-agent.md` |
| 0012 | Self-Consistency voting BLOCKER/CRITICAL (A1) | `code-review.md`, `security-auditor.md`, `dependency-audit-agent.md`, `idempotency-agent.md` |
| 0013 | Reflexion + cross-session memory (A3) | `ultracode.md`, `ultradebugger.md` |
| 0014 | Tree of Thoughts light (B1) | `ultraplan.md` |
| 0015 | Self-Refine pre-done (B4) + Delta Debugging (B5) + property/metamorphic (B6) | `ultracode.md`, `ultradebugger.md`, `test-writer.md` |
| 0016 | This reference doc | (none -- research reference only) |

Remaining sections below map each subagent to candidate strategies without
specifying implementation; consult ADRs above for adopted subsets.

## Per-subagent sections (1-15)

The detailed analysis lives in `plans/estrategias_subagentes.md` (sections
1-17, lines 59-750). This reference doc does NOT duplicate that content to
avoid drift. For each subagent, that document covers:
- Identified purpose.
- 2-4 candidate scientific strategies with arXiv citations.
- Mechanism explanation and justification against the subagent's purpose.
- Illustrative pseudocode (LangGraph for reasoning agents; structured agnostic
  pseudocode for tooling/review/git agents).

The pseudocode is ILLUSTRATIVE. Adopted implementations live in the subagent
prompt files themselves, governed by the ADRs above.

## Bibliography (arXiv IDs, `[V]` verified live, `[I]` canonical seminal)

### Reasoning and planning
- Chain-of-Thought (CoT) -- Wei et al., NeurIPS 2022, arXiv:2201.11903 `[I]`
- Zero-shot CoT -- Kojima et al., NeurIPS 2022, arXiv:2205.11916 `[I]`
- Self-Consistency -- Wang et al., ICLR 2023, arXiv:2203.11171 `[I]`
- Least-to-Most Prompting -- Zhou et al., ICLR 2023, arXiv:2205.10625 `[I]`
- Plan-and-Solve Prompting -- Wang et al., ACL 2023, arXiv:2305.04091 `[V]`
- Tree of Thoughts (ToT) -- Yao et al., NeurIPS 2023, arXiv:2305.10601 `[I]`

### Agents, action and tools
- ReAct -- Yao et al., ICLR 2023, arXiv:2210.03629 `[I]`
- Self-Ask -- Press et al., 2022, arXiv:2210.03350 `[I]`
- Toolformer -- Schick et al., NeurIPS 2023, arXiv:2302.04761 `[I]`
- RAG -- Lewis et al., NeurIPS 2020, arXiv:2005.11401 `[I]`

### Self-improvement and verification
- Self-Refine -- Madaan et al., NeurIPS 2023, arXiv:2303.17651 `[V]`
- Reflexion -- Shinn et al., NeurIPS 2023, arXiv:2303.11366 `[I]`
- Chain-of-Verification (CoVe) -- Dhuliawala et al., 2023, arXiv:2309.11495 `[V]`
- Constitutional AI -- Bai et al., 2022, arXiv:2212.08073 `[I]`

### Evaluation and multi-agent
- LLM-as-a-Judge (MT-Bench/Chatbot Arena) -- Zheng et al., NeurIPS 2023, arXiv:2306.05685 `[I]`
- Multi-Agent Debate -- Du et al., 2023, arXiv:2305.14325 `[I]`

### Prompt optimization
- APE (Automatic Prompt Engineer) -- Zhou et al., ICLR 2023, arXiv:2211.01910 `[V]`
- OPRO (LLMs as Optimizers) -- Yang et al., ICLR 2024, arXiv:2309.03409 `[V]`
- EvoPrompt -- Guo et al., 2023, arXiv:2309.08532 `[V]`

### Testing and debugging (classical SE)
- Property-Based Testing (QuickCheck) -- Claessen & Hughes, ICFP 2000 `[I]`
- Metamorphic Testing -- Chen et al., ACM Computing Surveys 2018 `[I]`
- Delta Debugging -- Zeller & Hildebrandt, IEEE TSE 2002 `[I]`

### Agent architecture patterns
- Building Effective Agents (prompt-chaining, routing, parallelization,
  orchestrator-workers, evaluator-optimizer) -- Anthropic, 2024 `[I]`
