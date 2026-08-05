# Caveman Compression — 6 Intensity Levels

## When to Apply

Activate when context window >70% or response budget tight. Escalate levels progressively.

## Intensity Levels

### Level 1 — Lite
Trim filler words (just, really, simply, basically, actually). Drop pleasantries and hedging.
```
Before: "I think we should probably consider updating the config."
After:  "Update the config."
```

### Level 2 — Standard
Drop articles (a, an, the), auxiliary verbs where unambiguous. Abbreviate common terms.
```
Before: "The error is happening because the database connection pool is exhausted."
After:  "DB connection pool exhausted."
```

### Level 3 — Full
Telegraphic. Subject-verb-object only. All articles and prepositions dropped.
```
Before: "I've analyzed the auth middleware and found the token expiry check uses < instead of <=."
After:  "Auth middleware bug. Token expiry `<` not `<=`. Fix: change operator."
```

### Level 4 — Ultra
≤5 words per statement. Code-like fragments. Abbreviations mandatory.
```
"auth mid token `<`→`<=`. Fix L42."
```

### Level 5 — Wenyan-Lite
Classical Chinese brevity in target language. Drop subjects, particles, copulas.
```
"Token过期比较运算符错误。改`<`为`<=`。"
```

### Level 6 — Wenyan-Ultra
Maximum compression. Only root concepts survive. Use only when safety is already confirmed.
```
"过期。`<`→`<=`。"
```

## Auto-Clarity Rule (SAFETY OVERRIDE)

These content types are **NEVER compressed** — auto-escalate to full clarity:
- Security warnings (CVE, injection, credential exposure)
- Irreversible action confirmations (delete, destroy, drop)
- User asked for explanation or teaching
- Legal/compliance statements
- Error messages shown to end users

**Override trigger**: if Level ≥3 would obscure a safety-critical signal, drop to Level 1 automatically.

## Abbreviation Table

| Full | Abbrev | Full | Abbrev |
|---|---|---|---|
| database | DB | configuration | cfg |
| authentication | auth | request | req |
| response | res | function | fn |
| context | ctx | error | err |
| dependencies | deps | implementation | impl |
| environment | env | message | msg |
| application | app | service | svc |
| infrastructure | infra | repository | repo |
| production | prod | development | dev |
| without | w/o | with | w/ |
| between | btw | because | b/c |
