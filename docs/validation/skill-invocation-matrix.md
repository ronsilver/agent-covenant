# Skill Invocation Matrix

Track empirical recall rate of core rule skills after hybrid architecture deployment (F2.8/2.9).

## Methodology

For each agent session where a core rule skill was relevant, record:
- Was the skill invoked automatically? (model_decision trigger)
- Was the skill invoked manually? (/skill-name)
- Was it NOT invoked but should have been?

## Matrix Template

| Skill | Agent | Sessions | Auto-invoked | Manual | Missed | Recall % |
|---|---|---|---|---|---|---|
| engineering-standards | claude-code | 0 | 0 | 0 | 0 | - |
| operating-protocol | claude-code | 0 | 0 | 0 | 0 | - |
| context-management | claude-code | 0 | 0 | 0 | 0 | - |
| tool-usage | claude-code | 0 | 0 | 0 | 0 | - |
| token-efficiency | claude-code | 0 | 0 | 0 | 0 | - |
| engineering-standards | windsurf | 0 | 0 | 0 | 0 | - |
| operating-protocol | windsurf | 0 | 0 | 0 | 0 | - |
| context-management | windsurf | 0 | 0 | 0 | 0 | - |
| tool-usage | windsurf | 0 | 0 | 0 | 0 | - |
| token-efficiency | windsurf | 0 | 0 | 0 | 0 | - |
| context-degradation | claude-code | 0 | 0 | 0 | 0 | - |
| context-degradation | windsurf | 0 | 0 | 0 | 0 | - |

## Decision Gate (F2.9)

After 2 weeks of observation:
- Recall % >= 80% for all skills → architecture validated, kernel-only mode confirmed.
- Recall % < 60% for any skill → expand kernel to include that rule section verbatim.
- Recall % 60-79% → improve skill description trigger verbs and retry for 1 more week.

## Weekly Review Files

Weekly snapshots: `docs/validation/weekly-review-<YYYY-WW>.md`
Format: date | skills invoked | missed signals | description improvements applied.
