# Tool Selection Decision Matrix

## File Operations
| Need | Tool | Never |
|---|---|---|
| Read file | Read | cat, less, head, tail |
| Edit file | Edit | sed, awk |
| Write file | Write | echo >, cat <<EOF |
| Search content | Grep | grep, rg, ack |
| Find files | Glob | find, ls, locate |
| Directory tree | filesystem_directory_tree | tree, ls -R |

## GitHub Operations
| Need | Tool | Fallback |
|---|---|---|
| PR review | github_pull_request_read | gh pr view |
| PR diff | github_pull_request_read (get_diff) | gh pr diff |
| Create PR | github_create_pull_request | gh pr create |
| Issue management | github_issue_read/write | gh issue |

## Shell Operations
| Need | Use |
|---|---|
| Run script | Bash |
| Git commands | Bash (git *) |
| Package managers | Bash (npm, pip, go, cargo) |
| Docker | Bash (docker *) |
| Testing | Bash (pytest, go test, jest) |

## When to Use Bash
- No dedicated tool exists for the operation
- Need to chain multiple commands
- Running project-specific scripts (make, npm scripts, CI)
- Git operations beyond simple status/diff

## Structured Data Operations

For JSON, YAML, CSV, TOML, and XML: ALWAYS use a parser, never sed/awk/grep.
Fallback chain: dedicated tool -> python3 -c -> error. Full recipes and
guard patterns: [structured-data-tools.md](structured-data-tools.md).

| Operation | JSON | YAML | CSV | TOML / XML | Universal |
|---|---|---|---|---|---|
| Read / filter | `jq '.k' f` | `yq '.k' f` | `mlr --csv filter '$k' f` | `dasel select -p fmt '.k' f` | `dasel select -p fmt '.k' f` |
| Transform (in place) | `jq '.' f > f.tmp && mv` | `yq -i '.k = v' f` | `mlr --csv ... > f.tmp` | `dasel put -p fmt '.k' 'v' f` | `dasel put -p fmt '.k' 'v' f` |
| Convert (A -> B) | `dasel select -p json -w yaml f` | `dasel select -p yaml -w json f` | `mlr --icsv --ojson f` | `dasel select -p xml -w json f` | `dasel select -p A -w B f` |
| Validate | `jq empty f` | `yq '.' f` | `mlr --csv check f` | `dasel select -p fmt '.' f` | `dasel select -p fmt '.' f` |
| Universal fallback | `python3 -c "import json,sys; ..."` | `python3 -c "import yaml,sys; ..."` (needs PyYAML) | `python3 -c "import csv,sys; ..."` | `python3 -c "import tomllib,sys; ..."` (3.11+) | STOP + report missing tool |

**Guards are mandatory.** Every command must be preceded by:
`command -v <tool> >/dev/null 2>&1 || { echo "Error: <tool> not installed. Fix: <install cmd>"; exit 1; }`
For yq, additionally verify mikefarah v4+: `yq --version 2>&1 | grep -qi "mikefarah"`.
