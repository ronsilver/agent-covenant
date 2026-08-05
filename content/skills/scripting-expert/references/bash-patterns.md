# Bash Best Practices

## Safety Header
```bash
#!/usr/bin/env bash
set -euo pipefail
```
-e: exit on error | -u: undefined variable error | -o pipefail: pipe fails if any cmd fails

## Quoting Rules
```bash
# ALWAYS quote variables
cp "${source}" "${dest}"
echo "Path: ${PATH}"

# NEVER unquoted
# cp $source $dest  # BREAKS on spaces

# Use $() over backticks
files=$(find . -name "*.go")   # correct
files=`find . -name "*.go"`    # deprecated
```

## Conditionals
```bash
# File tests
[[ -f "${file}" ]]   # exists and regular file
[[ -d "${dir}" ]]    # is directory
[[ -z "${var}" ]]    # is empty
[[ -n "${var}" ]]    # is non-empty

# String comparison
[[ "${a}" == "${b}" ]]
[[ "${a}" != "${b}" ]]

# Numeric
(( count > 5 ))
(( count <= 10 ))
```

## Functions
```bash
process_item() {
    local value="${1}"
    local type="${2:-standard}"  # default value
    echo "Processing ${value} ${type}"
}
```

## Traps
```bash
cleanup() {
    rm -f "${temp_file}"
    docker stop "${container_id}"
}
trap cleanup EXIT
```

## Logging
```bash
log_info()  { echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO  $*"; }
log_error() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR $*" >&2; }
```
