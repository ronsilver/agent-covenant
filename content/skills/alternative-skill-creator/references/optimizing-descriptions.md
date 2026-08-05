# Optimizing Skill Descriptions

A skill only helps if it gets activated. The `description` field is the **only** signal agents use to decide whether to load a skill for a given task.

## Principles for Effective Descriptions

- **Use imperative phrasing** — "Use when…" not "This skill does…" The agent is deciding whether to act, so tell it when to act.
- **Focus on user intent, not implementation** — describe what the user is trying to achieve.
- **Err on the side of being pushy** — explicitly list contexts, including cases where the user doesn't name the domain directly: "even if they don't explicitly mention 'CSV' or 'analysis.'"
- **Keep it concise** — a few sentences to a short paragraph. Hard limit: 1024 characters.

**Example (weak):**
```yaml
description: Analyzes CSV files and generates statistics.
```

**Example (strong):**
```yaml
description: Analyze CSV files and generate insights with descriptive statistics, trend analysis, and anomaly detection. Use when processing tabular data, summarizing transaction logs, detecting outliers, or extracting patterns from CSV exports — even if the user doesn't explicitly mention "CSV" or "analysis."
```

## Testing Triggering with Eval Queries

Design ~20 labeled queries to test whether the description triggers correctly:

```json
[
  { "query": "I have a spreadsheet with revenue in col C — can you add a profit margin column?", "should_trigger": true },
  { "query": "whats the quickest way to convert this json to yaml", "should_trigger": false }
]
```

### Should-Trigger Queries (8-10)

Vary along these axes:
- **Phrasing**: formal, casual, with typos or abbreviations
- **Explicitness**: some name the domain directly ("analyze this CSV"), others don't ("my boss wants a chart from this data file")
- **Detail**: terse vs. context-heavy
- **Complexity**: single-step vs. multi-step workflows

The most useful cases are ones where the skill would help but **the connection isn't obvious** — these are where description wording makes the difference.

### Should-Not-Trigger Queries (8-10)

Most valuable: **near-misses** — queries sharing keywords but needing something different.

**Weak negative examples** (test nothing):
- `"Write a fibonacci function"` — obviously irrelevant

**Strong negative examples:**
- `"I need to update formulas in my Excel budget spreadsheet"` — shares "spreadsheet" concept but needs Excel editing
- `"Write a Python script that reads a CSV and uploads rows to Postgres"` — involves CSV but is database ETL, not analysis

### Realism Tips

Include in test queries:
- File paths (`~/Downloads/report_final_v2.xlsx`)
- Personal context (`"my manager asked me to..."`)
- Specific column names and data values
- Casual language and occasional typos

## Improving a Failing Description

| Problem | Fix |
|---------|-----|
| Skill doesn't trigger on expected queries | Add synonyms, user intent phrases, and "even if they don't mention X" clauses |
| Skill triggers on irrelevant queries | Add exclusions: "NEVER use for X" or narrow the scope |
| Ambiguous scope | List specific use cases explicitly |

## Note on Simple Tasks

Agents typically only consult skills for tasks that require **knowledge or capabilities beyond what they can handle alone**. A simple "read this PDF" may not trigger a PDF skill even with a perfect description, because the agent can handle it without help. Tasks involving specialized knowledge, domain-specific workflows, or uncommon formats are where a well-written description makes the difference.
