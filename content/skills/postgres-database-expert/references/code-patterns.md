# PostgreSQL Code Patterns

## Table of Contents

- [Table Design](#table-design)
- [Enum Types](#enum-types)
- [Relationships](#relationships)
- [Migration Examples](#migration-examples)
- [Safe NOT NULL Addition](#safe-not-null-addition)
- [Index Strategy](#index-strategy)
- [Query Analysis](#query-analysis)
- [Common Query Patterns](#common-query-patterns)
- [GORM Patterns (Go)](#gorm-patterns-go)
- [pgx Patterns (Go)](#pgx-patterns-go)
- [Redis Caching](#redis-caching)
- [Cache Stampede Prevention](#cache-stampede-prevention)
- [Connection Pool Sizing](#connection-pool-sizing)
- [Security — Role-Based Access](#security--role-based-access)

## Table Design

```sql
CREATE TABLE orders (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id),
    status      order_status NOT NULL DEFAULT 'pending',
    category    VARCHAR(20) NOT NULL CHECK (category IN ('standard','premium','basic')),
    total       BIGINT NOT NULL CHECK (total > 0),  -- Store as integer units
    metadata    JSONB DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ  -- Soft delete
);

-- Partial index: only active orders
CREATE INDEX idx_orders_customer_status
    ON orders (customer_id, status)
    WHERE deleted_at IS NULL;

-- GIN index for JSONB queries
CREATE INDEX idx_orders_metadata ON orders USING GIN (metadata);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

## Enum Types

```sql
CREATE TYPE order_status AS ENUM (
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded'
);

-- Adding a new value (safe, no lock)
ALTER TYPE order_status ADD VALUE 'on_hold' AFTER 'processing';
```

**Warning**: You cannot remove enum values. Plan your enums carefully.

## Relationships

```sql
-- One-to-Many: customer has many orders
CREATE TABLE orders (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    -- ON DELETE RESTRICT = prevent deleting customer with orders
    -- ON DELETE CASCADE  = delete orders when customer deleted (dangerous)
    -- ON DELETE SET NULL = set customer_id to NULL (requires nullable FK)
);

-- Many-to-Many: orders have many products via order_items
CREATE TABLE order_items (
    id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id  UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity  INT NOT NULL CHECK (quantity > 0),
    unit_price BIGINT NOT NULL CHECK (unit_price >= 0),
    UNIQUE (order_id, product_id)
);
```

## Migration Examples

### File Structure

```
migrations/
├── 000001_create_customers.up.sql
├── 000001_create_customers.down.sql
├── 000002_create_orders.up.sql
├── 000002_create_orders.down.sql
├── 000003_add_orders_metadata.up.sql
└── 000003_add_orders_metadata.down.sql
```

### Adding a Column

```sql
-- 000003_add_orders_metadata.up.sql
-- Add JSONB column with default (safe, no table rewrite)
ALTER TABLE orders ADD COLUMN metadata JSONB DEFAULT '{}';

-- Create index CONCURRENTLY (non-blocking)
CREATE INDEX CONCURRENTLY idx_orders_metadata ON orders USING GIN (metadata);
```

```sql
-- 000003_add_orders_metadata.down.sql
DROP INDEX IF EXISTS idx_orders_metadata;
ALTER TABLE orders DROP COLUMN IF EXISTS metadata;
```

### Running Migrations

```bash
# golang-migrate
migrate -database "postgres://user:pass@localhost:5432/mydb?sslmode=disable" \
        -path migrations up

# Rollback last migration
migrate -database "..." -path migrations down 1

# Check current version
migrate -database "..." -path migrations version
```

## Safe NOT NULL Addition

```sql
-- Step 1: Add column nullable
ALTER TABLE orders ADD COLUMN notes TEXT;

-- Step 2: Backfill in batches
UPDATE orders SET notes = '' WHERE notes IS NULL AND id IN (
    SELECT id FROM orders WHERE notes IS NULL LIMIT 10000
);

-- Step 3: Add NOT NULL constraint with validation
ALTER TABLE orders ADD CONSTRAINT chk_orders_notes_not_null
    CHECK (notes IS NOT NULL) NOT VALID;

-- Step 4: Validate constraint (non-blocking scan)
ALTER TABLE orders VALIDATE CONSTRAINT chk_orders_notes_not_null;

-- Step 5: Set NOT NULL (instant, already validated)
ALTER TABLE orders ALTER COLUMN notes SET NOT NULL;
ALTER TABLE orders DROP CONSTRAINT chk_orders_notes_not_null;
```

## Index Strategy

```sql
-- B-tree: equality and range queries (default)
CREATE INDEX idx_orders_created_at ON orders (created_at);

-- Composite: for multi-column WHERE/ORDER BY
CREATE INDEX idx_orders_customer_status ON orders (customer_id, status);
-- Satisfies: WHERE customer_id = X
-- Satisfies: WHERE customer_id = X AND status = Y
-- Does NOT satisfy: WHERE status = Y (leftmost prefix rule)

-- Partial: filter subset of rows
CREATE INDEX idx_orders_pending ON orders (customer_id)
    WHERE status = 'pending' AND deleted_at IS NULL;

-- Covering: include columns to avoid table lookup
CREATE INDEX idx_orders_list ON orders (customer_id, created_at DESC)
    INCLUDE (status, total);

-- GIN: JSONB, arrays, full-text search
CREATE INDEX idx_orders_metadata ON orders USING GIN (metadata jsonb_path_ops);

-- Expression: computed values
CREATE INDEX idx_users_email_lower ON users (LOWER(email));
```

## Query Analysis

```sql
-- Always use EXPLAIN ANALYZE for real execution stats
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM orders
WHERE customer_id = 'abc' AND status = 'pending'
ORDER BY created_at DESC
LIMIT 20;
```

**Red flags in EXPLAIN output:**

| Warning | Issue | Fix |
|---------|-------|-----|
| `Seq Scan` on large table | Missing index | Add appropriate index |
| `Sort` with high cost | Sorting not covered by index | Add ORDER BY columns to index |
| `Nested Loop` on large sets | N+1 at DB level | Use JOIN or batch query |
| `Hash Join` with huge `Rows Removed` | Poor selectivity | Improve WHERE clause |
| High `Buffers: shared read` | Data not in cache | Increase `shared_buffers` or optimize query |

## Common Query Patterns

```sql
-- Cursor-based pagination (fast, stable)
SELECT id, customer_id, total, status, created_at
FROM orders
WHERE customer_id = $1
  AND deleted_at IS NULL
  AND (created_at, id) < ($2, $3)  -- cursor: last_created_at, last_id
ORDER BY created_at DESC, id DESC
LIMIT $4;

-- Avoid OFFSET pagination for large datasets
-- FAIL: SELECT * FROM orders OFFSET 10000 LIMIT 20; -- scans 10020 rows
```

```sql
-- Upsert (INSERT ON CONFLICT)
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES ($1, $2, $3, $4)
ON CONFLICT (order_id, product_id)
DO UPDATE SET
    quantity = EXCLUDED.quantity,
    unit_price = EXCLUDED.unit_price;
```

```sql
-- Batch insert
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
VALUES
    ($1, $2, $3, $4),
    ($5, $6, $7, $8),
    ($9, $10, $11, $12);
```

## GORM Patterns (Go)

### Model Definition

```go
type Order struct {
    ID         uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey"`
    CustomerID uuid.UUID      `gorm:"type:uuid;not null;index:idx_orders_customer_status"`
    Status     OrderStatus    `gorm:"type:order_status;not null;default:'pending';index:idx_orders_customer_status"`
    Currency   string         `gorm:"type:varchar(3);not null"`
    Total      int64          `gorm:"not null"`
    Metadata   datatypes.JSON `gorm:"type:jsonb;default:'{}'"`
    Items      []OrderItem    `gorm:"foreignKey:OrderID"`
    CreatedAt  time.Time      `gorm:"not null;default:now()"`
    UpdatedAt  time.Time      `gorm:"not null;default:now()"`
    DeletedAt  gorm.DeletedAt `gorm:"index"`
}
```

### Performance Tips

```go
// PASS: Select only needed columns
db.Select("id", "status", "total").Find(&orders)

// PASS: Use Preload with conditions (avoid N+1)
db.Preload("Items", "quantity > ?", 0).Find(&orders)

// PASS: Batch operations
db.CreateInBatches(orders, 100)

// PASS: Raw SQL for complex queries
db.Raw(`
    SELECT customer_id, COUNT(*) as count, SUM(total) as revenue
    FROM orders
    WHERE created_at >= ?
    GROUP BY customer_id
    HAVING COUNT(*) > 10
`, since).Scan(&results)

// FAIL: Avoid N+1
for _, order := range orders {
    db.Model(&order).Association("Items").Find(&order.Items) // N+1!
}

// FAIL: Avoid SELECT * on wide tables
db.Find(&orders) // loads ALL columns including metadata JSONB
```

## pgx Patterns (Go)

### Connection Pool

```go
config, _ := pgxpool.ParseConfig(databaseURL)
config.MaxConns = 25
config.MinConns = 5
config.MaxConnLifetime = 30 * time.Minute
config.MaxConnIdleTime = 5 * time.Minute
config.HealthCheckPeriod = 1 * time.Minute

pool, err := pgxpool.NewWithConfig(ctx, config)
```

### Query with OpenTelemetry

```go
func (r *orderRepo) GetByID(ctx context.Context, id uuid.UUID) (*Order, error) {
    ctx, span := otel.Tracer("repository").Start(ctx, "OrderRepo.GetByID")
    defer span.End()

    var o Order
    err := r.pool.QueryRow(ctx,
        `SELECT id, customer_id, total, status, created_at
         FROM orders WHERE id = $1 AND deleted_at IS NULL`, id,
    ).Scan(&o.ID, &o.CustomerID, &o.Total, &o.Status, &o.CreatedAt)

    if errors.Is(err, pgx.ErrNoRows) {
        return nil, ErrNotFound
    }
    if err != nil {
        span.RecordError(err)
        return nil, fmt.Errorf("get order %s: %w", id, err)
    }
    return &o, nil
}
```

### Batch Queries

```go
func (r *orderRepo) CreateBatch(ctx context.Context, orders []*Order) error {
    batch := &pgx.Batch{}
    for _, o := range orders {
        batch.Queue(
            `INSERT INTO items (owner_id, total, category, status)
             VALUES ($1, $2, $3, $4)`,
            o.CustomerID, o.Total, o.Currency, o.Status,
        )
    }

    br := r.pool.SendBatch(ctx, batch)
    defer br.Close()

    for range orders {
        if _, err := br.Exec(); err != nil {
            return fmt.Errorf("batch insert: %w", err)
        }
    }
    return nil
}
```

## Redis Caching

### Cache-Aside Pattern

```go
func (s *orderService) GetByID(ctx context.Context, id uuid.UUID) (*Order, error) {
    key := fmt.Sprintf("order:%s", id)

    // 1. Try cache
    val, err := s.redis.Get(ctx, key).Bytes()
    if err == nil {
        var order Order
        if json.Unmarshal(val, &order) == nil {
            return &order, nil
        }
    }

    // 2. Cache miss — query DB
    order, err := s.repo.GetByID(ctx, id)
    if err != nil {
        return nil, err
    }

    // 3. Populate cache with TTL
    data, _ := json.Marshal(order)
    s.redis.Set(ctx, key, data, 5*time.Minute)

    return order, nil
}

// 4. Invalidate on mutation
func (s *orderService) Update(ctx context.Context, order *Order) error {
    if err := s.repo.Update(ctx, order); err != nil {
        return err
    }
    s.redis.Del(ctx, fmt.Sprintf("order:%s", order.ID))
    return nil
}
```

### Cache TTL Strategy

| Data Type | TTL | Reason |
|-----------|-----|--------|
| **Frequently read, rarely changes** | 10-30 min | Customer config, product catalog |
| **User session / auth** | Match session TTL | Security |
| **Hot query results** | 1-5 min | Order lists, dashboards |
| **Computed aggregations** | 5-15 min | Revenue reports, counters |
| **Rate limit counters** | Window size | Fixed window: 60s |

## Cache Stampede Prevention

```go
// Use singleflight to prevent thundering herd
var group singleflight.Group

func (s *orderService) GetByID(ctx context.Context, id uuid.UUID) (*Order, error) {
    key := fmt.Sprintf("order:%s", id)

    // Check cache first
    if cached, err := s.cache.Get(ctx, key); err == nil {
        return cached, nil
    }

    // Singleflight: only one goroutine fetches from DB
    result, err, _ := group.Do(key, func() (interface{}, error) {
        order, err := s.repo.GetByID(ctx, id)
        if err != nil {
            return nil, err
        }
        s.cache.Set(ctx, key, order, 5*time.Minute)
        return order, nil
    })

    if err != nil {
        return nil, err
    }
    return result.(*Order), nil
}
```

## Connection Pool Sizing

```
max_connections = (cores * 2) + effective_spindle_count
```

| Environment | Max Connections | Pool per Service |
|-------------|----------------|-----------------|
| **Dev** | 100 | 5-10 |
| **Staging** | 200 | 10-15 |
| **Production** | 300-500 | 20-30 |

Use **PgBouncer** for connection pooling when you have many services connecting to one database.

## Security — Role-Based Access

```sql
-- Read-only role for reporting
CREATE ROLE reporting_ro;
GRANT CONNECT ON DATABASE mydb TO reporting_ro;
GRANT USAGE ON SCHEMA public TO reporting_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_ro;

-- App role: CRUD on specific tables
CREATE ROLE order_service;
GRANT CONNECT ON DATABASE mydb TO order_service;
GRANT USAGE ON SCHEMA public TO order_service;
GRANT SELECT, INSERT, UPDATE, DELETE ON orders, order_items TO order_service;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO order_service;
```
