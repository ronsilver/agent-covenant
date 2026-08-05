# Code Review Metrics & KPIs

## Process Metrics
| Metric | Target | Why |
|---|---|---|
| Time to first review | <4 hours | Prevents context switching cost |
| Review turnaround | <24 hours | Keeps velocity high |
| PR size | <400 LOC | Optimal for thorough review |
| Review depth (comments/LOC) | 0.5-1.5 | Enough feedback, not excessive |
| Defect escape rate | <5% | Bugs found after merge |

## Quality Signals
### What to Measure
- [ ] Test coverage for changed code (did it increase?)
- [ ] Number of review iterations (1-2 is healthy, >5 = unclear requirements)
- [ ] Types of comments (logic vs. style — excessive style = missing linters)
- [ ] Review approval time patterns (Friday afternoon reviews are lower quality)

### NEVER Measure
- Number of comments as performance metric (leads to nit-picking)
- Review speed as primary metric (fast reviews miss more bugs)
- Individual reviewer "defect found" count (incentivizes quantity over quality)

## Automated Gates (Pre-Review)
```
1. Linting passes (no style comments needed)
2. Tests pass (no broken functionality)
3. Security scan passes (no known CVEs introduced)
4. Coverage does not decrease
5. PR is <400 LOC
```
If any gate fails, fix BEFORE requesting human review.

## Review Checklist (per PR)
- [ ] Does this change need a feature flag?
- [ ] Are there database migrations? (is rollback defined?)
- [ ] Are external API contracts changed? (is version bumped?)
- [ ] Are new dependencies added? (is CVE scan clean?)
- [ ] Is observability added for new endpoints/services?
- [ ] Is documentation updated? (README, CHANGELOG, ADRs)
