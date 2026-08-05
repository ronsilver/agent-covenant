---
name: prompt-expert
description: "Prompt engineering for production LLM systems: prompt architecture (system/context/instructions/format/examples), advanced techniques (Chain-of-Thought, ReAct, Self-Consistency, Tree-of-Thought, Meta-Prompting, DSPy), multi-layer prompt injection defense (sanitization, context separation, instruction hierarchy, output validation, Bedrock Guardrails), temperature selection by task type, iterative optimization (write -> test -> identify failures -> refine), and team rules (ASCII-only, SYSDATE in SQL, no PII, versioned in code). Use when designing system prompts, implementing few-shot patterns, defending against injection attacks, tuning generation parameters, or iterating on prompt quality. Trigger: prompt engineering, system prompt, injection defense, LLM temperature, few-shot, CoT. Do NOT trigger for: building RAG pipelines, vector search indexing, model training."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: ai-agents
  status: stable
---

# Prompt Expert

**Prompt architecture, techniques, injection defense and team rules.**

## Prompt Architecture
→ Full guide with examples: [references/prompt-architecture.md](references/prompt-architecture.md)

## Injection Defense (5 layers)
→ Detailed defense guide: [references/injection-defense.md](references/injection-defense.md)

## Techniques Quick Ref
| Technique | Use Case |
|---|---|
| Few-Shot | Teach format via examples |
| Chain-of-Thought | Multi-step reasoning |
| ReAct | Tool-using agents (think -> act -> observe) |
| Self-Consistency | Multiple samples + voting |
| Tree-of-Thought | Explore reasoning paths |

## Rules (MANDATORY)
- ASCII-only in system prompts
- SYSDATE() not CURRENT_TIMESTAMP() in SQL
- NEVER embed PII in prompts
- Output format always explicitly specified
- ALL prompts versioned in code

## Core Rules
- NEVER embed secrets, tokens, or API keys in prompts
- NEVER use injection mitigation as only security layer
- NEVER trust LLM output as ground truth for operational data
- ALWAYS test prompts with edge cases before production
- ALWAYS version prompts in code, not hardcoded strings

## Overview

Prompt engineering for production LLM systems: prompt architecture (system/context/instructions/format/examples), advanced techniques (CoT, ReAct, Self-Consistency, Tree-of-Thought, DSPy), multi-layer injection defense, temperature selection per task type, and project-specific rules (ASCII-only, SYSDATE, no PII, versioned prompts).

## Quick Reference

| Technique | Task | Temperature |
|---|---|---|
| Few-Shot | Teach format via examples | 0.0-0.3 |
| Chain-of-Thought | Multi-step math/reasoning | 0.0-0.2 |
| ReAct | Tool-using agents | 0.0-0.5 |
| Self-Consistency | High-stakes classification | 0.3-0.7 (N samples) |
| Tree-of-Thought | Creative exploration | 0.7-1.0 |

## Workflow

1. Define task type and select base technique
2. Structure prompt: system → context → instructions → format → examples
3. Set temperature based on task (low for precision, high for creativity)
4. Add injection defense layers (sanitization, context separation, output validation)
5. Test with edge cases and failure modes
6. Version prompt in code repository, iterate based on eval results

## Anti-patterns

FAIL: Embedding secrets or API keys in system prompts
```python
# BAD: secret in prompt
system_prompt = f"You are a customer service assistant. API key: {API_KEY}"

# GOOD: secrets via tool, not prompt
system_prompt = "You are a customer service assistant. Use the get_api_key tool when needed."
```

FAIL: Using LLM output as ground truth for operational decisions
```python
# BAD: trusting LLM output without validation
quantity = llm.extract("quantity from text")  # may hallucinate

# GOOD: validate against actual record data
quantity = record_db.get_quantity(record_id)
```

FAIL: Not escaping user input in few-shot examples (prompt injection)
```python
# BAD: user input directly interpolated
prompt = f"Translate: {user_input}"

# GOOD: delimit user input clearly
prompt = f"=== USER INPUT ===\n{user_input}\n=== END OF INPUT ==="
```

## References

- Prompt engineering guide (OpenAI): https://platform.openai.com/docs/guides/prompt-engineering (last_verified: 2026-05)
- Anthropic prompt engineering: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering (last_verified: 2026-05)
- Prompt injection OWASP: https://owasp.org/www-community/attacks/Prompt_Injection (last_verified: 2026-05)

- [references/fewshot-library.md](references/fewshot-library.md)

## Verification Checklist

- [ ] No secrets, tokens, or API keys embedded in prompts
- [ ] team rules followed: ASCII-only text, `SYSDATE()` not `CURRENT_TIMESTAMP()`, no PII
- [ ] Injection defense layers applied: sanitization, context separation, output validation
- [ ] Temperature set appropriately for task type (low for precision, high for creativity)
- [ ] Prompts versioned in code repository (not hardcoded strings)
- [ ] Edge cases and failure modes tested before production

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Model ignores format instructions | Temperature too high for format-constrained tasks | Lower temperature to 0.0-0.3; restructure format section with clear delimiters |
| LLM hallucinates operational data in output | No output validation layer | Add validation: compare LLM output against actual record data before presenting |
| User input breaks prompt behavior (injection) | Missing input sanitization or context separation | Apply delimiters around user input; add instruction hierarchy layer |
| Chain-of-Thought prompt works with Sonnet but fails with Haiku (known issue: model-specific reasoning gap) | Weaker models skip intermediate reasoning steps | Add explicit step enumeration; always test prompts with the target model, not SOTA only |

| [WARN] Prompt with `---` YAML delimiter confuses model into treating it as frontmatter end | Model sees `---` and interprets everything after as document body, ignoring system instructions | Replace `---` with `===` or `--- PROMPT START ---` to avoid frontmatter triggering |
