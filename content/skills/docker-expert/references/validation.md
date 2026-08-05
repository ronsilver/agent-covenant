# Docker Validation & Linting

## Hadolint

Dockerfile linter that enforces best practices.

### Installation

```bash
# macOS
brew install hadolint

# Linux
wget https://github.com/hadolint/hadolint/releases/download/v2.12.0/hadolint-Linux-x86_64
chmod +x hadolint-Linux-x86_64
sudo mv hadolint-Linux-x86_64 /usr/local/bin/hadolint

# Docker
docker run --rm -i hadolint/hadolint < Dockerfile
```

### Usage

```bash
# Lint Dockerfile
hadolint Dockerfile

# Specific file
hadolint path/to/Dockerfile.prod

# Output formats
hadolint --format json Dockerfile
hadolint --format codeclimate Dockerfile
hadolint --format checkstyle Dockerfile
```

### Common Rules

| Rule ID | Issue | Example | Fix |
|---------|-------|---------|-----|
| **DL3000** | Invalid instruction | `FRON alpine` | Fix typo: `FROM alpine` |
| **DL3001** | Use JSON for ENTRYPOINT | `ENTRYPOINT node app.js` | `ENTRYPOINT ["node", "app.js"]` |
| **DL3002** | Last USER should not be root | `USER root` at end | Add `USER appuser` |
| **DL3006** | Always tag FROM | `FROM alpine` | `FROM alpine:3.19` |
| **DL3007** | Using latest tag | `FROM node:latest` | `FROM node:20-slim` |
| **DL3008** | Pin apt packages | `apt-get install curl` | `apt-get install curl=7.81.0-1` |
| **DL3009** | Delete apt lists | Missing cleanup | Add `rm -rf /var/lib/apt/lists/*` |
| **DL3013** | Pin pip packages | `pip install flask` | `pip install flask==3.0.0` |
| **DL3015** | Avoid apt-get upgrade | `apt-get upgrade` | Don't upgrade, update base image |
| **DL3018** | Pin apk packages | `apk add curl` | `apk add curl=8.5.0-r0` |
| **DL3020** | Use COPY not ADD | `ADD file.tar.gz /` | `COPY file.tar.gz /` (unless extracting) |
| **DL3025** | Use JSON for CMD | `CMD node app.js` | `CMD ["node", "app.js"]` |
| **DL3059** | Multiple FROM without aliases | Multiple `FROM` | Add `AS builder` aliases |
| **DL4006** | Set pipefail | `RUN cmd \| other` | `SHELL ["/bin/bash", "-o", "pipefail", "-c"]` |

### Ignore Rules

```dockerfile
# Inline ignore
# hadolint ignore=DL3018
RUN apk add --no-cache curl

# Global ignore (create .hadolint.yaml)
```

### Configuration (.hadolint.yaml)

```yaml
ignored:
  - DL3008  # Allow unpinned apt packages
  - DL3018  # Allow unpinned apk packages

trustedRegistries:
  - docker.io
  - gcr.io
  - quay.io

override:
  error:
    - DL3001  # Make this an error
  warning:
    - DL3042  # Make this a warning
  info:
    - DL3033  # Make this info
  style:
    - DL3015  # Make this style
```

### CI/CD Integration

```yaml
# GitHub Actions
- name: Lint Dockerfile
  run: hadolint Dockerfile

# GitLab CI
lint:dockerfile:
  image: hadolint/hadolint:latest-debian
  script:
    - hadolint Dockerfile

# Pre-commit hook
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint
```

## Trivy

Comprehensive vulnerability scanner.

### Installation

```bash
# macOS
brew install aquasecurity/trivy/trivy

# Linux
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
tar zxvf trivy_0.48.0_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/
```

### Scan Docker Image

```bash
# Basic scan
trivy image myapp:latest

# Only high/critical
trivy image --severity HIGH,CRITICAL myapp:latest

# Exit on vulnerabilities
trivy image --exit-code 1 --severity CRITICAL myapp:latest

# Output formats
trivy image --format json myapp:latest
trivy image --format sarif myapp:latest
trivy image --format template --template "@contrib/html.tpl" -o report.html myapp:latest
```

### Scan Dockerfile

```bash
# Scan Dockerfile for misconfigurations
trivy config Dockerfile

# With severity
trivy config --severity HIGH,CRITICAL Dockerfile
```

### Scan Filesystem

```bash
# Scan local directory
trivy fs .

# Scan for secrets
trivy fs --scanners secret .
```

### CI/CD Integration

```yaml
# GitHub Actions
- name: Run Trivy
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'

- name: Upload results
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

### Ignore Vulnerabilities

```yaml
# .trivyignore
# CVE-2023-12345  # Reason: False positive, not applicable
```

## Docker Scout

Built into Docker Desktop.

### Usage

```bash
# Scan image
docker scout cves myapp:latest

# Quick overview
docker scout quickview myapp:latest

# Recommendations
docker scout recommendations myapp:latest

# Compare images
docker scout compare --to myapp:old myapp:latest

# SBOM (Software Bill of Materials)
docker scout sbom myapp:latest
```

### CI/CD

```yaml
# GitHub Actions
- name: Docker Scout
  uses: docker/scout-action@v1
  with:
    command: cves
    image: myapp:latest
    exit-code: true
    only-severities: critical,high
```

## Dockle

Container image linter.

### Installation

```bash
# macOS
brew install goodwithtech/r/dockle

# Linux
wget https://github.com/goodwithtech/dockle/releases/download/v0.4.14/dockle_0.4.14_Linux-64bit.tar.gz
tar zxvf dockle_0.4.14_Linux-64bit.tar.gz
sudo mv dockle /usr/local/bin/
```

### Usage

```bash
# Scan image
dockle myapp:latest

# Ignore checks
dockle --ignore CIS-DI-0001 myapp:latest

# Exit on errors
dockle --exit-code 1 myapp:latest

# Output formats
dockle --format json myapp:latest
```

### Common Checks

- CIS-DI-0001: Create a user for the container
- CIS-DI-0005: Enable Content trust
- CIS-DI-0006: Add HEALTHCHECK
- CIS-DI-0008: Remove setuid/setgid permissions
- CIS-DI-0009: Use COPY instead of ADD
- CIS-DI-0010: NEVER store secrets

## dive

Analyze image layers and waste.

### Installation

```bash
# macOS
brew install dive

# Linux
wget https://github.com/wagoodman/dive/releases/download/v0.11.0/dive_0.11.0_linux_amd64.tar.gz
tar zxvf dive_0.11.0_linux_amd64.tar.gz
sudo mv dive /usr/local/bin/
```

### Usage

```bash
# Analyze image
dive myapp:latest

# CI mode (exit on wasted space)
CI=true dive myapp:latest
```

### Features

- **Layer view**: See what each layer adds
- **File changes**: Track file modifications
- **Wasted space**: Identify unnecessary files
- **Efficiency score**: Overall image efficiency

## Validation Workflow

### Complete Validation Pipeline

```bash
#!/bin/bash
set -e

IMAGE=$1

echo "1. Linting Dockerfile..."
hadolint Dockerfile

echo "2. Building image..."
docker build -t $IMAGE .

echo "3. Scanning for vulnerabilities..."
trivy image --severity HIGH,CRITICAL --exit-code 1 $IMAGE

echo "4. Linting container image..."
dockle --exit-code 1 $IMAGE

echo "5. Analyzing layers..."
dive --ci $IMAGE

echo "PASS: All validations passed!"
```

### Pre-commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/hadolint/hadolint
    rev: v2.12.0
    hooks:
      - id: hadolint
        args: [--ignore, DL3008]
  
  - repo: local
    hooks:
      - id: trivy-config
        name: Trivy Config Scan
        entry: trivy config
        language: system
        files: Dockerfile
        pass_filenames: true
```

## CI/CD Complete Example

```yaml
# .github/workflows/docker.yml
name: Docker Build & Scan

on: [push]

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Lint Dockerfile
        run: |
          docker run --rm -i hadolint/hadolint < Dockerfile
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Trivy scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          exit-code: 1
          severity: CRITICAL,HIGH
      
      - name: Dockle scan
        run: |
          wget https://github.com/goodwithtech/dockle/releases/download/v0.4.14/dockle_0.4.14_Linux-64bit.tar.gz
          tar zxvf dockle_0.4.14_Linux-64bit.tar.gz
          sudo mv dockle /usr/local/bin/
          dockle --exit-code 1 myapp:${{ github.sha }}
```

## Best Practices

1. **Lint before build** - Catch issues early with hadolint
2. **Scan after build** - Check for vulnerabilities with Trivy
3. **Automate in CI/CD** - Fail builds on issues
4. **Update regularly** - Keep scanners up to date
5. **Fix, don't ignore** - Address root causes
6. **Monitor continuously** - Scan production images
7. **Document exceptions** - When ignoring rules, document why

## Quick Reference

| Tool | Purpose | Command |
|------|---------|---------|
| **hadolint** | Lint Dockerfile | `hadolint Dockerfile` |
| **trivy** | Vulnerability scan | `trivy image myapp:latest` |
| **docker scout** | Built-in scanner | `docker scout cves myapp:latest` |
| **dockle** | Image linting | `dockle myapp:latest` |
| **dive** | Layer analysis | `dive myapp:latest` |
