# Compatibility & Rollout Rules

## Breaking Change Gate — CRITICAL

Renaming: resource / index / table / ARN / API path / column → STOP → warn explicitly → propose migration strategy → get user approval before applying.

## Schema Changes — Expand-Contract Pattern

```
1. Add new column (nullable or with default)
2. Backfill existing rows
3. Switch reads to new column
4. Remove old column (separate migration)
```

## API Changes

NEVER deploy breaking API change without versioning (/v2) or a deprecation window.

## Feature Flags

New behavior behind flag when rollout risk is non-zero.

## Canary / Dark Launch

Required for changes affecting >1% prod traffic or >1 service boundary.

## Data Migrations — MANDATORY

Always: reversible | idempotent | tested on a copy first.

## Pre-Commit Checklist — Golden Chain

Format → Lint → Type → Test → Security

Stop at first failure. NEVER claim done without running the full chain.
→ Full verification gate: `verification-before-completion` skill

## Dependency Policy

Pin exact versions in lockfiles.
Audit license + CVE before adding.
Upgrade one at a time + full test suite after each.
Vendored deps: include checksum/provenance.
Use stdlib or existing deps before adding new ones.
