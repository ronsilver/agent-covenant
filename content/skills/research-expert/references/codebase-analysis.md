# Codebase Analysis Recipes

## Find Hotspots (Most Changed Files)
```bash
git log --format=format: --name-only | sort | uniq -c | sort -nr | head -20
```

## Code Churn (Added + Deleted Lines)
```bash
git log --numstat --pretty=format: | awk '{a[$3]+=$1+$2} END {for(f in a) print a[f],f}' | sort -nr | head -20
```

## Dependency Mapping
```bash
# Who imports this package?
grep -r "import.*github.com/example/shipments" --include="*.go" -l

# Who calls this function?
grep -r "\.Reserve(" --include="*.go" | wc -l
```

## Bounded Context Detection
1. Analyze directory structure (team ownership hints)
2. Check import boundaries (does package A import package B?)
3. Review database ownership (who owns each table?)

## Triangulation Rule
NEVER trust single source. Cross-validate: code + tests + git history + docs. Code is highest authority.
