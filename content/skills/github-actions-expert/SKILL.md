---
name: github-actions-expert
description: "CI/CD pipeline construction with GitHub Actions: event-driven YAML workflows (push, PR, schedule, workflow_dispatch), build matrices, secrets management with OIDC for AWS, reusable workflows, composite actions, security hardening (pin actions to SHA, principle of least privilege for GITHUB_TOKEN), dependency caching, and artifact signing. Use when setting up CI/CD pipelines, configuring GitHub Actions workflows, managing OIDC secrets, or building reusable actions. Trigger: CI/CD pipeline, OIDC AWS, reusable workflow, composite action, dependency caching, artifact signing. Do NOT trigger for: general Kubernetes troubleshooting, database migration scripts, branch protection configuration, dependabot setup, CodeQL configuration (use github-expert)."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---
# GitHub Actions Expert

**CI/CD pipelines: workflows, OIDC, security hardening and reusable actions.**

## Core Stack

- Workflows: Event-driven (push, PR, schedule, workflow_dispatch, workflow_call)
- Security: OIDC for AWS, minimum GITHUB_TOKEN permissions, pin actions to SHA
- Reuse: Reusable workflows (workflow_call), composite actions
- Performance: Dependency caching, matrix builds, concurrency control
- Platform: All repos use GitHub Actions for build, test, deploy

## Workflow Anatomy

```yaml
name: Build & Deploy
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write       # OIDC for AWS — minimum needed

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        go-version: ["1.22", "1.23"]
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4 SHA
      - uses: actions/setup-go@0aaccfd150d50ccaeb58ebd88d36e91967a5f35b  # v5 SHA
        with: { go-version: ${{ matrix.go-version } }
      - uses: actions/cache@v4
        with:
          path: ~/go/pkg/mod
          key: go-${{ hashFiles('go.sum') }}
      - run: go test -race -cover ./...
      - run: golangci-lint run
```

## OIDC for AWS (no long-lived secrets)

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions-deploy
    aws-region: us-east-1

- name: Deploy to ECS
  run: |
    aws ecs update-service \
      --cluster example-prod \
      --service fulfillment \
      --force-new-deployment
```

## Reusable Workflows

```yaml
# .github/workflows/go-ci.yml (reusable)
name: Go CI
on:
  workflow_call:
    inputs:
      go-version:
        required: false
        type: string
        default: "1.23"

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
      - uses: actions/setup-go@0aaccfd150d50ccaeb58ebd88d36e91967a5f35b
        with: { go-version: ${{ inputs.go-version }} }
      - run: go test ./...
```

```yaml
# Consumer repo
jobs:
  call-ci:
    uses: example-org/.github/.github/workflows/go-ci.yml@main
    with: { go-version: "1.23" }
```

## Security Hardening

| Issue | Fix |
|---|---|
| Actions pinned to branch/tag | Pin to full-length commit SHA |
| GITHUB_TOKEN with write-all | Set minimum `permissions:` block |
| Script injection via user input | Use intermediate env vars, never `${{ github.event }}` in shell |
| Secrets in logs | Use `::add-mask::` for dynamic secrets |

```yaml
# UNSAFE
- run: echo "${{ github.event.issue.title }}"    # script injection risk

# SAFE
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
```

## Caching

```yaml
# Go modules
- uses: actions/cache@v4
  with:
    path: ~/go/pkg/mod
    key: go-${{ runner.os }}-${{ hashFiles('go.sum') }}

# Docker layers
- uses: docker/build-push-action@v6
  with:
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

## Artifact Signing (Sigstore)

Sign release artifacts so consumers can verify provenance and integrity.

```yaml
# .github/workflows/release.yml
- uses: sigstore/cosign-installer@v3
- name: Sign container image with keyless signing
  run: |
    cosign sign --yes ghcr.io/example/app:${{ github.sha }}

- name: Verify signature before deploy
  run: |
    cosign verify ghcr.io/example/app:${{ github.sha }} \
      --certificate-identity-regexp "https://github.com/example/.github/.github/workflows/release.yml@refs/heads/main"
```

- Use keyless signing: OIDC identity from GitHub Actions, no long-lived signing keys
- Attach provenance: publish an SBOM and SLSA provenance alongside the release
- Always `cosign verify` in the deploy job before rollout

## Constraints

- NEVER use `secrets.GITHUB_TOKEN` in forked repo PRs (read-only, no write access)
- NEVER store AWS credentials as long-lived secrets (use OIDC)
- NEVER use `${{ github.event }}` directly in shell commands (injection risk)
- ALWAYS pin third-party actions to full-length commit SHA
- ALWAYS set explicit `permissions:` block with minimum needed
- ALWAYS use concurrency groups to cancel redundant CI runs
- NEVER hardcode secrets in workflow files (even commented out)

## Overview

Build CI/CD pipelines with GitHub Actions: event-driven workflows (push, PR, schedule, workflow_dispatch), matrix builds, OIDC for AWS, reusable workflows, composite actions, security hardening (pin actions to SHA, least privilege GITHUB_TOKEN), dependency caching, and artifact signing.

## Quick Reference

| Feature | Best Practice | Security Note |
|---|---|---|
| Actions pinning | Full-length commit SHA | Prevents supply chain attacks |
| AWS auth | OIDC (no long-lived keys) | Uses STS AssumeRole |
| GITHUB_TOKEN | Explicit min permissions block | Never use write-all default |
| Matrix builds | Parallel across Go/Python versions | Fast feedback, broader coverage |
| Caching | hashFiles for cache key | Avoids stale cache hits |

## Workflow

1. Define trigger events and concurrency group to cancel duplicates
2. Set explicit permissions block with minimum needed scope
3. Pin all third-party actions to full-length commit SHA
4. Configure OIDC for AWS access (no long-lived secrets)
5. Add matrix strategy for multi-version testing
6. Set up dependency caching and artifact signing for releases

## Anti-patterns

FAIL: Pinning actions to branches or version tags
```yaml
# BAD: mutable reference — can be replaced silently
- uses: actions/checkout@v4

# GOOD: immutable SHA reference
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
```

FAIL: Direct shell interpolation of event data
```yaml
# BAD: script injection risk
- run: echo "${{ github.event.issue.title }}"

# GOOD: intermediate env var
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
```

FAIL: Using default GITHUB_TOKEN with write-all permissions
```yaml
# BAD: overly permissive default token
# (no permissions block — defaults to write-all)

# GOOD: explicit minimum permissions
permissions:
  contents: read
  id-token: write
  pull-requests: write  # only if needed
```

## References

- GitHub Actions documentation: https://docs.github.com/en/actions (last_verified: 2026-05-25)
- Security hardening guide: https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions (last_verified: 2026-05-25)
- OIDC with AWS: https://docs.github.com/en/actions/security-for-github-actions/deploying-with-openid-connect (last_verified: 2026-05-25)

- [references/matrix-strategies.md](references/matrix-strategies.md)
- [references/reusable-workflows.md](references/reusable-workflows.md)
- [references/security-hardening.md](references/security-hardening.md)

## Verification Checklist

- [ ] All third-party actions pinned to full-length commit SHA (not tags/branches)
- [ ] GITHUB_TOKEN permissions explicitly set to minimum required scope
- [ ] OIDC configured for AWS access (no long-lived secrets)
- [ ] Concurrency group set to cancel redundant runs
- [ ] Dependency caching configured with correct hash-based keys
- [ ] Artifact signing enabled for release builds

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Error: Credentials could not be loaded` | OIDC role ARN missing or misconfigured | Verify `role-to-assume` ARN and trust policy in AWS |
| Workflow not triggering on push | Branch filter mismatch | Check `on.push.branches` matches the branch name exactly |
| `Resource not accessible by integration` | GITHUB_TOKEN permissions insufficient | Add required permission to `permissions:` block (e.g., `contents: write`) |
| Known issue: reusable workflow secrets not inherited | Caller workflow secrets not passed to `workflow_call` target | Pass secrets explicitly with `secrets: inherit` or list each secret by name in the caller |

| [WARN] `OIDC` token expires mid-workflow for multi-hour jobs | Default token lifetime (1 hour) insufficient for long matrix builds | Split into smaller jobs; use `workflow_dispatch` event to resume; request longer token TTL in AWS |
| actions/cache restore hits on stale cache with wrong dependencies | Cache key based on hashFiles but lockfile not regenerated when deps change in package.json | Use hashFiles of lockfile in cache key; invalidate with restore-keys fallback |
| Gotcha: OIDC token fails when workflow runs from fork PR | GitHub Actions restricts OIDC tokens for pull requests from forked repos by default | Set id-token: write explicitly; use pull_request_target event instead of pull_request |
