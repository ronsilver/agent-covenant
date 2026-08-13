---
name: research-expert
description: "Exploratory analysis of repositories and technical sources: dependency map generation (AST parsing), bounded context detection, quantitative technical debt identification (code churn, cyclomatic complexity), hotspot analysis via git log mining, multi-source triangulation, and citation tracking. Use when exploring unfamiliar codebases, researching technical approaches, comparing technologies, analyzing repository structure, or building knowledge bases from source code. Trigger: research, codebase exploration, dependency mapping, technical debt, hot-spot analysis, git mining, triangulation. Do NOT trigger for: debugging specific bugs, writing code, reviewing pull requests, general web research without codebase context (use websearch tool directly)."
license: MIT
metadata:
  author: Community
  version: "1.1"
  category: process
  status: stable
---
# Research Expert

**Codebase exploration, dependency mapping, tech research and triangulation.**

## Research Workflow

1. **Define question** — what specifically are we trying to learn?
2. **Gather sources** — code, docs, git history, external references
3. **Map dependencies** — what depends on what?
4. **Identify patterns** — architecture style, bounded contexts, anti-patterns
5. **Triangulate** — cross-validate across >=3 independent sources
6. **Synthesize** — produce structured findings document

## Codebase Analysis

```bash
# Hotspot analysis — files changed most frequently
git log --format=format: --name-only | sort | uniq -c | sort -nr | head -20

# Code churn — files with most added/deleted lines
git log --numstat --pretty=format: | awk '{a[$3]+=$1+$2} END {for(f in a) print a[f],f}' | sort -nr | head -20

# Dependency map — what imports this package?
grep -r "import.*github.com/example/services" --include="*.go" -l
```

## Dependency Graph Analysis

```
Entry points -> Core domain -> Infrastructure -> External deps

Identify:
- Circular dependencies (A imports B, B imports A)
- God packages (imported by >20 files)
- Orphans (imported by 0 files — dead code?)
```

## Multi-Source Triangulation

| Source | Reliability | Use For |
|---|---|---|
| Source code | Highest | Behavior, architecture |
| Tests | High | Expected behavior, edge cases |
| Git history | High | Change frequency, ownership |
| Documentation | Medium | Intent, rationale |
| Issues/PRs | Medium | Known problems, discussions |
| External docs | Variable | API specs, best practices |

## Constraints
- NEVER trust documentation over code behavior (code is truth)
- NEVER draw conclusions from single source (triangulate >=3)
- ALWAYS verify assumptions by reading actual source code
- NEVER assume patterns without statistical evidence (grep counts, git stats)

## Overview

Conduct exploratory analysis of repositories and technical sources: dependency graph mapping via AST parsing, bounded context detection, quantitative technical debt identification (code churn, cyclomatic complexity), hotspot analysis through git log mining, multi-source triangulation, and citation tracking.

## Quick Reference

| Analysis | Command | Insight |
|---|---|---|
| Hotspot files | git log --name-only | sort | uniq -c | sort -nr | Files changed most frequently |
| Code churn | git log --numstat | awk sum | Files with most added/deleted lines |
| Dependencies | grep -r "import.*pkg" | Which files depend on a given package |
| Cyclomatic complexity | gocyclo ./... | High-complexity functions needing refactor |
| Bounded contexts | grep package declarations | Module boundaries and cohesion |

## Workflow

1. Define the research question explicitly before gathering data
2. Gather sources: code, git history, docs, issues, external references
3. Map dependencies and identify circular deps or god packages
4. Analyze hotspots: high churn + high complexity = refactor candidates
5. Triangulate findings across at least 3 independent sources
6. Synthesize into structured document with evidence and recommendations

## Anti-patterns

FAIL: Drawing conclusions from a single source
```python
# BAD: trusting a single comment or doc
# docs say "this is the target service" — may be outdated

# GOOD: triangulate
# 1. Check actual imports in go.mod
# 2. Read handler entry points
# 3. Verify with git history ownership
```

FAIL: Confusing documentation with implementation reality
```python
# BAD: trusting README over source code
# README says "supports async" — check actual code

# GOOD: verify assumptions
# grep -r "async\|goroutine\|channel" ./services/
```

FAIL: Relying on intuition instead of statistical data
```python
# BAD: "I think services is the most complex module"
# no data to back it up

# GOOD: measure it
# gocyclo ./services/ && git log --numstat -- services/
```

## Claim Verification and Fact-Check

Applies when a research question demands factual verification, not codebase exploration (closes the "no general web research" gap, master catalog #102):

1. Extract claims: split the question into individual checkable claims
2. Gather evidence: collect at least two independent sources per claim
3. Structured verdicts: mark each claim VERIFIED, PARTIALLY VERIFIED, or UNVERIFIED
4. Transparent report: list every source with its access date and any conflict between sources

Rules:
- A claim stays UNVERIFIED when sources conflict or a source cannot be located
- Rank sources: primary documentation and vendor docs above aggregators
- Never fabricate a citation; an unverifiable claim is reported as UNVERIFIED, not silently dropped

## References

- Martin Fowler on technical debt quadrant: https://martinfowler.com/bliki/TechnicalDebtQuadrant.html (last_verified: 2026-05)
- Adam Tornhill's code analysis tools: https://codescene.com/ (last_verified: 2026-05)
- Google's research methods guide: https://research.google/pubs/ (last_verified: 2026-05)

- [references/analysis-tools.md](references/analysis-tools.md)
- [references/codebase-analysis.md](references/codebase-analysis.md)
- [references/triangulation.md](references/triangulation.md)

## Verification Checklist

- [ ] Research question defined explicitly before gathering data
- [ ] Findings triangulated across at least 3 independent sources
- [ ] Code behavior verified by reading actual source (not trusting docs/comments alone)
- [ ] Statistical evidence gathered (grep counts, git stats) — not intuition
- [ ] Circular dependencies and god packages identified in dependency map
- [ ] Hotspot analysis run: high churn + high complexity files identified
- [ ] Structured findings document produced with evidence and recommendations

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Conclusion contradicts actual code | Relied on documentation instead of reading source | Re-read the actual source files; doc is always secondary to code |
| Multiple false hotspots identified | Git log includes auto-generated or vendored files | Exclude generated code and vendor dirs from git log analysis |
| Dependency graph shows no circular deps | Static grep misses dynamic imports or runtime resolution | Use AST-level analysis tool (e.g., `go tool deps`) instead of grep for Go modules |
| Git log hotspot analysis skews toward recent commits (known issue: recency bias in git mining) | Recent history weighted equally with all-time history | Use time-windowed analysis (last 3 months, last year) instead of full git log; compare delta |
