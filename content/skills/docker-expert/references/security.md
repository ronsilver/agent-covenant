# Docker Security Best Practices

## Non-Root User (MANDATORY)

Running as root inside containers is a critical security risk.

### Alpine Linux

```dockerfile
FROM alpine:3.19

# Create user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Switch to non-root
USER appuser

WORKDIR /app
COPY --chown=appuser:appgroup . .

CMD ["./app"]
```

### Debian/Ubuntu (slim images)

```dockerfile
FROM python:3.12-slim

# Create user and group
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# Switch to non-root
USER appuser

WORKDIR /app
COPY --chown=appuser:appgroup . .

CMD ["python", "app.py"]
```

### With Specific UID/GID

```dockerfile
FROM node:20-slim

# Create user with specific UID/GID (for volume permissions)
RUN groupadd -g 1000 appgroup && \
    useradd -u 1000 -g appgroup -s /bin/sh appuser

USER appuser
```

### Distroless (Already Non-Root)

```dockerfile
# Distroless images use user 'nonroot' (UID 65532)
FROM gcr.io/distroless/static-debian12:nonroot

# Already running as non-root, no need to create user
COPY --chown=nonroot:nonroot app /app
ENTRYPOINT ["/app"]
```

## Secrets Management

### FAIL: NEVER Do This

```dockerfile
# FAIL: Hardcoded secret
ENV API_KEY=sk-abc123def456

# FAIL: Copy .env file
COPY .env /app/.env

# FAIL: ARG secrets (visible in docker history!)
ARG DATABASE_PASSWORD
ENV DB_PASS=$DATABASE_PASSWORD
```

**Why dangerous**: Secrets baked into image, visible in layers

### PASS: Pass at Runtime

```dockerfile
# No secrets in Dockerfile
ENV API_KEY_FILE=/run/secrets/api_key

# Read from file at runtime
CMD ["sh", "-c", "export API_KEY=$(cat $API_KEY_FILE) && ./app"]
```

```bash
# Pass via environment variable
docker run -e API_KEY=$API_KEY myapp

# Pass via file (Docker secrets)
echo "sk-abc123" | docker secret create api_key -
docker service create --secret api_key myapp
```

### Docker Compose Secrets

```yaml
version: '3.8'
services:
  app:
    image: myapp
    secrets:
      - db_password
      - api_key
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password
      API_KEY_FILE: /run/secrets/api_key

secrets:
  db_password:
    file: ./secrets/db_password.txt
  api_key:
    file: ./secrets/api_key.txt
```

### BuildKit Secret Mounts

```dockerfile
# syntax=docker/dockerfile:1

FROM alpine

# Secret only available during build, not in final image
RUN --mount=type=secret,id=github_token \
    git clone https://$(cat /run/secrets/github_token)@github.com/private/repo.git
```

```bash
# Build with secret
docker build --secret id=github_token,src=$HOME/.github_token .
```

## Read-Only Root Filesystem

```dockerfile
# Make filesystem read-only
RUN chmod -R a-w /app
```

```bash
# Run with read-only root
docker run --read-only --tmpfs /tmp myapp
```

```yaml
# docker-compose.yml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

**Benefits**: Prevents malware from writing files

## Drop Capabilities

```bash
# Drop all capabilities, add only what's needed
docker run --cap-drop=ALL --cap-add=NET_BIND_SERVICE myapp
```

```yaml
# docker-compose.yml
services:
  app:
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE  # Only if binding to ports <1024
```

## Security Context

```bash
# Full security hardening
docker run \
  --read-only \
  --tmpfs /tmp \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  --user 1000:1000 \
  myapp
```

## Scan for Vulnerabilities

### Trivy

```bash
# Install
brew install aquasecurity/trivy/trivy

# Scan image
trivy image myapp:latest

# Only high/critical
trivy image --severity HIGH,CRITICAL myapp:latest

# Scan Dockerfile
trivy config Dockerfile

# CI/CD integration
trivy image --exit-code 1 --severity CRITICAL myapp:latest
```

### Docker Scout

```bash
# Scan with Docker Scout
docker scout cves myapp:latest

# Recommendations
docker scout recommendations myapp:latest

# Compare with another image
docker scout compare --to myapp:old myapp:latest
```

### Snyk

```bash
# Install
npm install -g snyk

# Scan
snyk container test myapp:latest

# Monitor in Snyk dashboard
snyk container monitor myapp:latest
```

## Minimal Attack Surface

### Use Minimal Base Images

```dockerfile
# FAIL: Full image - large attack surface
FROM python:3.12  # 1GB, includes many tools

# PASS: Slim image
FROM python:3.12-slim  # 150MB, minimal tools

# PASS:PASS: Distroless - smallest attack surface
FROM gcr.io/distroless/python3-debian12:nonroot  # No shell!
```

### Remove Unnecessary Packages

```dockerfile
FROM ubuntu:22.04

# Install only what's needed, clean up
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl && \
    rm -rf /var/lib/apt/lists/*
```

## Network Security

### Disable Inter-Container Communication

```bash
docker network create --driver bridge --opt com.docker.network.bridge.enable_icc=false mynetwork
```

```yaml
# docker-compose.yml
networks:
  app_network:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.enable_icc: "false"
```

### Use Internal Networks

```yaml
services:
  frontend:
    networks:
      - public
      - backend

  api:
    networks:
      - backend
      - db

  database:
    networks:
      - db  # Not exposed to public

networks:
  public:
  backend:
    internal: true  # No external access
  db:
    internal: true
```

## Resource Limits

```bash
# Prevent resource exhaustion
docker run \
  --memory=512m \
  --memory-swap=512m \
  --cpus=1.0 \
  --pids-limit=100 \
  myapp
```

```yaml
# docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
    pids_limit: 100
```

## Content Trust

Enable Docker Content Trust to verify image signatures:

```bash
export DOCKER_CONTENT_TRUST=1

# Only pull/run signed images
docker pull myapp:latest
```

## AppArmor/SELinux

```bash
# AppArmor profile
docker run --security-opt apparmor=docker-default myapp

# SELinux label
docker run --security-opt label=level:s0:c100,c200 myapp
```

## Health Checks

```dockerfile
# HTTP health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# TCP health check (no curl in distroless)
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD ["/healthcheck-binary"]

# Shell-less health check
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD ["/bin/grpc_health_probe", "-addr=:50051"]
```

## Logging

```dockerfile
# NEVER log to files inside container
# Use stdout/stderr instead
CMD ["python", "-u", "app.py"]  # -u for unbuffered output
```

```bash
# View logs
docker logs myapp

# Forward to logging driver
docker run --log-driver=syslog myapp
docker run --log-driver=fluentd myapp
```

## .dockerignore

```dockerignore
# Secrets (NEVER include)
.env
.env.*
*.pem
*.key
*.p12
secrets/
credentials/
id_rsa*
*.crt

# Sensitive files
.aws/
.ssh/
.docker/
.kube/

# Git
.git
.gitignore

# Dependencies (rebuild in container)
node_modules/
venv/
__pycache__/

# Build artifacts
dist/
build/
target/
*.egg-info/

# IDE
.idea/
.vscode/
*.swp
.DS_Store
```

## Security Scanning in CI/CD

### GitHub Actions

```yaml
name: Security Scan

on: [push]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t myapp:${{ github.sha }} .
      
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
```

## Security Checklist

- [ ] Running as non-root user
- [ ] No secrets in Dockerfile or image
- [ ] Base image pinned to specific version
- [ ] Scanned with Trivy/Snyk (no HIGH/CRITICAL)
- [ ] Multi-stage build (minimal runtime)
- [ ] Read-only root filesystem
- [ ] Capabilities dropped (--cap-drop=ALL)
- [ ] Resource limits set
- [ ] Health check defined
- [ ] .dockerignore excludes secrets
- [ ] Minimal base image (slim/distroless)
- [ ] Security context configured

## Common Vulnerabilities

### CVE in Base Image

```bash
# Check vulnerabilities
trivy image python:3.12-slim

# Update to newer patch
FROM python:3.12.2-slim  # Fix: update patch version
```

### Outdated Dependencies

```dockerfile
# FAIL: Outdated packages
RUN apt-get update && apt-get install -y curl

# PASS: Update and upgrade
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
```

## Security Tools Comparison

| Tool | Purpose | Best For |
|------|---------|----------|
| **Trivy** | Vulnerability scanning | CI/CD, comprehensive |
| **Docker Scout** | Vulnerability + recommendations | Docker Desktop users |
| **Snyk** | Vulnerability + monitoring | Enterprise |
| **Hadolint** | Dockerfile linting | Best practices |
| **Dockle** | Image linting | Security checks |

## References

- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
