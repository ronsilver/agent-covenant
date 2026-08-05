# PostgreSQL Technology Stack

## Core Libraries (Go)

| Component | Library | Purpose |
|-----------|---------|---------|
| ORM | `gorm.io/gorm` + `gorm.io/driver/postgres` | Model definition, simple CRUD |
| Raw SQL driver | `github.com/jackc/pgx/v5` | Complex queries, pgxpool, COPY |
| Connection pool | `github.com/jackc/pgx/v5/pgxpool` | Production connection pooling |
| Migrations | `github.com/golang-migrate/migrate/v4` | Schema versioning |
| Cache | `github.com/redis/go-redis/v9` | Cache-aside with TTL |

## When to Use GORM vs. pgx

| Use GORM | Use pgx directly |
|----------|----------------|
| Simple CRUD with model structs | Complex multi-table queries |
| Rapid prototyping | COPY FROM for bulk inserts |
| Associations with preloading | Custom type mapping |
| Soft deletes | Low-latency hot paths |
| — | Stored procedures / custom SQL |

## PostgreSQL Configuration (`postgresql.conf`)

Critical settings for production:

```ini
# Memory
shared_buffers = 25% of RAM          # e.g., 4GB on 16GB server
effective_cache_size = 75% of RAM    # planner hint only
work_mem = 64MB                      # per sort/hash — watch parallel queries
maintenance_work_mem = 512MB         # for VACUUM, CREATE INDEX

# Checkpoints
checkpoint_completion_target = 0.9   # spread checkpoint I/O
max_wal_size = 4GB

# Query planning
random_page_cost = 1.1               # for SSDs (default 4.0 is for HDDs)
effective_io_concurrency = 200       # for SSDs

# Logging (for identifying slow queries)
log_min_duration_statement = 1000    # log queries > 1s
log_checkpoints = on
log_lock_waits = on
log_temp_files = 0
```

## pgxpool Configuration (Go)

```go
func NewPool(ctx context.Context, cfg DatabaseConfig) (*pgxpool.Pool, error) {
    config, err := pgxpool.ParseConfig(cfg.URL)
    if err != nil {
        return nil, fmt.Errorf("parse db config: %w", err)
    }

    config.MaxConns = cfg.MaxConns              // default: 4 (too low for prod)
    config.MinConns = cfg.MinConns              // keep min connections warm
    config.MaxConnLifetime = cfg.MaxConnLife    // rotate connections (8h typical)
    config.MaxConnIdleTime = 30 * time.Minute  // close idle connections
    config.HealthCheckPeriod = 1 * time.Minute // detect dead connections

    // Connection pool sizing formula:
    // max_conns = (num_cores * 2) + effective_spindle_count
    // For a 4-core server with SSD: ~10 connections per service instance

    pool, err := pgxpool.NewWithConfig(ctx, config)
    if err != nil {
        return nil, fmt.Errorf("create pool: %w", err)
    }

    if err := pool.Ping(ctx); err != nil {
        return nil, fmt.Errorf("ping db: %w", err)
    }

    return pool, nil
}
```

## GORM Setup

```go
func NewGORM(cfg DatabaseConfig) (*gorm.DB, error) {
    db, err := gorm.Open(postgres.Open(cfg.URL), &gorm.Config{
        Logger: gormzap.New(logger),
        NowFunc: func() time.Time {
            return time.Now().UTC()
        },
        PrepareStmt: true,  // cache prepared statements
    })
    if err != nil {
        return nil, fmt.Errorf("open gorm: %w", err)
    }

    sqlDB, err := db.DB()
    if err != nil {
        return nil, fmt.Errorf("get sql.DB: %w", err)
    }

    sqlDB.SetMaxOpenConns(int(cfg.MaxConns))
    sqlDB.SetMaxIdleConns(int(cfg.MinConns))
    sqlDB.SetConnMaxLifetime(cfg.MaxConnLife)

    return db, nil
}
```

## Local Development Setup

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: example
      POSTGRES_PASSWORD: example
      POSTGRES_DB: payments_dev
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./db/init:/docker-entrypoint-initdb.d
    command: >
      postgres
      -c log_min_duration_statement=100
      -c log_statement=all
      -c log_destination=stderr

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

```bash
# Environment variables
DATABASE_URL=postgres://example:example@localhost:5432/payments_dev?sslmode=disable
REDIS_URL=redis://localhost:6379/0
```
