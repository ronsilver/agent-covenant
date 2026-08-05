# GitHub Actions Security Hardening

## Hardening Checklist

| Risk | Fix |
|---|---|
| Actions pinned to branch/tag | Pin to full-length commit SHA (`v4` -> `11bd71901bbe5b1630ceea73d27597364c9af683`) |
| GITHUB_TOKEN with write-all | Set explicit minimal `permissions:` block |
| Script injection via `${{ }}` in `run:` | Use intermediate env vars, never `${{ github.event }}` in shell |
| Secrets leaked in logs | Use `::add-mask::` for dynamic secrets |
| Unpinned dependencies | Use `actions/cache@v4` + hash-based keys |

## Example: Secure Workflow

```yaml
name: Deploy
on:
  push:
    branches: [main]

permissions:
  contents: read
  id-token: write
  packages: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: aws-actions/configure-aws-credentials@ececac1a... # exact SHA
        with:
          role-to-assume: arn:aws:iam::123:role/github-actions-deploy
          aws-region: us-east-1
      - run: |
          aws ecs update-service --cluster example-prod --service fulfillment --force-new-deployment
        env:
          CLUSTER: ${{ vars.CLUSTER_NAME }}  # use vars, not secrets, for non-sensitive
```

## OIDC for AWS (zero long-lived secrets)

1. Create IAM OIDC provider for `https://token.actions.githubusercontent.com`
2. Create IAM role with trust policy allowing `repo:example-org/*`
3. Use `aws-actions/configure-aws-credentials@v4` with `role-to-assume`
4. No AWS access keys stored anywhere

## Caching Strategies

```yaml
# Go modules
- uses: actions/cache@v4
  with: { path: ~/go/pkg/mod, key: go-${{ hashFiles('go.sum') }} }

# Docker layer cache (GitHub Actions Cache backend)
- uses: docker/build-push-action@v6
  with: { cache-from: type=gha, cache-to: type=gha,mode=max }
```
