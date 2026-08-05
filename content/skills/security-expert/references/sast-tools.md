# SAST Tools by Language

| Language | Tool | Command |
|---|---|---|
| Go | gosec | `gosec ./...` |
| Python | bandit | `bandit -r src/` |
| JavaScript | ESLint security | `eslint --rule 'no-eval:error'` |
| Java | SpotBugs | `mvn spotbugs:check` |
| Terraform | checkov | `checkov -d .` |
| Docker | trivy | `trivy image orders:latest` |

## Secret Scanning
```bash
gitleaks detect --source . --verbose
trufflehog filesystem .
```
- Check current state AND git history
- Rotate all exposed secrets immediately
- Add pre-commit hook to block future leaks

## OWASP Top 10 Automation
| Check | Tool |
|---|---|
| A03 Injection | SQLMap (DAST), CodeQL (SAST) |
| A06 Vuln Components | trivy, npm audit, OWASP Dependency Check |
| A01 Access Control | Manual review + authorization tests |
