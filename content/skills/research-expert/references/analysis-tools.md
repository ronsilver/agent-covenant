# Codebase Analysis Tools

## Git Mining
```bash
# Hotspot analysis (most-changed files)
git log --format=format: --name-only | sort | uniq -c | sort -nr | head -20

# Contributor activity (last 90 days)
git shortlog -sn --since="90 days ago"

# Code churn (lines added+deleted per file)
git log --numstat --pretty=format: | awk '{a[$3]+=$1+$2} END {for(f in a) print a[f],f}' | sort -nr

# Coupling analysis (files frequently changed together)
git log --name-only --pretty=format: | awk 'NF { for(i=1;i<=NF;i++) print $i }' | sort | uniq -c | sort -nr
```

## Dependency Analysis
```bash
# Go: package import map
go mod graph | grep "example"
grep -r "import.*example/shipments" --include="*.go" -l | wc -l

# Python: import graph
pipdeptree --reverse --packages example-core
grep -r "from example" --include="*.py" -l

# TypeScript: dependency usage
npx depcheck
grep -r "from '@example" --include="*.ts" -l
```

## Static Analysis
```bash
# Complexity
gocyclo -over 10 .           # Go cyclomatic complexity
radon cc -a src/             # Python complexity
eslint --rule "complexity"   # TypeScript complexity

# Dead code
deadcode ./...                # Go
vulture src/                  # Python
npx ts-prune                  # TypeScript

# Duplication
jscpd src/                    # All languages
```

## Visualization
```bash
# Dependency graph (Go -> Graphviz)
go mod graph | go-mod-graphviz | dot -Tpng -o deps.png

# Git history visualization
gource --key --title "Shipments" --seconds-per-day 0.5
```
