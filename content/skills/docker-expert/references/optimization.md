# Docker Image Optimization

## Layer Caching

Docker builds images in layers. Order matters!

### FAIL: Bad - Invalidates Cache Frequently

```dockerfile
FROM node:20-slim

WORKDIR /app

# Code changes invalidate all subsequent layers
COPY . .

# Dependencies reinstalled every time code changes
RUN npm install

CMD ["node", "index.js"]
```

### PASS: Good - Optimized for Caching

```dockerfile
FROM node:20-slim

WORKDIR /app

# 1. Copy dependency files (change rarely)
COPY package.json package-lock.json ./

# 2. Install dependencies (cached unless package files change)
RUN npm ci --only=production

# 3. Copy code (changes frequently, but deps already cached)
COPY . .

CMD ["node", "index.js"]
```

**Rule**: Order layers from **least → most frequently changed**

## Minimize Layers

### Combine RUN Commands

```dockerfile
# FAIL: Bad - 3 layers
RUN apt-get update
RUN apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*

# PASS: Good - 1 layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*
```

### Use Multi-Line for Readability

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        wget && \
    rm -rf /var/lib/apt/lists/*
```

## Clean Up in Same Layer

```dockerfile
# FAIL: Bad - cleanup in different layer doesn't reduce size
RUN apt-get update && apt-get install -y build-essential
RUN rm -rf /var/lib/apt/lists/*  # Layer still includes lists!

# PASS: Good - cleanup in same layer
RUN apt-get update && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/*  # Actually removes from this layer
```

## .dockerignore

Exclude unnecessary files from build context.

```dockerignore
# Version control
.git
.gitignore
.gitattributes

# Dependencies (will be installed in container)
node_modules
venv
__pycache__
*.pyc
.Python

# Build artifacts
dist
build
target
*.egg-info
.eggs

# IDE/Editor files
.idea
.vscode
.vs
*.swp
*.swo
*~
.DS_Store

# OS files
Thumbs.db
desktop.ini

# Logs
*.log
logs/
npm-debug.log*

# Test files
test/
tests/
*.test.js
*.spec.js
coverage/
.coverage

# Documentation
*.md
docs/
README*
LICENSE
CHANGELOG*

# CI/CD
.github
.gitlab-ci.yml
.travis.yml
Jenkinsfile

# Docker files themselves
Dockerfile*
docker-compose*.yml
.dockerignore

# Secrets (CRITICAL)
.env
.env.*
*.pem
*.key
*.p12
secrets/
credentials/
*.crt
id_rsa*
.ssh/
.aws/
.kube/

# Temporary files
tmp/
temp/
*.tmp
*.bak
*.swp
```

## Remove Package Manager Cache

### APT (Debian/Ubuntu)

```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends package && \
    rm -rf /var/lib/apt/lists/*  # Remove apt cache
```

### APK (Alpine)

```dockerfile
RUN apk add --no-cache package  # Don't cache in first place
```

### YUM/DNF (RHEL/CentOS)

```dockerfile
RUN yum install -y package && \
    yum clean all && \
    rm -rf /var/cache/yum
```

### pip (Python)

```dockerfile
RUN pip install --no-cache-dir package  # Don't cache
```

### npm (Node.js)

```dockerfile
RUN npm ci --only=production  # Clean install, no cache
# Or
RUN npm install --omit=dev && npm cache clean --force
```

## Image Size Optimization Techniques

### 1. Multi-Stage Builds

```dockerfile
# Build stage - large with all tools
FROM node:20 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage - minimal
FROM node:20-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

**Reduction**: 1GB → 200MB

### 2. Use Slim/Alpine Images

```dockerfile
# FAIL: Full image
FROM python:3.12  # 1GB

# PASS: Slim image
FROM python:3.12-slim  # 150MB

# PASS:PASS: Alpine (if compatible)
FROM python:3.12-alpine  # 50MB
```

### 3. Install Only Production Dependencies

```dockerfile
# Python
RUN pip install --no-cache-dir -r requirements.txt

# Node.js
RUN npm ci --only=production

# Go - no runtime dependencies needed
FROM scratch
COPY --from=builder /app/server /server
```

### 4. Remove Unnecessary Files

```dockerfile
# Remove docs, examples, tests from installed packages
RUN find /usr/local -type d -name '__pycache__' -exec rm -rf {} + && \
    find /usr/local -type f -name '*.pyc' -delete && \
    find /usr/local -type d -name 'tests' -exec rm -rf {} + && \
    find /usr/local -type d -name 'docs' -exec rm -rf {} +
```

### 5. Compress Binaries

```dockerfile
# Go - strip debug symbols
RUN go build -ldflags="-s -w" -o app

# C/C++ - strip
RUN gcc -o app app.c && strip app
```

## BuildKit Features

Enable BuildKit for better caching and parallelization:

```bash
export DOCKER_BUILDKIT=1
docker build .
```

### Cache Mounts

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.23-alpine

# Persistent cache for go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Persistent cache for go build
RUN --mount=type=cache,target=/root/.cache/go-build \
    go build -o /app
```

### Bind Mounts

```dockerfile
# Mount source without copying (faster builds)
RUN --mount=type=bind,source=.,target=/src \
    cd /src && make build
```

## Analyze Image Layers

### docker history

```bash
docker history myapp:latest

# Show sizes
docker history --no-trunc --format "{{.Size}}\t{{.CreatedBy}}" myapp:latest | sort -h
```

### dive

```bash
# Install
brew install dive

# Analyze image
dive myapp:latest
```

**Shows**:
- Layer-by-layer breakdown
- Wasted space
- File changes per layer

## Size Comparison Example

```dockerfile
# FAIL: Unoptimized - 1.2GB
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]

# PASS: Optimized - 180MB
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY app.py .
RUN groupadd -r app && useradd -r -g app app
USER app
CMD ["python", "app.py"]
```

**Reduction**: 1.2GB → 180MB (-85%)

## Caching Strategy

### Order of Operations

1. **System packages** (rarely change)
2. **Language runtime** (occasionally change)
3. **Dependencies** (change sometimes)
4. **Application code** (change frequently)

```dockerfile
FROM node:20-slim

# 1. System packages
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# 2. Language runtime (already in base image)

# 3. Dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci

# 4. Application code
COPY . .

CMD ["node", "index.js"]
```

### Separate Rarely-Changed Files

```dockerfile
# Copy config files separately
COPY nginx.conf /etc/nginx/
COPY config/ /app/config/

# Copy code
COPY src/ /app/src/
```

## Best Practices Summary

1. **Use .dockerignore** - Reduce build context
2. **Order layers** - Least → most frequently changed
3. **Combine RUN commands** - Fewer layers
4. **Clean up in same layer** - Actually reduces size
5. **Multi-stage builds** - Exclude build tools
6. **Minimal base images** - slim/alpine/distroless
7. **No cache for package managers** - `--no-cache-dir`
8. **Use BuildKit** - Better caching
9. **Analyze with dive** - Find wasted space
10. **Pin versions** - Reproducible builds

## Quick Wins

| Optimization | Size Reduction |
|--------------|----------------|
| Use slim instead of full | -70% |
| Multi-stage build | -60% |
| Remove package cache | -10% |
| Use distroless | -90% (for compiled binaries) |
| .dockerignore | -20% (build time) |

## Benchmark

```bash
# Before optimization
docker build -t myapp:before .
docker images myapp:before
# myapp:before - 1.2GB

# After optimization
docker build -t myapp:after .
docker images myapp:after
# myapp:after - 180MB

# Reduction
echo "$(( (1200 - 180) * 100 / 1200 ))% reduction"
# 85% reduction
```
