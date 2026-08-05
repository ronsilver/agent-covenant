# Schema Design Patterns

## Base Table Template

Every table should have these standard columns:

```sql
CREATE TABLE <table_name> (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ                         -- NULL = active (soft delete)
);

-- Auto-update updated_at
CREATE TRIGGER set_<table>_updated_at
    BEFORE UPDATE ON <table_name>
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

## Shipment Domain Schema

```sql
CREATE TABLE customers (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id     TEXT        NOT NULL UNIQUE,
    name            TEXT        NOT NULL,
    country_code    CHAR(2)     NOT NULL,
    is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE shipments (
    id                    UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id           UUID        NOT NULL REFERENCES customers(id),
    idempotency_key       TEXT        NOT NULL UNIQUE,
    quantity              BIGINT      NOT NULL,
    currency_code         CHAR(3)     NOT NULL,
    status                TEXT        NOT NULL DEFAULT 'pending',
    carrier_name          TEXT,
    carrier_transaction_id TEXT,
    carrier_response_code CHAR(2),
    metadata              JSONB,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT shipments_quantity_positive CHECK (quantity > 0),
    CONSTRAINT shipments_status_valid CHECK (
        status IN ('pending', 'processing', 'label_created', 'in_transit', 'delivered', 'failed')
    ),
    CONSTRAINT shipments_currency_valid CHECK (currency_code ~ '^[A-Z]{3}$')
);

CREATE INDEX idx_shipments_customer_id ON shipments(customer_id);
CREATE INDEX idx_shipments_status ON shipments(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_shipments_customer_status ON shipments(customer_id, status);
CREATE INDEX idx_shipments_created_at ON shipments(created_at DESC);
CREATE INDEX idx_shipments_carrier_tx ON shipments(carrier_name, carrier_transaction_id) WHERE carrier_transaction_id IS NOT NULL;
```

## JSONB for Flexible Metadata

```sql
-- Store carrier-specific fields without schema changes
ALTER TABLE shipments ADD COLUMN metadata JSONB;

-- Indexed JSONB field (GIN index)
CREATE INDEX idx_shipments_metadata ON shipments USING GIN(metadata);

-- Query JSONB
SELECT * FROM shipments
WHERE metadata->>'carrier_brand' = 'CARRIER_A'
  AND (metadata->>'anomaly_score')::int < 50;

-- Update specific field
UPDATE shipments
SET metadata = jsonb_set(metadata, '{anomaly_score}', '42')
WHERE id = $1;
```

## Audit Log Table

```sql
CREATE TABLE audit_log (
    id          BIGINT      PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    table_name  TEXT        NOT NULL,
    record_id   UUID        NOT NULL,
    action      TEXT        NOT NULL,   -- INSERT, UPDATE, DELETE
    old_data    JSONB,
    new_data    JSONB,
    changed_by  UUID,                  -- user ID if available
    changed_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_changed_at ON audit_log(changed_at DESC);
```

## Partitioning (High-Volume Tables)

```sql
-- Range partition shipments by month
CREATE TABLE shipments (
    id          UUID        NOT NULL DEFAULT gen_random_uuid(),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ...
) PARTITION BY RANGE (created_at);

CREATE TABLE shipments_2024_01 PARTITION OF shipments
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE shipments_2024_02 PARTITION OF shipments
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
```

## Enum Types

```sql
-- Use CHECK constraint (more flexible than ENUM type)
CONSTRAINT shipment_status_valid CHECK (
    status IN ('pending', 'label_created', 'in_transit', 'delivered', 'failed')
)

-- Or PostgreSQL ENUM (faster, but harder to alter)
CREATE TYPE shipment_status AS ENUM ('pending', 'label_created', 'in_transit', 'delivered', 'failed');
```
