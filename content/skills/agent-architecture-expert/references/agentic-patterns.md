# Agentic System Patterns (Anthropic, 2024)

## Workflows vs Agents
- **Workflows**: LLMs orchestrated through predefined code paths. Predictable, consistent.
- **Agents**: LLMs dynamically direct processes and tool usage. Flexible, decision-making at scale.

## Prompt Chaining
Decompose task into sequential steps where each LLM call processes previous output.
Gate checks between steps ensure correctness. Trade latency for accuracy.
Example: outline -> check outline -> write document -> translate.

## Routing
Classify input, direct to specialized handlers. Separation of concerns.
Route simple queries to Haiku, complex to Sonnet/Opus. Optimize cost + quality.

## Parallelization
- **Sectioning**: Break into independent subtasks run simultaneously
- **Voting**: Multiple runs for diverse outputs, aggregate for higher confidence
Example: guardrails model (content screening) runs parallel to response model.

## Orchestrator-Workers
Central LLM dynamically decomposes tasks, delegates to workers, synthesizes results.
Key difference from parallelization: subtasks NOT predefined — determined per input.
Example: multi-file code changes where files to modify are unknown upfront.

## Evaluator-Optimizer
One LLM generates, another evaluates + provides feedback in a loop.
Effective when: human feedback demonstrably improves output, LLM can provide feedback.
Example: literary translation refinement, complex multi-round search tasks.

## Autonomous Agents
LLM plans and operates independently using tools based on environmental feedback.
Includes: human feedback at checkpoints, stopping conditions (max iterations).
Implementation is straightforward: LLMs using tools in a feedback loop.

## When NOT to use agents
Start with simplest solution. Single LLM call with retrieval + in-context examples often sufficient.
Add agentic patterns only when simpler approaches demonstrably fail.
