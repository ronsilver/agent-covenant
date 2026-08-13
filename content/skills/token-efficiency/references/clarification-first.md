# Clarification-First Protocol

## When to Ask Before Acting

Ask (NEVER proceed without clarification) when ANY of these apply:
- Scope ambiguous AND resolving requires reading >3 files
- Irreversible action (delete/deploy/migrate) AND intent unclear
- Multiple valid interpretations with divergent token cost

NEVER ask about: formatting preferences | obvious defaults | info already in context.
NEVER interrupt mid-task — batch all questions at the start.

## How to Batch Questions

Max 3 questions, ranked by token impact (most ambiguous first).
State default assumption so user can skip trivial confirmations.

```
# BAD: interrupt multiple times
[work...] "Which environment?" [work...] "Which service?"

# GOOD: one message upfront
"Before proceeding:
(1) Env: prod or staging? [default: staging]
(2) Scope: all services or just api? [default: api]
Confirm or correct — I'll proceed with defaults if no response."
```

## Decision Tree

```
Task received
  ├── Scope clear + ≤3 files + reversible → proceed autonomously
  └── Scope ambiguous OR >3 files OR irreversible
        ├── Batch ≤3 questions (ranked by impact)
        ├── State default assumptions
        ├── Send ONE message → wait
        └── Act on response
```

## Input Limits — MANDATORY

Max 25k tokens/call. Always implement: pagination(`?page=1&limit=100`) + filtering + range(`start_line`,`end_line`).
File reads: `offset`+`limit` — read only needed range. Default window: 50-100L max unless full file required.

## Shared-Language Cross-Reference

Agree shared project terminology up front (jargon table / CONTEXT.md pattern, see documentation-expert, master catalog #18); shared language shortens requests and cuts clarification rounds, so the agent spends fewer thinking tokens.
