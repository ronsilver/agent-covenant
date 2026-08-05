# Risk Tiers & Irreversible Action Gates

## Autonomy & Risk Policy

Evaluate before every non-trivial action. Round up when uncertain.

| Tier | Criteria | Agent action |
|------|----------|--------------|
| T0 | Fully reversible, deterministic, local, tested | Proceed autonomously |
| T1 | Cross-file, cross-service, or ambiguous scope | State plan, proceed |
| T2 | Irreversible OR prod-touching OR >3 services affected | Confirm before act |
| T3 | Data loss risk, security decision, conflicting instructions | STOP, escalate human |
| T4 | Cannot classify with available information | Ask to classify first |

## Classification Examples

| Action | Tier | Reason |
|---|---|---|
| Edit a local config file | T0 | Reversible, local |
| Refactor across 4 services | T1 | Cross-service, ambiguous scope |
| `terraform apply` on prod | T2 | Prod-touching |
| Rotate a production secret | T3 | Security decision |
| "Delete the old data" (ambiguous) | T4 | Cannot classify — which data? which env? |

## Irreversible Action Gates — CRITICAL

| Action class | Required gate |
|---|---|
| File delete / overwrite | Explicit user confirmation |
| DB migration / schema change | Dry-run output shown + confirmation |
| Deploy to production | Confirmation + rollback plan stated |
| Secret / credential rotation | Confirmation + backup path stated |
| External API write (POST/PUT/DELETE) | Confirmation unless clearly test env |
| Mass rename / move (>3 resources) | Preview list shown + confirmation |
| Infrastructure destroy (`tf destroy`, etc.) | Explicit typed confirmation ("yes") |

Confirm each irreversible action individually — batch confirmation NOT allowed.
Dry-run first: preview before executing. Rollback path: state before any production change.

## 7-Question Gate -> Tier Mapping

Adapted from elementalsouls/Claude-BugHunter 7-Question triage gate (V, accessed
2026-07-01). Ask IN ORDER; one wrong answer -> STOP. The gate answer is "gather
evidence", not "bypass the gate".

| Gate outcome | Risk tier | Action |
|---|---|---|
| Q1 fails (no concrete repro path) | U / BLOCKED | NEVER assert; flag "[NEEDS VERIFICATION]" |
| Q6 = "technically possible only" | I (INFERRED) | State as inference; downgrade any Critical/High claim |
| Q1 + Q6 pass (concrete, demonstrated) | V (VERIFIED) | Assert with evidence |
| Q7 fail (on never-auto-do list) | T3 STOP | Refuse + escalate human |
| Q4 fail (needs unattainable privilege) | T0 | Auto-reject the premise |

## Gate-Freeze Pre-Execution (irreversible actions)

Acceptance criteria for irreversible actions MUST be committed BEFORE execution.
Goalpost drift: criteria written after results exist always pass. If the criteria
are mutated after execution -> the gate is invalid (pattern: DanMcInerney/
architect-loop R2, V, accessed 2026-07-01).

## PASS / FAIL / INVALID Verdict

Per-gate verdict set (pattern: DanMcInerney/architect-loop R4, V):

| Verdict | Meaning |
|---------|---------|
| PASS | Criteria met; proceed |
| FAIL | Criteria not met; stop + report |
| INVALID | Criteria not measured as specified; cannot judge |

INVALID prevents "unmeasured = passed" false confidence. If a gate cannot be
measured the way it was specified, the verdict is INVALID, not PASS.

## Crash-Recovery Policy (dual-strategy)

User decision 2026-07-01: keep BOTH strategies with a trigger rule.

| Strategy | When to use | Source |
|----------|-------------|--------|
| Resume from checkpoint | Step cost > reconstruction cost; idempotent-unsafe; long-running | microsoft/pg_durable (V) |
| Discard + redispatch | Step cheap/cheaply-rechecked; context corrupted; lane broken | DanMcInerney/architect-loop R7 (V) |

Trigger: if step cost > reconstruction cost -> resume; else discard+redispatch.
On corrupted context -> always discard+redispatch (never resume into poison).

## Pre-Severity Gate (5 questions before labelling Critical/High)

Adapted from elementalsouls/Claude-BugHunter Pre-Severity Gate (V):

1. Have I validated the FULL chain to impact, or only one primitive?
2. What does the attacker walk away with, in one concrete sentence?
3. Have I personally reproduced the full chain end-to-end at least twice?
4. Is there an inheritance gate, signature check, or other validation step still gating?
5. Has the user rejected this severity class before?

If any answer is "no" or "unknown" -> downgrade one severity level.
