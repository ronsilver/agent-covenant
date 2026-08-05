# Tool Design Principles

## Composite > Chained

One tool = complete workflow.

```
# BAD: 3 tool calls to get customer context
get_customer(id)
list_transactions(customer_id=id)
list_notes(customer_id=id)

# GOOD: 1 tool call
get_customer_context(id)  # returns all recent data
```

## Search > List-All

```
# BAD: loads 1000 entries into context
list_all_contacts() → filter in memory

# GOOD: targeted result
search_contacts(name="John") → 3 matches
```

## Namespacing — MANDATORY (MCP / multi-server)

Format: `{service}_{resource}_{action}`

```
# BAD: generic, collides across servers
search(query)
create(data)

# GOOD: scoped, unambiguous
asana_projects_search(query)
jira_issues_create(data)
```

Evaluate prefix vs suffix ordering — effects vary by model, test both.

## Tool Responses

Return semantic context, NOT technical noise:
- `name`, `file_type` > `uuid`, `mime_type`
- Resolve UUIDs → human-readable names (reduces hallucinations)

Expose `response_format` enum when both modes needed:
- `"concise"` — omit IDs, ~1/3 tokens (human-readable output)
- `"detailed"` — include IDs (for chained tool calls)

Response format (XML/JSON/Markdown): select based on eval, not habit.

## Tool Response Limits — MANDATORY

Max 25k tokens/call. Always implement:
- Pagination: `?page=1&limit=100`
- Filtering: `filter=X`
- Range: `start_line`, `end_line`
- Truncation with steering: `[truncated — use filter=X for targeted results]`

## Error Messages

One-line format: `Error: <what>. Fix: <how>.`

```
# BAD
Error: 422 Unprocessable Entity

# GOOD
Error: 'date' must be ISO 8601 (YYYY-MM-DD). Got: '01/15/2024'.
```

## Param Naming

Unambiguous: `user_id` NOT `user`. Make implicit explicit.
Descriptions: write for new hire, not API consumer.
Include 1-2 canonical param examples in descriptions.

## Parse, Don't Pattern-Match

Structured data is parseable. A regex that "works today" silently corrupts when
a field contains a newline, a quote, an escaped backslash, or a key that happens
to match your pattern. Always parse, never grep/sed/awk structured data.

### JSON

```bash
# BAD -- grep breaks on nested values and escaped quotes
grep '"version"' package.json

# GOOD -- jq parses the tree
jq '.version' package.json
```

### YAML

```bash
# BAD -- grep cannot handle multiline values, anchors, or quoted keys
grep -E '^\s*image:\s*' docker-compose.yml

# GOOD -- yq parses the YAML tree
yq '.services.web.image' docker-compose.yml
```

### CSV

```bash
# BAD -- sed breaks on quoted commas and embedded newlines
sed 's/,.*//' data.csv

# GOOD -- mlr respects CSV quoting rules
mlr --csv cut -f name data.csv
```

Full matrix, fallback chain, and guard patterns: [structured-data-tools.md](structured-data-tools.md).

## YAML Generation Anti-patterns

Never build YAML with `sed`, `heredoc`, or string interpolation. Verified
failure count from `history.bak`: 32 occurrences across three sub-patterns.

### Sub-pattern F4 -- sed + heredoc (10 hits)

```bash
# BAD -- indentation is fragile, quoting is manual
cat > manifest.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
EOF
sed -i 's/web/'"${NAME}"'/' manifest.yaml

# GOOD -- yq -n generates valid YAML with correct quoting
yq -n "apiVersion: \"apps/v1\" | kind: \"Deployment\" | metadata: {\"name\": \"${NAME}\"}"
```

### Sub-pattern F7 -- sed -i in-place YAML edit (6 hits)

```bash
# BAD -- sed cannot parse YAML structure; breaks on anchors and multiline values
sed -i 's/^  replicas: 1/  replicas: 3/' manifest.yaml

# GOOD -- yq -i edits in place with structural awareness
yq -i '.spec.replicas = 3' manifest.yaml
```

### Sub-pattern F9 -- heredoc with variable interpolation (10 hits)

```bash
# BAD -- quotes and anchors in $DB_PASS break the heredoc
cat > config.yaml << EOF
db:
  host: "$DB_HOST"
  password: "$DB_PASS"
EOF

# GOOD -- yq -n with env var reference (no shell interpolation of secrets)
yq -n ".db.host = strenv(DB_HOST) | .db.password = strenv(DB_PASS)" > config.yaml
```

## Cross-reference

- Full tool matrix and anti-pattern table -> [structured-data-tools.md](structured-data-tools.md)
- Tool selection decision matrix -> [tool-selection.md](tool-selection.md)
