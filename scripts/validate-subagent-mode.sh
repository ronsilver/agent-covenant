#!/usr/bin/env bash
set -euo pipefail

errors=0
for f in content/subagents/*.md; do
    [[ "$f" == *README.md ]] && continue
    mode=$(awk '/^---$/ {c++; next} c==1 && /^mode:/ {print $2; exit}' "$f")
    if [[ "$mode" != "subagent" ]]; then
        echo "FAIL: $f mode=$mode (must be subagent)"
        errors=$((errors + 1))
    fi
done
if [[ $errors -gt 0 ]]; then
    echo "FAILED subagent mode check: $errors file(s)"
    exit 1
fi
echo "PASS: all subagents mode=subagent"
