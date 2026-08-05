---
name: github-expert
description: "Advanced GitHub repository management: branch protection rules, CODEOWNERS, rulesets, semantic releases with changelog automation, Dependabot and secret scanning, CodeQL for code scanning, OpenSSF Scorecards, dependency graph, and issue/PR templates. Use when configuring repository settings, branch protection rules, CODEOWNERS, dependabot, or GitHub security features. Trigger: branch protection, CODEOWNERS, dependabot config, CodeQL, secret scanning, OpenSSF Scorecard, release-please. Do NOT trigger for: writing GitHub Actions workflows, general CI/CD pipeline design."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---
# GitHub Expert

**Repository management: branch protection, security, releases and compliance.**

## Core Stack

- Protection: Branch rules, rulesets (org-level), required status checks
- Ownership: CODEOWNERS with path patterns and precedence rules
- Releases: semantic-release, release-please, changelog automation
- Security: Dependabot alerts/updates, secret scanning, CodeQL, dependency review
- Compliance: OpenSSF Scorecards, dependency graph, advisory database

## Branch Protection

```yaml
# Required checks for main branch
branch: main
rules:
  - require_pull_request:
      required_approving_review_count: 1          # >=1 approval
      dismiss_stale_reviews: true
      require_code_owner_review: true
  - require_status_checks:
      strict: true                                # must be up-to-date with base
      contexts: [lint, test, build, security-scan]
  - require_signed_commits: true
  - require_conversation_resolution: true
  - block_force_pushes: true
  - block_deletions: true
```

## CODEOWNERS

```
# Path-based ownership with precedence (last match wins)
*                    @org/platform-team
/content/skills/     @org/ai-engineering
/terraform/          @org/devops
/api/                @org/api-team
*.md                 @org/docs-team
```

## Security Automation

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "gomod"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    labels: [dependencies, security]
    
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
```

## Semantic Releases

```yaml
# release-please workflow
name: Release
on:
  push:
    branches: [main]
jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          release-type: go
          package-name: example-api
```

## Supply Chain — OpenSSF Scorecard

```yaml
name: Scorecard
on:
  branch_protection_rule:
  schedule: [{ cron: "0 0 * * 0" }]  # weekly
jobs:
  scorecard:
    runs-on: ubuntu-latest
    steps:
      - uses: ossf/scorecard-action@v2
      - uses: actions/upload-artifact@v4
        with:
          name: scorecard-results
          path: results.sarif
```

## Constraints

- NEVER allow force pushes on shared branches (main, release/*)
- NEVER require <1 review approval for protected branches
- NEVER merge Dependabot PRs without reviewing changelog for breaking changes
- ALWAYS pin actions to full-length commit SHA (never branch/tag)
- ALWAYS set minimum `GITHUB_TOKEN` permissions in workflows
- NEVER store plaintext secrets in repository settings (use environments + OIDC)

## Overview

GitHub repository management combining branch protection, security automation, and supply chain compliance. Covers Dependabot, CodeQL, secret scanning, OpenSSF Scorecards, semantic releases, and CODEOWNERS-based review enforcement.

## Quick Reference

| Feature | Purpose | Configuration |
|---------|---------|---------------|
| Branch Protection | Enforce review/status checks before merge | `require_pull_request` + `require_status_checks` |
| CODEOWNERS | Path-based code review assignment | `.github/CODEOWNERS` — last match wins |
| Dependabot | Automated dependency updates | `.github/dependabot.yml` per ecosystem |
| CodeQL | Static analysis for security vulns | `github/codeql-action` — weekly or per push |
| Secret Scanning | Detect leaked credentials in repos | Built-in alert + push protection |
| Release Please | Automated semantic releases | `googleapis/release-please-action` |
| Scorecards | Supply chain security scoring | `ossf/scorecard-action` — weekly scan |

## Workflow

1. Create repository with branch protection rules: require PR reviews, status checks, signed commits, and conversation resolution
2. Configure CODEOWNERS for path-based ownership — `*` falls back to platform team, specific paths to specialized teams
3. Enable security: Dependabot (weekly, per ecosystem), CodeQL (push + schedule), secret scanning (push protection)
4. Set up semantic releases with release-please on main branch pushes
5. Configure OpenSSF Scorecard for weekly supply chain audit
6. Audit monthly: review Dependabot PRs, Scorecard results, and permission hygiene

## Anti-patterns

FAIL: Allowing direct pushes to main
```yaml
# BAD
# No branch protection — anyone can push to main
```
PASS: Require PRs with approval
```yaml
# GOOD
rules:
  - require_pull_request:
      required_approving_review_count: 1
      dismiss_stale_reviews: true
      require_code_owner_review: true
```

FAIL: Pinning actions to branch/tag names
```yaml
# BAD
uses: actions/checkout@main
```
PASS: Pin to full commit SHA
```yaml
# GOOD
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

FAIL: Using GITHUB_TOKEN with full permissions
```yaml
# BAD
permissions: write-all
```
PASS: Set minimum required permissions
```yaml
# GOOD
permissions:
  contents: read
  pull-requests: write
  issues: write
```

FAIL: Merging Dependabot PRs without review
```
# BAD — auto-merge dependabot PRs without checking changelog
```
PASS: Review breaking changes before merge
```
# GOOD — check release notes for breaking changes, run full test suite
```

## References

- [GitHub Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches) · last_verified: 2026-05-25
- [OpenSSF Scorecard](https://scorecard.dev/) · last_verified: 2026-05-25
- [Semantic Release — Release Please](https://github.com/googleapis/release-please) · last_verified: 2026-05-25

- [references/branch-protection.md](references/branch-protection.md)
- [references/release-automation.md](references/release-automation.md)
- [references/supply-chain.md](references/supply-chain.md)

## Verification Checklist

- [ ] Branch protection rules enforce required PR reviews and status checks on main
- [ ] CODEOWNERS file defines path-based ownership with correct team references
- [ ] Dependabot configured per ecosystem with weekly schedule and label
- [ ] Secret scanning and push protection enabled on the repository
- [ ] Release-please action configured for automated semantic releases
- [ ] OpenSSF Scorecard runs weekly with SARIF upload

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Dependabot not creating PRs | Ecosystem or schedule misconfigured in dependabot.yml | Verify `package-ecosystem` and `directory` match the project |
| Release-please not tagging | Missing conventional commit format in PR titles | Ensure PR titles follow `feat:`, `fix:`, `chore:` conventions |
| Branch protection bypassed | Admin override or ruleset not applied to all roles | Review branch protection settings; ensure `Include administrators` is checked |
| Known issue: Dependabot ignores .npmrc private registries | Dependabot uses its own auth scope and may not read local config | Configure `registries` in dependabot.yml with explicit token and scope |

| [WARN] CODEOWNERS file does not prevent admin bypass | CODEOWNERS is advisory; branch protection with "Require review from Code Owners" not enabled | Enable "Require review from Code Owners" in branch protection rules, not just CODEOWNERS file |
| Rulesets applied at org level silently override repo-level branch protection | Org rulesets take precedence; repo settings appear valid but org ruleset blocks operation | Check org-level rulesets before modifying repo protection; org rulesets override repo settings |
| Gotcha: dependabot.yml changes only take effect after merge to default branch | Dependabot reads config from default branch; changes on feature branches are ignored | Merge dependabot.yml changes to default branch first; use branches qualifier to test |
