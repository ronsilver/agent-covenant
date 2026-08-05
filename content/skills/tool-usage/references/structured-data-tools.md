# Structured Data Tools

Discipline for reading, filtering, transforming, and generating JSON, YAML, CSV,
TOML, and XML. Replaces ad-hoc `sed`/`awk`/`grep` pipelines that broke 381+ times
in production history (verified counts from `history.bak` audit, 11,262 lines).

> **Rule of thumb:** structured data is parseable. Parsing beats pattern-matching
> every time. A regex that "works today" silently corrupts when a field contains a
> newline, a quote, an escaped backslash, or a key named `end`.

## Tool Selection Matrix

| Format | Primary tool | Install check | Fallback (only if missing) |
|---|---|---|---|
| JSON | `jq` | `command -v jq >/dev/null 2>&1` | `python3 -c "import json,sys; ..."` |
| YAML | `yq` (mikefarah v4+) | `command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -qi "mikefarah"` | `python3 -c "import yaml,sys; ..."` (PyYAML) |
| CSV | `mlr` (preferred) or `csvkit` | `command -v mlr >/dev/null 2>&1` / `command -v csvcut >/dev/null 2>&1` | `python3 -c "import csv,sys; ..."` |
| TOML | `dasel` (preferred) or `yq` (v4 supports TOML) | `command -v dasel >/dev/null 2>&1` | `python3 -c "import tomllib,sys; ..."` (3.11+) |
| XML | `dasel` (preferred) or `yq` (xml mode) | `command -v dasel >/dev/null 2>&1` | `python3 -c "import xml.etree.ElementTree as ET,sys; ..."` |
| Universal | `dasel` (multi-format) | `command -v dasel >/dev/null 2>&1` | `python3 -c` with stdlib |

## Fallback Chain (MANDATORY)

When operating on structured data, follow this chain and STOP at the first error:

```
1. Dedicated tool (jq / yq / mlr / csvkit / dasel)
       |  if tool missing OR command fails
       v
2. python3 -c "<one-liner using stdlib: json/yaml/csv/tomllib/xml.etree>"
       |  if python3 missing OR stdlib lacks the parser (e.g. PyYAML not installed)
       v
3. STOP. Report: "Error: no tool available to parse <format>. Fix: install <tool> or PyYAML."
```

**NEVER fall through to `sed`, `awk`, or `grep` on structured data.** They cannot
correctly handle quoting, escaping, multi-line values, or nested structures. The
verified failure count across `history.bak` for these shortcuts is 381+.

## Guard Patterns

Every structured-data command MUST be guarded. Use this template:

```bash
# JSON
command -v jq >/dev/null 2>&1 || { echo "Error: jq not installed. Fix: brew install jq"; exit 1; }
jq '.users[] | select(.active)' data.json

# YAML (mikefarah v4 only -- kislyuk yq has incompatible syntax)
command -v yq >/dev/null 2>&1 && yq --version 2>&1 | grep -qi "mikefarah" || { echo "Error: mikefarah/yq not installed. Fix: brew install yq"; exit 1; }
yq '.services.web.port' docker-compose.yml

# CSV (mlr preferred)
command -v mlr >/dev/null 2>&1 || { echo "Error: mlr not installed. Fix: brew install miller"; exit 1; }
mlr --csv filter '$status == "active"' data.csv

# CSV (csvkit alternative)
command -v csvcut >/dev/null 2>&1 || { echo "Error: csvkit not installed. Fix: pip install csvkit"; exit 1; }
csvcut -c name,email data.csv

# TOML / XML / Universal (dasel)
command -v dasel >/dev/null 2>&1 || { echo "Error: dasel not installed. Fix: brew install dasel"; exit 1; }
dasel select -p yaml '.metadata.name' manifest.yaml
dasel select -p toml '.package.name' Cargo.toml
dasel select -p xml '//item[@id="42"]' feed.xml
```

**dasel syntax note:** Use `dasel select -p <format> '<selector>' <file>`.
NEVER use the older `dasel -f <file> -r <format> '<selector>'` form; it is
deprecated in dasel v2+.

## Common Operations -- Reference Recipes

### JSON (jq)

```bash
# Read a field
jq '.version' package.json

# Filter array
jq '.deps[] | select(.name | test("log"))' deps.json

# Transform and write back (atomic)
jq '.version = "2.1.0"' package.json > package.json.tmp && mv package.json.tmp package.json

# Generate from scratch
jq -n '{version: "2.1.0", name: "tool-usage"}'
```

### YAML (yq v4)

```bash
# Read a nested field
yq '.services.web.ports[0]' docker-compose.yml

# Update a field in place (yq -i edits the file)
yq -i '.services.web.image = "nginx:1.25"' docker-compose.yml

# Filter list items
yq '.items[] | select(.kind == "Deployment")' manifest.yaml

# Generate YAML from nothing
yq -n 'apiVersion: "apps/v1" | kind: "Deployment" | metadata: {"name": "web"}'
```

### CSV (mlr)

```bash
# Filter rows
mlr --csv filter '$status == "active"' data.csv

# Select columns
mlr --csv cut -f name,email data.csv

# Sort then filter
mlr --csv sort -f age data.csv | mlr --csv filter '$age > 30'

# JSON output
mlr --icsv --ojson filter '$active' data.csv
```

### TOML / XML (dasel)

```bash
# TOML read
dasel select -p toml '.package.name' Cargo.toml

# XML read (XPath-like)
dasel select -p xml '//item[@id="42"]' feed.xml

# Cross-format convert (YAML -> JSON)
dasel select -p yaml -w json manifest.yaml
```

## Anti-patterns -- Verified From `history.bak`

Each row below is backed by an independent audit of 11,262 lines of shell history.
The "count" column is the number of times the anti-pattern appeared. The fix is
MANDATORY.

| ID | Anti-pattern | Count | Evidence lines | Fix |
|----|-------------|------:|----------------|-----|
| F1 | `python3 -c "import json,sys; ..."` as a jq substitute | ~190 | L1813-2810+ | Use `jq '.field' file`. jq is purpose-built, 10x faster, and avoids Python startup overhead. |
| F2 | `grep` on YAML | 67 | L2053-8824 | Use `yq '.key' file`. yq parses the YAML tree; grep cannot handle multiline values, anchors, or quoted keys. |
| F3 | `grep` on JSON | 32 | L1769-5678 | Use `jq '.field' file`. grep misses nested values and breaks on escaped quotes inside strings. |
| F4+F7+F9 | YAML generation anti-patterns (sed-heredoc ~10 + sed -i 6 + heredoc-var-interp ~10) | 32 | L1092-1183, L10156-10746 | Use `yq -n 'key: value'`. Never build YAML with sed/heredoc -- indentation, quoting, and anchor escaping cannot be regex-safely produced. |
| F5 | `sed -n 'Np' file` for range reads (exclude `cmd | sed -n` which is acceptable) | ~25 | L1353-4777 | Use the Read tool with `offset` and `limit` params. `sed -n '50,75p' file` is replaced by `Read(file, offset=50, limit=25)`. |
| F6 | `cat file.json | jq '.'` redundancy | ~35 | L6326-6546 | `jq` accepts a filename directly: `jq '.' file.json`. The `cat` is a useless process fork and an extra pipe. |

### F1 -- python3-as-jq (worst offender, ~190 hits)

```bash
# BAD -- 190 verified occurrences
python3 -c "import json,sys; d=json.load(sys.stdin); print(d['version'])" package.json

# GOOD
jq '.version' package.json
```

### F2 -- grep on YAML (67 hits)

```bash
# BAD -- grep cannot parse YAML structure
grep -E '^\s*image:\s*' docker-compose.yml

# GOOD
yq '.services.web.image' docker-compose.yml
```

### F3 -- grep on JSON (32 hits)

```bash
# BAD -- breaks on nested values and escaped quotes
grep '"version"' package.json

# GOOD
jq '.version' package.json
```

### F4+F7+F9 -- YAML generation anti-patterns (32 hits total)

```bash
# BAD: sed + heredoc to build YAML (indentation is fragile)
cat > manifest.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $NAME
EOF
sed -i "s/\$NAME/${NAME}/" manifest.yaml

# BAD: sed -i for in-place YAML edits
sed -i 's/^  replicas: 1/  replicas: 3/' manifest.yaml

# BAD: heredoc with variable interpolation (quotes and anchors break)
cat > config.yaml << EOF
db:
  host: "$DB_HOST"
  password: "$DB_PASS"
EOF

# GOOD: yq -n generates valid YAML with correct quoting
yq -n "apiVersion: \"apps/v1\" | kind: \"Deployment\" | metadata: {\"name\": \"${NAME}\"}"

# GOOD: yq -i edits in place with structural awareness
yq -i '.spec.replicas = 3' manifest.yaml
```

### F5 -- sed -n range reads (25 hits)

```bash
# BAD -- sed to slice a file (use the Read tool instead)
sed -n '50,75p' largefile.yaml

# GOOD -- use the dedicated Read tool with offset/limit
# Read(filePath=largefile.yaml, offset=50, limit=25)

# Acceptable exception: piping command output through sed -n
git log --oneline | sed -n '5,10p'
```

### F6 -- cat | jq redundancy (35 hits)

```bash
# BAD -- useless cat process
cat package.json | jq '.version'

# GOOD -- jq reads the file directly
jq '.version' package.json
```

## Decision Flow

```
1. Is the data structured (JSON / YAML / CSV / TOML / XML)?
   YES -> go to 2
   NO  -> use Grep / Read / Edit (ordinary file ops)

2. Is the operation READ or FILTER?
   YES -> use the primary tool from the matrix (jq / yq / mlr / dasel)
   NO  -> go to 3

3. Is the operation TRANSFORM or GENERATE?
   YES -> jq -n / yq -i / yq -n (generate) -- never sed or heredoc
   NO  -> go to 4

4. Is the operation CONVERT (format A -> format B)?
   YES -> dasel select -p A -w B file
   NO  -> go to 5

5. Is the primary tool missing on this host?
   YES -> python3 -c with stdlib (json/csv/tomllib/xml.etree)
   NO  -> STOP. Report the missing tool.
```

## Cross-references

- File operations (Read/Edit/Write) -> [tool-selection.md](tool-selection.md)
- Composite tool design -> [design-principles.md](design-principles.md)
- Anti-patterns (general) -> ../SKILL.md#anti-patterns
