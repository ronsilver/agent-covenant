# Supply Chain Security

## Dependabot
```yaml
version: 2
updates:
  - package-ecosystem: gomod
    directory: /
    schedule: { interval: weekly }
    open-pull-requests-limit: 5
```

## OpenSSF Scorecard
```yaml
- uses: ossf/scorecard-action@v2
  with:
    results_file: results.sarif
```

## Secret Scanning
- Enable push protection
- Custom patterns for API key format
- Alert on exposure

## CodeQL
```yaml
- uses: github/codeql-action/init@v3
  with:
    languages: go, python, javascript
```
