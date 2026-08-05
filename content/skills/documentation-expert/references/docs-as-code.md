# Docs-as-Code Patterns

## Principles
1. Documentation lives in the same repo as code
2. Documentation is versioned alongside code
3. Documentation changes go through same review process
4. Documentation is built and published via CI/CD

## Repository Structure
```
docs/
  README.md                # project overview
  architecture/
    ADR-001-shipment-flow.md
  api/
    openapi.yaml           # OpenAPI spec
    examples/              # request/response examples
  guides/
    getting-started.md
    deployment.md
    troubleshooting.md
  runbooks/
    alert-shipment-errors.md
CHANGELOG.md               # root level
```

## Keep a Changelog Format
```markdown
# Changelog
## [1.2.0] - 2026-05-16
### Added
- cash-on-delivery shipment support
### Changed
- Upgraded Go to 1.23
### Fixed
- Race condition in shipment reservation
```

## Validation Pipeline
```yaml
- name: Validate Docs
  run: |
    markdownlint docs/**/*.md
    spectral lint docs/api/openapi.yaml
    lychee docs/
```

## NEVER
- Write docs in a wiki separate from code (drift inevitable)
- Copy-paste documentation between repos
- Write docs after implementation is forgotten
