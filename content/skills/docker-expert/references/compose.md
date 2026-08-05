# Docker Compose Best Practices

## Basic Structure

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
    depends_on:
      - db
      - redis

  db:
    image: postgres:16-alpine
    volumes:
      - db_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  db_data:
  redis_data:

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Resource Limits

```yaml
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
      restart_policy:
        condition: on-failure
        max_attempts: 3
```

## Health Checks

```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s
```

## Environment Variables

### FAIL: Don't Hardcode Secrets

```yaml
# FAIL: Bad
services:
  app:
    environment:
      DB_PASSWORD: mypassword123
```

### PASS: Use .env File

```yaml
# PASS: Good
services:
  app:
    env_file:
      - .env
```

```.env
DB_HOST=postgres
DB_PORT=5432
DB_NAME=myapp
DB_USER=appuser
# .env should be in .gitignore!
```

### PASS:PASS: Use Secrets

```yaml
services:
  app:
    secrets:
      - db_password
    environment:
      DB_PASSWORD_FILE: /run/secrets/db_password

secrets:
  db_password:
    file: ./secrets/db_password.txt
```

## Networks

```yaml
services:
  frontend:
    networks:
      - public
      - backend

  api:
    networks:
      - backend
      - database

  db:
    networks:
      - database

networks:
  public:
  backend:
    internal: true  # No external access
  database:
    internal: true
```

## Volumes

### Named Volumes

```yaml
services:
  db:
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
    driver: local
```

### Bind Mounts

```yaml
services:
  app:
    volumes:
      - ./app:/app  # Development
      - ./config:/app/config:ro  # Read-only
```

### Volume Options

```yaml
services:
  app:
    volumes:
      - type: bind
        source: ./app
        target: /app
      - type: volume
        source: data
        target: /data
        volume:
          nocopy: true
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 1000000  # bytes
```

## Dependency Management

```yaml
services:
  app:
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    
  db:
    healthcheck:
      test: ["CMD", "pg_isready"]
      interval: 5s
```

## Multi-Environment Setup

### docker-compose.yml (Base)

```yaml
version: '3.8'

services:
  app:
    build: .
    env_file:
      - .env
```

### docker-compose.dev.yml (Override)

```yaml
version: '3.8'

services:
  app:
    build:
      target: development
    volumes:
      - ./app:/app  # Hot reload
    environment:
      DEBUG: "true"
```

### docker-compose.prod.yml

```yaml
version: '3.8'

services:
  app:
    build:
      target: production
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
```

### Usage

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Secrets Management

```yaml
services:
  app:
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
    external: true  # Managed outside compose
```

## Logging

```yaml
services:
  app:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Logging Drivers

```yaml
# Syslog
logging:
  driver: syslog
  options:
    syslog-address: "tcp://192.168.0.42:123"

# Fluentd
logging:
  driver: fluentd
  options:
    fluentd-address: localhost:24224
    tag: myapp

# Disable logging (not recommended)
logging:
  driver: none
```

## Complete Production Example

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certs:/etc/nginx/certs:ro
      - static_files:/var/www/static:ro
    networks:
      - public
    depends_on:
      - app
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 3s
      retries: 3
    restart: unless-stopped

  app:
    build:
      context: .
      target: production
    expose:
      - "3000"
    networks:
      - public
      - backend
    environment:
      NODE_ENV: production
      DB_HOST: postgres
      REDIS_HOST: redis
    env_file:
      - .env.production
    secrets:
      - db_password
      - session_secret
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
      restart_policy:
        condition: on-failure
        max_attempts: 3
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 40s
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  postgres:
    image: postgres:16-alpine
    networks:
      - backend
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    secrets:
      - db_password
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '1.0'
          memory: 1G
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U appuser -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    networks:
      - backend
    volumes:
      - redis_data:/data
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    restart: unless-stopped

networks:
  public:
  backend:
    internal: true

volumes:
  postgres_data:
    driver: local
  redis_data:
    driver: local
  static_files:
    driver: local

secrets:
  db_password:
    file: ./secrets/db_password.txt
  session_secret:
    file: ./secrets/session_secret.txt
```

## Docker Compose Commands

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Rebuild images
docker-compose build

# Rebuild without cache
docker-compose build --no-cache

# Scale service
docker-compose up -d --scale app=3

# Execute command in service
docker-compose exec app sh

# View running services
docker-compose ps
```

## Best Practices

1. **Use version 3.8+** - Latest features
2. **Pin image versions** - Reproducible builds
3. **Use secrets** - Not environment variables
4. **Set resource limits** - Prevent resource exhaustion
5. **Add health checks** - Ensure service health
6. **Use networks** - Isolate services
7. **Named volumes** - Data persistence
8. **depends_on with conditions** - Proper startup order
9. **Logging configuration** - Prevent disk fill
10. **restart policies** - Automatic recovery

## Common Mistakes

### FAIL: Secrets in Environment

```yaml
environment:
  DB_PASSWORD: mypassword
```

### FAIL: No Resource Limits

```yaml
services:
  app:
    image: myapp
    # No limits - can consume all resources!
```

### FAIL: Using :latest

```yaml
services:
  db:
    image: postgres:latest  # Will change!
```

### FAIL: Bind Mounting in Production

```yaml
services:
  app:
    volumes:
      - ./app:/app  # Don't do this in production!
```

## Troubleshooting

```bash
# View service logs
docker-compose logs app

# Follow logs
docker-compose logs -f --tail=100 app

# Check service status
docker-compose ps

# Inspect service
docker-compose exec app env

# Validate compose file
docker-compose config

# Check what would be created
docker-compose config --services
```

## CI/CD Integration

```yaml
# .github/workflows/docker-compose.yml
name: Docker Compose Test

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Start services
        run: docker-compose up -d
      
      - name: Wait for services
        run: |
          timeout 60 sh -c 'until docker-compose exec -T app curl -f http://localhost:3000/health; do sleep 1; done'
      
      - name: Run tests
        run: docker-compose exec -T app npm test
      
      - name: Stop services
        run: docker-compose down -v
```
