# Branch Protection Rules

## Required Settings
- Require PR before merging: 1+ approval
- Dismiss stale reviews on new commits
- Require CODEOWNERS review
- Require status checks: lint, test, build, security
- Require conversation resolution
- Require signed commits
- Block force pushes
- Block deletions
- Include administrators

## CODEOWNERS Syntax
```
* @platform-team
/content/skills/ @ai-engineering
/terraform/ @devops
*.md @docs-team
# Last match wins
```

## Rulesets (org-level)
- Apply to all repos
- Restrict creation/deletion
- Require workflows as code
