# Output Compression Guide

## Always-Active Rules
- ≤25 words between tool calls
- ≤50 words task completion summary
- Drop: articles (the, a, an), filler words (just, really, simply)
- Drop: pleasantries (hello, thank you, great question)
- Abbreviate: DB, auth, cfg, req, res, fn, ctx, err, deps, impl, env, msg

## Compression Levels
| Level | Verbosity | Use |
|---|---|---|
| L0 (Default) | Normal | Human-readable |
| L1 (Compressed) | ≤25w | Between tool calls |
| L2 (Ultra) | ≤10w | Multi-step chains |
| L3 (Data) | Schema only | Agent-to-agent |
| L4 (Code) | Code only | Implementation |
| L5 (Silent) | 0 tokens | Trivial operations |

## Thinking Budget
| Task | Budget |
|---|---|
| File read, grep, list | 0t (call directly) |
| Single-file edit, known pattern | ≤500t |
| Cross-file refactor, debug | ≤2000t |
| Arch decision, multi-repo | ≤5000t |

NEVER re-reason resolved conclusions.
NEVER speculate before simple tool calls.
Extended thinking ONLY for: arch decisions, security, multi-file bugs, first-attempt failures.
