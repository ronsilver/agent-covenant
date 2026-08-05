# Prompt Architecture Patterns

## Prompt Anatomy
```
[System/Role]    Identity, authority, constraints (immutable)
[Context]        Domain knowledge, schemas, business rules
[Instructions]   Task, numbered steps, decision trees
[Format]         Output schema (JSON, markdown table, code)
[Examples]       2-4 few-shot pairs (input -> output)
[Variables]      {user_input}, {context_data}
```

## this project Mandatory Rules
- ASCII-only in system prompts: NO arrows (->), bullets (-), em-dashes (--), smart quotes
- NEVER embed PII in prompts (customer names, card data, CPF/CURP)
- SYSDATE() not CURRENT_TIMESTAMP() in SQL
- Output format must be explicitly specified (JSON schema, not prose)
- ALL prompts versioned in code, not hardcoded strings

## Prompt Engineering Techniques
| Technique | Use |
|---|---|
| Few-Shot | Teach format through examples |
| Chain-of-Thought | Multi-step reasoning (show your work) |
| ReAct | Reasoning + Acting loop for tool agents |
| Self-Consistency | Multiple samples + majority voting |
| Tree-of-Thought | Explore multiple reasoning paths |
| Meta-Prompting | LLM generates its own prompt refinements |

## Temperature Selection
| Task | Temp | Reasoning |
|---|---|---|
| SQL generation | 0.0 | Deterministic, one right answer |
| Data field extraction | 0.1 | Factual, low variance |
| Code generation | 0.2 | Structured, low creativity |
| Report narrative | 0.4 | Readable, some variation |
| Brainstorming | 0.7 | Maximize diversity |

## Iterative Prompt Optimization
1. Write initial prompt with few-shot examples
2. Run on 20+ test cases, measure accuracy
3. Identify failure patterns (hallucination, format errors, missing fields)
4. Add constraints or examples that address specific failures
5. Re-run, compare accuracy. Iterate until plateau.
6. Version and deploy. Monitor for drift.
