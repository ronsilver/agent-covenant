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

## OWASP Top 10 (2025) Automation
| Check | Tool |
|---|---|
| A03 Software Supply Chain Failures | trivy, syft, OWASP Dependency Check |
| A05 Injection | SQLMap (DAST), CodeQL (SAST) |
| A01 Broken Access Control | Manual review + authorization tests |
| A10 Mishandling of Exceptional Conditions | Error-pathing review + fail-secure tests |

## Supply Chain and SBOM Tooling
| Tool | Purpose | Command |
|---|---|---|
| CVE Lite CLI | Lightweight CVE lookup for the local SBOM | `cve-lite-cli --sbom sbom.json --format table` |
| Syft | SBOM generation | `syft orders:latest -o spdx-json > sbom.json` |
| cosign | Artifact signing and verification | `cosign sign --key cosign.key orders:latest` |
| OWASP Dependency-Check | Dependency vulnerability analysis | `dependency-check --scan . --format JSON` |
| CycloneDX (ECMA-424) | SBOM interchange standard consumed by Dependency-Track | `https://cyclonedx.org` |
