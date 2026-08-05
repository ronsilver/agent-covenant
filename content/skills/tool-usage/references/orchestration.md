# Orchestration & Path/Bash Rules

## Orchestration — MANDATORY

Independent tool calls → parallel (same message).
Sequential dependencies → chain (await result before next call).
Long-running, result not needed immediately → `run_in_background`.
N similar commands → single loop in one Bash call.

```bash
# BAD: 3 separate Bash calls
curl https://api.example.com/a
curl https://api.example.com/b
curl https://api.example.com/c

# GOOD: single call
for x in a b c; do curl "https://api.example.com/$x"; done
```

NEVER use `run_in_background` for:
- Operations <5s
- When output is needed for the next step

NEVER use newlines to separate commands — use `;` for sequential, parallel tool calls for independent.

## Path & Bash — MANDATORY

ALWAYS use absolute paths (agent threads reset `cwd`).
NEVER `cd` — use absolute paths throughout.
NEVER sleep in loops or before commands.
NEVER heredoc in terminal (`cat << EOF`) — heredoc fails in non-interactive shells.
Correct: write script to `/tmp/script.sh` via Write tool, then `chmod +x` + execute.

## Interactive Git — NEVER

NEVER: `git add -i` | `git rebase -i` | `git commit --amend`
These require interactive input which is not supported in agent context.

## Read Before Edit/Write — MANDATORY

NEVER reference a file, function, or import without reading it first.
NEVER assume command output — run and verify.
NEVER fabricate results.
