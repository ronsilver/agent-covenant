# GitHub Actions Reusable Workflows

## Caller
```yaml
jobs:
  ci:
    uses: example-org/.github/.github/workflows/go-ci.yml@main
    with:
      go_version: "1.23"
      docker_tag: ${{ github.sha }}
    secrets: inherit
```

## Callee (Reusable)
```yaml
name: Go CI
on:
  workflow_call:
    inputs:
      go_version:
        required: true
        type: string
      docker_tag:
        required: false
        type: string
    secrets:
      AWS_ROLE:
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@sha256_pin
      - uses: actions/setup-go@sha256_pin
        with: { go-version: "${{ inputs.go_version }}" }
      - run: go test -race ./...
```

## Composite Actions
```yaml
# .github/actions/deploy-ecs/action.yml
name: Deploy to ECS
inputs:
  cluster:
    required: true
  service:
    required: true
runs:
  using: composite
  steps:
    - uses: aws-actions/configure-aws-credentials@v4
      with: { role-to-assume: "${{ inputs.role }}" }
    - run: |
        aws ecs update-service           --cluster "${{ inputs.cluster }}"           --service "${{ inputs.service }}"           --force-new-deployment
      shell: bash
```

## Deployment Patterns
| Pattern | Use |
|---|---|
| Branch deploy (main -> prod) | Simple services |
| Environment-based (dev/staging/prod) | Multi-env pipelines |
| Matrix deploy (multi-region) | Global services |
| Canary (gradual rollout) | High-risk changes |

## Caching
```yaml
- uses: actions/cache@v4
  with:
    path: ~/go/pkg/mod
    key: go-${{ runner.os }}-${{ hashFiles('go.sum') }}
    restore-keys: go-${{ runner.os }}-
```
Cache key must include hash of dependency file. restore-keys finds partial matches.
