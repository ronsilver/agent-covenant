---
name: scripting-expert
description: "Infrastructure and OS automation via shell scripts (Bash/Zsh for macOS/Linux) and PowerShell 7+ (cross-OS): CI/CD hooks, Helm hooks, Airflow operators, idempotency, static validation with ShellCheck and PSScriptAnalyzer, and testing with bats-core/Pester. Use when writing Bash scripts for CI/CD pipelines, creating Airflow bash operators, implementing Helm chart hooks, writing portable shell scripts, or creating PowerShell automation for DevOps tasks. Trigger: Bash, shell script, CI/CD hook, Helm hook, Airflow, PowerShell, ShellCheck, bats-core. Do NOT trigger for: application code in Go/Python/TypeScript, Kubernetes YAML authoring."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---
# Scripting Expert

**Bash/Zsh + PowerShell: CI/CD, automation, hooks and testing.**

## Core Stack

- POSIX Shell: Bash 5+ / Zsh (macOS default)
- Windows/Cross: PowerShell 7+ (.NET Core, cross-OS)
- Linting: ShellCheck (bash), PSScriptAnalyzer (PowerShell)
- Testing: bats-core (bash), Pester (PowerShell)
- team context: Airflow bash operators, Helm hooks, CI/CD scripts

## Bash/Zsh Patterns

### Safety Header (MANDATORY)

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- `-e`: exit on first error (NEVER omit)
- `-u`: error on undefined variable
- `-o pipefail`: pipe fails if any command in pipe fails

### Idempotent Operations

```bash
# Check state before acting — never assume
if ! command -v aws &>/dev/null; then
  echo "Error: aws CLI not installed" >&2
  exit 1
fi

# Idempotent create-if-not-exists
if [[ ! -d "/opt/example/config" ]]; then
  mkdir -p "/opt/example/config"
fi
```

### Traps for Cleanup

```bash
cleanup() {
  rm -f "${TEMP_FILE}"
  docker stop "${CONTAINER_ID}" 2>/dev/null || true
}
trap cleanup EXIT
```

### Quoting Rules

```bash
# ALWAYS quote variables
cp "${SOURCE}" "${DEST}"      # correct
cp $SOURCE $DEST              # breaks on spaces — NEVER

# NEVER use backticks — use $()
files=$(find . -name "*.go") # correct
files=`find . -name "*.go"`   # deprecated — NEVER
```

## PowerShell 7+ Patterns

```powershell
# Error handling
$ErrorActionPreference = "Stop"

# Idempotent: check before create
if (-not (Test-Path "C:\example\config")) {
    New-Item -ItemType Directory -Path "C:\example\config"
}
```

## Linting (Golden Chain)

```
shellcheck script.sh -> bats test
```

```bash
# Run shellcheck on all scripts
find . -name "*.sh" -exec shellcheck {} +
```

```
PSScriptAnalyzer -> Pester test
```

## Testing with bats-core

```bash
#!/usr/bin/env bats

@test "script exits 0 on valid input" {
  run ./process_item.sh --value 1000 --type standard
  [ "$status" -eq 0 ]
}

@test "script exits non-zero on missing value" {
  run ./process_item.sh --type standard
  [ "$status" -ne 0 ]
}
```

## Patterns

### Airflow Bash Operator

```python
# data-orchestration-airflow
BashOperator(
    task_id="validate_partitions",
    bash_command="scripts/validate_partitions.sh --table {{ ds }}",
    dag=dag
)
```

### Helm Hook

```yaml
# infraestructure-helm
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    "helm.sh/hook": pre-upgrade
spec:
  template:
    spec:
      containers:
      - name: migrate
        command: ["/scripts/migrate.sh"]
```

## Choosing Between Shells

| Scenario | Shell |
|---|---|
| macOS/Linux CI | Bash (shebang `#!/usr/bin/env bash`) |
| Cross-platform | PowerShell 7+ |
| Airflow operators | Bash (Linux workers) |
| Helm hooks | Bash (container images) |
| Windows targets | PowerShell |

## Constraints

- ALWAYS `set -euo pipefail` or equivalent error handling
- NEVER use backticks — `$()` only
- ALWAYS quote variables in bash (spaces break unquoted)
- NEVER `eval` on user/external input
- NEVER hardcode secrets — use env vars or secret management
- ALWAYS log to stderr for diagnostics (`>&2`), stdout for data output
- ALWAYS handle exit codes explicitly — never assume success
- NEVER `rm -rf` without explicit path validation
- NEVER `curl | bash` — download, verify, then execute
- ALWAYS test idempotency: run twice, expect same result

## Overview

Automate infrastructure and CI/CD through shell scripts (Bash/Zsh for macOS/Linux) and PowerShell 7+ (cross-OS): Helm hooks, Airflow operators, idempotent operations, static validation with ShellCheck/PSScriptAnalyzer, and testing with bats-core/Pester.

## Quick Reference

| Task | Tool | Command |
|---|---|---|
| Bash linting | ShellCheck | shellcheck script.sh |
| Bash testing | bats-core | bats test.bats |
| PowerShell linting | PSScriptAnalyzer | Invoke-ScriptAnalyzer script.ps1 |
| PowerShell testing | Pester | Invoke-Pester test.ps1 |
| Safety header | Bash | set -euo pipefail |

## Workflow

1. Add safety header: `set -euo pipefail` (Bash) or `$ErrorActionPreference = "Stop"` (PowerShell)
2. Check prerequisites: commands exist, files accessible
3. Implement idempotent operations (check state before changing)
4. Add traps for cleanup of temp files and resources
5. Run shellcheck/PSScriptAnalyzer linting
6. Write bats-core/Pester tests, run twice to verify idempotency

## Anti-patterns

FAIL: Running rm -rf without path validation
```bash
# BAD: unvalidated path
rm -rf "${DIR}/temp"

# GOOD: validate path is safe
[[ "${DIR}" == "/tmp/example/"* ]] || { echo "unsafe path: ${DIR}" >&2; exit 1; }
rm -rf "${DIR}/temp"
```

FAIL: Piping curl output directly to shell
```bash
# BAD: execute without verification
curl -sL https://example.com/install.sh | bash

# GOOD: download, verify, then execute
curl -sL -o install.sh https://example.com/install.sh
sha256sum -c install.sha256 && bash install.sh
```

FAIL: Using eval with user-supplied input
```bash
# BAD: eval on external input
eval "command ${user_input}"

# GOOD: structured parsing with validation
case "${user_input}" in
    start|stop|restart) service_action "${user_input}" ;;
    *) echo "invalid action" >&2; exit 1 ;;
esac
```

## References

- ShellCheck documentation: https://www.shellcheck.net/ (last_verified: 2026-05)
- bats-core test framework: https://github.com/bats-core/bats-core (last_verified: 2026-05)
- PowerShell PSScriptAnalyzer: https://learn.microsoft.com/en-us/powershell/module/psscriptanalyzer/ (last_verified: 2026-05)

- [references/bash-patterns.md](references/bash-patterns.md)
- [references/idempotency.md](references/idempotency.md)
- [references/testing-bats.md](references/testing-bats.md)

## Verification Checklist

- [ ] Safety header present: `set -euo pipefail` (Bash) or `$ErrorActionPreference = "Stop"` (PowerShell)
- [ ] All variables quoted in Bash (no unquoted expansions)
- [ ] No backticks used — `$()` syntax only
- [ ] No `eval` on user or external input
- [ ] No `rm -rf` without explicit path validation
- [ ] Cleanup trap registered for temp files and resources
- [ ] Exit codes handled explicitly (never assume success)
- [ ] Idempotency verified: script produces same result when run twice

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Script fails on paths with spaces | Variables not quoted | Wrap all variable expansions in double quotes: `"${VAR}"` |
| Trap cleanup not triggered on error | `set -e` causes exit before `trap` registers | Move `trap` registration to top of script, before any commands |
| ShellCheck passes but script behaves differently on macOS | Bash version differences (3.2 on macOS vs 5+ on Linux) | Test on target OS; avoid Bash 4+ only features or use `#!/usr/bin/env bash` compatible syntax |
| `trap` does not catch `SIGKILL` (known limitation: SIGKILL cannot be trapped) | `kill -9` bypasses all trap handlers | Use `SIGTERM` as primary signal; implement watchdog process for forced termination cleanup |

| [WARN] Bash `set -euo pipefail` still ignores error in `if` condition or `&&` chain | `set -e` is disabled inside conditions (`if`, `while`, `until`, `||`, `&&`) | Add explicit `|| exit $?` after critical commands; use `trap ERR` for global coverage |
| trap EXIT fires but script continues running because trap does not exit automatically | trap EXIT runs cleanup code but does not stop script execution after trap completes | Add exit at end of trap body; use trap "cleanup; exit" EXIT pattern for termination |
| Edge case: process substitution <() creates named pipe that leaks if shell exits before read | Process substitution file descriptor stays open; zombie process if parent exits without consuming output | Use temp file with trap cleanup instead of process substitution for critical scripts |
