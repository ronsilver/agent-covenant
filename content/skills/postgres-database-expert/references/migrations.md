# Database Migrations

## Tool: golang-migrate

```bash
# Install
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Create new migration
migrate create -ext sql -dir db/migrations -seq add_shipment_metadata

# Apply all pending
migrate -path db/migrations -database $DATABASE_URL up

# Rollback one step
migrate -path db/migrations -database $DATABASE_URL down 1

# Check version
migrate -path db/migrations -database $DATABASE_URL version
```

## Migration File Structure

```
db/migrations/
├── 000001_init_schema.up.sql
├── 000001_init_schema.down.sql
├── 000002_add_shipments_table.up.sql
├── 000002_add_shipments_table.down.sql
└── 000003_add_shipment_metadata.up.sql
    000003_add_shipment_metadata.down.sql
```

## Writing Safe Migrations

### Adding a Column (Zero-downtime)

```sql
-- UP: safe — adding nullable column is instant
ALTER TABLE shipments ADD COLUMN metadata JSONB;

-- If NOT NULL needed, add with default first, then remove default
ALTER TABLE shipments ADD COLUMN currency_code CHAR(3) NOT NULL DEFAULT 'USD';
-- Later migration: ALTER TABLE shipments ALTER COLUMN currency_code DROP DEFAULT;
```

```sql
-- DOWN
ALTER TABLE shipments DROP COLUMN IF EXISTS metadata;
```

### Adding an Index Concurrently

```sql
-- UP: CONCURRENTLY avoids table lock — critical for production
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_shipments_customer_id ON shipments(customer_id);

-- DOWN
DROP INDEX CONCURRENTLY IF EXISTS idx_shipments_customer_id;
```

### Renaming a Column (Zero-downtime — multi-step)

```sql
-- Step 1: Add new column + sync trigger
ALTER TABLE shipments ADD COLUMN customer_ref_id UUID;
CREATE TRIGGER sync_customer_ref_id
    BEFORE INSERT OR UPDATE ON shipments
    FOR EACH ROW EXECUTE FUNCTION sync_column('customer_id', 'customer_ref_id');

-- Step 2 (next deploy): Update application to use new column
-- Step 3 (next deploy): Drop old column + trigger
ALTER TABLE shipments DROP COLUMN customer_id;
DROP TRIGGER sync_customer_ref_id ON shipments;
```

### Dropping a Column (Safe)

```sql
-- Never drop immediately — application may still reference it
-- Step 1: Deploy code that stops using the column
-- Step 2: Then drop
ALTER TABLE shipments DROP COLUMN IF EXISTS deprecated_field;
```

## Running Migrations in Go

```go
import (
    "github.com/golang-migrate/migrate/v4"
    _ "github.com/golang-migrate/migrate/v4/database/postgres"
    _ "github.com/golang-migrate/migrate/v4/source/file"
)

func RunMigrations(databaseURL string) error {
    m, err := migrate.New("file://db/migrations", databaseURL)
    if err != nil {
        return fmt.Errorf("create migrator: %w", err)
    }
    defer m.Close()

    if err := m.Up(); err != nil && !errors.Is(err, migrate.ErrNoChange) {
        return fmt.Errorf("run migrations: %w", err)
    }
    return nil
}
```

## Migration Best Practices

- **Always write a down migration** — even if you won't use it
- **Never edit existing migrations** — create a new one instead
- **Test rollback** in CI: `migrate up && migrate down 1 && migrate up`
- **Concurrent indexes**: always use `CONCURRENTLY` in production
- **Lock timeout**: set `lock_timeout` to prevent blocking
- **Idempotent**: use `IF NOT EXISTS` / `IF EXISTS` everywhere

```sql
-- Set lock timeout for risky DDL
SET lock_timeout = '2s';
ALTER TABLE shipments ADD CONSTRAINT ...;
```
