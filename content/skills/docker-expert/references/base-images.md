# Docker Base Images

## Recommended Base Images

| Language/Stack | Production Base | Development Base | Size |
|---------------|-----------------|------------------|------|
| **Go (static)** | `gcr.io/distroless/static-debian12:nonroot` | `golang:1.23-alpine` | 2MB / 300MB |
| **Go (with libc)** | `gcr.io/distroless/base-debian12:nonroot` | `golang:1.23-alpine` | 20MB / 300MB |
| **Python** | `python:3.12-slim` | `python:3.12` | 150MB / 1GB |
| **Node.js** | `node:20-slim` | `node:20` | 200MB / 1GB |
| **Java** | `eclipse-temurin:21-jre-alpine` | `eclipse-temurin:21-jdk` | 200MB / 400MB |
| **Rust** | `gcr.io/distroless/cc-debian12:nonroot` | `rust:1.75-alpine` | 20MB / 800MB |
| **.NET** | `mcr.microsoft.com/dotnet/aspnet:8.0-alpine` | `mcr.microsoft.com/dotnet/sdk:8.0` | 100MB / 700MB |
| **Ruby** | `ruby:3.3-slim` | `ruby:3.3` | 170MB / 900MB |

## Distroless Images

Google's distroless images contain only your application and runtime dependencies (no shell, package manager).

```dockerfile
# Static binary (Go, Rust)
FROM gcr.io/distroless/static-debian12:nonroot

# Requires libc
FROM gcr.io/distroless/base-debian12:nonroot

# With Java runtime
FROM gcr.io/distroless/java17-debian12:nonroot

# With Python runtime
FROM gcr.io/distroless/python3-debian12:nonroot
```

**Benefits**:
- Smallest attack surface
- No shell = no shell exploits
- Only runtime dependencies

**Drawback**: Debugging is harder (no shell)

## Alpine Linux

Minimal Linux distribution (~7MB base).

```dockerfile
FROM alpine:3.19

RUN apk add --no-cache ca-certificates
```

**Benefits**:
- Very small base
- Fast builds
- Good for multi-stage builds

**Drawbacks**:
- Uses musl libc (not glibc) - compatibility issues
- Some Python packages fail to build
- DNS resolution quirks in some environments

## Slim Images

Debian-based minimal images.

```dockerfile
FROM python:3.12-slim
FROM node:20-slim
FROM ruby:3.3-slim
```

**Benefits**:
- Smaller than full images (~150MB vs ~1GB)
- Uses glibc (better compatibility)
- Includes apt package manager

**Use when**: Alpine causes compatibility issues

## Version Pinning

### FAIL: Bad - Mutable Tags

```dockerfile
FROM python:3.12          # Can change over time
FROM node:latest          # Always changes
FROM alpine               # Version unspecified
```

### PASS: Good - Specific Versions

```dockerfile
FROM python:3.12.1-slim
FROM node:20.10.0-slim
FROM alpine:3.19.0
```

### PASS:PASS: Best - SHA Digests

```dockerfile
FROM python:3.12-slim@sha256:a3e58f9399...
FROM node:20-slim@sha256:7f8c4e5b2a...
```

**Get SHA**: `docker pull python:3.12-slim && docker inspect python:3.12-slim | grep Id`

## Language-Specific Recommendations

### Go

```dockerfile
# Multi-stage with distroless
FROM golang:1.23-alpine AS builder
# ... build ...

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=builder /app/server /server
ENTRYPOINT ["/server"]
```

**Why distroless**: Go binaries are static (no dependencies needed)

### Python

```dockerfile
# Use slim, not alpine (better package compatibility)
FROM python:3.12-slim

RUN pip install --no-cache-dir -r requirements.txt
```

**Avoid alpine**: Many Python packages (numpy, pandas, pillow) have C extensions that fail on alpine.

### Node.js

```dockerfile
# Use slim for production
FROM node:20-slim

# Or alpine if image size critical
FROM node:20-alpine
```

### Java

```dockerfile
# JRE for runtime (smaller than JDK)
FROM eclipse-temurin:21-jre-alpine

# Or distroless
FROM gcr.io/distroless/java21-debian12:nonroot
```

## Chainguard Images

Ultra-minimal, security-hardened images.

```dockerfile
FROM cgr.dev/chainguard/python:latest-dev AS builder
# ... build ...

FROM cgr.dev/chainguard/python:latest
```

**Benefits**:
- Even smaller than distroless
- Updated daily
- SBOM included
- Non-root by default

## Image Size Comparison

| Base Image | Size | Use Case |
|------------|------|----------|
| `scratch` | 0MB | Static binaries only |
| `gcr.io/distroless/static` | 2MB | Go static binaries |
| `alpine:3.19` | 7MB | General minimal |
| `gcr.io/distroless/base` | 20MB | Dynamic binaries |
| `python:3.12-slim` | 150MB | Python apps |
| `node:20-slim` | 200MB | Node.js apps |
| `python:3.12` | 1GB | Development only |

## Security Considerations

### Non-Root User

```dockerfile
# Distroless (already non-root)
FROM gcr.io/distroless/static-debian12:nonroot

# Alpine
FROM alpine:3.19
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Debian/slim
FROM python:3.12-slim
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser
```

### Read-Only Root Filesystem

```dockerfile
# Make files read-only
RUN chmod -R a-w /app

# Run with --read-only flag
# docker run --read-only --tmpfs /tmp myapp
```

## Base Image Selection Flowchart

```
Start
  ↓
Is it a compiled binary? (Go, Rust, C++)
  ├─ Yes → Use distroless/static or scratch
  └─ No ↓
Does it need many system packages?
  ├─ Yes → Use -slim variant
  └─ No ↓
Need smallest possible size?
  ├─ Yes → Try Alpine (test compatibility)
  └─ No → Use -slim variant
```

## Common Mistakes

### FAIL: Using Full Images in Production

```dockerfile
FROM python:3.12  # 1GB!
```

**Fix**: Use `python:3.12-slim` (150MB)

### FAIL: Not Pinning Versions

```dockerfile
FROM node:latest
```

**Fix**: `FROM node:20.10.0-slim@sha256:...`

### FAIL: Using Alpine for Python

```dockerfile
FROM python:3.12-alpine
RUN pip install numpy  # Often fails!
```

**Fix**: Use `python:3.12-slim`

## Updating Base Images

```bash
# Pull latest
docker pull python:3.12-slim

# Get new SHA
docker inspect python:3.12-slim | grep Id

# Update Dockerfile
FROM python:3.12-slim@sha256:NEW_SHA
```

## Tools

### Dive (Analyze Layers)

```bash
brew install dive
dive myapp:latest
```

### Docker Scout (Vulnerability Scanning)

```bash
docker scout cves myapp:latest
docker scout recommendations myapp:latest
```

## Best Practices

1. **Use minimal base images** - Smaller attack surface
2. **Pin versions** - Reproducible builds
3. **Use SHA digests** - Immutable references
4. **Non-root user** - Principle of least privilege
5. **Scan regularly** - Check for vulnerabilities
6. **Update frequently** - Security patches
7. **Test compatibility** - Especially with Alpine

## References

- [Distroless Images](https://github.com/GoogleContainerTools/distroless)
- [Chainguard Images](https://www.chainguard.dev/chainguard-images)
- [Docker Official Images](https://hub.docker.com/_/python)
