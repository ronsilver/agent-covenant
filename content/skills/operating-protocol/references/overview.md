# Operating Protocol — Overview

Core agent behavioral rules: identity, risk classification, task execution, safety, and anti-hallucination.

## Reference Files

| File | Content |
|---|---|
| [risk-tiers.md](risk-tiers.md) | T0-T4 table, irreversible action gates, 7Q gate, crash policy |
| [risk-framework.md](risk-framework.md) | Autonomy matrix, weighted priority, permissionMode mapping, ATLAS IDs |
| [anti-hallucination.md](anti-hallucination.md) | Evidence labels, confidence bands, retraction discipline, status-claim audit |
| [scope-discipline.md](scope-discipline.md) | Scope rules, HARD-GATE, 4-status handoff, checkpoint, progress reporting |
| [untrusted-content.md](untrusted-content.md) | Injection detection, ATLAS IDs, cumulative-output, never-auto-do list |
| [done-criteria.md](done-criteria.md) | PASS/FAIL/INVALID verdict, 4-status semantics, status-claim audit, silent-compliance |

## Glossary

EXECUTED=ran | STATIC=read | INFERRED=logic | BLOCKED=missing-source
V=VERIFIED | I=INFERRED | U=UNKNOWN
PASS=criteria-met | FAIL=criteria-not-met | INVALID=cannot-judge
DONE=complete+verified | DONE_WITH_CONCERNS=complete+open-items | NEEDS_CONTEXT=missing-info | BLOCKED=needs-human | SKIPPED=requirement-impossible+user-notified
fn=function | ctx=context | DB=database | auth=authentication | cfg=config
req=request | res=response | deps=dependencies | impl=implementation
env=environment | err=error | msg=message | T0-T4=risk tiers
