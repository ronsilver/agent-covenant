# Database Development Workflow

## Adding a New Feature (with Schema Change)

```
1. Design schema changes (columns, indexes, constraints)
2. Create migration files: migrate create -ext sql -dir db/migrations -seq <description>
3. Write up.sql (forward) + down.sql (rollback)
4. Test locally: make migrate-up && make migrate-down && make migrate-up
5. Update GORM models / pgx queries
6. Write repository tests against real DB (use testcontainers)
7. PR: migration files + model changes + tests together
```

## Local Development Setup

```bash
# Start PostgreSQL + Redis with Docker
docker compose up -d postgres redis

# Run migrations
DATABASE_URL="postgres://postgres:postgres@localhost:5432/payments_dev?sslmode=disable"
migrate -path db/migrations -database $DATABASE_URL up

# Seed test data
psql $DATABASE_URL < db/seeds/dev.sql
```

```yaml
# docker-compose.yml
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: payments_dev
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
volumes:
  pg_data:
```

## Testing with testcontainers-go

```go
func SetupTestDB(t *testing.T) *pgxpool.Pool {
    t.Helper()
    ctx := context.Background()

    req := testcontainers.ContainerRequest{
        Image:        "postgres:15-alpine",
        ExposedPorts: []string{"5432/tcp"},
        Env: map[string]string{
            "POSTGRES_DB":       "test_db",
            "POSTGRES_USER":     "test",
            "POSTGRES_PASSWORD": "test",
        },
        WaitingFor: wait.ForLog("database system is ready to accept connections"),
    }
    container, err := testcontainers.GenericContainer(ctx, testcontainers.GenericContainerRequest{
        ContainerRequest: req,
        Started:          true,
    })
    require.NoError(t, err)
    t.Cleanup(func() { _ = container.Terminate(ctx) })

    port, _ := container.MappedPort(ctx, "5432")
    dsn := fmt.Sprintf("postgres://test:test@localhost:%s/test_db", port.Port())

    RunMigrations(dsn)

    pool, err := pgxpool.New(ctx, dsn)
    require.NoError(t, err)
    t.Cleanup(pool.Close)
    return pool
}
```

## Makefile Targets

```makefile
DB_URL ?= postgres://postgres:postgres@localhost:5432/payments_dev?sslmode=disable

migrate-up:
	migrate -path db/migrations -database $(DB_URL) up

migrate-down:
	migrate -path db/migrations -database $(DB_URL) down 1

migrate-create:
	@read -p "Migration name: " name; \
	migrate create -ext sql -dir db/migrations -seq $$name

db-shell:
	psql $(DB_URL)

db-reset: migrate-down migrate-up

test-db:
	go test ./internal/repository/... -v -count=1
```

## Query Review Checklist

Before merging a PR with new queries:

- [ ] No `SELECT *` — explicit column list
- [ ] Parameterized queries — no string formatting
- [ ] Index exists for all WHERE/JOIN/ORDER BY columns
- [ ] `EXPLAIN ANALYZE` run on production-sized data
- [ ] N+1 queries eliminated (use joins or batch loading)
- [ ] Transactions used for multi-step mutations
- [ ] Context propagation in all DB calls
- [ ] Proper error handling (not just `_ = err`)
