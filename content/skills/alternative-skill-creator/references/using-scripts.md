# Using Scripts in Skills

## One-Off Commands (No `scripts/` Directory Needed)

When an existing package does what you need, reference it directly in `SKILL.md` without bundling a script:

| Tool | Language | Install |
|------|----------|---------|
| `uvx` | Python | Ships with `uv` |
| `pipx run` | Python | `brew install pipx` |
| `npx` | Node.js | Ships with Node.js |
| `bunx` | Bun | Ships with Bun |
| `deno run` | Deno | Ships with Deno |
| `go run` | Go | Ships with Go |

**Examples:**

```bash
uvx ruff@0.8.0 check .
npx eslint@9 --fix .
go run golang.org/x/tools/cmd/goimports@v0.28.0 .
```

**Tips for one-off commands:**
- **Pin versions** (`npx eslint@9.0.0`) for reproducible behavior
- **State prerequisites** in `SKILL.md` or `compatibility` frontmatter (e.g., "Requires Node.js 18+")
- **Move to scripts/** when a command grows complex enough to be error-prone inline

## Self-Contained Scripts (PEP 723)

Bundle scripts that declare their own dependencies inline — the agent runs them with one command, no separate install step.

### Python with `uv run` (recommended)

Use [PEP 723](https://peps.python.org/pep-0723/) inline script metadata:

```python
# scripts/extract.py
# /// script
# dependencies = [
#   "beautifulsoup4>=4.12,<5",
# ]
# requires-python = ">=3.11"
# ///

from bs4 import BeautifulSoup

html = '<p class="info">Hello</p>'
print(BeautifulSoup(html, "html.parser").select_one("p.info").get_text())
```

Run with:

```bash
uv run scripts/extract.py
```

`uv run` creates an isolated environment, installs declared deps, and runs the script. Fast — caches aggressively.

### Deno (TypeScript, self-contained by default)

```typescript
#!/usr/bin/env -S deno run
import * as cheerio from "npm:cheerio@1.0.0";

const $ = cheerio.load("<p class='info'>Hello</p>");
console.log($("p.info").text());
```

```bash
deno run scripts/extract.ts
```

### Referencing Scripts from SKILL.md

Use **relative paths from the skill root**:

```markdown
## Available scripts

- **`scripts/validate.sh`** — Validates configuration files
- **`scripts/process.py`** — Processes input data

## Workflow

1. Validate input:
   ```bash
   bash scripts/validate.sh "$INPUT_FILE"
   ```
2. Process results:
   ```bash
   uv run scripts/process.py --input results.json
   ```
```

## When to Bundle vs. One-Off

| Situation | Approach |
|-----------|----------|
| Simple package invocation, few flags | One-off command in SKILL.md |
| Same logic reused across multiple tasks | Bundle in `scripts/` |
| Fragile operation requiring exact sequence | Bundle in `scripts/` |
| Complex command error-prone to write inline | Bundle in `scripts/` |
| Needs inline dependency declarations | Bundle with PEP 723 + `uv run` |

## Script Design for Agents

- **Include helpful error messages** — agents use stderr to self-correct
- **Handle edge cases gracefully** — NEVER crash silently
- **Document dependencies inline** (PEP 723) or in a comment block at the top
- **Accept input via arguments or stdin**, not hardcoded paths
- **Test before packaging**: run with sample input and verify output

```python
# /// script
# dependencies = ["pandas>=2.0"]
# ///
import pandas as pd
import sys

if len(sys.argv) < 2:
    print("Usage: uv run scripts/analyze.py <input.csv>", file=sys.stderr)
    sys.exit(1)

df = pd.read_csv(sys.argv[1])
print(df.describe().to_markdown())
```
