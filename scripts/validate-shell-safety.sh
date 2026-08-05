#!/usr/bin/env bash
set -euo pipefail

CONTENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../content" && pwd)"
CI_MODE=false
TARGET_FILE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ci) CI_MODE=true; shift ;;
        --file) TARGET_FILE="$2"; shift 2 ;;
        *) echo "Usage: $0 [--ci] [--file path.md]"; exit 1 ;;
    esac
done

echo "Scanning for shell-unsafe '!' patterns in content/"
echo ""

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
VIOLATIONS="$TMPDIR/violations"
touch "$VIOLATIONS"

if [ -n "$TARGET_FILE" ]; then
    FILES="$TARGET_FILE"
else
    FILES=$(find "$CONTENT_DIR" -name "*.md" -not -path "*/node_modules/*" 2>/dev/null)
fi

for f in $FILES; do
    awk '
    BEGIN { in_fence = 0 }
    /^```/ { in_fence = 1 - in_fence; next }
    in_fence == 0 && /!["'\''`\*]/ { print FILENAME ":" NR ": " $0 }
    ' "$f" >> "$VIOLATIONS" 2>/dev/null || true
done

COUNT=0
if [ -s "$VIOLATIONS" ]; then
    COUNT=$(wc -l < "$VIOLATIONS" | tr -d ' ')
    while IFS= read -r v; do
        fname=$(echo "$v" | cut -d: -f1)
        rpath="${fname#"$CONTENT_DIR/"}"
        rest=$(echo "$v" | cut -d: -f2-)
        echo "  $rpath:$rest"
    done < "$VIOLATIONS"
fi

echo ""
if [ "$COUNT" -gt 0 ]; then
    echo "FAIL: $COUNT shell-unsafe '!' patterns found."
    echo "Fix: replace '!' with clear prose (e.g., 'not', 'avoid', 'without')."
    [ "$CI_MODE" = true ] && exit 1
else
    echo "PASS: No shell-unsafe '!' patterns found."
fi
