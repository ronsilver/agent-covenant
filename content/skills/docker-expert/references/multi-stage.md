# Multi-Stage Docker Builds

## Why Multi-Stage?

- **Smaller images**: Exclude build tools from final image
- **Faster builds**: Cache build dependencies separately
- **Security**: Don't ship compilers, dev tools to production
- **Clean separation**: Build artifacts vs runtime

## Go Example

```dockerfile
# ============================================
# Build Stage
# ============================================
FROM golang:1.23-alpine AS builder

WORKDIR /build

# Dependencies (cached layer)
COPY go.mod go.sum ./
RUN go mod download

# Source code
COPY . .

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags="-s -w" \
    -o /app/server \
    ./cmd/server

# ============================================
# Runtime Stage
# ============================================
FROM gcr.io/distroless/static-debian12:nonroot

# Copy only the binary
COPY --from=builder /app/server /server

EXPOSE 8080
ENTRYPOINT ["/server"]
```

**Result**: 2MB image vs 300MB+ with build tools

## Python Example

```dockerfile
# ============================================
# Build Stage
# ============================================
FROM python:3.12-slim AS builder

WORKDIR /app

# Install poetry
RUN pip install --no-cache-dir poetry

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Export requirements
RUN poetry export -f requirements.txt --output requirements.txt --without-hashes

# ============================================
# Runtime Stage
# ============================================
FROM python:3.12-slim

WORKDIR /app

# Copy requirements from builder
COPY --from=builder /app/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY src/ ./src/

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
USER appuser

EXPOSE 8000
CMD ["python", "-m", "src.main"]
```

## Node.js Example

```dockerfile
# ============================================
# Dependencies Stage
# ============================================
FROM node:20-slim AS deps

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install production dependencies only
RUN npm ci --only=production

# ============================================
# Build Stage
# ============================================
FROM node:20-slim AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install all dependencies (including devDependencies)
RUN npm ci

# Copy source
COPY . .

# Build (TypeScript compilation, etc.)
RUN npm run build

# ============================================
# Runtime Stage
# ============================================
FROM node:20-slim

WORKDIR /app

# Copy production dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy built assets from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# Use non-root user
USER node

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

## Java (Maven) Example

```dockerfile
# ============================================
# Build Stage
# ============================================
FROM maven:3.9-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy pom.xml first (dependency layer cache)
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests

# ============================================
# Runtime Stage
# ============================================
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app

# Copy JAR from builder
COPY --from=builder /app/target/*.jar app.jar

# Non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## Rust Example

```dockerfile
# ============================================
# Build Stage
# ============================================
FROM rust:1.75-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache musl-dev

# Copy Cargo files
COPY Cargo.toml Cargo.lock ./

# Create dummy main to cache dependencies
RUN mkdir src && \
    echo "fn main() {}" > src/main.rs && \
    cargo build --release && \
    rm -rf src

# Copy real source
COPY src ./src

# Build release
RUN cargo build --release

# ============================================
# Runtime Stage
# ============================================
FROM gcr.io/distroless/cc-debian12:nonroot

# Copy binary from builder
COPY --from=builder /app/target/release/myapp /myapp

ENTRYPOINT ["/myapp"]
```

## Frontend (React/Next.js) Example

```dockerfile
# ============================================
# Dependencies Stage
# ============================================
FROM node:20-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# ============================================
# Build Stage
# ============================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build static assets
RUN npm run build

# ============================================
# Runtime Stage (Nginx)
# ============================================
FROM nginx:alpine

# Copy built assets
COPY --from=builder /app/dist /usr/share/nginx/html

# Custom nginx config (optional)
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Multi-Language Example

```dockerfile
# ============================================
# Frontend Build
# ============================================
FROM node:20-slim AS frontend

WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ============================================
# Backend Build
# ============================================
FROM golang:1.23-alpine AS backend

WORKDIR /app/backend
COPY backend/go.mod backend/go.sum ./
RUN go mod download
COPY backend/ ./
RUN CGO_ENABLED=0 go build -o /app/server

# ============================================
# Runtime
# ============================================
FROM gcr.io/distroless/static-debian12:nonroot

# Copy backend binary
COPY --from=backend /app/server /server

# Copy frontend static files
COPY --from=frontend /app/frontend/dist /static

EXPOSE 8080
ENTRYPOINT ["/server"]
```

## Advanced Patterns

### Named Stages for Reuse

```dockerfile
FROM node:20-slim AS base
WORKDIR /app
COPY package*.json ./

FROM base AS development
RUN npm install
COPY . .
CMD ["npm", "run", "dev"]

FROM base AS production
RUN npm ci --only=production
COPY --from=development /app/dist ./dist
USER node
CMD ["node", "dist/index.js"]
```

### Build with --target

```bash
# Build development image
docker build --target development -t myapp:dev .

# Build production image
docker build --target production -t myapp:prod .
```

### External Build Cache

```dockerfile
FROM golang:1.23-alpine AS builder

# Mount cache for go modules
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

# Mount cache for build cache
RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -o /app/server
```

## Copy Patterns

### Copy Specific Files

```dockerfile
# Copy only binary
COPY --from=builder /app/server /server

# Copy with rename
COPY --from=builder /app/target/myapp-1.0.jar /app.jar

# Copy directory
COPY --from=builder /app/dist /var/www/html
```

### Copy with Permissions

```dockerfile
# Copy as specific user
COPY --from=builder --chown=appuser:appgroup /app/server /server

# Copy with specific permissions
COPY --from=builder --chmod=755 /app/script.sh /script.sh
```

## Optimization Tips

### 1. Order Layers by Change Frequency

```dockerfile
# PASS: Good - dependencies change less than code
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
```

### 2. Leverage BuildKit Cache

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Or in docker-compose.yml
DOCKER_BUILDKIT=1 docker-compose build
```

### 3. Use .dockerignore

```.dockerignore
node_modules
dist
.git
*.md
.env
```

### 4. Minimize Layers in Final Image

```dockerfile
# FAIL: Multiple COPY commands
COPY file1.txt /app/
COPY file2.txt /app/
COPY file3.txt /app/

# PASS: Single COPY
COPY file1.txt file2.txt file3.txt /app/
```

## Testing Multi-Stage Builds

```bash
# Build and check image size
docker build -t myapp:test .
docker images myapp:test

# Inspect layers
docker history myapp:test

# Analyze with dive
dive myapp:test

# Run container
docker run --rm myapp:test
```

## Common Mistakes

### FAIL: Not Using Multi-Stage

```dockerfile
FROM python:3.12
# Includes pip, setuptools, etc. (1GB+)
```

### FAIL: Copying Entire Build Directory

```dockerfile
COPY --from=builder /app /app
# Includes source, tests, build cache!
```

**Fix**: Copy only what's needed

```dockerfile
COPY --from=builder /app/dist /app
```

### FAIL: Installing Dev Dependencies in Final Image

```dockerfile
FROM node:20-slim
RUN npm install  # Includes devDependencies!
```

**Fix**: Use `npm ci --only=production`

## Size Comparison

| Approach | Image Size | Build Time |
|----------|------------|------------|
| Single-stage (full) | 1.2GB | 5min |
| Single-stage (slim) | 300MB | 4min |
| Multi-stage | 50MB | 5min (cached: 30s) |

## Best Practices

1. **Use multi-stage for all compiled languages**
2. **Order stages**: dependencies → build → runtime
3. **Copy only artifacts** - not source code
4. **Use specific COPY** - don't copy everything
5. **Leverage caching** - separate dependency and code layers
6. **Name stages** - for clarity and --target builds
7. **Minimize final image** - only runtime dependencies

## BuildKit Features

```dockerfile
# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder

# Cache mounts
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /app/server

# Secret mounts (don't bake into image)
RUN --mount=type=secret,id=github_token \
    git clone https://$(cat /run/secrets/github_token)@github.com/...
```

Build with secrets:

```bash
docker build --secret id=github_token,src=$HOME/.github_token .
```
