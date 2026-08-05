# Matrix Build Strategies

## Multi-Platform
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
    go_version: ["1.22", "1.23"]
    exclude:
      - os: macos-latest
        go_version: "1.22"  # skip this combo
```

## Multi-Environment
```yaml
strategy:
  matrix:
    environment: [staging, production]
steps:
  - name: Deploy to ${{ matrix.environment }}
    run: ./deploy.sh --env "${{ matrix.environment }}"
```

## Sharding (Parallel E2E)
```yaml
strategy:
  matrix:
    shard: [1, 2, 3, 4]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/${{ strategy.job-total }}
```

## Performance
- max-parallel: limit concurrent matrix jobs (default: 256)
- fail-fast: false -> don't cancel other jobs on first failure
- include: add custom combinations beyond matrix

## Secrets in Matrix
```yaml
strategy:
  matrix:
    environment: [staging, production]
steps:
  - env:
      DB_URL: ${{ matrix.environment == 'production' && secrets.PROD_DB_URL || secrets.STAGING_DB_URL }}
```
