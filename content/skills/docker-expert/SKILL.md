---
name: docker-expert
description: "Build secure, optimized Docker images and compose setups. Use when creating Dockerfiles, optimizing image size, setting up multi-stage builds, fixing container issues, configuring docker-compose services, managing layer caching, or implementing container security scanning. Trigger: Dockerfiles, multi-stage builds, container security. Do NOT trigger for: Kubernetes deployment or orchestration without Docker image concerns."
license: MIT
metadata:
  author: Community
  version: "1.0"
  category: infrastructure
  status: stable
---

# Docker Expert

## Base Images

**See [references/base-images.md](references/base-images.md) for complete guide**

| Use Case | Build Stage | Runtime Stage |
|----------|-------------|---------------|
| Go | `golang:1.23-alpine` | `alpine:3.21` |
| Python | `python:3.12-alpine` | `alpine:3.21` |
| Node.js | `node:20-alpine` | `alpine:3.21` |

**Rules**: ALWAYS `alpine`; `slim` only as fallback when musl breaks wheels; NEVER `distroless` | pin versions | use SHA for prod | NEVER `latest`

## Multi-Stage Builds (MANDATORY)

**See [references/multi-stage.md](references/multi-stage.md) for language-specific examples**

```dockerfile
# Build stage
FROM golang:1.23-alpine AS builder
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/server

# Runtime stage — alpine only
FROM alpine:3.21
RUN adduser -S appuser
USER appuser
COPY --from=builder /app/server /server
ENTRYPOINT ["/server"]
```

## Security & Optimization

**See [references/security.md](references/security.md) and [references/optimization.md](references/optimization.md)**

| Requirement | Implementation |
|-------------|----------------|
| **Non-root user** | `RUN adduser -S appuser && USER appuser` |
| **Minimal image** | ALWAYS `alpine`; `slim` only as fallback when musl breaks wheels; NEVER `distroless` |
| **Layer caching** | Order: system deps → app deps → code |
| **Combine RUNs** | Single layer with `&&` + cleanup |

## Security

- NEVER run as root — ALWAYS `adduser -S appuser && USER appuser`
- NEVER embed secrets — use `docker secret` or env vars at runtime (avoid build args)
- NEVER install unnecessary packages — `apk add --no-cache <pkg>` only what's needed
- ALWAYS multi-stage — build tools NEVER reach runtime image
- ALWAYS scan with `trivy image` before push — block on CRITICAL/HIGH CVEs
- ALWAYS `hadolint` to catch `apt-get` without pinning, `curl | sh`, etc.
- ALWAYS read-only filesystem when possible: `--read-only` + `tmpfs` for writable dirs
- ALWAYS drop capabilities: `--cap-drop ALL --cap-add NET_BIND_SERVICE` (only what's needed)
- COPY specific files (avoid `COPY . .` in runtime stage) — prevent secret leakage

→ [references/security.md](references/security.md)

## Validation

**See [references/validation.md](references/validation.md) for complete guide**

```bash
hadolint Dockerfile
trivy image myapp:latest
```

## .dockerignore

**See [references/optimization.md](references/optimization.md)**

Exclude: `.git`, `node_modules`, `*.env`, secrets, IDE files

## Docker Compose

**See [references/compose.md](references/compose.md) for complete examples**

```yaml
services:
  app:
    deploy:
      resources:
        limits: {cpus: '1.0', memory: 512M}
    secrets:
      - db_password
```

## Production Checklist

- [ ] Base image pinned (no `latest`)
- [ ] Multi-stage build
- [ ] Non-root user
- [ ] No secrets in image
- [ ] `.dockerignore` configured
- [ ] `HEALTHCHECK` defined
- [ ] `hadolint` passes
- [ ] Scanned with Trivy

## Constraints
- NEVER `latest` tags | NEVER secrets in image | NEVER `distroless` images
- ALWAYS `alpine` base images | ALWAYS multi-stage | ALWAYS non-root | ALWAYS `hadolint` + `trivy`

## Overview

Build secure, optimized Docker images and Compose setups for cloud-native services. Covers multi-stage builds (Go, Python, Node.js), Alpine base images (slim only as musl fallback), non-root user enforcement, layer caching optimization, .dockerignore, and production security scanning with hadolint and Trivy. Includes Compose best practices for resource limits and secrets.

## Workflow

1. Choose Alpine base image for language runtime (never `latest`, pin version)
2. Write multi-stage Dockerfile: build stage → runtime stage (Alpine only)
3. Add non-root user: `RUN adduser -S appuser && USER appuser`
4. Order layers for cache efficiency: system deps → app deps → code
5. Configure `.dockerignore` (exclude .git, node_modules, *.env)
6. Add `HEALTHCHECK` instruction
7. Validate: `hadolint Dockerfile` passes
8. Scan: `trivy image myapp:latest` — block on CRITICAL/HIGH CVEs
9. Run with `--read-only --cap-drop ALL --cap-add NET_BIND_SERVICE`

## Anti-patterns

FAIL: Using `latest` tag for base images
```dockerfile
FROM golang:latest
```

PASS: Pin exact version or SHA for reproducibility
```dockerfile
FROM golang:1.23-alpine@sha256:abc123...
```

FAIL: Running as root inside the container
```dockerfile
FROM alpine:3.21
COPY app /app
ENTRYPOINT ["/app"]
```

PASS: Always create and switch to a non-root user
```dockerfile
FROM alpine:3.21
RUN adduser -S appuser
USER appuser
COPY --chown=appuser app /app
```

FAIL: Using `distroless` instead of Alpine
```dockerfile
FROM node:20-slim
```

PASS: Use Alpine — minimal, secure, well-maintained
```dockerfile
FROM node:20-alpine
```

FAIL: Embedding secrets via build args
```dockerfile
ARG DB_PASSWORD
RUN echo "$DB_PASSWORD" > /etc/secrets/db.conf
```

PASS: Use Docker secrets or runtime environment variables
```yaml
secrets:
  - db_password
```

FAIL: Ordering layers for cache-inefficient builds (deps before system packages)
```dockerfile
FROM golang:1.23-alpine AS builder
COPY . .
RUN go mod download
RUN apk add --no-cache gcc musl-dev
```

PASS: Install system deps first, then app deps, then code — maximize layer cache reuse
```dockerfile
FROM golang:1.23-alpine AS builder
RUN apk add --no-cache gcc musl-dev
COPY go.mod go.sum ./
RUN go mod download
COPY . .
```

FAIL: Not using .dockerignore — sending entire repo as build context
```dockerfile
# BAD: no .dockerignore — sends .git, node_modules, .env to Docker daemon
COPY . .
```

PASS: Exclude unnecessary files from build context to speed builds and reduce cache misses
```
# .dockerignore
.git
node_modules
*.env
secrets/
*.pem
*.key
```

## Quick Reference

| Requirement | Implementation |
|---|---|
| Base image | Pin Alpine version + SHA, never `latest` |
| Non-root user | `RUN adduser -S appuser && USER appuser` |
| Layer cache order | System deps → app deps → code |
| Security scan | `hadolint` + `trivy image` pre-push |
| Build context | `.dockerignore` excludes .git, node_modules, .env |

## References

| Resource | URL | Last verified |
|---|---|---|
| Docker best practices guide | https://docs.docker.com/develop/dev-best-practices/ | 2026-04 |
| hadolint — Dockerfile linter | https://github.com/hadolint/hadolint | 2026-04 |
| Trivy vulnerability scanner | https://trivy.dev/ | 2026-04 |
| Docker security — non-root user | https://docs.docker.com/engine/security/ | 2026-03 |

## Verification Checklist
- [ ] Multi-stage build used — build tools never in runtime image
- [ ] Alpine base image pinned (no `latest` tag; version or SHA specified)
- [ ] Non-root user configured via `adduser -S appuser && USER appuser`
- [ ] No secrets embedded in image (docker secret or runtime env vars only)
- [ ] `.dockerignore` configured excluding `.git`, `node_modules`, `*.env`
- [ ] `hadolint` passes with zero violations
- [ ] `trivy image` scan shows no CRITICAL or HIGH CVEs

## Troubleshooting

| [WARN] Known issue | Likely cause | Fix |
|---|---|---|
| Image build fails with `COPY --from=builder` not found | Build stage name mismatch between `AS builder` and `--from=builder` | Verify stage name matches exactly; check for typo in `FROM golang:1.23-alpine AS builder` |
| Trivy reports CRITICAL CVE in final image | Alpine version outdated; unnecessary packages installed | Update Alpine base to latest patch; install only needed packages; use `--no-cache` |
| Container exits immediately with permission denied | Binary not built for Alpine (CGO_ENABLED=1 missing static build); `--chown` mismatch | Set `CGO_ENABLED=0` for static binary; add `--chown=appuser` on COPY to runtime stage |
| `docker compose up` fails with secret not found | Secret path incorrect in docker-compose.yml; Docker Swarm mode required | Use `file:` path syntax for compose; ensure secret file exists on host; for `external: true`, create secret first |
| Alpine-based Python image missing system packages for common wheels (known limitation) | Alpine uses musl libc, not glibc — some Python wheels (psycopg2, cryptography) have no musl-compatible build | Install build deps with `apk add gcc musl-dev`; or switch to slim variant if Alpine compatibility breaks too many packages |
| Layer cache invalidated by `COPY` before `RUN` (known bug) | Docker uses layer checksums — any changed file in `COPY .` busts all subsequent layers including `RUN apt-get install` | Order: `COPY package.json` (only deps manifest) → `RUN install` → `COPY .` (code changes don't invalidate deps layer) |
| Alpine musl libc breaks Go/Python compiled binaries (edge case) | Alpine uses musl, not glibc — binaries compiled against glibc (ubuntu/debian) segfault on Alpine | Set `CGO_ENABLED=0` for Go static builds; use `python:3.12-alpine` for Python; test binary on Alpine before deploying |
